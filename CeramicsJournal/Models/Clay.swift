import Foundation
import SwiftData

/// A reusable record for a clay body (or engobe) in the material library (FR-003).
@Model
final class Clay {
    var id: UUID
    var name: String
    var kind: MaterialKind
    var manufacturer: String?
    var notes: String?

    var rawImagePath: String?
    var firedImagePath: String?

    var minFiringTemperature: Double?
    var maxFiringTemperature: Double?
    var testedTemperature: Double?

    var confidence: MaterialConfidence
    var source: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Project.clay)
    var projects: [Project]

    init(
        name: String,
        kind: MaterialKind = .clay,
        manufacturer: String? = nil,
        notes: String? = nil,
        rawImagePath: String? = nil,
        firedImagePath: String? = nil,
        minFiringTemperature: Double? = nil,
        maxFiringTemperature: Double? = nil,
        testedTemperature: Double? = nil,
        confidence: MaterialConfidence = .reference,
        source: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.kind = kind
        self.manufacturer = manufacturer
        self.notes = notes
        self.rawImagePath = rawImagePath
        self.firedImagePath = firedImagePath
        self.minFiringTemperature = minFiringTemperature
        self.maxFiringTemperature = maxFiringTemperature
        self.testedTemperature = testedTemperature
        self.confidence = confidence
        self.source = source
        self.createdAt = createdAt
        self.projects = []
    }

    /// "1000–1240°C", "Tested at 1240°C", or a friendly placeholder.
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
