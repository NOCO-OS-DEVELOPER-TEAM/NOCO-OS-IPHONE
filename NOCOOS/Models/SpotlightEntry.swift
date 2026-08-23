import Foundation

struct SpotlightEntry: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case assistant
        case action
        case calculating
    }

    let id: UUID
    let role: Role
    var text: String
    let createdAt: Date
    var isProcessing: Bool

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date(), isProcessing: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.isProcessing = isProcessing
    }
}
