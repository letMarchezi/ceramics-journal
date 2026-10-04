import SwiftUI
import SwiftData

/// SCREEN 6 — pick a clay from the library; "None" and "New clay" options.
struct ClayPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Clay?

    @Query(sort: \Clay.name) private var clays: [Clay]
    @State private var showNewClay = false

    var body: some View {
        NavigationStack {
            Group {
                if clays.isEmpty {
                    EmptyState(
                        emoji: "🧱",
                        title: "No clays yet",
                        message: "Create your first clay record."
                    )
                } else {
                    List {
                        ForEach(clays) { clay in
                            Button {
                                selection = clay
                            } label: {
                                HStack(spacing: 12) {
                                    MaterialThumb(
                                        image: ImageStore.shared.load(clay.firedImagePath),
                                        accent: Theme.clayFallback,
                                        icon: "drop.fill",
                                        size: 44
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(clay.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Theme.ink)
                                            if selection?.id == clay.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.burgundy)
                                            }
                                        }
                                        Text("\(clay.kind.label) · \(clay.displayRange)")
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
                        selection = nil
                    } label: {
                        Label("None", systemImage: "xmark")
                            .font(.footnote.weight(.semibold))
                    }
                    .tint(Theme.burgundy)

                    Button {
                        showNewClay = true
                    } label: {
                        Label("New clay", systemImage: "plus")
                            .font(.footnote.weight(.semibold))
                    }
                    .tint(Theme.oliveDark)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Choose Clay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showNewClay) {
                ClayEditorView()
            }
        }
    }
}

#Preview {
    ClayPickerView(selection: .constant(nil))
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
