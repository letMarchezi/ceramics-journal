import SwiftUI
import SwiftData

/// SCREEN 9 — the material library with Clays / Glazes / Engobes categories.
struct MaterialsView: View {
    @Query(sort: \Clay.createdAt, order: .reverse) private var clays: [Clay]
    @Query(sort: \Glaze.createdAt, order: .reverse) private var glazes: [Glaze]

    @State private var tab: MaterialTab = .clays
    @State private var searchText = ""
    @State private var showClayEditor = false
    @State private var showGlazeEditor = false

    enum MaterialTab: String, CaseIterable, Identifiable {
        case clays = "Clays"
        case glazes = "Glazes"
        case engobes = "Engobes"

        var id: String { rawValue }
    }

    // MARK: - Data

    private var visibleClays: [Clay] {
        switch tab {
        case .clays: return clays.filter { $0.kind == .clay }
        case .engobes: return clays.filter { $0.kind == .engobe }
        case .glazes: return []
        }
    }

    private var visibleGlazes: [Glaze] {
        tab == .glazes ? glazes : []
    }

    private var filteredClays: [Clay] {
        guard !searchText.isEmpty else { return visibleClays }
        let q = searchText.lowercased()
        return visibleClays.filter {
            $0.name.lowercased().contains(q)
            || ($0.manufacturer?.lowercased().contains(q) ?? false)
            || ($0.notes?.lowercased().contains(q) ?? false)
        }
    }

    private var filteredGlazes: [Glaze] {
        guard !searchText.isEmpty else { return visibleGlazes }
        let q = searchText.lowercased()
        return visibleGlazes.filter {
            $0.name.lowercased().contains(q)
            || ($0.manufacturer?.lowercased().contains(q) ?? false)
            || ($0.notes?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category", selection: $tab) {
                    ForEach(MaterialTab.allCases) { materialTab in
                        Text(materialTab.rawValue).tag(materialTab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                content
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Materials")
            .searchable(text: $searchText, prompt: "Search materials")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if tab == .glazes {
                            showGlazeEditor = true
                        } else {
                            showClayEditor = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showClayEditor) {
                ClayEditorView(existing: nil, defaultKind: tab == .engobes ? .engobe : .clay)
            }
            .sheet(isPresented: $showGlazeEditor) {
                GlazeEditorView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if filteredClays.isEmpty && filteredGlazes.isEmpty {
            EmptyState(
                emoji: tab == .glazes ? "🎨" : "🧱",
                title: "Nothing here yet",
                message: "Tap + to add your first \(tabLabel). \(hasMaterials ? "" : "This library is still empty.")"
            )
        } else {
            List {
                ForEach(filteredClays) { clay in
                    NavigationLink {
                        ClayDetailView(clay: clay)
                    } label: {
                        MaterialCard(
                            title: clay.name,
                            subtitle: "\(clay.kind.label) · \(clay.displayRange)",
                            image: ImageStore.shared.load(clay.firedImagePath),
                            accent: Theme.clayFallback,
                            confidence: clay.confidence,
                            icon: "drop.fill"
                        )
                    }
                }

                ForEach(filteredGlazes) { glaze in
                    NavigationLink {
                        GlazeDetailView(glaze: glaze)
                    } label: {
                        MaterialCard(
                            title: glaze.name,
                            subtitle: "\(glaze.finish.label) · \(glaze.displayRange)",
                            image: ImageStore.shared.load(glaze.firedImagePath),
                            accent: Theme.mustard,
                            confidence: glaze.confidence,
                            icon: "paintbrush"
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var tabLabel: String {
        switch tab {
        case .clays: return "clay"
        case .glazes: return "glaze"
        case .engobes: return "engobe"
        }
    }

    private var hasMaterials: Bool {
        !clays.isEmpty || !glazes.isEmpty
    }
}

#Preview {
    MaterialsView()
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
