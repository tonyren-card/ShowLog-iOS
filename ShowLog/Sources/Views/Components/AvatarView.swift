import SwiftUI

/// Renders another user's avatar from a `Profile` (falls back to an initial-letter badge).
struct AvatarView: View {
    let profile: Profile?
    var size: CGFloat = 32

    private var initial: String {
        (profile?.displayName.first).map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        if let urlStr = profile?.avatarUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    letterBadge
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            letterBadge
        }
    }

    private var letterBadge: some View {
        Circle()
            .fill(Color.showGreen.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(Color.showGreen)
            )
    }
}
