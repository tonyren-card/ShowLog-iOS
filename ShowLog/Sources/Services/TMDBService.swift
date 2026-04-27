import Foundation

actor TMDBService {
    static let shared = TMDBService()

    private let base = Config.tmdbBaseURL
    private let key  = Config.tmdbAPIKey

    // MARK: - Browse

    func trending() async throws -> [Show] {
        try await fetch("/trending/tv/week")
    }

    func popular() async throws -> [Show] {
        try await fetch("/tv/popular")
    }

    func topRated() async throws -> [Show] {
        try await fetch("/tv/top_rated")
    }

    // MARK: - Search

    func search(query: String) async throws -> [Show] {
        var comps = URLComponents(string: base + "/search/tv")!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "query",   value: query),
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(TMDBListResponse<Show>.self, from: data).results
    }

    // MARK: - Detail

    func detail(id: Int) async throws -> Show {
        var show = try await fetchOne("/tv/\(id)")
        let credits: TMDBCreditsResponse = try await fetchRaw("/tv/\(id)/credits")
        show.cast = Array(credits.cast.prefix(12))
        return show
    }

    func season(showId: Int, seasonNumber: Int) async throws -> [Episode] {
        let response: TMDBSeasonResponse = try await fetchRaw("/tv/\(showId)/season/\(seasonNumber)")
        return response.episodes
    }

    // MARK: - Helpers

    private func fetch(_ path: String) async throws -> [Show] {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = [URLQueryItem(name: "api_key", value: key)]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(TMDBListResponse<Show>.self, from: data).results
    }

    private func fetchOne(_ path: String) async throws -> Show {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = [URLQueryItem(name: "api_key", value: key)]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(Show.self, from: data)
    }

    private func fetchRaw<T: Decodable>(_ path: String) async throws -> T {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = [URLQueryItem(name: "api_key", value: key)]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
