import SwiftUI

/// A rounded thumbnail for a material (or any photo) with a cute fallback.
struct MaterialThumb: View {
    var image: UIImage?
    var accent: Color
    var icon: String = "swatch"
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(accent.opacity(0.18))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}

/// A material row card: thumbnail, name, subtitle and confidence badge.
struct MaterialCard: View {
    let title: String
    let subtitle: String
    var image: UIImage?
    var accent: Color
    var confidence: MaterialConfidence?
    var icon: String

    var body: some View {
        HStack(spacing: 12) {
            MaterialThumb(image: image, accent: accent, icon: icon, size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }

            Spacer()

            if let confidence {
                ConfidenceBadge(confidence: confidence)
            }
        }
        .padding(12)
        .cuteCard()
    }
}
