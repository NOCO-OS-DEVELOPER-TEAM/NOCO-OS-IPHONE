import SwiftUI

enum AppRegistry {
    static func view(for app: NOCOAppID) -> AnyView {
        switch app {
        case .nocoAI: return AnyView(NOCOAIAppView())
        case .notes: return AnyView(NotesAppView())
        case .camera: return AnyView(CameraAppView())
        case .video: return AnyView(VideoAppView())
        case .photos: return AnyView(PhotosAppView())
        case .settings: return AnyView(SettingsAppView())
        case .appStore: return AnyView(AppStoreAppView())
        case .games: return AnyView(GamesAppView())
        case .calculator: return AnyView(CalculatorAppView())
        case .calendar: return AnyView(CalendarAppView())
        case .timer: return AnyView(TimerAppView())
        case .weather: return AnyView(WeatherAppView())
        case .music: return AnyView(MusicAppView())
        case .spotlight: return AnyView(SpotlightView())
        }
    }
}
