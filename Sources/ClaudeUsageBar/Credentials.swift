import Foundation

/// Reads the OAuth access token that Claude Code stores after `claude` login.
/// macOS: Keychain item "Claude Code-credentials". Fallback: ~/.claude/.credentials.json
enum Credentials {
    struct Token {
        let accessToken: String
        let expiresAt: Date?
    }

    enum CredError: LocalizedError {
        case notFound
        case malformed
        var errorDescription: String? {
            switch self {
            case .notFound: return "No Claude Code login found. Run `claude` in Terminal and log in."
            case .malformed: return "Couldn't read Claude Code credentials."
            }
        }
    }

    static func load() throws -> Token {
        if let data = keychainData() ?? fileData() {
            return try parse(data)
        }
        throw CredError.notFound
    }

    private static func parse(_ data: Data) throws -> Token {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String else {
            throw CredError.malformed
        }
        var expires: Date?
        if let ms = oauth["expiresAt"] as? Double {
            expires = Date(timeIntervalSince1970: ms / 1000)
        }
        return Token(accessToken: token, expiresAt: expires)
    }

    /// Uses the `security` CLI so the app needs no keychain entitlements.
    /// macOS will ask once to allow access — choose "Always Allow".
    private static func keychainData() -> Data? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let trimmed = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Data(trimmed.utf8)
    }

    private static func fileData() -> Data? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/.credentials.json")
        return try? Data(contentsOf: url)
    }
}
