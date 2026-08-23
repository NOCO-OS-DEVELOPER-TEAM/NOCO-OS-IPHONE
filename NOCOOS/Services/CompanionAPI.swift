import Foundation

enum CompanionAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case invalidPIN
    case unreachable
    case server(String)
    case network(Error)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige Server-Adresse"
        case .unauthorized: return "Kopplung ungültig – bitte erneut verbinden"
        case .invalidPIN: return "PIN ungültig oder abgelaufen"
        case .unreachable: return "Server nicht erreichbar"
        case .server(let msg): return msg
        case .network(let err): return err.localizedDescription
        case .decoding: return "Antwort konnte nicht gelesen werden"
        }
    }
}

struct CompanionStatus: Codable {
    let ok: Bool
    let version: String?
    let model: String?
}

struct CompanionChatResponse: Codable {
    let reply: String?
    let text: String?
    let message: String?

    var content: String {
        reply ?? text ?? message ?? ""
    }
}

struct CompanionAPI {
    let baseURL: URL
    var token: String?

    func status() async throws -> CompanionStatus {
        try await get("/api/v1/status", as: CompanionStatus.self)
    }

    func pair(pin: String, deviceName: String) async throws -> String {
        struct PairBody: Encodable {
            let pin: String
            let deviceName: String
            let platform: String
        }
        struct PairResponse: Decodable {
            let token: String
        }
        let response: PairResponse = try await post(
            "/api/v1/pair",
            body: PairBody(pin: pin, deviceName: deviceName, platform: "nocoos"),
            as: PairResponse.self,
            auth: false
        )
        return response.token
    }

    func chat(prompt: String, model: String?, notesContext: String?) async throws -> String {
        struct ChatBody: Encodable {
            let prompt: String
            let model: String?
            let context: String?
            let source: String
        }
        let response: CompanionChatResponse = try await post(
            "/api/v1/chat",
            body: ChatBody(
                prompt: prompt,
                model: model,
                context: notesContext,
                source: "nocoos"
            ),
            as: CompanionChatResponse.self
        )
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CompanionAPIError.decoding }
        return text
    }

    private func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw CompanionAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await perform(request, as: type)
    }

    private func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B,
        as type: T.Type,
        auth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw CompanionAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60
        if auth, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await perform(request, as: type)
    }

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CompanionAPIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CompanionAPIError.unreachable
        }

        switch http.statusCode {
        case 200...299:
            break
        case 401:
            throw CompanionAPIError.unauthorized
        case 403:
            throw CompanionAPIError.invalidPIN
        default:
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw CompanionAPIError.server(msg)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CompanionAPIError.decoding
        }
    }
}
