import Foundation
import SwiftData

/// A photo belonging to a project (final result photos, etc.).
///
/// Photos are stored as files in Application Support; the model only keeps
/// the filename (section 32).
@Model
final class ProjectPhoto {
    var id: UUID
    var caption: String
    var kind: ImageKind
    var imagePath: String
    var createdAt: Date

    var project: Project?

    init(caption: String = "", kind: ImageKind = .actualResult, imagePath: String) {
        self.id = UUID()
        self.caption = caption
        self.kind = kind
        self.imagePath = imagePath
        self.createdAt = Date()
    }
}
