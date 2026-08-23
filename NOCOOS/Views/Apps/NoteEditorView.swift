import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject private var notes: NotesService
    @Environment(\.dismiss) private var dismiss

    @State var note: Note
    @State private var showAIMenu = false
    @State private var aiResult = ""
    @State private var showAIResult = false
    @State private var isAIWorking = false

    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Titel", text: $note.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding()

                Divider().overlay(Color.white.opacity(0.15))

                TextEditor(text: $note.body)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .padding(12)

                if !note.body.isEmpty {
                    aiToolbar
                }
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.14))
            .navigationTitle("Notiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { saveAndClose() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { saveAndClose() }
                }
            }
            .alert("NOCO AI", isPresented: $showAIResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(aiResult)
            }
        }
    }

    private var aiToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                aiActionButton("Zusammenfassen", icon: "text.alignleft") {
                    await runAI("Fasse folgenden Text kurz zusammen:\n\(note.body)")
                }
                aiActionButton("Erklären", icon: "questionmark.circle") {
                    await runAI("Erkläre folgenden Text einfach:\n\(note.body)")
                }
                aiActionButton("Umformulieren", icon: "arrow.triangle.2.circlepath") {
                    await runAI("Formuliere folgenden Text um:\n\(note.body)")
                }
                aiActionButton("Rechtschreibung", icon: "textformat") {
                    await runAI("Verbessere Rechtschreibung und Grammatik:\n\(note.body)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.25))
    }

    private func aiActionButton(_ title: String, icon: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .nocoGlass(cornerRadius: 12, opacity: 0.1)
        }
        .buttonStyle(.plain)
        .disabled(isAIWorking)
    }

    private func runAI(_ prompt: String) async {
        guard connection.isPaired, let api = connection.api else {
            aiResult = "Server nicht verbunden."
            showAIResult = true
            return
        }
        isAIWorking = true
        defer { isAIWorking = false }
        do {
            let reply = try await api.chat(prompt: prompt, model: nil, notesContext: nil)
            aiResult = reply
            showAIResult = true
            settings.log("Note AI action: \(prompt.prefix(40))…")
        } catch {
            aiResult = error.localizedDescription
            showAIResult = true
        }
    }

    private func saveAndClose() {
        notes.update(note)
        dismiss()
    }
}
