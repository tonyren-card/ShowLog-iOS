import Foundation

// MARK: - Show

struct Show: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let overview: String
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let posterPath: String?
    let backdropPath: String?

    // Populated from detail endpoint
    var genreNames: [String]
    var numberOfSeasons: Int?
    var statusText: String?
    var networkNames: [String]
    var cast: [CastMember]
    var seasons: [ShowSeason]

    // MARK: Computed

    var posterURL: URL? {
        posterPath.flatMap { URL(string: Config.tmdbImageBase + $0) }
    }

    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: Config.tmdbBackdropBase + $0) }
    }

    var year: String {
        guard let d = firstAirDate, d.count >= 4 else { return "" }
        return String(d.prefix(4))
    }

    // MARK: Coding

    enum CodingKeys: String, CodingKey {
        case id, name, overview, seasons
        case firstAirDate    = "first_air_date"
        case voteAverage     = "vote_average"
        case voteCount       = "vote_count"
        case posterPath      = "poster_path"
        case backdropPath    = "backdrop_path"
        case numberOfSeasons = "number_of_seasons"
        case statusText      = "status"
        case genres
        case genreNames      = "genre_names"
        case networks
        case genreIds        = "genre_ids"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(Int.self, forKey: .id)
        name          = try c.decode(String.self, forKey: .name)
        overview      = try c.decode(String.self, forKey: .overview)
        firstAirDate  = try c.decodeIfPresent(String.self, forKey: .firstAirDate)
        voteAverage   = try c.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        voteCount     = try c.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        posterPath    = try c.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath  = try c.decodeIfPresent(String.self, forKey: .backdropPath)
        numberOfSeasons = try c.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        statusText    = try c.decodeIfPresent(String.self, forKey: .statusText)
        seasons       = try c.decodeIfPresent([ShowSeason].self, forKey: .seasons) ?? []
        cast          = []

        // genres: TMDB detail objects, stored string arrays (web/iOS), or genre_id ints
        if let genres = try? c.decode([TMDBGenre].self, forKey: .genres) {
            genreNames = genres.map(\.name)
        } else if let names = try? c.decode([String].self, forKey: .genres) {
            genreNames = names
        } else if let names = try? c.decode([String].self, forKey: .genreNames) {
            genreNames = names
        } else if let ids = try? c.decode([Int].self, forKey: .genreIds) {
            genreNames = ids.compactMap { Show.genreMap[$0] }
        } else {
            genreNames = []
        }

        // networks: TMDB detail objects or stored string arrays
        if let nets = try? c.decode([TMDBNetwork].self, forKey: .networks) {
            networkNames = nets.map(\.name)
        } else if let names = try? c.decode([String].self, forKey: .networks) {
            networkNames = names
        } else {
            networkNames = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(overview, forKey: .overview)
        try c.encodeIfPresent(firstAirDate, forKey: .firstAirDate)
        try c.encode(voteAverage, forKey: .voteAverage)
        try c.encode(voteCount, forKey: .voteCount)
        try c.encodeIfPresent(posterPath, forKey: .posterPath)
        try c.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try c.encodeIfPresent(numberOfSeasons, forKey: .numberOfSeasons)
        try c.encodeIfPresent(statusText, forKey: .statusText)
        try c.encode(genreNames, forKey: .genres)
        try c.encode(networkNames, forKey: .networks)
        try c.encode(seasons, forKey: .seasons)
    }

    // MARK: Genre map (TMDB TV genre IDs)
    static let genreMap: [Int: String] = [
        10759: "Action & Adventure", 16: "Animation", 35: "Comedy",
        80: "Crime", 99: "Documentary", 18: "Drama",
        10751: "Family", 10762: "Kids", 9648: "Mystery",
        10763: "News", 10764: "Reality", 10765: "Sci-Fi & Fantasy",
        10766: "Soap", 10767: "Talk", 10768: "War & Politics", 37: "Western"
    ]
}

// MARK: - Supporting types

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBNetwork: Codable {
    let id: Int
    let name: String
}

struct CastMember: Codable, Hashable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }

    var profileURL: URL? {
        profilePath.flatMap { URL(string: Config.tmdbImageBase + $0) }
    }
}

struct ShowSeason: Codable, Hashable, Identifiable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let episodeCount: Int
    var episodes: [Episode]

    enum CodingKeys: String, CodingKey {
        case id, name, episodes
        case seasonNumber  = "season_number"
        case episodeCount  = "episode_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seasonNumber  = try c.decode(Int.self, forKey: .seasonNumber)
        id            = try c.decodeIfPresent(Int.self, forKey: .id) ?? seasonNumber
        name          = try c.decode(String.self, forKey: .name)
        episodeCount  = try c.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
        episodes      = try c.decodeIfPresent([Episode].self, forKey: .episodes) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(seasonNumber, forKey: .seasonNumber)
        try c.encode(name, forKey: .name)
        try c.encode(episodeCount, forKey: .episodeCount)
        try c.encode(episodes, forKey: .episodes)
    }
}

struct Episode: Codable, Hashable, Identifiable {
    let id: Int
    let episodeNumber: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case episodeNumber = "episode_number"
    }
}

// MARK: - TMDB list response wrappers

struct TMDBListResponse<T: Codable>: Codable {
    let results: [T]
}

struct TMDBCreditsResponse: Codable {
    let cast: [CastMember]
}

struct TMDBSeasonResponse: Codable {
    let episodes: [Episode]
}
