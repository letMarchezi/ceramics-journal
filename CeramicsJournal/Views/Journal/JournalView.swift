import SwiftUI
import SwiftData

/// SCREEN 11 — chronological studio history: project creation,
/// construction entries and firings, grouped by day.
struct JournalView: View {
    @Query private var projects: [Project]
    @Query private var entries: [JournalEntry]
    @Query private var firings: [FiringRecord]

    @State private var searchText = ""
    @State private var showEditor = false

    struct TimelineItem: Identifiable {
        let id: UUID
        let date: Date
        let icon: String
        let title: String
        let subtitle: String
        let detail: String?
        let photos: [String]
        let project: Project?
    }

    // MARK: - Timeline

    private var items: [TimelineItem] {
        var result: [TimelineItem] = []

        for project in projects {
            result.append(TimelineItem(
                id: project.id,
                date: project.createdAt,
                icon: "tray.badge.plus",
                title: "Project created",
                subtitle: project.name,
                detail: nil,
                photos: [],
                project: project
            ))

            for entry in project.journalEntries {
                result.append(TimelineItem(
                    id: entry.id,
                    date: entry.createdAt,
                    icon: "book",
                    title: entry.title,
                    subtitle: project.name,
                    detail: entry.text.isEmpty ? nil : entry.text,
                    photos: entry.photoPaths,
                    project: project
                ))
            }

            for firing in project.firingRecords {
                let target = firing.targetTemperature.map { "\(Int($0.rounded()))°C" }
                result.append(TimelineItem(
                    id: firing.id,
                    date: firing.date,
                    icon: firing.type.icon,
                    title: "\(firing.type.label) firing",
                    subtitle: project.name,
                    detail: [target, firing.result.label].compactMap { $0 }.joined(separator: " · "),
                    photos: firing.photoPaths,
                    project: project
                ))
            }
        }

        // Stand-alone entries without a project.
        for entry in entries where entry.project == nil {
            result.append(TimelineItem(
                id: entry.id,
                date: entry.createdAt,
                icon: "book",
                title: entry.title,
                subtitle: "General",
                detail: entry.text.isEmpty ? nil : entry.text,
                photos: entry.photoPaths,
                project: nil
            ))
        }

        var filtered = result
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            filtered = filtered.filter {
                $0.title.lowercased().contains(q)
                || $0.subtitle.lowercased().contains(q)
                || ($0.detail?.lowercased().contains(q) ?? false)
            }
        }

        return filtered.sorted { $0.date > $1.date }
    }

    private struct DayGroup: Identifiable {
        let date: Date
        let items: [TimelineItem]
        var id: Date { date }
    }

    private var days: [DayGroup] {
        Dictionary(grouping: items) { $0.date.startOfDay }
            .map { DayGroup(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyState(
                        emoji: "📖",
                        title: searchText.isEmpty ? "Journal is empty" : "No matching entries",
                        message: searchText.isEmpty
                            ? "Add a journal entry to start your studio history."
                            : "Try a different search."
                    )
                } else {
                    List {
                        ForEach(days) { day in
                            Section(day.date.prettyDay) {
                                ForEach(day.items) { item in
                                    row(for: item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                JournalEntryEditorView()
            }
        }
    }

    @ViewBuilder
    private func row(for item: TimelineItem) -> some View {
        if let project = item.project {
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                content(for: item)
            }
        } else {
            content(for: item)
        }
    }

    private func content(for item: TimelineItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Theme.olive.opacity(0.15))
                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundStyle(Theme.olive)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(item.subtitle) · \(item.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }

            if let detail = item.detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(3)
            }

            if !item.photos.isEmpty {
                HStack(spacing: 8) {
                    ForEach(item.photos.prefix(4), id: \.self) { path in
                        if let image = ImageStore.shared.load(path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalView()
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
