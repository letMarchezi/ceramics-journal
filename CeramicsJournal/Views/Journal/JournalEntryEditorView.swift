import SwiftUI
import SwiftData
import PhotosUI

/// Create a journal entry — optionally attached to a project,
/// with title, text and photos (US-J01…J05, TASK-022/023).
struct JournalEntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var project: Project?

    @Query(sort: \Project.name) private var allProjects: [Project]

    @State private var selectedProjectID: UUID?
    @State private var title: String = ""
    @State private var text: String = ""
    @State private var photoPaths: [String] = []
    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false

    private let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    init(project: Project? = nil) {
        self.project = project
        _selectedProjectID = State(initialValue: project?.id)
    }

    private var selectedProject: Project? {
        if let project {
            return project
        }
        return allProjects.first { $0.id == selectedProjectID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    card {
                        SectionTitle(emoji: "📖", title: "Journal Entry")
                        TextField("Title (e.g. Wedging)", text: $title)
                            .padding(12)
                            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))

                        if project == nil {
                            Picker("Project", selection: $selectedProjectID) {
                                Text("General (no project)").tag(UUID?.none)
                                ForEach(allProjects) { item in
                                    Text(item.name).tag(UUID?.some(item.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    card {
                        SectionTitle(emoji: "✍️", title: "Notes")
                        TextField(
                            "What happened? Mistakes, surprises, anything worth remembering…",
                            text: $text,
                            axis: .vertical
                        )
                        .lineLimit(4...8)
                    }

                    card {
                        SectionTitle(emoji: "📷", title: "Photos")
                        HStack(spacing: 10) {
                            if photoPaths.isEmpty {
                                Text("No photos attached.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }

                            ForEach(photoPaths, id: \.self) { path in
                                if let image = ImageStore.shared.load(path) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                photoPaths.removeAll { $0 == path }
                                                ImageStore.shared.delete(path)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, Theme.burgundy)
                                            }
                                        }
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
            .navigationTitle("New Journal Entry")
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in
                    photoPaths.append(ImageStore.shared.save(image))
                }
            }
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoPaths.append(ImageStore.shared.save(image))
                    }
                    pickedItem = nil
                }
            }
        }
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

    private func save() {
        let entry = JournalEntry(
            title: title.trimmingCharacters(in: .whitespaces),
            text: text,
            project: selectedProject
        )
        entry.photoPaths = photoPaths
        context.insert(entry)
        selectedProject?.touch()
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
    JournalEntryEditorView()
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
