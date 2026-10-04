import SwiftUI
import SwiftData

/// SCREEN 2 — all projects with search, filters and list/grid toggle
/// (US-R01…R05, FR-043).
struct ProjectsView: View {
    @Query private var projects: [Project]
    @Query(sort: \Clay.name) private var clays: [Clay]
    @Query(sort: \Glaze.name) private var glazes: [Glaze]

    @State private var searchText = ""
    @State private var statusFilter: ProjectStatus?
    @State private var clayFilter: Clay?
    @State private var glazeFilter: Glaze?
    @State private var shapeFilter: ShapeCategory?
    @State private var sort: ProjectSort = .newest
    @State private var isGrid = false
    @State private var showNewProject = false

    // MARK: - Filtering

    private var filtered: [Project] {
        var result = projects

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q)
                || $0.displayClayName.lowercased().contains(q)
                || $0.displayShapeName.lowercased().contains(q)
                || ($0.notes?.lowercased().contains(q) ?? false)
            }
        }
        if let statusFilter {
            result = result.filter { $0.status == statusFilter }
        }
        if let clayFilter {
            result = result.filter {
                $0.clay?.id == clayFilter.id || $0.claySnapshotName == clayFilter.name
            }
        }
        if let glazeFilter {
            result = result.filter {
                $0.glazeApplications.contains {
                    $0.glaze?.id == glazeFilter.id || $0.snapshotGlazeName == glazeFilter.name
                }
            }
        }
        if let shapeFilter {
            result = result.filter { $0.shape?.category == shapeFilter }
        }

        switch sort {
        case .newest:
            return result.sorted { $0.updatedAt > $1.updatedAt }
        case .oldest:
            return result.sorted { $0.updatedAt < $1.updatedAt }
        case .name:
            return result.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    private var hasActiveFilters: Bool {
        statusFilter != nil || clayFilter != nil || glazeFilter != nil
            || shapeFilter != nil || !searchText.isEmpty
    }

    private func clearFilters() {
        statusFilter = nil
        clayFilter = nil
        glazeFilter = nil
        shapeFilter = nil
        searchText = ""
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    EmptyState(
                        emoji: "🏺",
                        title: projects.isEmpty ? "No projects yet" : "No matching projects",
                        message: projects.isEmpty
                            ? "Plan your first ceramic piece."
                            : "Try adjusting the search or filters."
                    )
                } else if isGrid {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160), spacing: 14)],
                            spacing: 14
                        ) {
                            ForEach(filtered) { project in
                                NavigationLink {
                                    ProjectDetailView(project: project)
                                } label: {
                                    ProjectCard(project: project, vertical: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                } else {
                    List(filtered) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectCard(project: project)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.card)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects")
            .background(Theme.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Status", selection: $statusFilter) {
                            Text("All statuses").tag(ProjectStatus?.none)
                            ForEach(ProjectStatus.allCases) { status in
                                Text(status.label).tag(ProjectStatus?.some(status))
                            }
                        }

                        Picker("Clay", selection: $clayFilter) {
                            Text("All clays").tag(Clay?.none)
                            ForEach(clays) { clay in
                                Text(clay.name).tag(Clay?.some(clay))
                            }
                        }

                        Picker("Glaze", selection: $glazeFilter) {
                            Text("All glazes").tag(Glaze?.none)
                            ForEach(glazes) { glaze in
                                Text(glaze.name).tag(Glaze?.some(glaze))
                            }
                        }

                        Picker("Shape", selection: $shapeFilter) {
                            Text("All shapes").tag(ShapeCategory?.none)
                            ForEach(ShapeCategory.allCases) { category in
                                Text(category.label).tag(ShapeCategory?.some(category))
                            }
                        }

                        Picker("Sort", selection: $sort) {
                            ForEach(ProjectSort.allCases) { order in
                                Text(order.label).tag(order)
                            }
                        }

                        if hasActiveFilters {
                            Button("Clear filters") {
                                clearFilters()
                            }
                        }
                    } label: {
                        Label(
                            "Filters",
                            systemImage: hasActiveFilters
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle"
                        )
                    }

                    Button {
                        isGrid.toggle()
                    } label: {
                        Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                    }

                    Button {
                        showNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewProject) {
                NewProjectView()
            }
        }
    }
}

enum ProjectSort: String, CaseIterable, Identifiable {
    case newest, oldest, name

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: return "Newest first"
        case .oldest: return "Oldest first"
        case .name: return "Name A–Z"
        }
    }
}

#Preview {
    ProjectsView()
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
