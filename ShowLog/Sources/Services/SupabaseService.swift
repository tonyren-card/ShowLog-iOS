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
        var avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case username
            case avatarUrl = "avatar_url"
        }
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

private struct WatchedShowRow: Codable {
    let showId: Int
    let showData: Show
    enum CodingKeys: String, CodingKey {
        case showId = "show_id"; case showData = "show_data"
    }
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

    // Returns the signed-in user if email confirmation is disabled, or nil if confirmation email was sent.
    func signUp(email: String, password: String) async throws -> AuthUser? {
        let body = ["email": email, "password": password]
        var req = URLRequest(url: URL(string: base + "/auth/v1/signup")!)
        req.httpMethod = "POST"
        headers(auth: false).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status >= 400 {
            let msg = (try? JSONDecoder().decode(SupabaseError.self, from: data))?.effectiveMessage ?? "Sign up failed (\(status))"
            throw SupabaseAuthError(message: msg)
        }
        // When email confirmation is required, Supabase returns a bare user object with no access_token.
        // When confirmation is disabled (or auto-confirmed), it returns a full AuthResponse with tokens.
        if let resp = try? JSONDecoder().decode(AuthResponse.self, from: data),
           !resp.accessToken.isEmpty {
            accessToken = resp.accessToken
            currentUser = resp.user
            persist(resp)
            return resp.user
        }
        return nil
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

    func deleteAccount() async throws {
        guard let token = accessToken else { throw ServiceError.unauthorized }
        var req = URLRequest(url: URL(string: Config.netlifyBaseURL + "/api/delete-account")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw DeleteAccountError.failed(msg ?? "Unknown error")
        }
        clearPersisted()
        accessToken = nil
        currentUser = nil
    }

    func updateUsername(_ username: String) async throws {
        let body = ["data": ["username": username]]
        let _: AuthUser = try await put(path: "/auth/v1/user", body: body)
        currentUser?.userMetadata?.username = username
    }

    func uploadAvatar(imageData: Data, userId: String) async throws -> String {
        guard let token = accessToken else { throw ServiceError.unauthorized }
        let urlStr = "\(base)/storage/v1/object/avatars/\(userId).jpg"
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")
        req.httpBody = imageData
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        #if DEBUG
        print("[Supabase] UPLOAD avatar → \(status)")
        if status >= 400 { print("[Supabase] Body: \(String(data: data, encoding: .utf8) ?? "nil")") }
        #endif
        guard status < 400 else { throw URLError(.badServerResponse) }
        let ts = Int(Date().timeIntervalSince1970)
        return "\(base)/storage/v1/object/public/avatars/\(userId).jpg?t=\(ts)"
    }

    func updateAvatarUrl(_ url: String) async throws {
        let body = ["data": ["avatar_url": url]]
        let updated: AuthUser = try await put(path: "/auth/v1/user", body: body)
        currentUser = updated
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

    func loadWatched() async throws -> (ids: Set<Int>, shows: [Show]) {
        let rows: [WatchedShowRow] = try await get(
            path: "/rest/v1/watched_shows",
            query: ["select": "show_id,show_data", "order": "marked_at.desc"])
        return (Set(rows.map(\.showId)), rows.map(\.showData))
    }

    func markWatched(show: Show) async throws {
        let body: [String: AnyEncodable] = [
            "show_id": AnyEncodable(show.id),
            "show_data": AnyEncodable(show)
        ]
        try await upsert(path: "/rest/v1/watched_shows", body: body,
                         onConflict: "user_id,show_id")
    }

    func removeWatched(showId: Int) async throws {
        try await delete(path: "/rest/v1/watched_shows",
                         query: ["show_id": "eq.\(showId)"])
    }

    // MARK: Diary

    func loadDiary() async throws -> [DiaryEntry] {
        guard let uid = currentUser?.id else { return [] }
        // Must filter explicitly: the FEA-11 "public profiles" SELECT policy is permissive
        // and ORs together with the owner-only policy, so an unfiltered query would also
        // return every public profile's diary rows, not just the signed-in user's own.
        return try await get(path: "/rest/v1/diary_entries",
                            query: ["user_id": "eq.\(uid)", "select": "*", "order": "watched_at.desc"])
    }

    func addDiaryEntry(showId: Int, show: Show, watchedAt: String,
                       notes: String, rating: Int) async throws -> DiaryEntry {
        let body: [String: AnyEncodable] = [
            "show_id":    AnyEncodable(showId),
            "show_data":  AnyEncodable(show),
            "watched_at": AnyEncodable(watchedAt),
            "notes":      AnyEncodable(notes),
            "rating":     AnyEncodable(Double(rating) / 2.0)  // store on 0.5–5 scale (web format)
        ]
        let entries: [DiaryEntry] = try await post(path: "/rest/v1/diary_entries",
                                                   body: body, returning: true)
        guard let entry = entries.first else { throw ServiceError.noData }
        return entry
    }

    func updateDiaryEntry(_ entry: DiaryEntry) async throws {
        guard let uid = currentUser?.id else { return }
        let body: [String: AnyEncodable] = [
            "watched_at": AnyEncodable(entry.watchedAt),
            "notes":      AnyEncodable(entry.notes),
            "rating":     AnyEncodable(Double(entry.rating) / 2.0)  // store on 0.5–5 scale (web format)
        ]
        try await patch(path: "/rest/v1/diary_entries",
                        query: ["id": "eq.\(entry.id)", "user_id": "eq.\(uid)"], body: body)
    }

    func deleteDiaryEntry(id: String) async throws {
        guard let uid = currentUser?.id else { return }
        try await delete(path: "/rest/v1/diary_entries",
                         query: ["id": "eq.\(id)", "user_id": "eq.\(uid)"])
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

    // MARK: Social (profiles + follows)

    private struct FollowingRow: Codable {
        let followingId: String
        enum CodingKeys: String, CodingKey { case followingId = "following_id" }
    }

    func loadFollowingIds() async throws -> [String] {
        guard let uid = currentUser?.id else { return [] }
        let rows: [FollowingRow] = try await get(
            path: "/rest/v1/follows",
            query: ["follower_id": "eq.\(uid)", "select": "following_id"])
        return rows.map(\.followingId)
    }

    func loadProfile(id: String) async throws -> Profile? {
        let rows: [Profile] = try await get(
            path: "/rest/v1/profiles",
            query: ["id": "eq.\(id)", "select": "id,username,avatar_url,is_public"])
        return rows.first
    }

    func loadProfiles(ids: [String]) async throws -> [Profile] {
        guard !ids.isEmpty else { return [] }
        // Via a SECURITY DEFINER function so usernameless-but-public profiles can fall
        // back to an email_prefix for display — the same visibility rule as the table's
        // own RLS (is_public or self) is replicated inside the function itself.
        let body: [String: AnyEncodable] = ["ids": AnyEncodable(ids)]
        return try await post(path: "/rest/v1/rpc/get_profiles", body: body)
    }

    func loadFeed(followingIds: [String]) async throws -> [DiaryEntry] {
        guard !followingIds.isEmpty else { return [] }
        return try await get(
            path: "/rest/v1/diary_entries",
            query: ["user_id": "in.(\(followingIds.joined(separator: ",")))",
                    "select": "*", "order": "watched_at.desc", "limit": "100"])
    }

    func loadCommunityReviews(showId: Int) async throws -> [DiaryEntry] {
        try await get(
            path: "/rest/v1/diary_entries",
            query: ["show_id": "eq.\(showId)", "select": "*",
                    "order": "watched_at.desc", "limit": "50"])
    }

    func searchProfiles(query: String, excluding: String) async throws -> [Profile] {
        // Matches username OR email server-side via a SECURITY DEFINER function — the
        // email value itself is never part of the function's return signature, so it
        // never crosses back to the client regardless of what's requested here.
        struct SearchResult: Codable {
            let id: String
            let username: String?
            let avatarUrl: String?
            let emailPrefix: String?
            enum CodingKeys: String, CodingKey {
                case id, username
                case avatarUrl = "avatar_url"
                case emailPrefix = "email_prefix"
            }
        }
        let body: [String: AnyEncodable] = [
            "search_query": AnyEncodable(query),
            "excluding_id": AnyEncodable(excluding)
        ]
        let results: [SearchResult] = try await post(path: "/rest/v1/rpc/search_profiles", body: body)
        return results.map { Profile(id: $0.id, username: $0.username, avatarUrl: $0.avatarUrl, isPublic: true, emailPrefix: $0.emailPrefix) }
    }

    func follow(id: String) async throws {
        guard let uid = currentUser?.id else { return }
        let body: [String: AnyEncodable] = [
            "follower_id": AnyEncodable(uid),
            "following_id": AnyEncodable(id)
        ]
        try await post(path: "/rest/v1/follows", body: body)
    }

    func unfollow(id: String) async throws {
        guard let uid = currentUser?.id else { return }
        try await delete(path: "/rest/v1/follows",
                         query: ["follower_id": "eq.\(uid)", "following_id": "eq.\(id)"])
    }

    func updateIsPublic(_ value: Bool) async throws {
        guard let uid = currentUser?.id else { return }
        let body: [String: AnyEncodable] = ["is_public": AnyEncodable(value)]
        try await patch(path: "/rest/v1/profiles", query: ["id": "eq.\(uid)"], body: body)
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
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        #if DEBUG
        print("[Supabase] POST \(path) → \(status)")
        if status >= 400 { print("[Supabase] Body: \(String(data: data, encoding: .utf8) ?? "nil")") }
        #endif
        if status >= 400 {
            let msg = (try? JSONDecoder().decode(SupabaseError.self, from: data))?.effectiveMessage ?? "Request failed (\(status))"
            throw SupabaseAuthError(message: msg)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[Supabase] Decode error on POST \(path): \(error)")
            print("[Supabase] Raw: \(String(data: data, encoding: .utf8) ?? "nil")")
            #endif
            throw error
        }
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
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        #if DEBUG
        print("[Supabase] UPSERT \(path) → \(status)")
        if status >= 400 { print("[Supabase] Body: \(String(data: data, encoding: .utf8) ?? "nil")") }
        #endif
        guard status < 400 else {
            throw URLError(.badServerResponse)
        }
    }

    private func delete(path: String, query: [String: String] = [:]) async throws {
        var comps = URLComponents(string: base + path)!
        comps.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "DELETE"
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        #if DEBUG
        print("[Supabase] DELETE \(path) → \(status)")
        if status >= 400 { print("[Supabase] Body: \(String(data: data, encoding: .utf8) ?? "nil")") }
        #endif
    }
}

// MARK: - Errors

enum ServiceError: Error {
    case noData
    case unauthorized
}

struct SupabaseAuthError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private struct SupabaseError: Decodable {
    let message: String?
    let msg: String?
    var effectiveMessage: String? { message ?? msg }
}

enum DeleteAccountError: LocalizedError {
    case failed(String)
    var errorDescription: String? {
        if case .failed(let msg) = self { return msg }
        return nil
    }
}

// MARK: - Type-erased Encodable wrapper

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
