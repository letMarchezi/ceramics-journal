import Foundation
import SwiftData

/// One glaze applied to a project, with its placement area (section 14).
@Model
final class GlazeApplication {
    var id: UUID

    var glaze: Glaze?
    var area: ApplicationArea
    var areaLabel: String?
    var opacity: Double
    var notes: String?
    var order: Int
    var createdAt: Date

    // Snapshots so history survives glaze edits/deletion.
    var snapshotGlazeName: String?
    var snapshotGlazeFinish: GlazeFinish
    var snapshotFiredImagePath: String?

    var project: Project?

    init(
        glaze: Glaze?,
        area: ApplicationArea = .entirePiece,
        areaLabel: String? = nil,
        opacity: Double = 1.0,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = UUID()
        self.glaze = glaze
        self.area = area
        self.areaLabel = areaLabel
        self.opacity = opacity
        self.notes = notes
        self.order = order
        self.createdAt = Date()
        self.snapshotGlazeName = glaze?.name
        self.snapshotGlazeFinish = glaze?.finish ?? .unknown
        self.snapshotFiredImagePath = glaze?.firedImagePath
    }

    var displayGlazeName: String {
        glaze?.name ?? snapshotGlazeName ?? "Unknown glaze"
    }
}
