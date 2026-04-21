import Foundation

struct DiaryEntry: Identifiable, Codable {
    let id: String          // UUID from Supabase
    let showId: Int
    var showData: Show
    var watchedAt: String   // ISO date string "YYYY-MM-DD"
    var notes: String
    var rating: Int         // 1–10 (displayed as 1–5 stars, half-star = 0.5)

    enum CodingKeys: String, CodingKey {
        case id
        case showId   = "show_id"
        case showData = "show_data"
        case watchedAt = "watched_at"
        case notes, rating
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(String.self, forKey: .id)
        showId    = try c.decode(Int.self, forKey: .showId)
        showData  = try c.decode(Show.self, forKey: .showData)
        watchedAt = try c.decode(String.self, forKey: .watchedAt)
        notes     = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        // Web app stores rating on a 0.5–5 scale (as Double).
        // iOS stores on a 1–10 scale (as Int). Multiply web values by 2.
        if let r = try? c.decode(Int.self, forKey: .rating) {
            rating = r  // already iOS 1–10 scale
        } else if let r = try? c.decode(Double.self, forKey: .rating) {
            rating = Int((r * 2).rounded())  // web 0.5–5 → iOS 1–10
        } else {
            rating = 0
        }
    }

    // MARK: Computed

    var watchedDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: watchedAt)
    }

    var formattedDate: String {
        guard let d = watchedDate else { return watchedAt }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }

    /// Rating as a 1–5 star value (10-point scale → 5-star display)
    var starRating: Double { Double(rating) / 2.0 }
}
