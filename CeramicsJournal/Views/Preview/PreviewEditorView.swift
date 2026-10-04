import SwiftUI
import SwiftData

/// SCREEN 8 — adjust the planned combination:
/// shape, clay, glazes, placement areas and opacity.
struct PreviewEditorView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Glaze.name) private var allGlazes: [Glaze]

    @State private var showShapePicker = false
    @State private var showClayPicker = false
    @State private var showGlazePicker = false
    @State private var pendingGlazeIDs: Set<UUID> = []

    private var glazeApps: [GlazeApplication] {
        project.glazeApplications.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PreviewCanvas(spec: .init(project: project), size: 250)
                        .frame(maxWidth: .infinity)

                    shapeCard
                    clayCard
                    glazesCard
                }
                .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Preview Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
            .sheet(isPresented: $showGlazePicker) {
                GlazePickerView(selection: $pendingGlazeIDs)
            }
            .onChange(of: showGlazePicker) { _, isVisible in
                // The picker just closed with a selection.
                if !isVisible, !pendingGlazeIDs.isEmpty {
                    addSelectedGlazes()
                    pendingGlazeIDs = []
                }
            }
        }
    }

    // MARK: - Cards

    private var shapeCard: some View {
        card {
            SectionTitle(emoji: "📐", title: "Shape")
            HStack(spacing: 10) {
                ShapeThumb(category: project.shape?.category ?? .other)
                    .frame(width: 44, height: 44)
                    .padding(6)
                    .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.displayShapeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(project.shape?.category.label ?? "No shape")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer()

                Button("Change") {
                    showShapePicker = true
                }
                .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold), compact: true))
            }
        }
    }

    private var clayCard: some View {
        card {
            SectionTitle(emoji: "🧱", title: "Clay")
            HStack(spacing: 10) {
                MaterialThumb(
                    image: project.clay.flatMap { ImageStore.shared.load($0.firedImagePath) }
                        ?? ImageStore.shared.load(project.claySnapshotFiredPath),
                    accent: Theme.clayFallback,
                    icon: "drop.fill",
                    size: 44
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.displayClayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(project.clay?.displayRange ?? "Material reference")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Button("Change") {
                    showClayPicker = true
                }
                .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold), compact: true))
            }
        }
    }

    private var glazesCard: some View {
        card {
            HStack {
                SectionTitle(emoji: "🎨", title: "Glazes")
                Spacer()
                Button {
                    showGlazePicker = true
                } label: {
                    Label("Add glaze", systemImage: "plus")
                }
                .buttonStyle(CuteSecondaryButton(font: .caption.weight(.semibold), compact: true))
            }

            if glazeApps.isEmpty {
                Text("No glazes yet — add one to start composing.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(glazeApps) { app in
                    glazeAppRow(app)
                }
            }
        }
    }

    private func glazeAppRow(_ app: GlazeApplication) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                MaterialThumb(
                    image: app.glaze.flatMap { ImageStore.shared.load($0.firedImagePath) }
                        ?? ImageStore.shared.load(app.snapshotFiredImagePath),
                    accent: Theme.mustard,
                    icon: "paintbrush",
                    size: 36
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayGlazeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(areaText(app))
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer()

                Menu {
                    Picker("Area", selection: Binding(
                        get: { app.area },
                        set: { newArea in
                            app.area = newArea
                            project.touch()
                        }
                    )) {
                        ForEach(ApplicationArea.allCases) { area in
                            Text(area.label).tag(area)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(Theme.oliveDark)
                }

                Button(role: .destructive) {
                    removeApplication(app)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
            }

            if app.area == .custom {
                TextField(
                    "Describe the area (e.g. Dragon)",
                    text: Binding(
                        get: { app.areaLabel ?? "" },
                        set: { app.areaLabel = $0.isEmpty ? nil : $0 }
                    )
                )
                .font(.caption)
                .padding(8)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft)
                Slider(
                    value: Binding(
                        get: { app.opacity },
                        set: { app.opacity = $0; project.touch() }
                    ),
                    in: 0.2...1.0
                )
                Text("\(Int((app.opacity * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(10)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func areaText(_ app: GlazeApplication) -> String {
        var text = app.area.label
        if let label = app.areaLabel, !label.isEmpty {
            text += " · \(label)"
        }
        return text
    }

    private func addSelectedGlazes() {
        for glaze in allGlazes where pendingGlazeIDs.contains(glaze.id) {
            let app = GlazeApplication(
                glaze: glaze,
                area: .entirePiece,
                opacity: 1.0,
                order: project.glazeApplications.count
            )
            app.project = project
        }
        project.touch()
    }

    private func removeApplication(_ app: GlazeApplication) {
        // The glaze image is shared library data — never delete it here.
        project.glazeApplications.removeAll { $0.id == app.id }
        context.delete(app)
        project.touch()
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
    NavigationStack {
        PreviewEditorView(project: Project(name: "Test"))
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
