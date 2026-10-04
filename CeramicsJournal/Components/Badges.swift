import SwiftUI

/// A section heading with a little emoji accent.
struct SectionTitle: View {
    let emoji: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

/// Project status pill, colored per status.
struct StatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.statusColor(status).opacity(0.16)))
        .foregroundStyle(Theme.statusColor(status))
    }
}

/// Material confidence pill (Reference / Manufacturer data / User tested).
struct ConfidenceBadge: View {
    let confidence: MaterialConfidence

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidence.icon)
                .font(.caption2)
            Text(confidence.label)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(confidence.color.opacity(0.15)))
        .foregroundStyle(confidence.color)
    }
}

/// The small tag that labels what kind of image is being shown
/// (FR-037: inspiration / material reference / preview / actual result
/// must never be visually conflated).
struct ImageTagView: View {
    let kind: ImageKind

    var body: some View {
        Text(kind.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(kind.color.opacity(0.92)))
            .foregroundStyle(.white)
    }
}
