import Foundation
import SwiftData

/// The experiment evaluation for a completed project (section 22).
@Model
final class Evaluation {
    var id: UUID
    var whatWorked: String
    var whatFailed: String
    var surprises: String
    var changesForNextTime: String
    var repeatDecision: RepeatDecision

    var project: Project?

    init() {
        self.id = UUID()
        self.whatWorked = ""
        self.whatFailed = ""
        self.surprises = ""
        self.changesForNextTime = ""
        self.repeatDecision = .maybe
    }
}
