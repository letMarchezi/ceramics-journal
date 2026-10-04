import SwiftUI
import CoreGraphics

/// Hand-drawn silhouettes and region masks for the preview system.
///
/// All geometry is defined in normalized coordinates (0…1) and scaled into
/// the given rect, so it works at any canvas size.
enum ShapeGeometry {

    // MARK: - Coordinate helpers

    private static func point(_ x: Double, _ y: Double, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }

    private static func box(_ x: Double, _ y: Double, _ w: Double, _ h: Double, in rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX + x * rect.width,
            y: rect.minY + y * rect.height,
            width: w * rect.width,
            height: h * rect.height
        )
    }

    private static func cornerSize(_ s: Double, in rect: CGRect) -> CGSize {
        CGSize(width: s * rect.width, height: s * rect.height)
    }

    // MARK: - Silhouettes

    /// The full silhouette of a shape category.
    static func silhouette(_ category: ShapeCategory, in rect: CGRect) -> Path {
        var p = Path()

        switch category {
        case .mug:
            p.addRoundedRect(in: box(0.16, 0.24, 0.52, 0.62, in: rect),
                             cornerSize: cornerSize(0.07, in: rect))
            p.addPath(handle(in: rect))

        case .cup:
            let topLeft = point(0.30, 0.22, in: rect)
            let topRight = point(0.70, 0.22, in: rect)
            p.move(to: topLeft)
            p.addLine(to: topRight)
            p.addQuadCurve(to: point(0.60, 0.84, in: rect), control: point(0.72, 0.62, in: rect))
            p.addQuadCurve(to: point(0.40, 0.84, in: rect), control: point(0.50, 0.90, in: rect))
            p.addQuadCurve(to: topLeft, control: point(0.28, 0.62, in: rect))
            p.closeSubpath()

        case .bowl:
            let rimLeft = point(0.14, 0.42, in: rect)
            let rimRight = point(0.86, 0.42, in: rect)
            p.move(to: rimLeft)
            p.addCurve(to: point(0.5, 0.88, in: rect),
                       control1: point(0.14, 0.78, in: rect),
                       control2: point(0.32, 0.88, in: rect))
            p.addCurve(to: rimRight,
                       control1: point(0.68, 0.88, in: rect),
                       control2: point(0.86, 0.78, in: rect))
            p.closeSubpath()
            // Foot
            p.addRoundedRect(in: box(0.43, 0.88, 0.14, 0.04, in: rect),
                             cornerSize: cornerSize(0.015, in: rect))

        case .plate:
            p.move(to: point(0.08, 0.44, in: rect))
            p.addCurve(to: point(0.5, 0.44, in: rect),
                       control1: point(0.10, 0.68, in: rect),
                       control2: point(0.30, 0.70, in: rect))
            p.addCurve(to: point(0.92, 0.44, in: rect),
                       control1: point(0.70, 0.70, in: rect),
                       control2: point(0.90, 0.68, in: rect))
            p.closeSubpath()

        case .vase:
            let neckLeft = point(0.38, 0.12, in: rect)
            let neckRight = point(0.62, 0.12, in: rect)
            p.move(to: neckLeft)
            p.addLine(to: neckRight)
            p.addCurve(to: point(0.75, 0.50, in: rect),
                       control1: point(0.64, 0.22, in: rect),
                       control2: point(0.78, 0.34, in: rect))
            p.addCurve(to: point(0.57, 0.88, in: rect),
                       control1: point(0.75, 0.68, in: rect),
                       control2: point(0.68, 0.80, in: rect))
            p.addLine(to: point(0.43, 0.88, in: rect))
            p.addCurve(to: point(0.25, 0.50, in: rect),
                       control1: point(0.32, 0.80, in: rect),
                       control2: point(0.25, 0.68, in: rect))
            p.addCurve(to: neckLeft,
                       control1: point(0.22, 0.34, in: rect),
                       control2: point(0.36, 0.22, in: rect))
            p.closeSubpath()

        case .jar:
            p.addRoundedRect(in: box(0.30, 0.30, 0.40, 0.54, in: rect),
                             cornerSize: cornerSize(0.07, in: rect))
            p.addRoundedRect(in: box(0.27, 0.22, 0.46, 0.12, in: rect),
                             cornerSize: cornerSize(0.035, in: rect))

        case .planter:
            let topLeft = point(0.24, 0.34, in: rect)
            let topRight = point(0.76, 0.34, in: rect)
            p.move(to: topLeft)
            p.addLine(to: topRight)
            p.addQuadCurve(to: point(0.66, 0.86, in: rect), control: point(0.74, 0.72, in: rect))
            p.addLine(to: point(0.34, 0.86, in: rect))
            p.addQuadCurve(to: topLeft, control: point(0.26, 0.72, in: rect))
            p.closeSubpath()
            // Rim band
            p.addRoundedRect(in: box(0.21, 0.26, 0.58, 0.10, in: rect),
                             cornerSize: cornerSize(0.03, in: rect))

        case .other:
            p.addEllipse(in: box(0.30, 0.20, 0.40, 0.64, in: rect))
        }

        return p
    }

    /// The mug's C-shaped handle, as a filled ring segment.
    private static func handle(in rect: CGRect) -> Path {
        var h = Path()
        let center = point(0.78, 0.54, in: rect)
        let outerR = 0.135 * rect.width
        let innerR = 0.065 * rect.width
        let start = Angle.degrees(-70)
        let end = Angle.degrees(70)

        h.move(to: CGPoint(
            x: center.x + outerR * cos(start.radians),
            y: center.y + outerR * sin(start.radians)
        ))
        h.addArc(center: center, radius: outerR, startAngle: start, endAngle: end, clockwise: false)
        h.addLine(to: CGPoint(
            x: center.x + innerR * cos(end.radians),
            y: center.y + innerR * sin(end.radians)
        ))
        h.addArc(center: center, radius: innerR, startAngle: end, endAngle: start, clockwise: true)
        h.closeSubpath()
        return h
    }

    // MARK: - Regions

    /// The opening (mouth) ellipse of a shape — used for interior/exterior
    /// glaze regions.
    static func opening(_ category: ShapeCategory, in rect: CGRect) -> Path {
        switch category {
        case .mug:
            return Path(ellipseIn: box(0.17, 0.205, 0.50, 0.075, in: rect))
        case .cup:
            return Path(ellipseIn: box(0.315, 0.195, 0.37, 0.07, in: rect))
        case .bowl:
            return Path(ellipseIn: box(0.15, 0.385, 0.70, 0.09, in: rect))
        case .plate:
            return Path(ellipseIn: box(0.09, 0.405, 0.82, 0.09, in: rect))
        case .vase:
            return Path(ellipseIn: box(0.395, 0.095, 0.21, 0.06, in: rect))
        case .jar:
            return Path(ellipseIn: box(0.28, 0.195, 0.44, 0.07, in: rect))
        case .planter:
            return Path(ellipseIn: box(0.22, 0.275, 0.56, 0.07, in: rect))
        case .other:
            return Path(ellipseIn: box(0.36, 0.175, 0.28, 0.06, in: rect))
        }
    }

    /// The region a glaze application covers for a given area.
    static func region(_ category: ShapeCategory, _ area: ApplicationArea, in rect: CGRect) -> Path {
        let silhouette = silhouette(category, in: rect)

        switch area {
        case .entirePiece:
            return silhouette

        case .interior:
            return opening(category, in: rect)

        case .exterior:
            // Silhouette minus the opening, via an even-odd union.
            let diff = silhouette.cgPath.union(opening(category, in: rect).cgPath, using: .evenOdd)
            return Path(diff)

        case .base:
            let band = Path(baseBand(category, in: rect))
            let intersection = silhouette.cgPath.intersection(band.cgPath, using: .winding)
            return Path(intersection)

        case .custom:
            // A small organic patch near the middle; the user describes it
            // in words (e.g. "Dragon").
            let patch = Path(ellipseIn: box(0.36, 0.36, 0.28, 0.24, in: rect))
            let intersection = patch.cgPath.intersection(silhouette.cgPath, using: .winding)
            return Path(intersection)
        }
    }

    /// The bottom band used for the "base" region, tuned per category.
    private static func baseBand(_ category: ShapeCategory, in rect: CGRect) -> CGRect {
        switch category {
        case .mug, .cup, .jar:
            return box(0, 0.72, 1, 0.28, in: rect)
        case .bowl:
            return box(0, 0.78, 1, 0.22, in: rect)
        case .plate:
            return box(0, 0.60, 1, 0.40, in: rect)
        case .vase:
            return box(0, 0.76, 1, 0.24, in: rect)
        case .planter, .other:
            return box(0, 0.70, 1, 0.30, in: rect)
        }
    }
}
