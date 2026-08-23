import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @Published var serverHost: String {
        didSet { UserDefaults.standard.set(serverHost, forKey: Keys.serverHost) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    @Published var animationsEnabled: Bool {
        didSet { UserDefaults.standard.set(animationsEnabled, forKey: Keys.animations) }
    }
    @Published var voiceEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: Keys.voice) }
    }
    @Published var aiModelName: String {
        didSet { UserDefaults.standard.set(aiModelName, forKey: Keys.aiModel) }
    }
    @Published var debugLogs: [String] = []

    private enum Keys {
        static let serverHost = "nocoos.serverHost"
        static let haptics = "nocoos.haptics"
        static let animations = "nocoos.animations"
        static let voice = "nocoos.voice"
        static let aiModel = "nocoos.aiModel"
    }

    init() {
        serverHost = UserDefaults.standard.string(forKey: Keys.serverHost) ?? ""
        hapticsEnabled = UserDefaults.standard.object(forKey: Keys.haptics) as? Bool ?? true
        animationsEnabled = UserDefaults.standard.object(forKey: Keys.animations) as? Bool ?? true
        voiceEnabled = UserDefaults.standard.object(forKey: Keys.voice) as? Bool ?? true
        aiModelName = UserDefaults.standard.string(forKey: Keys.aiModel) ?? "default"
    }

    var colorScheme: ColorScheme? { .dark }

    func log(_ message: String) {
        let line = "[\(Self.timestamp())] \(message)"
        debugLogs.insert(line, at: 0)
        if debugLogs.count > 200 {
            debugLogs = Array(debugLogs.prefix(200))
        }
    }

    func clearLogs() {
        debugLogs.removeAll()
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }
}
