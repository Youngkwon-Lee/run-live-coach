import Foundation
import HealthKit
import CryptoKit

struct RunIngestPayload: Codable {
    let external_run_id: String
    let started_at: String
    let ended_at: String
    let distance_m: Double
    let moving_time_s: Int
    let elevation_gain_m: Double?
    let avg_hr: Double?
    let max_hr: Double?
    let cadence_avg: Double?
    let splits: [String: String]?
}

final class HealthKitIngestService {
    private let store = HKHealthStore()
    private let ingestURL: URL
    private let ingestApiKey: String
    private let signingSecret: String

    init(
        ingestURL: URL,
        ingestApiKey: String,
        signingSecret: String
    ) {
        self.ingestURL = ingestURL
        self.ingestApiKey = ingestApiKey
        self.signingSecret = signingSecret
    }

    func requestPermissions() async throws {
        let workout = HKObjectType.workoutType()
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!

        try await store.requestAuthorization(toShare: [], read: [workout, heartRate, distance])
    }

    func syncLatestRun() async throws {
        let workout = try await fetchLatestRunningWorkout()
        let avgHR = try await avgHeartRate(for: workout)
        let maxHR = try await maxHeartRate(for: workout)

        let payload = RunIngestPayload(
            external_run_id: "apple_health_\(workout.uuid.uuidString)",
            started_at: iso8601(workout.startDate),
            ended_at: iso8601(workout.endDate),
            distance_m: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
            moving_time_s: Int(workout.duration.rounded()),
            elevation_gain_m: nil,
            avg_hr: avgHR,
            max_hr: maxHR,
            cadence_avg: nil,
            splits: nil
        )

        try await send(payload: payload)
    }

    private func fetchLatestRunningWorkout() async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { cont in
            let type = HKObjectType.workoutType()
            let predicate = HKQuery.predicateForWorkouts(with: .running)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error { return cont.resume(throwing: error) }
                guard let run = samples?.first as? HKWorkout else {
                    return cont.resume(throwing: NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No running workout"]))
                }
                cont.resume(returning: run)
            }
            self.store.execute(q)
        }
    }

    private func avgHeartRate(for workout: HKWorkout) async throws -> Double? {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
        return try await quantityStatistics(type: hrType, predicate: predicate, option: .discreteAverage)?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }

    private func maxHeartRate(for workout: HKWorkout) async throws -> Double? {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
        return try await quantityStatistics(type: hrType, predicate: predicate, option: .discreteMax)?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }

    private func quantityStatistics(type: HKQuantityType, predicate: NSPredicate, option: HKStatisticsOptions) async throws -> HKQuantity? {
        try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: option) { _, stats, error in
                if let error { return cont.resume(throwing: error) }
                let result: HKQuantity?
                switch option {
                case .discreteAverage: result = stats?.averageQuantity()
                case .discreteMax: result = stats?.maximumQuantity()
                default: result = nil
                }
                cont.resume(returning: result)
            }
            self.store.execute(q)
        }
    }

    private func send(payload: RunIngestPayload) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        let bodyData = try encoder.encode(payload)
        let raw = String(data: bodyData, encoding: .utf8)!

        let sig = hmacSHA256Hex(secret: signingSecret, message: raw)

        var req = URLRequest(url: ingestURL)
        req.httpMethod = "POST"
        req.httpBody = bodyData
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(ingestApiKey)", forHTTPHeaderField: "Authorization")
        req.setValue(ingestApiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(sig, forHTTPHeaderField: "x-signature")

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "Ingest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ingest failed"])
        }
    }

    private func hmacSHA256Hex(secret: String, message: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let sig = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return sig.map { String(format: "%02x", $0) }.joined()
    }

    private func iso8601(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.string(from: date)
    }
}
