import SwiftUI
import SwiftData

/// SCREEN 10 — clay detail: photos, firing data, notes and the projects
/// that use it.
struct ClayDetailView: View {
    let clay: Clay
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var confirmDelete = false

    private var usingProjects: [Project] {
        clay.projects.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                photosCard
                firingCard
                notesCard
                projectsCard
                actionBar
            }
            .padding()
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(clay.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            ClayEditorView(existing: clay)
        }
        .confirmationDialog(
            "Delete “\(clay.name)”?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete clay", role: .destructive) {
                deleteClay()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Projects that used this clay keep their historical reference to it.")
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                MaterialThumb(
                    image: ImageStore.shared.load(clay.firedImagePath),
                    accent: Theme.clayFallback,
                    icon: "drop.fill",
                    size: 64
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(clay.name)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.ink)
                    if let manufacturer = clay.manufacturer {
                        Text(manufacturer)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ConfidenceBadge(confidence: clay.confidence)
                Text(clay.kind.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.olive.opacity(0.15)))
                    .foregroundStyle(Theme.olive)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(emoji: "📷", title: "Appearance")
            HStack(spacing: 12) {
                labeledPhoto("Raw", path: clay.rawImagePath)
                labeledPhoto("Fired", path: clay.firedImagePath)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var firingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "🔥", title: "Firing")
            infoRow("Recommended range", clay.displayRange)
            infoRow(
                "Tested temperature",
                clay.testedTemperature.map { "\(Int($0.rounded()))°C" } ?? "Not recorded"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "📝", title: "Notes")
            if let notes = clay.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
            } else {
                Text("No notes yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            if let source = clay.source, !source.isEmpty {
                infoRow("Source", source)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var projectsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "📔", title: "Projects using this clay")

            if usingProjects.isEmpty {
                Text("Not used in any project yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(usingProjects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(project.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(project.displayShapeName)
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            StatusBadge(status: project.status)
                        }
                        .padding(10)
                        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                showEditor = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CuteSecondaryButton())

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CutePrimaryButton())
        }
    }

    // MARK: - Helpers

    private func labeledPhoto(_ title: String, path: String?) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if let path, let image = ImageStore.shared.load(path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.mustard.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Theme.inkSoft.opacity(0.4))
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .bottomTrailing) {
                if path != nil {
                    ImageTagView(kind: .materialReference).padding(6)
                }
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
    }

    private func deleteClay() {
        // Preserve the historical reference in every project before deleting.
        for project in clay.projects {
            project.claySnapshotName = project.claySnapshotName ?? clay.name
            project.claySnapshotManufacturer = project.claySnapshotManufacturer ?? clay.manufacturer
            if let path = clay.firedImagePath, let copied = ImageStore.shared.copy(path) {
                project.claySnapshotFiredPath = project.claySnapshotFiredPath ?? copied
            }
            project.touch()
        }

        ImageStore.shared.delete(clay.rawImagePath)
        ImageStore.shared.delete(clay.firedImagePath)
        context.delete(clay)
    }
}

#Preview {
    NavigationStack {
        ClayDetailView(clay: Clay(name: "Egito", manufacturer: "Casa do Ceramista"))
    }
    .modelContainer(for: [
        Project.self,
        Clay.self,
        Glaze.self,
        PieceShape.self,
        GlazeApplication.self,
        JournalEntry.self,
        FiringRecord.self,
        Evaluation.self,
        ProjectPhoto.self
    ], inMemory: true)
}
