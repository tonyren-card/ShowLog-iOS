import SwiftUI

/// Display-only star rating. `rating` is 1–10; displayed as 1–5 stars (half-star increments).
struct StarRating: View {
    let rating: Int         // 1–10
    var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 2) {
            ForEach([1, 2, 3, 4, 5], id: \.self) { star in
                let threshold = star * 2
                let filled = rating >= threshold
                let half   = !filled && rating >= threshold - 1
                Image(systemName: filled ? "star.fill" : half ? "star.leadinghalf.filled" : "star")
                    .font(.system(size: size))
                    .foregroundStyle((rating >= threshold - 1) ? Color.showGreen : Color.border)
            }
        }
    }
}

/// Interactive star picker. Binding is 1–10 (half-star = tap left vs. right half isn't feasible
/// in SwiftUI without custom gestures, so we map 5 tappable stars to values 2,4,6,8,10).
struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach([1, 2, 3, 4, 5], id: \.self) { star in
                Image(systemName: rating >= star * 2 ? "star.fill" : "star")
                    .font(.system(size: 24))
                    .foregroundStyle(rating >= star * 2 ? Color.showGreen : Color.border)
                    .onTapGesture { rating = star * 2 }
            }
        }
    }
}

/// Compact inline version (used in list rows).
struct StarRatingSmall: View {
    let rating: Int
    var body: some View {
        StarRating(rating: rating, size: 10)
    }
}
