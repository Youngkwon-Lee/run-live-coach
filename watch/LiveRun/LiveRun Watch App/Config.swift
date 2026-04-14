import Foundation

enum Config {
    static let apiBaseURL: String = {
        guard let value = Bundle.main.infoDictionary?["API_BASE_URL"] as? String else {
            fatalError("API_BASE_URL not set in Info.plist")
        }
        return value
    }()

    static let liveMetricsURL: String? = {
        let value = Bundle.main.infoDictionary?["LIVE_METRICS_URL"] as? String
        return value?.isEmpty == false ? value : nil
    }()

    static let liveToken: String? = {
        let value = Bundle.main.infoDictionary?["LIVE_TOKEN"] as? String
        return value?.isEmpty == false ? value : nil
    }()
}
