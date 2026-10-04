import SwiftUI
import SwiftData
import PhotosUI

/// SCREEN 3 — the full history of one piece:
/// preview, materials, construction, firings, final result, evaluation.
struct ProjectDetailView: View {
    let project: Project
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showPreviewEditor = false
    @State private var showEdit = false
    @State private var showJournalEditor = false
    @State private var showFiringEditor = false
    @State private var showFinal = false
    @State private var confirmDelete = false
    @State private var firingTypeToEdit: FiringType = .bisque
    @State private var pickedFinalPhoto: PhotosPickerItem?
    @State private var showFinalCamera = false

    // MARK: - Derived data

    private var journalEntries: [JournalEntry] {
        project.journalEntries.sorted { $0.createdAt < $1.createdAt }
    }

    private var firingRecords: [FiringRecord] {
        project.firingRecords.sorted { $0.date < $1.date }
    }

    private var glazeApps: [GlazeApplication] {
        project.glazeApplications.sorted { $0.order < $1.order }
    }

    private var latestActualPhoto: ProjectPhoto? {
        project.actualPhotos.sorted { $0.createdAt > $1.createdAt }.first
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                previewSection
                materialsSection
                constructionSection
                firingSection
                finalResultSection
                evaluationSection
            }
            .padding()
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit project", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPreviewEditor) {
            PreviewEditorView(project: project)
        }
        .sheet(isPresented: $showEdit) {
            ProjectEditView(project: project)
        }
        .sheet(isPresented: $showJournalEditor) {
            JournalEntryEditorView(project: project)
        }
        .sheet(isPresented: $showFiringEditor) {
            FiringRecordEditorView(project: project, type: firingTypeToEdit)
        }
        .sheet(isPresented: $showFinal) {
            FinalResultView(project: project)
        }
        .confirmationDialog(
            "Delete “\(project.name)”?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete project", role: .destructive) {
                deleteProject()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Journal entries, firings and project photos will be deleted. Material library entries are kept.")
        }
        .onChange(of: pickedFinalPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    addActualPhoto(image)
                }
                pickedFinalPhoto = nil
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.name)
                .font(.title2.bold())
                .foregroundStyle(Theme.ink)

            Menu {
                ForEach(ProjectStatus.allCases) { status in
                    Button {
                        project.status = status
                        project.touch()
                    } label: {
                        Label(status.label, systemImage: status.icon)
                    }
                }
            } label: {
                StatusBadge(status: project.status)
            }

            Text("Created \(project.createdAt.formatted(date: .abbreviated, time: .omitted)) · Updated \(project.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)

            if let notes = project.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
            }

            if let path = project.inspirationImagePath,
               let image = ImageStore.shared.load(path) {
                HStack(spacing: 10) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            ImageTagView(kind: .inspiration).padding(5)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        if let title = project.inspirationTitle {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                        }
                        if let source = project.inspirationSource {
                            Text(source)
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "🎨", title: "Design Preview")

            HStack {
                Spacer()
                PreviewCanvas(spec: .init(project: project), size: 230)
                Spacer()
            }

            Text("Material reference preview — a composition from your saved references, not a prediction of the fired result.")
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                showPreviewEditor = true
            } label: {
                Label("Adjust design", systemImage: "paintbrush.pointed")
            }
            .buttonStyle(CuteSecondaryButton())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    // MARK: - Materials

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(emoji: "🧱", title: "Materials")

            HStack(spacing: 10) {
                ShapeThumb(category: project.shape?.category ?? .other)
                    .frame(width: 40, height: 40)
                    .padding(6)
                    .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.displayShapeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(project.shape?.category.label ?? "Shape")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                MaterialThumb(
                    image: clayImage,
                    accent: Theme.clayFallback,
                    icon: "drop.fill",
                    size: 40
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.displayClayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(claySubtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                ImageTagView(kind: .materialReference)
            }

            if glazeApps.isEmpty {
                Text("No glazes assigned yet — tap “Adjust design” to add some.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(glazeApps) { app in
                    HStack(spacing: 10) {
                        MaterialThumb(
                            image: glazeImage(app),
                            accent: Theme.mustard,
                            icon: "paintbrush",
                            size: 36
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.displayGlazeName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Text(glazeAreaText(app))
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        ImageTagView(kind: .materialReference)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    // MARK: - Construction

    private var constructionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(emoji: "🛠️", title: "Construction")
                Spacer()
                Button {
                    showJournalEditor = true
                } label: {
                    Label("Add entry", systemImage: "plus")
                }
                .buttonStyle(CuteSecondaryButton(font: .caption.weight(.semibold), compact: true))
            }

            if journalEntries.isEmpty {
                Text("No construction notes yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(journalEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSoft)
                            Text(entry.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                        }
                        if !entry.text.isEmpty {
                            Text(entry.text)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        if !entry.photoPaths.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(entry.photoPaths, id: \.self) { path in
                                    if let image = ImageStore.shared.load(path) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    // MARK: - Firing

    private var firingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(emoji: "🔥", title: "Firing")
                Spacer()
                Menu {
                    Button("Bisque firing · 1000°C") {
                        firingTypeToEdit = .bisque
                        showFiringEditor = true
                    }
                    Button("Glaze firing · 1240°C") {
                        firingTypeToEdit = .glaze
                        showFiringEditor = true
                    }
                    Button("Other firing") {
                        firingTypeToEdit = .other
                        showFiringEditor = true
                    }
                } label: {
                    Label("Add firing", systemImage: "plus")
                }
                .buttonStyle(CuteSecondaryButton(font: .caption.weight(.semibold), compact: true))
            }

            if firingRecords.isEmpty {
                Text("No firings recorded yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(firingRecords) { firing in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Theme.mustard.opacity(0.18))
                            Image(systemName: firing.type.icon)
                                .font(.caption)
                                .foregroundStyle(Theme.mustardDark)
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("\(firing.type.label) firing")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.ink)
                                firingResultTag(firing.result)
                            }
                            Text(firingSubtitle(firing))
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
    }

    private func firingSubtitle(_ firing: FiringRecord) -> String {
        var parts: [String] = []
        if let target = firing.targetTemperature {
            parts.append("target \(Int(target.rounded()))°C")
        }
        if let maxTemperature = firing.maximumTemperature {
            parts.append("max \(Int(maxTemperature.rounded()))°C")
        }
        parts.append(firing.date.formatted(date: .abbreviated, time: .omitted))
        return parts.joined(separator: " · ")
    }

    private func firingResultTag(_ result: FiringResult) -> some View {
        Text(result.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.firingResultColor(result).opacity(0.15)))
            .foregroundStyle(Theme.firingResultColor(result))
    }

    // MARK: - Final result (SCREEN 13, planned vs actual)

    private var finalResultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(emoji: "⚖️", title: "Final Result")

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 6) {
                    PreviewCanvas(spec: .init(project: project), size: 120, showTag: false)
                    Text("PLANNED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.burgundy)
                }

                VStack(spacing: 6) {
                    Group {
                        if let photo = latestActualPhoto,
                           let image = ImageStore.shared.load(photo.imagePath) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(alignment: .topTrailing) {
                                    ImageTagView(kind: .actualResult).padding(6)
                                }
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.olive.opacity(0.12))
                                .frame(width: 120, height: 120)
                                .overlay {
                                    VStack(spacing: 6) {
                                        Image(systemName: "camera.viewfinder")
                                            .font(.title3)
                                        Text("No photo yet")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(Theme.inkSoft)
                                }
                        }
                    }
                    Text("ACTUAL")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.olive)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showFinalCamera = true
                    } label: {
                        Label("Add photo", systemImage: "camera")
                    }
                    .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold), compact: true))
                }

                PhotosPicker(selection: $pickedFinalPhoto, matching: .images) {
                    Label("Choose", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(CuteSecondaryButton(font: .footnote.weight(.semibold), compact: true))

                Spacer()

                Button {
                    showFinal = true
                } label: {
                    Label(
                        project.evaluation == nil ? "Write evaluation" : "Edit evaluation",
                        systemImage: "checklist"
                    )
                }
                .buttonStyle(CutePrimaryButton(font: .footnote.weight(.semibold), compact: true))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCard()
        .sheet(isPresented: $showFinalCamera) {
            CameraCaptureView { image in
                addActualPhoto(image)
            }
        }
    }

    // MARK: - Evaluation

    @ViewBuilder
    private var evaluationSection: some View {
        if let evaluation = project.evaluation {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(emoji: "✅", title: "Evaluation")

                evaluationField("What worked", evaluation.whatWorked)
                evaluationField("What failed", evaluation.whatFailed)
                evaluationField("Surprises", evaluation.surprises)
                evaluationField("Next time", evaluation.changesForNextTime)

                HStack {
                    Text("Repeat this combination?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(evaluation.repeatDecision.label)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(evaluation.repeatDecision.color)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cuteCard()
        }
    }

    private func evaluationField(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.mustardDark)
            Text(text.isEmpty ? "—" : text)
                .font(.subheadline)
                .foregroundStyle(text.isEmpty ? Theme.inkSoft : Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private var clayImage: UIImage? {
        project.clay.flatMap { ImageStore.shared.load($0.firedImagePath) }
            ?? ImageStore.shared.load(project.claySnapshotFiredPath)
    }

    private var claySubtitle: String {
        let parts: [String] = [
            project.clay?.manufacturer ?? project.claySnapshotManufacturer,
            project.clay?.displayRange
        ].compactMap { $0 }
        return parts.isEmpty ? "Material reference" : parts.joined(separator: " · ")
    }

    private func glazeImage(_ app: GlazeApplication) -> UIImage? {
        app.glaze.flatMap { ImageStore.shared.load($0.firedImagePath) }
            ?? ImageStore.shared.load(app.snapshotFiredImagePath)
    }

    private func glazeAreaText(_ app: GlazeApplication) -> String {
        var text = app.area.label
        if let label = app.areaLabel, !label.isEmpty {
            text += " · \(label)"
        }
        if app.opacity < 1.0 {
            text += " · \(Int((app.opacity * 100).rounded()))%"
        }
        return text
    }

    private func addActualPhoto(_ image: UIImage) {
        let path = ImageStore.shared.save(image)
        let photo = ProjectPhoto(caption: "", kind: .actualResult, imagePath: path)
        photo.project = project
        project.touch()
    }

    private func deleteProject() {
        for entry in project.journalEntries {
            entry.photoPaths.forEach { ImageStore.shared.delete($0) }
        }
        for firing in project.firingRecords {
            firing.photoPaths.forEach { ImageStore.shared.delete($0) }
        }
        for photo in project.photos {
            ImageStore.shared.delete(photo.imagePath)
        }
        ImageStore.shared.delete(project.inspirationImagePath)
        context.delete(project)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(name: "Dragon Mug"))
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
