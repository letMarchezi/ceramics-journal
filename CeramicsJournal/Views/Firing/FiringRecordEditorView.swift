import SwiftUI
import SwiftData
import PhotosUI

/// SCREEN 12 — record a firing with the default profile
/// (bisque 1000°C, glaze 1240°C).
struct FiringRecordEditorView: View {
    let project: Project
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var type: FiringType
    @State private var target: String
    @State private var actualMax: String
    @State private var date: Date
    @State private var kiln: String
    @State private var atmosphere: String
    @State private var result: FiringResult
    @State private var notes: String
    @State private var photoPaths: [String] = []
    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false

    private let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    init(project: Project, type: FiringType = .bisque) {
        self.project = project
        _type = State(initialValue: type)
        _target = State(initialValue: type == .glaze ? "1240" : "1000")
        _actualMax = State(initialValue: "")
        _date = State(initialValue: Date())
        _kiln = State(initialValue: "")
        _atmosphere = State(initialValue: "")
        _result = State(initialValue: .unknown)
        _notes = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    card {
                        SectionTitle(emoji: "🔥", title: "Firing")

                        Picker("Type", selection: $type) {
                            ForEach(FiringType.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 12) {
                            tempField(
                                "Target temperature (°C)",
                                text: $target,
                                placeholder: type.defaultTargetTemperature.map { String(Int($0)) } ?? "—"
                            )
                            tempField("Actual max (°C)", text: $actualMax, placeholder: "—")
                        }

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .font(.subheadline)

                        Picker("Result", selection: $result) {
                            ForEach(FiringResult.allCases) { item in
                                Label(item.label, systemImage: item.icon).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    card {
                        SectionTitle(emoji: "⚙️", title: "Details")
                        TextField("Kiln (optional)", text: $kiln)
                        TextField("Atmosphere (optional, e.g. oxidation)", text: $atmosphere)
                        TextField("Firing notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
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
            .navigationTitle("Firing Record")
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
            .onChange(of: type) { _, newValue in
                // Default the target temperature per the studio profile.
                target = newValue == .glaze ? "1240" : "1000"
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
        .background(Theme.mustard.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Theme.mustardDark)
    }

    private func tempField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func save() {
        let record = FiringRecord(type: type, project: project, date: date)
        record.targetTemperature = Double(target)
        record.maximumTemperature = Double(actualMax)
        record.kiln = blankToNil(kiln)
        record.atmosphere = blankToNil(atmosphere)
        record.result = result
        record.notes = notes
        record.photoPaths = photoPaths
        context.insert(record)
        project.touch()
        dismiss()
    }

    private func blankToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
        FiringRecordEditorView(project: Project(name: "Test"))
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
