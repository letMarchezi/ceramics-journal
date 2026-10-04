import SwiftUI
import SwiftData
import PhotosUI

/// SCREEN 13 — planned vs actual plus the experiment evaluation
/// (sections 21 & 22).
struct FinalResultView: View {
    let project: Project
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var whatWorked: String
    @State private var whatFailed: String
    @State private var surprises: String
    @State private var changes: String
    @State private var repeatDecision: RepeatDecision
    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false

    private let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    init(project: Project) {
        self.project = project
        let evaluation = project.evaluation
        _whatWorked = State(initialValue: evaluation?.whatWorked ?? "")
        _whatFailed = State(initialValue: evaluation?.whatFailed ?? "")
        _surprises = State(initialValue: evaluation?.surprises ?? "")
        _changes = State(initialValue: evaluation?.changesForNextTime ?? "")
        _repeatDecision = State(initialValue: evaluation?.repeatDecision ?? .maybe)
    }

    private var latestActualPhoto: ProjectPhoto? {
        project.actualPhotos.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    comparisonCard

                    card {
                        SectionTitle(emoji: "🌟", title: "What worked?")
                        entryField($whatWorked, "Describe the successes…")
                    }

                    card {
                        SectionTitle(emoji: "💥", title: "What failed?")
                        entryField($whatFailed, "Crazing, stuck, running glaze…")
                    }

                    card {
                        SectionTitle(emoji: "🪄", title: "What surprised me?")
                        entryField($surprises, "Unexpected colors, textures…")
                    }

                    card {
                        SectionTitle(emoji: "🔁", title: "What would I change next time?")
                        entryField($changes, "Thickness, firing, glaze combo…")
                    }

                    card {
                        SectionTitle(emoji: "🔁", title: "Would I repeat this combination?")
                        Picker("Decision", selection: $repeatDecision) {
                            ForEach(RepeatDecision.allCases) { decision in
                                Text(decision.label).tag(decision)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    card {
                        SectionTitle(emoji: "📷", title: "Actual result photos")
                        HStack(spacing: 10) {
                            if let photo = latestActualPhoto,
                               let image = ImageStore.shared.load(photo.imagePath) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(alignment: .topTrailing) {
                                        ImageTagView(kind: .actualResult).padding(4)
                                    }
                            }

                            if cameraAvailable {
                                Button {
                                    showCamera = true
                                } label: {
                                    photoButtonLabel(icon: "camera", text: "Take")
                                }
                            }

                            PhotosPicker(selection: $pickedItem, matching: .images) {
                                photoButtonLabel(icon: "photo.on.rectangle", text: "Choose")
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Final Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in
                    addActualPhoto(image)
                }
            }
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        addActualPhoto(image)
                    }
                    pickedItem = nil
                }
            }
        }
    }

    // MARK: - Comparison

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "⚖️", title: "Planned vs Actual")

            HStack(spacing: 14) {
                VStack(spacing: 6) {
                    PreviewCanvas(spec: .init(project: project), size: 130, showTag: false)
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
                                .frame(width: 130, height: 130)
                        } else {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Theme.olive.opacity(0.12))
                                .frame(width: 130, height: 130)
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
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    Text("ACTUAL")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.olive)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .cuteCard()
    }

    // MARK: - Helpers

    private func entryField(_ text: Binding<String>, _ placeholder: String) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(2...5)
            .padding(12)
            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
    }

    private func photoButtonLabel(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .font(.caption2)
        }
        .frame(width: 56, height: 56)
        .background(Theme.olive.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Theme.oliveDark)
    }

    private func addActualPhoto(_ image: UIImage) {
        let path = ImageStore.shared.save(image)
        let photo = ProjectPhoto(caption: "", kind: .actualResult, imagePath: path)
        photo.project = project
        project.touch()
    }

    private func save() {
        if let existing = project.evaluation {
            existing.whatWorked = whatWorked
            existing.whatFailed = whatFailed
            existing.surprises = surprises
            existing.changesForNextTime = changes
            existing.repeatDecision = repeatDecision
        } else {
            let evaluation = Evaluation()
            evaluation.whatWorked = whatWorked
            evaluation.whatFailed = whatFailed
            evaluation.surprises = surprises
            evaluation.changesForNextTime = changes
            evaluation.repeatDecision = repeatDecision
            evaluation.project = project
            project.evaluation = evaluation
        }
        project.touch()
        dismiss()
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
    FinalResultView(project: Project(name: "Test"))
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
