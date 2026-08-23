import SwiftUI

struct SettingsAppView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var connection: ConnectionStore

    @State private var hostInput = ""
    @State private var pinInput = ""
    @State private var testResult = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("NOCO AI Server") {
                    TextField("Server (z.B. 192.168.1.10:4747)", text: $hostInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("PIN", text: $pinInput)
                        .keyboardType(.numberPad)
                    Button("Verbinden") {
                        Task {
                            let host = hostInput.isEmpty ? (connection.storedHost ?? "") : hostInput
                            await connection.pair(pin: pinInput, host: host)
                            settings.log("Pairing attempt")
                        }
                    }
                    Button("Verbindung testen") {
                        Task {
                            await connection.refreshStatus()
                            testResult = connection.isOnline ? "Server erreichbar ✓" : (connection.lastError ?? "Offline")
                        }
                    }
                    if !testResult.isEmpty {
                        Text(testResult).font(.caption)
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(connection.statusMessage)
                            .foregroundStyle(connection.isOnline ? .green : .orange)
                    }
                    if let version = connection.serverVersion {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(version).foregroundStyle(.secondary)
                        }
                    }
                    if connection.isPaired {
                        Button("Trennen", role: .destructive) {
                            connection.disconnect()
                            settings.log("Disconnected")
                        }
                    }
                }

                Section("System") {
                    Toggle("Haptik", isOn: $settings.hapticsEnabled)
                    Toggle("Animationen", isOn: $settings.animationsEnabled)
                    Toggle("Sprachsteuerung", isOn: $settings.voiceEnabled)
                    TextField("KI-Modell", text: $settings.aiModelName)
                        .textInputAutocapitalization(.never)
                }

                Section("Entwickler") {
                    Button("Logs löschen") { settings.clearLogs() }
                    if settings.debugLogs.isEmpty {
                        Text("Keine Logs").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(settings.debugLogs.prefix(20), id: \.self) { line in
                            Text(line).font(.caption2.monospaced())
                        }
                    }
                }

                Section("Datenschutz") {
                    Text("NOCO OS speichert Notizen lokal auf dem iPhone. KI-Anfragen gehen nur an deinen konfigurierten NOCO AI Server im lokalen Netzwerk.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
        }
        .onAppear {
            hostInput = connection.storedHost ?? settings.serverHost
        }
    }
}
