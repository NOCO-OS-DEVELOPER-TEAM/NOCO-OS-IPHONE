import Foundation
import Combine

@MainActor
final class ConnectionStore: ObservableObject {
    @Published var isPaired = false
    @Published var isOnline = false
    @Published var lastError: String?
    @Published var serverVersion: String?
    @Published var statusMessage = "Nicht verbunden"

    private let tokenKey = "nocoos.companion.token"
    private let hostKey = "nocoos.companion.host"

    var api: CompanionAPI? {
        guard let host = storedHost, let url = URL(string: host) else { return nil }
        return CompanionAPI(baseURL: url, token: KeychainService.load(key: tokenKey))
    }

    var storedHost: String? {
        UserDefaults.standard.string(forKey: hostKey)
    }

    init() {
        isPaired = KeychainService.load(key: tokenKey) != nil && storedHost != nil
        if isPaired {
            statusMessage = "Verbunden"
        }
    }

    func saveHost(_ raw: String) -> Bool {
        guard let host = HostSanitizer.normalizeHost(raw) else {
            lastError = "Ungültige Adresse"
            return false
        }
        UserDefaults.standard.set(host, forKey: hostKey)
        return true
    }

    func pair(pin: String, host: String) async {
        guard saveHost(host) else { return }
        guard let api else {
            lastError = "Server-URL fehlt"
            return
        }
        do {
            let token = try await api.pair(pin: pin, deviceName: "NOCO OS iPhone")
            KeychainService.save(token, key: tokenKey)
            isPaired = true
            lastError = nil
            await refreshStatus()
        } catch {
            lastError = error.localizedDescription
            isPaired = false
        }
    }

    func disconnect() {
        KeychainService.delete(key: tokenKey)
        isPaired = false
        isOnline = false
        statusMessage = "Nicht verbunden"
        serverVersion = nil
    }

    func refreshStatus() async {
        guard let api else {
            isOnline = false
            statusMessage = "Kein Server konfiguriert"
            return
        }
        do {
            let status = try await api.status()
            isOnline = status.ok
            serverVersion = status.version
            statusMessage = isOnline ? "Online" : "Offline"
            lastError = nil
        } catch {
            isOnline = false
            statusMessage = "Offline"
            lastError = error.localizedDescription
        }
    }

    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "nocoos" else { return }
        if url.host == "pair" {
            // nocoos://pair?host=...&pin=...
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let host = components?.queryItems?.first(where: { $0.name == "host" })?.value
            let pin = components?.queryItems?.first(where: { $0.name == "pin" })?.value
            if let host, let pin {
                Task { await pair(pin: pin, host: host) }
            }
        }
    }
}
