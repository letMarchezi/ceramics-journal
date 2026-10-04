import SwiftUI
import SwiftData

/// Tab-based navigation (section 34): Home / Projects / Materials / Journal.
struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ProjectsView()
                .tabItem { Label("Projects", systemImage: "tray.full") }

            MaterialsView()
                .tabItem { Label("Materials", systemImage: "swatch") }

            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
        }
        .tint(Theme.burgundy)
        .fontDesign(.rounded)
        .task {
            SeedData.seedIfNeeded(context: context)
        }
    }
}

#Preview {
    RootView()
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
