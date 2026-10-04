import SwiftUI

/// A small vector silhouette of a shape category, used in pickers and cards.
struct ShapeThumb: View {
    let category: ShapeCategory
    var fill: Color = Theme.olive.opacity(0.30)
    var stroke: Color = Theme.olive

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size).insetBy(dx: 5, dy: 5)
            let path = ShapeGeometry.silhouette(category, in: rect)
            path
                .fill(fill)
                .overlay(path.stroke(stroke, lineWidth: 2))
        }
    }
}
