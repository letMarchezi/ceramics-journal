import SwiftUI

/// Everything the canvas needs to compose a preview.
///
/// Deliberately decoupled from the models so it can be driven by drafts
/// (new-project flow) or live projects.
struct PreviewSpec {
    var category: ShapeCategory
    var clayImage: UIImage?
    var clayColor: UIColor
    var apps: [Application]

    struct Application: Identifiable {
        let id: UUID
        var glazeImage: UIImage?
        var glazeColor: UIColor
        var area: ApplicationArea
        var opacity: Double

        init(
            id: UUID = UUID(),
            glazeImage: UIImage?,
            glazeColor: UIColor,
            area: ApplicationArea,
            opacity: Double
        ) {
            self.id = id
            self.glazeImage = glazeImage
            self.glazeColor = glazeColor
            self.area = area
            self.opacity = opacity
        }
    }

    init(
        category: ShapeCategory = .mug,
        clayImage: UIImage? = nil,
        clayColor: UIColor = UIColor(Theme.clayFallback),
        apps: [Application] = []
    ) {
        self.category = category
        self.clayImage = clayImage
        self.clayColor = clayColor
        self.apps = apps
    }

    /// Builds a spec from a live project (with material snapshots as
    /// fallback for deleted library materials).
    init(project: Project) {
        let clay = project.clay

        self.init(
            category: project.shape?.category ?? .mug,
            clayImage: clay.flatMap { ImageStore.shared.load($0.firedImagePath) }
                ?? ImageStore.shared.load(project.claySnapshotFiredPath),
            clayColor: {
                if let clay, let color = ImageStore.shared.averageColor(clay.firedImagePath) {
                    return color
                }
                if let color = ImageStore.shared.averageColor(project.claySnapshotFiredPath) {
                    return color
                }
                return UIColor(Theme.clayFallback)
            }(),
            apps: project.glazeApplications
                .sorted { $0.order < $1.order }
                .map { app in
                    PreviewSpec.Application(
                        glazeImage: app.glaze.flatMap { ImageStore.shared.load($0.firedImagePath) }
                            ?? ImageStore.shared.load(app.snapshotFiredImagePath),
                        glazeColor: {
                            if let glaze = app.glaze,
                               let color = ImageStore.shared.averageColor(glaze.firedImagePath) {
                                return color
                            }
                            if let color = ImageStore.shared.averageColor(app.snapshotFiredImagePath) {
                                return color
                            }
                            return UIColor(Theme.mustard)
                        }(),
                        area: app.area,
                        opacity: app.opacity
                    )
                }
        )
    }
}

/// The preview canvas: clay base + glaze layers composed on a shape
/// silhouette (FR-006…FR-016).
///
/// It is always presented with the "Material reference preview" tag —
/// never as a predicted final result (section 16).
struct PreviewCanvas: View {
    var spec: PreviewSpec
    var size: CGFloat = 240
    /// The "Material reference preview" tag. Keep it visible on the main
    /// canvases; hide it on small thumbnails where it would overflow.
    var showTag: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.canvas)

            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                    .insetBy(dx: geo.size.width * 0.10, dy: geo.size.height * 0.10)

                ZStack {
                    clayLayer(in: rect)
                    ForEach(spec.apps) { app in
                        glazeLayer(in: rect, app: app)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .overlay(alignment: .topTrailing) {
            if showTag {
                ImageTagView(kind: .preview)
                    .padding(8)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func clayLayer(in rect: CGRect) -> some View {
        let silhouette = ShapeGeometry.silhouette(spec.category, in: rect)
        if let image = spec.clayImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: rect.width, height: rect.height)
                .mask(silhouette)
        } else {
            silhouette.fill(spec.clayColor)
        }
    }

    @ViewBuilder
    private func glazeLayer(in rect: CGRect, app: PreviewSpec.Application) -> some View {
        let region = ShapeGeometry.region(spec.category, app.area, in: rect)
        Group {
            if let image = app.glazeImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: rect.width, height: rect.height)
            } else {
                Rectangle().fill(app.glazeColor)
            }
        }
        .opacity(app.opacity)
        .mask(region)
    }
}
