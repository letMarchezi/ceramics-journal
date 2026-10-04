import Foundation
import SwiftData

/// Seeds the predefined shape library on first launch (TASK-004).
enum SeedData {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<PieceShape>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let presets: [(String, ShapeCategory)] = [
            ("Mug", .mug),
            ("Cup", .cup),
            ("Bowl", .bowl),
            ("Plate", .plate),
            ("Vase", .vase),
            ("Jar", .jar),
            ("Planter", .planter),
            ("Free Form", .other)
        ]

        for (name, category) in presets {
            context.insert(PieceShape(name: name, category: category))
        }

        try? context.save()
    }
}
