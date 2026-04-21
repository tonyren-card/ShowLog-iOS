import Foundation

// MARK: - Auth types

struct AuthUser: Codable {
    let id: String
    let email: String?
    var userMetadata: UserMeta?

    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
    }

    struct UserMeta: Codable {
        var username: String?
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

// MARK: - DB row types

private struct WatchlistRow: Codable {
    let showId: Int
    let showData: Show
    enum CodingKeys: String, CodingKey {
        case showId = "show_id"; case showData = "show_data"
    }
}

private struct WatchedRow: Codable {
    let showId: Int
    enum CodingKeys: String, CodingKey { case showId = "show_id" }
}

private struct ProgressRow: Codable {
    let showId: Int
    let watchedEpisodes: [String: Bool]
    let totalEpisodes: Int?
    enum CodingKeys: String, CodingKey {
        case showId = "show_id"
        case watchedEpisodes = "watched_episodes"
        case totalEpisodes = "total_episodes"
    }
}

// MARK: - Service

actor SupabaseService {
    static let shared = SupabaseService()

    private let base    = Config.supabaseURL
    private let anonKey = Config.supabaseAnonKey

    private(set) var accessToken: String?
    private(set) var currentUser: AuthUser?

    private let tokenKey        = "supabase_access_token"
    private let refreshTokenKey = "supabase_refresh_token"
    private let userKey         = "supabase_user"

    // MARK: Auth

    func restoreSession() async -> AuthUser? {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey),
              let data = UserDefaults.standard.data(forKey: userKey),
              let cachedUser = try? JSONDecoder().decode(AuthUser.self, from: data) else { return nil }
        // Use refresh token to get a fresh access token
        do {
            let body = ["refresh_token": refreshToken]
            let resp: AuthResponse = try await post(
                path: "/auth/v1/token?grant_type=refresh_token", body: body, auth: false)
            accessToken  = resp.accessToken
            currentUser  = resp.user
            persist(resp)
            return resp.user
        } catch {
            // Refresh failed — clear stale session
            clearPersisted()
            return nil
        }
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        let body = ["email": email, "password": password]
        let resp: AuthResponse = try await post(path: "/auth/v1/signup", body: body, auth: false)
        accessToken = resp.accessToken
        currentUser = resp.user
        persist(resp)
        return resp.user
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        let body = ["email": email, "password": password]
        let resp: AuthResponse = try await post(
            path: "/auth/v1/token?grant_type=password", body: body, auth: false)
        accessToken = resp.accessToken
        currentUser = resp.user
        persist(resp)
        return resp.user
    }

    func signOut() {
        accessToken = nil
        currentUser = nil
        clearPersisted()
    }

    private func persist(_ resp: AuthResponse) {
        UserDefaults.standard.set(resp.accessToken, forKey: tokenKey)
        UserDefaults.standard.set(resp.refreshToken, forKey: refreshTokenKey)
        if let data = try? JSONEncoder().encode(resp.user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private func clearPersisted() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    func updateUsername(_ username: String) async throws {
        let body = ["data": ["username": username]]
        let _: AuthUser = try await put(path: "/auth/v1/user", body: body)
        currentUser?.userMetadata?.username = username
    }

    // MARK: Watchlist

    func loadWatchlist() async throws -> [Show] {
        let rows: [WatchlistRow] = try await get(
            path: "/rest/v1/watchlist_entries", query: ["select": "*"])
        return rows.map(\.showData)
    }

    func addToWatchlist(show: Show) async throws {
        let body: [String: AnyEncodable] = [
            "show_id": AnyEncodable(show.id),
            "show_data": AnyEncodable(show)
        ]
        try await upsert(path: "/rest/v1/watchlist_entries", body: body,
                         onConflict: "user_id,show_id")
    }

    func removeFromWatchlist(showId: Int) async throws {
        try await delete(path: "/rest/v1/watchlist_entries",
                         query: ["show_id": "eq.\(showId)"])
    }

    // MARK: Watched

    func loadWatched() async throws -> Set<Int> {
        let rows: [WatchedRow] = try await get(
            path: "/rest/v1/watched_shows", query: ["select": "show_id"])
        return Set(rows.map(\.showId))
    }

    func markWatched(show: Show) async throws {
        let body: [String: AnyEncodable] = [
            "show_id": AnyEncodable(show.id),
            "show_data": AnyEncodable(show)
        ]
        try await upsert(path: "/rest/v1/watched_shows", body: body,
                         onConflict: "user_id,show_id")
    }

    // MARK: Diary

    func loadDiary() async throws -> [DiaryEntry] {
        try await get(path: "/rest/v1/diary_entries",
                      query: ["select": "*", "order": "watched_at.desc"])
    }

    func addDiaryEntry(showId: Int, show: Show, watchedAt: String,
                       notes: String, rating: Int) async throws -> DiaryEntry {
        let body: [String: AnyEncodable] = [
            "show_id":    AnyEncodable(showId),
            "show_data":  AnyEncodable(show),
            "watched_at": AnyEncodable(watchedAt),
            "notes":      AnyEncodable(notes),
            "rating":     AnyEncodable(rating)
        ]
        let entries: [DiaryEntry] = try await post(path: "/rest/v1/diary_entries",
                                                   body: body, returning: true)
        guard let entry = entries.first else { throw ServiceError.noData }
        return entry
    }

    func updateDiaryEntry(_ entry: DiaryEntry) async throws {
        let body: [String: AnyEncodable] = [
            "watched_at": AnyEncodable(entry.watchedAt),
            "notes":      AnyEncodable(entry.notes),
            "rating":     AnyEncodable(entry.rating)
        ]
        try await patch(path: "/rest/v1/diary_entries",
                        query: ["id": "eq.\(entry.id)"], body: body)
    }

    func deleteDiaryEntry(id: String) async throws {
        try await delete(path: "/rest/v1/diary_entries", query: ["id": "eq.\(id)"])
    }

    // MARK: Episode Progress

    func loadProgress() async throws -> [ShowProgress] {
        let rows: [ProgressRow] = try await get(
            path: "/rest/v1/show_progress", query: ["select": "*"])
        return rows.map {
            let watchedCount = $0.watchedEpisodes.values.filter { $0 }.count
            return ShowProgress(showId: $0.showId,
                                watchedEpisodes: $0.watchedEpisodes,
                                totalEpisodes: $0.totalEpisodes ?? watchedCount)
        }
    }

    func updateProgress(showId: Int, watchedEpisodes: [String: Bool],
                        totalEpisodes: Int) async throws {
        let body: [String: AnyEncodable] = [
            "show_id":          AnyEncodable(showId),
            "watched_episodes": AnyEncodable(watchedEpisodes),
            "total_episodes":   AnyEncodable(totalEpisodes)
        ]
        try await upsert(path: "/rest/v1/show_progress", body: body,
                         onConflict: "user_id,show_id")
    }

    // MARK: - HTTP helpers

    private func headers(auth: Bool = true) -> [String: String] {
        var h = ["apikey": anonKey, "Content-Type": "application/json"]
        if auth, let token = accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }

    private func get<T: Decodable>(path: String, query: [String: String] = [:]) async throws -> T {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        #if DEBUG
        print("[Supabase] GET \(path) → \(status)")
        if status >= 400 { print("[Supabase] Body: \(String(data: data, encoding: .utf8) ?? "nil")") }
        #endif
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[Supabase] Decode error on \(path): \(error)")
            print("[Supabase] Raw: \(String(data: data, encoding: .utf8) ?? "nil")")
            #endif
            throw error
        }
    }

    private func post<B: Encodable, T: Decodable>(path: String, body: B,
                                                   auth: Bool = true,
                                                   returning: Bool = false) async throws -> T {
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "POST"
        var h = headers(auth: auth)
        if returning { h["Prefer"] = "return=representation" }
        h.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // Overload for Void response (e.g. sign-out, delete with no return)
    private func post<B: Encodable>(path: String, body: B, auth: Bool = true) async throws {
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "POST"
        headers(auth: auth).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: req)
    }

    private func put<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "PUT"
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func patch<B: Encodable>(path: String, query: [String: String] = [:],
                                     body: B) async throws {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "PATCH"
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: req)
    }

    private func upsert<B: Encodable>(path: String, body: B, onConflict: String) async throws {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = [URLQueryItem(name: "on_conflict", value: onConflict)]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        var h = headers()
        h["Prefer"] = "resolution=merge-duplicates"
        h.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: req)
    }

    private func delete(path: String, query: [String: String] = [:]) async throws {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "DELETE"
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        _ = try await URLSession.shared.data(for: req)
    }
}

// MARK: - Errors

enum ServiceError: Error {
    case noData
    case unauthorized
}

// MARK: - Type-erased Encodable wrapper

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
