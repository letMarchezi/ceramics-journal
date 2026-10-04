import Foundation
import SwiftData

/// A single ceramic piece, from idea to fired result (FR-001, FR-002).
///
/// The project keeps *snapshots* of the materials assigned to it so that
/// later edits or deletion of library materials never rewrite history
/// (sections 38 & 39 of the spec).
@Model
final class Project {
    var id: UUID
    var name: String
    var status: ProjectStatus
    var createdAt: Date
    var updatedAt: Date = Date()

    var notes: String?

    var shape: PieceShape?
    var clay: Clay?

    // Material snapshots (historical record, preserved after edits/deletion).
    var claySnapshotName: String?
    var claySnapshotManufacturer: String?
    var claySnapshotFiredPath: String?

    // Inspiration image — always shown and labeled as "Inspiration" only.
    var inspirationImagePath: String?
    var inspirationTitle: String?
    var inspirationNotes: String?
    var inspirationSource: String?

    @Relationship(deleteRule: .cascade, inverse: \GlazeApplication.project)
    var glazeApplications: [GlazeApplication]

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.project)
    var journalEntries: [JournalEntry]

    @Relationship(deleteRule: .cascade, inverse: \FiringRecord.project)
    var firingRecords: [FiringRecord]

    @Relationship(deleteRule: .cascade, inverse: \ProjectPhoto.project)
    var photos: [ProjectPhoto]

    @Relationship(deleteRule: .cascade, inverse: \Evaluation.project)
    var evaluation: Evaluation?

    init(
        name: String,
        status: ProjectStatus = .idea,
        notes: String? = nil,
        shape: PieceShape? = nil,
        clay: Clay? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.status = status
        self.notes = notes
        self.shape = shape
        self.clay = clay
        self.claySnapshotName = clay?.name
        self.claySnapshotManufacturer = clay?.manufacturer
        self.claySnapshotFiredPath = clay?.firedImagePath
        self.glazeApplications = []
        self.journalEntries = []
        self.firingRecords = []
        self.photos = []
    }

    /// Bump the "last updated" timestamp after meaningful edits.
    func touch() {
        updatedAt = Date()
    }

    // MARK: - Display helpers

    var displayClayName: String {
        clay?.name ?? claySnapshotName ?? "No clay"
    }

    var displayClayManufacturer: String? {
        clay?.manufacturer ?? claySnapshotManufacturer
    }

    var displayShapeName: String {
        shape?.name ?? "No shape"
    }

    var actualPhotos: [ProjectPhoto] {
        photos.filter { $0.kind == .actualResult }
    }
}
