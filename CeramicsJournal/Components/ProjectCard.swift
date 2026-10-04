import SwiftUI

/// A project card used on the Home tab and in the Projects list/grid.
struct ProjectCard: View {
    let project: Project
    var vertical: Bool = false

    var body: some View {
        if vertical {
            VStack(alignment: .leading, spacing: 10) {
                PreviewCanvas(spec: .init(project: project), size: 110, showTag: false)
                    .frame(maxWidth: .infinity)
                Text(project.name)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                StatusBadge(status: project.status)
                Text("\(project.displayClayName) · \(project.displayShapeName)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cuteCard()
        } else {
            HStack(spacing: 12) {
                PreviewCanvas(spec: .init(project: project), size: 72, showTag: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    StatusBadge(status: project.status)
                    Text("\(project.displayClayName) · \(project.displayShapeName)")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft.opacity(0.5))
            }
            .padding(12)
            .cuteCard()
        }
    }
}
