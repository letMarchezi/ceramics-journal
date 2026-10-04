import Foundation
import SwiftData

/// A chronological construction / journal entry (section 20).
@Model
final class JournalEntry {
    var id: UUID
    var createdAt: Date
    var title: String
    var text: String
    var photoPaths: [String]

    var project: Project?

    init(
        title: String,
        text: String = "",
        project: Project? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.title = title
        self.text = text
        self.photoPaths = []
        self.project = project
    }
}
