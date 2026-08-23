import SwiftUI

enum AppRegistry {
    static func view(for app: NOCOAppID) -> AnyView {
        switch app {
        case .nocoAI:
            return AnyView(NOCOAIAppView())
        case .notes:
            return AnyView(NotesAppView())
        case .camera:
            return AnyView(CameraAppView())
        case .settings:
            return AnyView(SettingsAppView())
        case .spotlight:
            return AnyView(SpotlightView())
        }
    }
}
