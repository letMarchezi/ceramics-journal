import SwiftUI
import SwiftData

/// Global search across projects, materials, journal, firings and
/// evaluation text (section 42).
struct SearchResultsView: View {
    let query: String

    @Query private var projects: [Project]
    @Query private var clays: [Clay]
    @Query private var glazes: [Glaze]
    @Query private var entries: [JournalEntry]
    @Query private var firings: [FiringRecord]

    private var q: String {
        query.lowercased()
    }

    // MARK: - Matching

    private var matchingProjects: [Project] {
        projects.filter { p in
            p.name.lowercased().contains(q)
            || (p.notes?.lowercased().contains(q) ?? false)
            || p.displayClayName.lowercased().contains(q)
            || p.displayShapeName.lowercased().contains(q)
            || p.journalEntries.contains {
                $0.title.lowercased().contains(q) || $0.text.lowercased().contains(q)
            }
            || p.firingRecords.contains {
                $0.notes.lowercased().contains(q)
                || ($0.kiln?.lowercased().contains(q) ?? false)
            }
            || (p.evaluation?.whatWorked.lowercased().contains(q) ?? false)
            || (p.evaluation?.whatFailed.lowercased().contains(q) ?? false)
            || (p.evaluation?.surprises.lowercased().contains(q) ?? false)
            || (p.evaluation?.changesForNextTime.lowercased().contains(q) ?? false)
        }
    }

    private var matchingClays: [Clay] {
        clays.filter { c in
            c.name.lowercased().contains(q)
            || (c.manufacturer?.lowercased().contains(q) ?? false)
            || (c.notes?.lowercased().contains(q) ?? false)
        }
    }

    private var matchingGlazes: [Glaze] {
        glazes.filter { g in
            g.name.lowercased().contains(q)
            || (g.manufacturer?.lowercased().contains(q) ?? false)
            || (g.notes?.lowercased().contains(q) ?? false)
        }
    }

    private var matchingEntries: [JournalEntry] {
        entries.filter { e in
            e.title.lowercased().contains(q) || e.text.lowercased().contains(q)
        }
    }

    private var matchingFirings: [FiringRecord] {
        firings.filter { f in
            f.notes.lowercased().contains(q)
            || (f.kiln?.lowercased().contains(q) ?? false)
            || (f.atmosphere?.lowercased().contains(q) ?? false)
        }
    }

    private var totalCount: Int {
        matchingProjects.count + matchingClays.count + matchingGlazes.count
            + matchingEntries.count + matchingFirings.count
    }

    // MARK: - Body

    var body: some View {
        List {
            if matchingProjects.isEmpty
                && matchingClays.isEmpty
                && matchingGlazes.isEmpty
                && matchingEntries.isEmpty
                && matchingFirings.isEmpty {
                Section {
                    Text("Nothing found for “\(query)”.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            if !matchingProjects.isEmpty {
                Section("Projects") {
                    ForEach(matchingProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            resultRow(
                                icon: "tray.full",
                                tint: Theme.burgundy,
                                title: project.name,
                                subtitle: "\(project.displayClayName) · \(project.displayShapeName) · \(project.status.label)"
                            )
                        }
                    }
                }
            }

            if !matchingClays.isEmpty {
                Section("Clays & Engobes") {
                    ForEach(matchingClays) { clay in
                        NavigationLink {
                            ClayDetailView(clay: clay)
                        } label: {
                            resultRow(
                                icon: "drop.fill",
                                tint: Theme.clayFallback,
                                title: clay.name,
                                subtitle: "\(clay.kind.label) · \(clay.manufacturer ?? "—")"
                            )
                        }
                    }
                }
            }

            if !matchingGlazes.isEmpty {
                Section("Glazes") {
                    ForEach(matchingGlazes) { glaze in
                        NavigationLink {
                            GlazeDetailView(glaze: glaze)
                        } label: {
                            resultRow(
                                icon: "paintbrush",
                                tint: Theme.mustard,
                                title: glaze.name,
                                subtitle: "\(glaze.finish.label) · \(glaze.manufacturer ?? "—")"
                            )
                        }
                    }
                }
            }

            if !matchingEntries.isEmpty {
                Section("Journal") {
                    ForEach(matchingEntries) { entry in
                        if let project = entry.project {
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                resultRow(
                                    icon: "book",
                                    tint: Theme.olive,
                                    title: entry.title,
                                    subtitle: entry.project?.name ?? "General"
                                )
                            }
                        } else {
                            resultRow(
                                icon: "book",
                                tint: Theme.olive,
                                title: entry.title,
                                subtitle: entry.text.isEmpty ? "General journal" : String(entry.text.prefix(60))
                            )
                        }
                    }
                }
            }

            if !matchingFirings.isEmpty {
                Section("Firings") {
                    ForEach(matchingFirings) { firing in
                        resultRow(
                            icon: firing.type.icon,
                            tint: Theme.mustardDark,
                            title: "\(firing.type.label) firing",
                            subtitle: "\(firing.project?.name ?? "—") · \(firing.result.label)"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Theme.cream.ignoresSafeArea())
    }

    // MARK: - Row

    private func resultRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.18))
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}
