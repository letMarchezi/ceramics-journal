import SwiftUI
import SwiftData

/// Editing a project: name, status, shape, clay, notes and the
/// inspiration image (which always stays an *inspiration* reference).
struct ProjectEditView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss

    @State private var showShapePicker = false
    @State private var showClayPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    card {
                        SectionTitle(emoji: "🏺", title: "Project")
                        TextField("Project name", text: $project.name)
                            .padding(12)
                            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))

                        Picker("Status", selection: $project.status) {
                            ForEach(ProjectStatus.allCases) { status in
                                Label(status.label, systemImage: status.icon).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    card {
                        SectionTitle(emoji: "🧱", title: "Shape & Clay")

                        HStack(spacing: 10) {
                            ShapeThumb(category: project.shape?.category ?? .other)
                                .frame(width: 40, height: 40)
                                .padding(6)
                                .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.displayShapeName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(project.shape?.category.label ?? "")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Button("Change") {
                                showShapePicker = true
                            }
                            .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold), compact: true))
                        }

                        HStack(spacing: 10) {
                            MaterialThumb(
                                image: project.clay.flatMap { ImageStore.shared.load($0.firedImagePath) },
                                accent: Theme.clayFallback,
                                icon: "drop.fill",
                                size: 40
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.displayClayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(project.clay?.manufacturer ?? project.claySnapshotManufacturer ?? "Material reference")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            if project.clay != nil {
                                Button("Remove") {
                                    project.clay = nil
                                    project.claySnapshotName = nil
                                    project.claySnapshotManufacturer = nil
                                    project.claySnapshotFiredPath = nil
                                    project.touch()
                                }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.burgundy)
                            }
                            Button("Change") {
                                showClayPicker = true
                            }
                            .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold), compact: true))
                        }
                    }

                    card {
                        SectionTitle(emoji: "✍️", title: "Notes")
                        TextField("Notes (optional)", text: optionalText(\.notes), axis: .vertical)
                            .lineLimit(3...6)
                    }

                    card {
                        SectionTitle(emoji: "💡", title: "Inspiration")

                        HStack(spacing: 10) {
                            Group {
                                if let path = project.inspirationImagePath,
                                   let image = ImageStore.shared.load(path) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(alignment: .topTrailing) {
                                            ImageTagView(kind: .inspiration).padding(5)
                                        }
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.olive.opacity(0.12))
                                        .frame(width: 72, height: 72)
                                        .overlay {
                                            Image(systemName: "lightbulb")
                                                .foregroundStyle(Theme.inkSoft)
                                        }
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Title (optional)", text: optionalText(\.inspirationTitle))
                                TextField("Notes (optional)", text: optionalText(\.inspirationNotes))
                                TextField("Source (optional)", text: optionalText(\.inspirationSource))
                            }
                            .font(.subheadline)
                        }

                        PhotoSlot(
                            title: "Inspiration photo",
                            imagePath: Binding(
                                get: { project.inspirationImagePath },
                                set: { newValue in
                                    project.inspirationImagePath = newValue
                                    project.touch()
                                }
                            )
                        )
                    }
                }
                .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        project.touch()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShapePicker) {
                ShapePickerView(selection: Binding(
                    get: { project.shape },
                    set: { newValue in
                        project.shape = newValue
                        project.touch()
                    }
                ))
            }
            .sheet(isPresented: $showClayPicker) {
                ClayPickerView(selection: Binding(
                    get: { project.clay },
                    set: { newValue in
                        project.clay = newValue
                        project.claySnapshotName = newValue?.name
                        project.claySnapshotManufacturer = newValue?.manufacturer
                        project.claySnapshotFiredPath = newValue?.firedImagePath
                        project.touch()
                    }
                ))
            }
        }
    }

    // MARK: - Helpers

    private func optionalText(_ keyPath: WritableKeyPath<Project, String?>) -> Binding<String> {
        Binding(
            get: { project[keyPath: keyPath] ?? "" },
            set: { project[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }
}

#Preview {
    ProjectEditView(project: Project(name: "Test"))
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
