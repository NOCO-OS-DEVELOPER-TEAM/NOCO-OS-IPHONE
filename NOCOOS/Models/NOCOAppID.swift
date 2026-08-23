import SwiftUI

enum NOCOAppID: String, CaseIterable, Identifiable, Codable {
    case nocoAI = "noco_ai"
    case notes = "notes"
    case camera = "camera"
    case video = "video"
    case photos = "photos"
    case settings = "settings"
    case appStore = "app_store"
    case games = "games"
    case calculator = "calculator"
    case calendar = "calendar"
    case timer = "timer"
    case weather = "weather"
    case music = "music"
    case spotlight = "spotlight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nocoAI: return "NOCO AI"
        case .notes: return "Notizen"
        case .camera: return "Kamera"
        case .video: return "Video"
        case .photos: return "Fotos"
        case .settings: return "Einstellungen"
        case .appStore: return "App Store"
        case .games: return "Spiele"
        case .calculator: return "Rechner"
        case .calendar: return "Kalender"
        case .timer: return "Timer"
        case .weather: return "Wetter"
        case .music: return "Musik"
        case .spotlight: return "Spotlight"
        }
    }

    var iconName: String {
        switch self {
        case .nocoAI: return "sparkles"
        case .notes: return "note.text"
        case .camera: return "camera.fill"
        case .video: return "video.fill"
        case .photos: return "photo.on.rectangle.angled"
        case .settings: return "gearshape.fill"
        case .appStore: return "bag.fill"
        case .games: return "gamecontroller.fill"
        case .calculator: return "function"
        case .calendar: return "calendar"
        case .timer: return "timer"
        case .weather: return "cloud.sun.fill"
        case .music: return "music.note"
        case .spotlight: return "magnifyingglass"
        }
    }

    var accent: Color {
        switch self {
        case .nocoAI: return Color(red: 0.45, green: 0.55, blue: 1.0)
        case .notes: return Color(red: 1.0, green: 0.78, blue: 0.25)
        case .camera: return Color(red: 0.35, green: 0.85, blue: 0.65)
        case .video: return Color(red: 0.95, green: 0.35, blue: 0.45)
        case .photos: return Color(red: 0.55, green: 0.75, blue: 1.0)
        case .settings: return Color(red: 0.65, green: 0.68, blue: 0.75)
        case .appStore: return Color(red: 0.30, green: 0.55, blue: 1.0)
        case .games: return Color(red: 0.85, green: 0.40, blue: 0.95)
        case .calculator: return Color(red: 0.45, green: 0.45, blue: 0.50)
        case .calendar: return Color(red: 1.0, green: 0.45, blue: 0.35)
        case .timer: return Color(red: 0.35, green: 0.90, blue: 0.75)
        case .weather: return Color(red: 0.40, green: 0.70, blue: 1.0)
        case .music: return Color(red: 1.0, green: 0.35, blue: 0.55)
        case .spotlight: return Color(red: 0.55, green: 0.75, blue: 1.0)
        }
    }

    var isSystemApp: Bool { self != .spotlight }

    var storeDescription: String {
        switch self {
        case .nocoAI: return "System-KI und Assistent"
        case .notes: return "Notizen erstellen und durchsuchen"
        case .camera: return "Fotos und Videos aufnehmen"
        case .video: return "Videoaufnahmen mit Live-Vorschau"
        case .photos: return "Mediathek durchsuchen"
        case .games: return "NOCO Minispiele"
        case .calculator: return "Schnelle Berechnungen"
        case .calendar: return "Termine und Übersicht"
        case .timer: return "Countdown und Stoppuhr"
        case .weather: return "Wetter auf einen Blick"
        case .music: return "Musik abspielen"
        case .settings: return "System und NOCO AI Server"
        case .appStore: return "NOCO OS Apps entdecken"
        case .spotlight: return "Intelligente Systemsuche"
        }
    }

    static var homeScreenApps: [NOCOAppID] {
        [.nocoAI, .notes, .camera, .photos, .calculator, .games, .appStore, .weather, .music, .calendar, .timer, .settings]
    }

    static var storeApps: [NOCOAppID] {
        allCases.filter { $0.isSystemApp && $0 != .appStore }
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
