import SwiftUI

/// The app's visual identity: a warm, cute studio palette built around
/// mustard, olive green and burgundy on a soft cream background.
enum Theme {
    // MARK: - Palette

    static let mustard = Color(red: 0.85, green: 0.65, blue: 0.20)
    static let mustardDark = Color(red: 0.64, green: 0.48, blue: 0.13)
    static let olive = Color(red: 0.44, green: 0.49, blue: 0.27)
    static let oliveDark = Color(red: 0.30, green: 0.34, blue: 0.19)
    static let burgundy = Color(red: 0.53, green: 0.21, blue: 0.21)
    static let burgundyDark = Color(red: 0.40, green: 0.14, blue: 0.15)

    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let card = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let ink = Color(red: 0.23, green: 0.19, blue: 0.15)
    static let inkSoft = Color(red: 0.47, green: 0.43, blue: 0.38)

    /// Fallback clay tone used when a material has no photo yet.
    static let clayFallback = Color(red: 0.80, green: 0.68, blue: 0.52)

    /// The soft background behind the preview canvas.
    static let canvas = Color(red: 0.96, green: 0.93, blue: 0.86)

    // MARK: - Semantic colors

    static func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .idea: return mustard
        case .planned: return olive
        case .inProgress: return mustardDark
        case .bisqueFired: return burgundy
        case .glazeFired: return oliveDark
        case .completed: return burgundyDark
        case .archived: return inkSoft
        }
    }

    static func firingResultColor(_ result: FiringResult) -> Color {
        switch result {
        case .success: return olive
        case .partial: return mustardDark
        case .failed: return burgundy
        case .unknown: return inkSoft
        }
    }
}

// MARK: - Reusable styles

/// A soft, rounded card background used across the app.
struct CuteCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Theme.ink.opacity(0.07), radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    func cuteCard() -> some View {
        modifier(CuteCardModifier())
    }
}

/// Primary action — a plump burgundy capsule.
struct CutePrimaryButton: ButtonStyle {
    var font: Font = .headline
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 14 : 20)
            .padding(.vertical, compact ? 8 : 12)
            .background(
                Capsule().fill(configuration.isPressed ? Theme.burgundyDark : Theme.burgundy)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Secondary action — an olive outline-ish capsule.
struct CuteSecondaryButton: ButtonStyle {
    var font: Font = .subheadline.weight(.semibold)
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(configuration.isPressed ? .white : Theme.oliveDark)
            .padding(.horizontal, compact ? 12 : 16)
            .padding(.vertical, compact ? 7 : 10)
            .background(
                Capsule().fill(configuration.isPressed ? Theme.olive : Theme.olive.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Small value helpers

extension Double {
    /// Formats a temperature value in degrees Celsius, e.g. 1240 -> "1240°C".
    var celsius: String {
        "\(Int((self * 10).rounded() / 10))°C"
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var prettyDay: String {
        formatted(.dateTime.month(.abbreviated).day())
    }
}
