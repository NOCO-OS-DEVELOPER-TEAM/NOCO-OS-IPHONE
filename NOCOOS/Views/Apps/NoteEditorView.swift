import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject private var notes: NotesService
    @EnvironmentObject private var ai: AIService
    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var bridge: SystemBridge
    @Environment(\.dismiss) private var dismiss

    @State var note: Note
    @State private var aiResult = ""
    @State private var showAIResult = false
    @State private var isAIWorking = false
    @State private var selectionPreview = ""

    var body: some View {
        VStack(spacing: 0) {
            TextField("Titel", text: $note.title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding()

            Divider().overlay(Color.white.opacity(0.15))

            SelectableTextEditor(text: $note.body) { action, text in
                selectionPreview = text
                Task { await runSelectedTextAI(action, text: text) }
            }
            .frame(maxHeight: .infinity)

            if !selectionPreview.isEmpty {
                NOCOTextContextToolbar(
                    selectedText: selectionPreview,
                    onCopy: {
                        UIPasteboard.general.string = selectionPreview
                        NOCOOSTheme.lightHaptic()
                    },
                    onAI: { action in
                        Task { await runSelectedTextAI(action, text: selectionPreview) }
                    }
                )
            } else if !note.body.isEmpty {
                aiToolbar
            }
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
        .navigationTitle("Notiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { saveAndClose() }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("NOCO AI", isPresented: $showAIResult) {
            Button("In Notiz übernehmen") {
                note.body += note.body.isEmpty ? aiResult : "\n\n\(aiResult)"
            }
            Button("Als neue Notiz") {
                bridge.createNoteFromText(aiResult)
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(aiResult)
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.25))
    }

    private func aiActionButton(_ title: String, icon: String, action: @escaping () async -> Void) -> some View {
        Button { Task { await action() } } label: {
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

    private func runSelectedTextAI(_ action: String, text: String) async {
        isAIWorking = true
        defer { isAIWorking = false }
        if let reply = await ai.processSelectedText(action, text: text) {
            aiResult = reply
            showAIResult = true
        }
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
            aiResult = try await api.chat(prompt: prompt, model: nil, notesContext: nil)
            showAIResult = true
            settings.log("Note AI: \(prompt.prefix(30))…")
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
