import SwiftUI
import SwiftData

/// SCREEN 10 (glaze variant) — glaze detail with projects that use it.
struct GlazeDetailView: View {
    let glaze: Glaze
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var confirmDelete = false

    private var usingProjects: [Project] {
        var seen = Set<UUID>()
        return glaze.applications.compactMap { app in
            guard let project = app.project, seen.insert(project.id).inserted else { return nil }
            return project
        }
        .sorted { $0.updatedAt > $1.updatedAt }
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
        .navigationTitle(glaze.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            GlazeEditorView(existing: glaze)
        }
        .confirmationDialog(
            "Delete “\(glaze.name)”?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete glaze", role: .destructive) {
                deleteGlaze()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Projects that used this glaze keep their historical reference to it.")
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                MaterialThumb(
                    image: ImageStore.shared.load(glaze.firedImagePath),
                    accent: Theme.mustard,
                    icon: "paintbrush",
                    size: 64
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(glaze.name)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.ink)
                    if let manufacturer = glaze.manufacturer {
                        Text(manufacturer)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ConfidenceBadge(confidence: glaze.confidence)
                Text(glaze.finish.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.mustard.opacity(0.15)))
                    .foregroundStyle(Theme.mustardDark)
                Text(glaze.transparency.label)
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
            SectionTitle(emoji: "📷", title: "Fired appearance")
            ZStack {
                if let path = glaze.firedImagePath,
                   let image = ImageStore.shared.load(path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.mustard.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .overlay {
                            Image(systemName: "paintbrush")
                                .foregroundStyle(Theme.inkSoft.opacity(0.4))
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .bottomTrailing) {
                if glaze.firedImagePath != nil {
                    ImageTagView(kind: .materialReference).padding(6)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var firingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "🔥", title: "Firing")
            infoRow("Recommended range", glaze.displayRange)
            infoRow(
                "Tested temperature",
                glaze.testedTemperature.map { "\(Int($0.rounded()))°C" } ?? "Not recorded"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "📝", title: "Notes")
            if let applicationNotes = glaze.applicationNotes, !applicationNotes.isEmpty {
                infoRow("Application", applicationNotes)
            }
            if let notes = glaze.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
            }
            if let source = glaze.source, !source.isEmpty {
                infoRow("Source", source)
            }
            if glaze.applicationNotes?.isEmpty ?? true,
               glaze.notes?.isEmpty ?? true {
                Text("No notes yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var projectsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "📔", title: "Projects using this glaze")

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
                                Text(project.displayClayName)
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

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func deleteGlaze() {
        // Preserve the historical reference in every application before deleting.
        for app in glaze.applications {
            app.snapshotGlazeName = app.snapshotGlazeName ?? glaze.name
            app.snapshotGlazeFinish = glaze.finish
            if let path = glaze.firedImagePath, let copied = ImageStore.shared.copy(path) {
                app.snapshotFiredImagePath = app.snapshotFiredImagePath ?? copied
            }
            if let project = app.project {
                project.touch()
            }
        }

        ImageStore.shared.delete(glaze.firedImagePath)
        context.delete(glaze)
    }
}

#Preview {
    NavigationStack {
        GlazeDetailView(glaze: Glaze(name: "Silver"))
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
