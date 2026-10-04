import SwiftUI
import SwiftData

/// SCREEN 1 — quick overview of the studio with global search.
struct HomeView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \Clay.createdAt, order: .reverse) private var clays: [Clay]
    @Query(sort: \Glaze.createdAt, order: .reverse) private var glazes: [Glaze]

    @State private var searchText = ""
    @State private var showNewProject = false
    @State private var showClayEditor = false
    @State private var showGlazeEditor = false
    @State private var showJournalEditor = false

    private var recentProjects: [Project] {
        Array(projects.prefix(4))
    }

    var body: some View {
        NavigationStack {
            Group {
                if !searchText.isEmpty {
                    SearchResultsView(query: searchText)
                } else {
                    homeContent
                }
            }
            .navigationTitle("Ceramics Journal")
            .searchable(text: $searchText, prompt: "Search projects, materials, journal")
            .background(Theme.cream.ignoresSafeArea())
        }
        .sheet(isPresented: $showNewProject) { NewProjectView() }
        .sheet(isPresented: $showClayEditor) { ClayEditorView() }
        .sheet(isPresented: $showGlazeEditor) { GlazeEditorView() }
        .sheet(isPresented: $showJournalEditor) { JournalEntryEditorView() }
    }

    // MARK: - Content

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                newProjectButton
                recentProjectsSection
                materialsSection
                quickActions
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("🏺")
                .font(.system(size: 52))
            Text("Welcome back, ceramicist")
                .font(.title2.bold())
                .foregroundStyle(Theme.ink)
            Text("Your studio notebook — plan, fire, remember.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var newProjectButton: some View {
        Button {
            showNewProject = true
        } label: {
            Label("New Project", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(CutePrimaryButton())
    }

    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "📔", title: "Recent Projects")

            if recentProjects.isEmpty {
                EmptyState(
                    emoji: "🫙",
                    title: "No projects yet",
                    message: "Tap “New Project” to plan your first piece."
                )
            } else {
                ForEach(recentProjects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "🎨", title: "Materials")

            if clays.isEmpty && glazes.isEmpty {
                EmptyState(
                    emoji: "🧱",
                    title: "No materials yet",
                    message: "Add clays and glazes to build your library."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(clays.prefix(4))) { clay in
                            NavigationLink {
                                ClayDetailView(clay: clay)
                            } label: {
                                materialChip(
                                    title: clay.name,
                                    subtitle: clay.displayRange,
                                    image: ImageStore.shared.load(clay.firedImagePath),
                                    accent: Theme.clayFallback,
                                    icon: "drop.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(Array(glazes.prefix(4))) { glaze in
                            NavigationLink {
                                GlazeDetailView(glaze: glaze)
                            } label: {
                                materialChip(
                                    title: glaze.name,
                                    subtitle: glaze.finish.label,
                                    image: ImageStore.shared.load(glaze.firedImagePath),
                                    accent: Theme.mustard,
                                    icon: "paintbrush"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func materialChip(title: String, subtitle: String, image: UIImage?, accent: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            MaterialThumb(image: image, accent: accent, icon: icon, size: 72)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(10)
        .frame(width: 110, alignment: .leading)
        .cuteCard()
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(emoji: "⚡️", title: "Quick Actions")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickActionButton("New Project", "tray.badge.plus", Theme.burgundy) {
                    showNewProject = true
                }
                quickActionButton("Add Clay", "square.stack.3d.up", Theme.olive) {
                    showClayEditor = true
                }
                quickActionButton("Add Glaze", "paintbrush.fill", Theme.mustardDark) {
                    showGlazeEditor = true
                }
                quickActionButton("Journal Entry", "book", Theme.oliveDark) {
                    showJournalEditor = true
                }
            }
        }
    }

    private func quickActionButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(color)
            .cuteCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
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
