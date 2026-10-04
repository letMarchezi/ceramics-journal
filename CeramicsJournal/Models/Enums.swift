import SwiftUI

// MARK: - Project

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case idea, planned, inProgress, bisqueFired, glazeFired, completed, archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .idea: return "Idea"
        case .planned: return "Planned"
        case .inProgress: return "In progress"
        case .bisqueFired: return "Bisque fired"
        case .glazeFired: return "Glaze fired"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    var icon: String {
        switch self {
        case .idea: return "lightbulb"
        case .planned: return "square.and.pencil"
        case .inProgress: return "hand.draw"
        case .bisqueFired: return "flame"
        case .glazeFired: return "sparkles"
        case .completed: return "checkmark.seal"
        case .archived: return "archivebox"
        }
    }
}

// MARK: - Materials

enum MaterialKind: String, Codable, CaseIterable, Identifiable {
    case clay, engobe

    var id: String { rawValue }
    var label: String {
        switch self {
        case .clay: return "Clay"
        case .engobe: return "Engobe"
        }
    }
}

/// How trustworthy a material's recorded appearance is (FR-005).
enum MaterialConfidence: String, Codable, CaseIterable, Identifiable {
    case reference, manufacturerData, userTested

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reference: return "Reference"
        case .manufacturerData: return "Manufacturer data"
        case .userTested: return "User tested"
        }
    }

    var icon: String {
        switch self {
        case .reference: return "doc.text"
        case .manufacturerData: return "building.2"
        case .userTested: return "checkmark.shield"
        }
    }

    var color: Color {
        switch self {
        case .reference: return Theme.inkSoft
        case .manufacturerData: return Theme.mustardDark
        case .userTested: return Theme.olive
        }
    }
}

enum GlazeFinish: String, Codable, CaseIterable, Identifiable {
    case matte, satin, glossy, crackle, crystalline, unknown

    var id: String { rawValue }
    var label: String {
        switch self {
        case .matte: return "Matte"
        case .satin: return "Satin"
        case .glossy: return "Glossy"
        case .crackle: return "Crackle"
        case .crystalline: return "Crystalline"
        case .unknown: return "Unknown finish"
        }
    }
}

enum GlazeTransparency: String, Codable, CaseIterable, Identifiable {
    case transparent, translucent, opaque, unknown

    var id: String { rawValue }
    var label: String {
        switch self {
        case .transparent: return "Transparent"
        case .translucent: return "Translucent"
        case .opaque: return "Opaque"
        case .unknown: return "Unknown transparency"
        }
    }
}

// MARK: - Shapes & glaze placement

enum ShapeCategory: String, Codable, CaseIterable, Identifiable {
    case mug, cup, bowl, plate, vase, jar, planter, other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .mug: return "Mug"
        case .cup: return "Cup"
        case .bowl: return "Bowl"
        case .plate: return "Plate"
        case .vase: return "Vase"
        case .jar: return "Jar"
        case .planter: return "Planter"
        case .other: return "Custom / other"
        }
    }
}

enum ApplicationArea: String, Codable, CaseIterable, Identifiable {
    case entirePiece, interior, exterior, base, custom

    var id: String { rawValue }
    var label: String {
        switch self {
        case .entirePiece: return "Entire piece"
        case .interior: return "Interior"
        case .exterior: return "Exterior"
        case .base: return "Base"
        case .custom: return "Custom area"
        }
    }
}

// MARK: - Firing

enum FiringType: String, Codable, CaseIterable, Identifiable {
    case bisque, glaze, other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .bisque: return "Bisque"
        case .glaze: return "Glaze"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .bisque: return "flame"
        case .glaze: return "sparkles"
        case .other: return "square.grid.2x2"
        }
    }

    /// Default target temperature used by the MVP firing profile (FR-018).
    var defaultTargetTemperature: Double? {
        switch self {
        case .bisque: return 1000
        case .glaze: return 1240
        case .other: return nil
        }
    }
}

enum FiringResult: String, Codable, CaseIterable, Identifiable {
    case success, partial, failed, unknown

    var id: String { rawValue }
    var label: String {
        switch self {
        case .success: return "Success"
        case .partial: return "Partial"
        case .failed: return "Failed"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle"
        case .partial: return "minus.circle"
        case .failed: return "xmark.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Evaluation

enum RepeatDecision: String, Codable, CaseIterable, Identifiable {
    case yes, no, maybe

    var id: String { rawValue }
    var label: String {
        switch self {
        case .yes: return "Yes"
        case .no: return "No"
        case .maybe: return "Maybe"
        }
    }

    var color: Color {
        switch self {
        case .yes: return Theme.olive
        case .no: return Theme.burgundy
        case .maybe: return Theme.mustardDark
        }
    }
}

// MARK: - Image semantics (FR-037: four image types, never conflated)

enum ImageKind: String, Codable, CaseIterable, Identifiable {
    case inspiration, materialReference, preview, actualResult

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inspiration: return "Inspiration"
        case .materialReference: return "Material reference"
        case .preview: return "Material reference preview"
        case .actualResult: return "Actual result"
        }
    }

    var color: Color {
        switch self {
        case .inspiration: return Theme.olive
        case .materialReference: return Theme.mustardDark
        case .preview: return Theme.burgundy
        case .actualResult: return Theme.ink
        }
    }
}
