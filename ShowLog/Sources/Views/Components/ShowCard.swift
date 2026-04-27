import SwiftUI

struct ShowCard: View {
    let show: Show
    var progress: ShowProgress?
    var width: CGFloat = 120
    var height: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // Poster
                if let url = show.posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            posterPlaceholder
                        }
                    }
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    posterPlaceholder
                }

                // Progress bar
                if let p = progress, p.totalEpisodes > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        if let label = p.latestEpisodeLabel {
                            Text(label)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Color.white.opacity(0.2)
                                Color.showGreen
                                    .frame(width: geo.size.width * p.progressFraction)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                        .frame(height: 3)
                    }
                    .padding(6)
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(show.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .frame(width: width, alignment: .leading)

            if !show.year.isEmpty {
                Text(show.year)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textMuted)
            }
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.surface)
            .frame(width: width, height: height)
            .overlay(
                Image(systemName: "tv")
                    .foregroundStyle(Color.border)
                    .font(.system(size: 24))
            )
    }
}
