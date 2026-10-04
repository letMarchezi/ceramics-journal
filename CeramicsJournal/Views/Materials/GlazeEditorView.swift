import SwiftUI
import SwiftData

/// Create / edit a glaze record (FR-004, US-M05…M06).
struct GlazeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existing: Glaze?

    @State private var name: String
    @State private var manufacturer: String
    @State private var notes: String
    @State private var applicationNotes: String
    @State private var source: String
    @State private var finish: GlazeFinish
    @State private var transparency: GlazeTransparency
    @State private var minTemp: String
    @State private var maxTemp: String
    @State private var testedTemp: String
    @State private var confidence: MaterialConfidence
    @State private var firedPath: String?

    init(existing: Glaze? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _manufacturer = State(initialValue: existing?.manufacturer ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _applicationNotes = State(initialValue: existing?.applicationNotes ?? "")
        _source = State(initialValue: existing?.source ?? "")
        _finish = State(initialValue: existing?.finish ?? .unknown)
        _transparency = State(initialValue: existing?.transparency ?? .unknown)
        _minTemp = State(initialValue: existing?.minFiringTemperature.map { String(Int($0.rounded())) })
        _maxTemp = State(initialValue: existing?.maxFiringTemperature.map { String(Int($0.rounded())) })
        _testedTemp = State(initialValue: existing?.testedTemperature.map { String(Int($0.rounded())) })
        _confidence = State(initialValue: existing?.confidence ?? .reference)
        _firedPath = State(initialValue: existing?.firedImagePath)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    card {
                        SectionTitle(emoji: "🎨", title: "Basics")
                        TextField("Name (e.g. Silver)", text: $name)
                        TextField("Manufacturer (optional)", text: $manufacturer)

                        Picker("Finish", selection: $finish) {
                            ForEach(GlazeFinish.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Transparency", selection: $transparency) {
                            ForEach(GlazeTransparency.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    card {
                        SectionTitle(emoji: "📷", title: "Appearance")
                        PhotoSlot(title: "Fired appearance", imagePath: $firedPath)
                    }

                    card {
                        SectionTitle(emoji: "🔥", title: "Firing")
                        HStack(spacing: 12) {
                            tempField("Min (°C)", text: $minTemp)
                            tempField("Max (°C)", text: $maxTemp)
                        }
                        tempField("Tested temperature (°C)", text: $testedTemp)

                        Picker("Result status", selection: $confidence) {
                            ForEach(MaterialConfidence.allCases) { item in
                                Label(item.label, systemImage: item.icon).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    card {
                        SectionTitle(emoji: "📝", title: "Notes")
                        TextField("Surface / behavior notes", text: $applicationNotes, axis: .vertical)
                            .lineLimit(3...5)
                        TextField("General notes", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                        TextField("Source (optional)", text: $source)
                    }
                }
                .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New Glaze" : "Edit Glaze")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        let minTemp = Double(minTemp)
        let maxTemp = Double(maxTemp)
        let testedTemp = Double(testedTemp)

        if let existing {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.manufacturer = blankToNil(manufacturer)
            existing.notes = blankToNil(notes)
            existing.applicationNotes = blankToNil(applicationNotes)
            existing.source = blankToNil(source)
            existing.finish = finish
            existing.transparency = transparency
            existing.minFiringTemperature = minTemp
            existing.maxFiringTemperature = maxTemp
            existing.testedTemperature = testedTemp
            existing.confidence = confidence
            existing.firedImagePath = firedPath
        } else {
            let glaze = Glaze(
                name: name.trimmingCharacters(in: .whitespaces),
                manufacturer: blankToNil(manufacturer),
                notes: blankToNil(notes),
                firedImagePath: firedPath,
                finish: finish,
                transparency: transparency,
                minFiringTemperature: minTemp,
                maxFiringTemperature: maxTemp,
                testedTemperature: testedTemp,
                applicationNotes: blankToNil(applicationNotes),
                confidence: confidence,
                source: blankToNil(source)
            )
            context.insert(glaze)
        }
        dismiss()
    }

    // MARK: - Helpers

    private func blankToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func tempField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 10))
        }
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
    GlazeEditorView()
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
