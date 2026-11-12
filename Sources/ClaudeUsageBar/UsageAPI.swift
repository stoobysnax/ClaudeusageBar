import Foundation

struct UsageWindow: Decodable {
    /// Percent used, 0–100.
    let utilization: Double
    let resetsAt: Date?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        utilization = (try? c.decode(Double.self, forKey: .utilization)) ?? 0
        if let s = try? c.decode(String.self, forKey: .resetsAt) {
            resetsAt = UsageWindow.parseDate(s)
        } else {
            resetsAt = nil
        }
    }

    static func parseDate(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}

struct UsageResponse: Decodable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDayOpus: UsageWindow?
    let sevenDaySonnet: UsageWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
    }
}

enum UsageAPI {
    enum APIError: LocalizedError {
        case expired
        case http(Int, String)
        var errorDescription: String? {
            switch self {
            case .expired:
                return "Login expired. Run `claude` in Terminal once to refresh it."
            case let .http(code, body):
                return "HTTP \(code): \(body.prefix(200))"
            }
        }
    }

    /// Same endpoint Claude Code's `/usage` command uses.
    static func fetch() async throws -> UsageResponse {
        let cred = try Credentials.load()
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.setValue("Bearer \(cred.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 20

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if code == 401 { throw APIError.expired }
        guard (200..<300).contains(code) else {
            throw APIError.http(code, String(decoding: data, as: UTF8.self))
        }
        return try JSONDecoder().decode(UsageResponse.self, from: data)
    }
}
