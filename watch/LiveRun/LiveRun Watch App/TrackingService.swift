import Foundation

struct TrackingPoint: Codable {
    let runId: String
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let heartRate: Double?
    let pace: Double?
    let distanceMeters: Double?
    let cadence: Double?
    let gradeAdjustedPace: Double?
    let recordedAt: Date

    enum CodingKeys: String, CodingKey {
        case runId, latitude, longitude, altitude, heartRate, pace, distanceMeters, cadence, gradeAdjustedPace, recordedAt
    }
}

struct LiveMetricsPayload: Codable {
    let session_id: String
    let pace_sec: Double
    let hr: Double?
    let distance_km: Double
    let elapsed_sec: Int
    let force: Bool
}

actor TrackingService {
    // MARK: - Configuration
    private let baseURL = Config.apiBaseURL
    private let liveMetricsURL = Config.liveMetricsURL
    private let liveToken = Config.liveToken
    var bearerToken: String?

    private var buffer: [TrackingPoint] = []
    private let maxBatchSize = 1
    private let maxInterval: TimeInterval = 2
    private var lastFlushDate = Date()
    private(set) var lastCheerSeenId: Int = 0

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.liverun.tracking")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config)
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    func configure(token: String?) {
        bearerToken = token
    }

    // MARK: - Run lifecycle

    private func addAuth(_ request: inout URLRequest) {
        if let token = bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    func createRun() async -> String? {
        guard let url = URL(string: "\(baseURL)/api/runs") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuth(&request)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(RunResponse.self, from: data)
            return result.id
        } catch {
            print("Failed to create run: \(error)")
            return nil
        }
    }

    func endRun(runId: String) async {
        guard let url = URL(string: "\(baseURL)/api/runs/\(runId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addAuth(&request)

        do {
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Failed to end run: \(error)")
        }
    }

    // MARK: - Point batching

    @discardableResult
    func enqueue(_ point: TrackingPoint) async -> CheerUpdate? {
        if liveMetricsURL != nil {
            await sendLiveMetrics(point)
            return nil
        }

        buffer.append(point)

        let timeSinceFlush = Date().timeIntervalSince(lastFlushDate)
        if buffer.count >= maxBatchSize || timeSinceFlush >= maxInterval {
            return await flush()
        }
        return nil
    }

    private func sendLiveMetrics(_ point: TrackingPoint) async {
        print("🚀 Sending live metrics: pace=\(point.pace ?? 0), hr=\(point.heartRate ?? 0), dist=\(point.distanceMeters ?? 0)")
        guard let liveMetricsURL,
              let url = URL(string: liveMetricsURL) else { return }

        let paceSec = (point.pace ?? 0) * 60.0
        let distanceKm = (point.distanceMeters ?? 0) / 1000.0
        let elapsed = 0

        let payload = LiveMetricsPayload(
            session_id: point.runId,
            pace_sec: paceSec,
            hr: point.heartRate.map { (($0 * 10).rounded() / 10) },
            distance_km: distanceKm,
            elapsed_sec: elapsed,
            force: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let liveToken, !liveToken.isEmpty {
            request.setValue(liveToken, forHTTPHeaderField: "x-live-token")
        }

        do {
            request.httpBody = try encoder.encode(payload)
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Failed to send live metrics: \(error)")
        }
    }

    @discardableResult
    func flush() async -> CheerUpdate? {
        guard !buffer.isEmpty else { return nil }

        let points = buffer
        buffer.removeAll()
        lastFlushDate = Date()

        guard let url = URL(string: "\(baseURL)/api/track?cheersAfter=\(lastCheerSeenId)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuth(&request)

        do {
            request.httpBody = try encoder.encode(points)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TrackResponse.self, from: data)
            if let cheers = response.cheers {
                lastCheerSeenId = cheers.lastId
                return cheers.count > 0 ? cheers : nil
            }
            return nil
        } catch {
            // Re-enqueue on failure
            buffer.insert(contentsOf: points, at: 0)
            print("Failed to send points: \(error)")
            return nil
        }
    }
}

struct CheerUpdate: Codable {
    let count: Int
    let highlight: CheerHighlight?
    let lastId: Int
}

struct CheerHighlight: Codable {
    let id: Int
    let message: String
}

private struct TrackResponse: Codable {
    let ok: Bool
    let cheers: CheerUpdate?
}

private struct RunResponse: Codable {
    let id: String
}
