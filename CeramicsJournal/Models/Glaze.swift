import Foundation
import SwiftData

/// A reusable glaze record in the material library (FR-004).
@Model
final class Glaze {
    var id: UUID
    var name: String
    var manufacturer: String?
    var notes: String?

    var firedImagePath: String?

    var finish: GlazeFinish
    var transparency: GlazeTransparency

    var minFiringTemperature: Double?
    var maxFiringTemperature: Double?
    var testedTemperature: Double?

    var applicationNotes: String?

    var confidence: MaterialConfidence
    var source: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \GlazeApplication.glaze)
    var applications: [GlazeApplication]

    init(
        name: String,
        manufacturer: String? = nil,
        notes: String? = nil,
        firedImagePath: String? = nil,
        finish: GlazeFinish = .unknown,
        transparency: GlazeTransparency = .unknown,
        minFiringTemperature: Double? = nil,
        maxFiringTemperature: Double? = nil,
        testedTemperature: Double? = nil,
        applicationNotes: String? = nil,
        confidence: MaterialConfidence = .reference,
        source: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.manufacturer = manufacturer
        self.notes = notes
        self.firedImagePath = firedImagePath
        self.finish = finish
        self.transparency = transparency
        self.minFiringTemperature = minFiringTemperature
        self.maxFiringTemperature = maxFiringTemperature
        self.testedTemperature = testedTemperature
        self.applicationNotes = applicationNotes
        self.confidence = confidence
        self.source = source
        self.createdAt = createdAt
        self.applications = []
    }

    var displayRange: String {
        if let min = minFiringTemperature, let max = maxFiringTemperature {
            return "\(Int(min.rounded()))–\(Int(max.rounded()))°C"
        }
        if let tested = testedTemperature {
            return "Tested at \(Int(tested.rounded()))°C"
        }
        return "Firing range not recorded"
    }
}
