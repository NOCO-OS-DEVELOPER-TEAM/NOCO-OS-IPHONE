import SwiftUI

enum NOCOAppID: String, CaseIterable, Identifiable, Codable {
    case nocoAI = "noco_ai"
    case notes = "notes"
    case camera = "camera"
    case settings = "settings"
    case spotlight = "spotlight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nocoAI: return "NOCO AI"
        case .notes: return "Notizen"
        case .camera: return "Kamera"
        case .settings: return "Einstellungen"
        case .spotlight: return "Spotlight"
        }
    }

    var iconName: String {
        switch self {
        case .nocoAI: return "sparkles"
        case .notes: return "note.text"
        case .camera: return "camera.fill"
        case .settings: return "gearshape.fill"
        case .spotlight: return "magnifyingglass"
        }
    }

    var accent: Color {
        switch self {
        case .nocoAI: return Color(red: 0.45, green: 0.55, blue: 1.0)
        case .notes: return Color(red: 1.0, green: 0.78, blue: 0.25)
        case .camera: return Color(red: 0.35, green: 0.85, blue: 0.65)
        case .settings: return Color(red: 0.65, green: 0.68, blue: 0.75)
        case .spotlight: return Color(red: 0.55, green: 0.75, blue: 1.0)
        }
    }

    var isSystemApp: Bool {
        self != .spotlight
    }

    static var homeScreenApps: [NOCOAppID] {
        [.nocoAI, .notes, .camera, .settings]
    }
}

struct NOCOAppDescriptor: Identifiable {
    let id: NOCOAppID
    let displayName: String
    let iconName: String
    let accent: Color

    init(_ app: NOCOAppID) {
        id = app
        displayName = app.displayName
        iconName = app.iconName
        accent = app.accent
    }
}
