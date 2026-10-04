import SwiftUI
import SwiftData

/// SCREEN 5 — grid of shapes; selecting one updates the binding
/// immediately. Includes custom shape creation (TASK-006).
struct ShapePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: PieceShape?

    @Query(sort: \PieceShape.createdAt) private var shapes: [PieceShape]
    @State private var showCustom = false

    private var ordered: [PieceShape] {
        shapes.filter { !$0.isCustom } + shapes.filter { $0.isCustom }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(ordered) { shape in
                        cell(for: shape)
                    }
                }
                .padding()

                Button {
                    showCustom = true
                } label: {
                    Label("New custom shape", systemImage: "plus")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.olive.opacity(0.15)))
                        .foregroundStyle(Theme.oliveDark)
                }
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Choose Shape")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCustom) {
                CustomShapeEditorView { newShape in
                    selection = newShape
                }
            }
        }
    }

    private func cell(for shape: PieceShape) -> some View {
        let isSelected = selection?.id == shape.id
        return Button {
            selection = shape
        } label: {
            VStack(spacing: 8) {
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
}

// MARK: - Custom shape

/// Create a custom shape with an optional reference photo and dimensions.
struct CustomShapeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var onCreated: (PieceShape) -> Void

    @State private var name = ""
    @State private var category: ShapeCategory = .other
    @State private var referencePath: String?
    @State private var width = ""
    @State private var height = ""
    @State private var depth = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    card {
                        SectionTitle(emoji: "📐", title: "Custom Shape")
                        TextField("Name (e.g. Dragon Mug)", text: $name)

                        Picker("Base category", selection: $category) {
                            ForEach(ShapeCategory.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack(spacing: 10) {
                            dimField("W", $width)
                            dimField("H", $height)
                            dimField("D", $depth)
                        }
                    }

                    card {
                        PhotoSlot(title: "Reference photo (optional)", imagePath: $referencePath)
                    }

                    VStack(spacing: 6) {
                        Text("Preview silhouette")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                        ShapeThumb(category: category)
                            .frame(height: 90)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Custom Shape")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        create()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func dimField(_ label: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft)
            TextField("cm", text: text)
                .keyboardType(.decimalPad)
                .font(.caption)
                .padding(8)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
    }

    private func create() {
        let shape = PieceShape(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            referenceImagePath: referencePath,
            defaultWidth: Double(width),
            defaultHeight: Double(height),
            defaultDepth: Double(depth),
            isCustom: true
        )
        context.insert(shape)
        onCreated(shape)
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
    ShapePickerView(selection: .constant(nil))
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
