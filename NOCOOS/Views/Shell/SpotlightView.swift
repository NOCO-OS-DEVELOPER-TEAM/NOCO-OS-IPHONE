import SwiftUI

struct SpotlightView: View {
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var notes: NotesService
    @EnvironmentObject private var ai: AIService
    @StateObject private var spotlight = SpotlightService()

    @State private var query = ""
    @FocusState private var focused: Bool
    @State private var dragOffset: CGFloat = 0

    private var searchService: SearchService {
        SearchService(notes: notes)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture { router.closeSpotlight() }

            VStack(spacing: 0) {
                dragHandle
                searchBar
                content
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height * 0.35
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 80 {
                            router.closeSpotlight()
                        }
                        withAnimation(NOCOOSTheme.spring()) {
                            dragOffset = 0
                        }
                    }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        .onAppear {
            focused = true
            dragOffset = 0
        }
        .onDisappear {
            spotlight.clear()
        }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.25))
            .frame(width: 42, height: 5)
            .padding(.bottom, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(NOCOOSTheme.accentGlow)
                .symbolEffect(.pulse, options: spotlight.isProcessing ? .repeating : .nonRepeating)
            TextField("Fragen, suchen, rechnen …", text: $query)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .foregroundStyle(.white)
                .onSubmit { Task { await submitQuery() } }
            if spotlight.isProcessing {
                ProgressView().tint(NOCOOSTheme.accent)
            } else if !query.isEmpty {
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
        .nocoGlass(cornerRadius: 20)
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if !spotlight.entries.isEmpty {
                        conversation
                        continueInAIButton
                    } else if !query.isEmpty {
                        quickResults
                    } else {
                        suggestions
                    }
                }
                .padding(.vertical, 14)
            }
            .onChange(of: spotlight.entries.count) { _, _ in
                if let last = spotlight.entries.last?.id {
                    withAnimation(NOCOOSTheme.spring()) {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var continueInAIButton: some View {
        Button {
            router.closeSpotlight()
            router.open(.nocoAI)
        } label: {
            Label("In NOCO AI fortsetzen", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NOCOOSTheme.accentGlow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .nocoGlass(cornerRadius: 14, opacity: 0.1)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var conversation: some View {
        ForEach(spotlight.entries) { entry in
            spotlightBubble(entry)
                .id(entry.id)
                .transition(.asymmetric(
                    insertion: .move(edge: entry.role == .user ? .trailing : .leading).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vorschläge")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NOCOOSTheme.textSecondary)
                .padding(.horizontal, 4)

            ForEach(searchService.suggestions()) { result in
                suggestionRow(result)
            }
        }
    }

    private var quickResults: some View {
        ForEach(searchService.search(query)) { result in
            suggestionRow(result)
        }
    }

    private func suggestionRow(_ result: SearchResult) -> some View {
        Button {
            if result.kind == .aiSuggestion, let q = result.query {
                query = q
                Task { await submitQuery() }
            } else {
                open(result)
            }
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
            }
            .padding(14)
            .nocoGlass(cornerRadius: 16, opacity: 0.08)
        }
        .buttonStyle(.plain)
    }

    private func spotlightBubble(_ entry: SpotlightEntry) -> some View {
        HStack {
            if entry.role == .user { Spacer(minLength: 36) }
            VStack(alignment: entry.role == .user ? .trailing : .leading, spacing: 4) {
                if entry.role == .action {
                    Label(entry.text, systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                } else {
                    Text(entry.text)
                        .font(.body)
                }
            }
            .foregroundStyle(entry.role == .user ? Color.black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(bubbleColor(for: entry.role))
            )
            .opacity(entry.isProcessing ? 0.7 : 1)
            if entry.role != .user { Spacer(minLength: 36) }
        }
        .padding(.horizontal, 4)
    }

    private func bubbleColor(for role: SpotlightEntry.Role) -> Color {
        switch role {
        case .user: return .white
        case .assistant: return Color.white.opacity(0.14)
        case .action: return NOCOOSTheme.accent.opacity(0.35)
        case .calculating: return Color.white.opacity(0.10)
        }
    }

    private func icon(for kind: SearchResult.Kind) -> String {
        switch kind {
        case .app: return "app.fill"
        case .note: return "note.text"
        case .action: return "bolt.fill"
        case .aiSuggestion: return "sparkles"
        case .calculation: return "function"
        }
    }

    private func submitQuery() async {
        let text = query
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        NOCOOSTheme.lightHaptic()
        query = ""
        await spotlight.submit(text, ai: ai, router: router, notes: notes)
    }

    private func open(_ result: SearchResult) {
        switch result.kind {
        case .app, .action:
            if let app = result.app {
                router.closeSpotlight()
                if app == .notes, let q = result.query {
                    router.openNotes(search: q)
                } else {
                    router.open(app)
                }
            }
        case .note:
            router.closeSpotlight()
            if let id = result.noteID {
                router.openNotes(noteID: id)
            } else {
                router.open(.notes)
            }
        case .aiSuggestion:
            if let q = result.query {
                query = q
                Task { await submitQuery() }
            }
        case .calculation:
            break
        }
    }
}
