import SwiftUI

@main
struct NOCOOSApp: App {
    @StateObject private var router = NOCOOSRouter()
    @StateObject private var connection = ConnectionStore()
    @StateObject private var notes = NotesService()
    @StateObject private var settings = SettingsStore()
    @StateObject private var ai: AIService

    init() {
        let connection = ConnectionStore()
        let notes = NotesService()
        let settings = SettingsStore()
        _connection = StateObject(wrappedValue: connection)
        _notes = StateObject(wrappedValue: notes)
        _settings = StateObject(wrappedValue: settings)
        _ai = StateObject(wrappedValue: AIService(connection: connection, notes: notes, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            NOCOOSRootView()
                .environmentObject(router)
                .environmentObject(connection)
                .environmentObject(notes)
                .environmentObject(settings)
                .environmentObject(ai)
                .preferredColorScheme(settings.colorScheme)
                .onOpenURL { url in
                    connection.handleIncomingURL(url)
                }
        }
    }
}
