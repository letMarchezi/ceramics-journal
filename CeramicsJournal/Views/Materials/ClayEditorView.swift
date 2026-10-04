import SwiftUI
import SwiftData

/// Create / edit a clay (or engobe) record (FR-003, US-M01…M04).
struct ClayEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existing: Clay?

    @State private var name: String
    @State private var kind: MaterialKind
    @State private var manufacturer: String
    @State private var notes: String
    @State private var source: String
    @State private var minTemp: String
    @State private var maxTemp: String
    @State private var testedTemp: String
    @State private var confidence: MaterialConfidence
    @State private var rawPath: String?
    @State private var firedPath: String?

    init(existing: Clay? = nil, defaultKind: MaterialKind = .clay) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _kind = State(initialValue: existing?.kind ?? defaultKind)
        _manufacturer = State(initialValue: existing?.manufacturer ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _source = State(initialValue: existing?.source ?? "")
        _minTemp = State(initialValue: existing?.minFiringTemperature.map { String(Int($0.rounded())) })
        _maxTemp = State(initialValue: existing?.maxFiringTemperature.map { String(Int($0.rounded())) })
        _testedTemp = State(initialValue: existing?.testedTemperature.map { String(Int($0.rounded())) })
        _confidence = State(initialValue: existing?.confidence ?? .reference)
        _rawPath = State(initialValue: existing?.rawImagePath)
        _firedPath = State(initialValue: existing?.firedImagePath)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    card {
                        SectionTitle(emoji: "🧱", title: "Basics")
                        TextField("Name (e.g. Egito)", text: $name)
                        Picker("Type", selection: $kind) {
                            ForEach(MaterialKind.allCases) { materialKind in
                                Text(materialKind.label).tag(materialKind)
                            }
                        }
                        .pickerStyle(.segmented)
                        TextField("Manufacturer (optional)", text: $manufacturer)
                    }

                    card {
                        SectionTitle(emoji: "📷", title: "Appearance")
                        PhotoSlot(title: "Raw appearance", imagePath: $rawPath)
                        Divider()
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
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                        TextField("Source (optional)", text: $source)
                    }
                }
                .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New \(kind.label)" : "Edit \(kind.label)")
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
            existing.kind = kind
            existing.manufacturer = blankToNil(manufacturer)
            existing.notes = blankToNil(notes)
            existing.source = blankToNil(source)
            existing.minFiringTemperature = minTemp
            existing.maxFiringTemperature = maxTemp
            existing.testedTemperature = testedTemp
            existing.confidence = confidence
            existing.rawImagePath = rawPath
            existing.firedImagePath = firedPath
        } else {
            let clay = Clay(
                name: name.trimmingCharacters(in: .whitespaces),
                kind: kind,
                manufacturer: blankToNil(manufacturer),
                notes: blankToNil(notes),
                rawImagePath: rawPath,
                firedImagePath: firedPath,
                minFiringTemperature: minTemp,
                maxFiringTemperature: maxTemp,
                testedTemperature: testedTemp,
                confidence: confidence,
                source: blankToNil(source)
            )
            context.insert(clay)
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
    ClayEditorView()
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
