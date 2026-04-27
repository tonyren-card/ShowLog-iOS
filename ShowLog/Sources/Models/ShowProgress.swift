import Foundation

struct ShowProgress: Codable {
    let showId: Int
    /// Keys are "season-episode", e.g. "1-3". Value is always true.
    var watchedEpisodes: [String: Bool]
    var totalEpisodes: Int

    enum CodingKeys: String, CodingKey {
        case showId           = "show_id"
        case watchedEpisodes  = "watched_episodes"
        case totalEpisodes    = "total_episodes"
    }

    var watchedCount: Int { watchedEpisodes.values.filter { $0 }.count }

    var progressFraction: Double {
        guard totalEpisodes > 0 else { return 0 }
        return Double(watchedCount) / Double(totalEpisodes)
    }

    /// Returns the highest season+episode watched, e.g. "S2 E5"
    var latestEpisodeLabel: String? {
        let watched = watchedEpisodes.filter(\.value).keys
        guard !watched.isEmpty else { return nil }
        let parsed = watched.compactMap { key -> (Int, Int)? in
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 2 else { return nil }
            return (parts[0], parts[1])
        }
        guard let latest = parsed.max(by: { a, b in a.0 == b.0 ? a.1 < b.1 : a.0 < b.0 }) else { return nil }
        return "S\(latest.0) E\(latest.1)"
    }

    func isWatched(season: Int, episode: Int) -> Bool {
        watchedEpisodes["\(season)-\(episode)"] == true
    }
}
