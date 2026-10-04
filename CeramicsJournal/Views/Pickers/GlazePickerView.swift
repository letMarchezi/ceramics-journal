import SwiftUI
import SwiftData

/// SCREEN 7 — pick one or more glazes from the library.
struct GlazePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Set<UUID>

    @Query(sort: \Glaze.name) private var glazes: [Glaze]
    @State private var showNewGlaze = false

    var body: some View {
        NavigationStack {
            Group {
                if glazes.isEmpty {
                    EmptyState(
                        emoji: "🎨",
                        title: "No glazes yet",
                        message: "Create your first glaze record to start composing previews."
                    )
                } else {
                    List {
                        ForEach(glazes) { glaze in
                            Button {
                                if selection.contains(glaze.id) {
                                    selection.remove(glaze.id)
                                } else {
                                    selection.insert(glaze.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    MaterialThumb(
                                        image: ImageStore.shared.load(glaze.firedImagePath),
                                        accent: Theme.mustard,
                                        icon: "paintbrush",
                                        size: 44
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(glaze.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Theme.ink)
                                            if selection.contains(glaze.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.burgundy)
                                            }
                                        }
                                        Text("\(glaze.finish.label) · \(glaze.transparency.label) · \(glaze.displayRange)")
                                            .font(.caption)
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Theme.cream.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button {
                        selection.removeAll()
                    } label: {
                        Label("Clear", systemImage: "xmark")
                            .font(.footnote.weight(.semibold))
                    }
                    .tint(Theme.burgundy)

                    Button {
                        showNewGlaze = true
                    } label: {
                        Label("New glaze", systemImage: "plus")
                            .font(.footnote.weight(.semibold))
                    }
                    .tint(Theme.oliveDark)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Choose Glaze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showNewGlaze) {
                GlazeEditorView()
            }
        }
    }
}

#Preview {
    GlazePickerView(selection: .constant([]))
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
