import Foundation

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var preview: String {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "Leere Notiz" }
        return String(text.prefix(120))
    }

    var searchableText: String {
        ([title] + tags + [body]).joined(separator: " ").lowercased()
    }
}
