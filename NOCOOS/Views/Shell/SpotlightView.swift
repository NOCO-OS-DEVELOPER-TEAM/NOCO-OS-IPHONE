import SwiftUI

struct SpotlightView: View {
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var notes: NotesService
    @State private var query = ""
    @FocusState private var focused: Bool

    private var searchService: SearchService {
        SearchService(notes: notes)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { router.closeSpotlight() }

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NOCOOSTheme.textSecondary)
                    TextField("Apps, Notizen, Befehle …", text: $query)
                        .focused($focused)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(NOCOOSTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .nocoGlass(cornerRadius: 18)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(searchService.search(query)) { result in
                            Button {
                                open(result)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: icon(for: result.kind))
                                        .foregroundStyle(NOCOOSTheme.accent)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .foregroundStyle(.white)
                                            .font(.body.weight(.medium))
                                        Text(result.subtitle)
                                            .foregroundStyle(NOCOOSTheme.textSecondary)
                                            .font(.caption)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(NOCOOSTheme.textSecondary)
                                }
                                .padding(14)
                                .nocoGlass(cornerRadius: 16, opacity: 0.08)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
            .padding(.top, 40)
        }
        .onAppear {
            focused = true
        }
    }

    private func icon(for kind: SearchResult.Kind) -> String {
        switch kind {
        case .app: return "app.fill"
        case .note: return "note.text"
        case .action: return "bolt.fill"
        case .aiSuggestion: return "sparkles"
        }
    }

    private func open(_ result: SearchResult) {
        router.closeSpotlight()
        switch result.kind {
        case .app, .action, .aiSuggestion:
            if let app = result.app {
                if app == .notes, let q = result.query {
                    router.openNotes(search: q)
                } else if app == .nocoAI, let q = result.query {
                    router.open(.nocoAI)
                    // pending prompt handled in NOCOAIAppView via notification
                    NotificationCenter.default.post(name: .nocoOSSpotlightAI, object: q)
                } else {
                    router.open(app)
                }
            }
        case .note:
            if let id = result.noteID {
                router.openNotes(noteID: id)
            } else {
                router.open(.notes)
            }
        }
    }
}

extension Notification.Name {
    static let nocoOSSpotlightAI = Notification.Name("nocoos.spotlight.ai")
}
