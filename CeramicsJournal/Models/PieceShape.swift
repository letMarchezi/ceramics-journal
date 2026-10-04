import Foundation
import SwiftData

/// A reusable shape record. The category drives the built-in silhouette
/// used by the preview system; custom shapes may attach a reference photo.
///
/// Named `PieceShape` (rather than `Shape`) to avoid colliding with
/// `SwiftUI.Shape`.
@Model
final class PieceShape {
    var id: UUID
    var name: String
    var category: ShapeCategory

    var previewImagePath: String?
    var referenceImagePath: String?
    var descriptionText: String?

    var defaultWidth: Double?
    var defaultHeight: Double?
    var defaultDepth: Double?

    var isCustom: Bool
    var createdAt: Date

    init(
        name: String,
        category: ShapeCategory = .other,
        previewImagePath: String? = nil,
        referenceImagePath: String? = nil,
        descriptionText: String? = nil,
        defaultWidth: Double? = nil,
        defaultHeight: Double? = nil,
        defaultDepth: Double? = nil,
        isCustom: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.previewImagePath = previewImagePath
        self.referenceImagePath = referenceImagePath
        self.descriptionText = descriptionText
        self.defaultWidth = defaultWidth
        self.defaultHeight = defaultHeight
        self.defaultDepth = defaultDepth
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}
