import Foundation

extension HealthKitIngestService {
    static func fromBuildSettings() -> HealthKitIngestService {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "RUN_INGEST_URL") as? String ?? ""
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "RUN_INGEST_API_KEY") as? String ?? ""
        let signingSecret = Bundle.main.object(forInfoDictionaryKey: "RUN_INGEST_SIGNING_SECRET") as? String ?? ""

        return HealthKitIngestService(
            ingestURL: URL(string: urlString) ?? URL(string: "https://example.com")!,
            ingestApiKey: apiKey,
            signingSecret: signingSecret
        )
    }
}
