import Foundation

enum HostSanitizer {
    static func normalizeHost(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if !value.contains("://") {
            value = "http://\(value)"
        }

        guard var components = URLComponents(string: value),
              let host = components.host, !host.isEmpty else {
            return nil
        }

        if components.scheme == nil {
            components.scheme = "http"
        }
        if components.port == nil {
            components.port = 4747
        }
        components.path = ""
        components.query = nil
        components.fragment = nil

        return components.url?.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
