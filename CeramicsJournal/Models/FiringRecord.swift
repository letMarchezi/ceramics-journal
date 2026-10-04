import Foundation
import SwiftData

/// A bisque / glaze / other firing record (section 19).
@Model
final class FiringRecord {
    var id: UUID
    var type: FiringType
    var targetTemperature: Double?
    var maximumTemperature: Double?
    var date: Date
    var kiln: String?
    var atmosphere: String?
    var result: FiringResult
    var notes: String
    var photoPaths: [String]

    var project: Project?

    init(type: FiringType = .bisque, project: Project? = nil, date: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.project = project
        self.date = date
        self.targetTemperature = type.defaultTargetTemperature
        self.result = .unknown
        self.notes = ""
        self.photoPaths = []
    }
}
