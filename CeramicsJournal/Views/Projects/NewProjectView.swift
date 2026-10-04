import SwiftUI
import SwiftData

/// SCREEN 4 — the 5-step project creation flow:
/// 1 Name & Shape · 2 Clay · 3 Glaze · 4 Application · 5 Preview.
/// Optional steps can be skipped.
struct NewProjectView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PieceShape.name) private var shapes: [PieceShape]
    @Query(sort: \Clay.name) private var clays: [Clay]
    @Query(sort: \Glaze.name) private var glazes: [Glaze]

    @State private var step = 1
    @State private var name = ""
    @State private var shape: PieceShape?
    @State private var clay: Clay?
    @State private var selectedGlazeIDs: Set<UUID> = []
    @State private var drafts: [DraftApplication] = []
    @State private var showClayEditor = false
    @State private var showGlazeEditor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                stepIndicator
                if step == 5 {
                    ScrollView {
                        previewStep
                    }
                } else {
                    ScrollView {
                        stepContent
                    }
                }
                bottomBar
            }
            .padding()
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedGlazeIDs) { _, newValue in
            // Drop drafts for glazes that are no longer selected.
            drafts.removeAll { draft in
                !newValue.contains(draft.glaze.id)
            }
        }
        .sheet(isPresented: $showClayEditor) { ClayEditorView() }
        .sheet(isPresented: $showGlazeEditor) { GlazeEditorView() }
    }

    // MARK: - Steps

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { s in
                Capsule()
                    .fill(s <= step ? Theme.burgundy : Theme.burgundy.opacity(0.2))
                    .frame(width: s == step ? 28 : 18, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: step)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1:
            VStack(spacing: 16) {
                card {
                    SectionTitle(emoji: "🏺", title: "Name & Shape")
                    TextField("Project name (e.g. Dragon Mug)", text: $name)
                        .padding(12)
                        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
                }
                shapePickerCard
            }
        case 2:
            clayStep
        case 3:
            glazeStep
        case 4:
            applicationStep
        default:
            EmptyView()
        }
    }

    private var shapePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(emoji: "📐", title: "Shape")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(orderedShapes) { shape in
                    shapeCell(shape)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private var orderedShapes: [PieceShape] {
        shapes.filter { !$0.isCustom } + shapes.filter { $0.isCustom }
    }

    private func shapeCell(_ shape: PieceShape) -> some View {
        let isSelected = self.shape?.id == shape.id
        return Button {
            self.shape = shape
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Theme.burgundy.opacity(0.12) : Theme.canvas)
                    ShapeThumb(
                        category: shape.category,
                        fill: isSelected ? Theme.burgundy.opacity(0.5) : Theme.olive.opacity(0.35),
                        stroke: isSelected ? Theme.burgundy : Theme.olive
                    )
                }
                .frame(height: 74)

                Text(shape.name)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.burgundy)
                }
            }
            .padding(10)
        }
        .buttonStyle(.plain)
    }

    private var clayStep: some View {
        card {
            SectionTitle(emoji: "🧱", title: "Clay Body")

            if clays.isEmpty {
                EmptyState(
                    emoji: "🧱",
                    title: "No clays yet",
                    message: "Add a clay to continue — or skip for now."
                )
            } else {
                ForEach(clays) { clayItem in
                    Button {
                        clay = clayItem
                    } label: {
                        HStack(spacing: 12) {
                            MaterialThumb(
                                image: ImageStore.shared.load(clayItem.firedImagePath),
                                accent: Theme.clayFallback,
                                icon: "drop.fill",
                                size: 48
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(clayItem.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.ink)
                                    if clay?.id == clayItem.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.burgundy)
                                    }
                                }
                                Text("\(clayItem.manufacturer ?? "—") · \(clayItem.displayRange)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(clay?.id == clayItem.id ? Theme.burgundy.opacity(0.10) : Theme.cream)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Button("Skip for now") {
                    clay = nil
                    advance()
                }
                .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold)))

                Button("New clay") {
                    showClayEditor = true
                }
                .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold)))
            }
        }
    }

    private var glazeStep: some View {
        card {
            SectionTitle(emoji: "🎨", title: "Glazes")
            Text("Select one or more glazes to apply to this piece.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)

            if glazes.isEmpty {
                EmptyState(
                    emoji: "🎨",
                    title: "No glazes yet",
                    message: "Add a glaze to continue — or continue without glaze."
                )
            } else {
                ForEach(glazes) { glaze in
                    Button {
                        if selectedGlazeIDs.contains(glaze.id) {
                            selectedGlazeIDs.remove(glaze.id)
                        } else {
                            selectedGlazeIDs.insert(glaze.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            MaterialThumb(
                                image: ImageStore.shared.load(glaze.firedImagePath),
                                accent: Theme.mustard,
                                icon: "paintbrush",
                                size: 48
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(glaze.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.ink)
                                    if selectedGlazeIDs.contains(glaze.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.burgundy)
                                    }
                                }
                                Text("\(glaze.finish.label) · \(glaze.displayRange)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedGlazeIDs.contains(glaze.id) ? Theme.burgundy.opacity(0.10) : Theme.cream)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("New glaze") {
                showGlazeEditor = true
            }
            .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold)))
        }
    }

    private var applicationStep: some View {
        card {
            SectionTitle(emoji: "🖌️", title: "Glaze Placement")

            if drafts.isEmpty {
                EmptyState(
                    emoji: "🖌️",
                    title: "No glazes selected",
                    message: "Go back and pick at least one glaze — or continue without glaze."
                )
            } else {
                ForEach($drafts) { $draft in
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            MaterialThumb(
                                image: ImageStore.shared.load(draft.glaze.firedImagePath),
                                accent: Theme.mustard,
                                icon: "paintbrush",
                                size: 36
                            )
                            Text(draft.glaze.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                        }

                        Picker("Area", selection: $draft.area) {
                            ForEach(ApplicationArea.allCases) { area in
                                Text(area.label).tag(area)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if draft.area == .custom {
                            TextField("Describe the area (e.g. Dragon)", text: $draft.label)
                                .font(.caption)
                                .padding(8)
                                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 8))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSoft)
                            Slider(value: $draft.opacity, in: 0.2...1.0)
                            Text("\(Int((draft.opacity * 100).rounded()))%")
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(10)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var previewStep: some View {
        VStack(spacing: 14) {
            PreviewCanvas(spec: previewSpec, size: 250)
                .frame(maxWidth: .infinity)

            Text("Material reference preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.burgundy)

            Text("This preview composes your shape with your saved clay and glaze references. It is a visual mockup, not a prediction of the fired result.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cuteCard()
    }

    // MARK: - Navigation bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 1 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(CuteSecondaryButton())
            }
            Spacer()
            if step < 5 {
                Button {
                    prepareNextStep()
                    withAnimation { step += 1 }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(CutePrimaryButton())
                .disabled(step == 1 && !isStep1Valid)
            } else {
                Button(action: save) {
                    Label("Save Project", systemImage: "checkmark")
                }
                .buttonStyle(CutePrimaryButton())
                .disabled(!isStep1Valid)
            }
        }
    }

    private var isStep1Valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && shape != nil
    }

    private func prepareNextStep() {
        if step == 3 {
            for glaze in glazes where selectedGlazeIDs.contains(glaze.id)
                && !drafts.contains(where: { $0.glaze.id == glaze.id }) {
                drafts.append(DraftApplication(glaze: glaze))
            }
        }
    }

    private func advance() {
        prepareNextStep()
        withAnimation { step += 1 }
    }

    // MARK: - Preview spec & save

    private var previewSpec: PreviewSpec {
        var spec = PreviewSpec(
            category: shape?.category ?? .mug,
            clayImage: clay.flatMap { ImageStore.shared.load($0.firedImagePath) },
            clayColor: clay.flatMap { ImageStore.shared.averageColor($0.firedImagePath) }
                ?? UIColor(Theme.clayFallback)
        )
        for draft in drafts {
            spec.apps.append(
                PreviewSpec.Application(
                    glazeImage: ImageStore.shared.load(draft.glaze.firedImagePath),
                    glazeColor: ImageStore.shared.averageColor(draft.glaze.firedImagePath)
                        ?? UIColor(Theme.mustard),
                    area: draft.area,
                    opacity: draft.opacity
                )
            )
        }
        return spec
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let project = Project(name: trimmedName, shape: shape, clay: clay)
        project.status = (clay != nil && !drafts.isEmpty) ? .planned : .idea
        context.insert(project)

        for (index, draft) in drafts.enumerated() {
            let trimmedLabel = draft.label.trimmingCharacters(in: .whitespaces)
            let app = GlazeApplication(
                glaze: draft.glaze,
                area: draft.area,
                areaLabel: trimmedLabel.isEmpty ? nil : trimmedLabel,
                opacity: draft.opacity,
                order: index
            )
            app.project = project
        }

        let entry = JournalEntry(
            title: "Project created",
            text: "Started \(project.displayShapeName.lowercased()) in \(project.displayClayName.lowercased()).",
            project: project
        )
        context.insert(entry)

        project.touch()
        dismiss()
    }

    // MARK: - Helpers

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }
}

/// A glaze placement draft used by the new-project flow.
struct DraftApplication: Identifiable {
    let id: UUID
    let glaze: Glaze
    var area: ApplicationArea
    var label: String
    var opacity: Double

    init(
        id: UUID = UUID(),
        glaze: Glaze,
        area: ApplicationArea = .entirePiece,
        label: String = "",
        opacity: Double = 1.0
    ) {
        self.id = id
        self.glaze = glaze
        self.area = area
        self.label = label
        self.opacity = opacity
    }
}

#Preview {
    NewProjectView()
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
