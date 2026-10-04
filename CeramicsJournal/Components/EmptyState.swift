import SwiftUI

/// Friendly placeholder for empty lists (EPIC 10 — polish).
struct EmptyState: View {
    let emoji: String
    let title: String
    var message: String?

    var body: some View {
        VStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 44))
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
