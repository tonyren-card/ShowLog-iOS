import Foundation
import Observation

@Observable
final class AppState {

    // MARK: - Auth
    var user: AuthUser?
    var isSignedIn: Bool { user != nil }

    // MARK: - Browse
    var trending:  [Show] = []
    var popular:   [Show] = []
    var topRated:  [Show] = []

    // MARK: - Search
    var searchQuery   = ""
    var searchResults: [Show] = []
    var isSearching   = false

    // MARK: - User data
    var watchlist:  [Show] = []
    var watched:    Set<Int> = []
    var diary:      [DiaryEntry] = []
    var progress:   [Int: ShowProgress] = [:]  // showId → progress

    // MARK: - UI state
    var selectedShow:  Show?
    var showAuthSheet  = false
    var errorMessage:  String?
    var isLoadingBrowse = false

    private var searchTask: Task<Void, Never>?

    // MARK: - Init / Load

    func restoreSession() async {
        if let u = await SupabaseService.shared.restoreSession() {
            user = u
            await loadUserData()
        }
    }

    func loadBrowse() async {
        isLoadingBrowse = true
        defer { isLoadingBrowse = false }
        async let t = TMDBService.shared.trending()
        async let p = TMDBService.shared.popular()
        async let r = TMDBService.shared.topRated()
        trending = (try? await t) ?? []
        popular  = (try? await p) ?? []
        topRated = (try? await r) ?? []
    }

    func loadUserData() async {
        guard isSignedIn else { return }
        async let wl  = SupabaseService.shared.loadWatchlist()
        async let wd  = SupabaseService.shared.loadWatched()
        async let d   = SupabaseService.shared.loadDiary()
        async let pr  = SupabaseService.shared.loadProgress()
        watchlist = (try? await wl) ?? []
        watched   = (try? await wd) ?? []
        diary     = (try? await d)  ?? []
        let prList = (try? await pr) ?? []
        progress  = Dictionary(uniqueKeysWithValues: prList.map { ($0.showId, $0) })
    }

    func clearUserData() {
        watchlist = []
        watched = []
        diary = []
        progress = [:]
        user = nil
    }

    // MARK: - Auth actions

    func signIn(email: String, password: String) async throws {
        let u = try await SupabaseService.shared.signIn(email: email, password: password)
        user = u
        await loadUserData()
    }

    func signUp(email: String, password: String) async throws {
        let u = try await SupabaseService.shared.signUp(email: email, password: password)
        user = u
    }

    func signOut() async {
        await SupabaseService.shared.signOut()
        clearUserData()
    }

    func updateUsername(_ name: String) async throws {
        try await SupabaseService.shared.updateUsername(name)
        user?.userMetadata?.username = name
    }

    // MARK: - Search

    func search(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else { searchResults = []; return }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            isSearching = true
            searchResults = (try? await TMDBService.shared.search(query: query)) ?? []
            isSearching = false
        }
    }

    // MARK: - Show detail

    func loadDetail(for show: Show) async {
        if let detail = try? await TMDBService.shared.detail(id: show.id) {
            selectedShow = detail
        }
    }

    // MARK: - Watchlist

    func toggleWatchlist(show: Show) async {
        guard isSignedIn else { showAuthSheet = true; return }
        if watchlist.contains(where: { $0.id == show.id }) {
            watchlist.removeAll { $0.id == show.id }
            try? await SupabaseService.shared.removeFromWatchlist(showId: show.id)
        } else {
            watchlist.append(show)
            try? await SupabaseService.shared.addToWatchlist(show: show)
        }
    }

    func isInWatchlist(_ showId: Int) -> Bool {
        watchlist.contains { $0.id == showId }
    }

    // MARK: - Watched

    func markWatched(show: Show) async {
        guard isSignedIn else { showAuthSheet = true; return }
        watched.insert(show.id)
        try? await SupabaseService.shared.markWatched(show: show)
    }

    func isWatched(_ showId: Int) -> Bool { watched.contains(showId) }

    // MARK: - Diary

    func addDiaryEntry(show: Show, watchedAt: String,
                       notes: String, rating: Int) async throws {
        guard isSignedIn else { showAuthSheet = true; return }
        let entry = try await SupabaseService.shared.addDiaryEntry(
            showId: show.id, show: show,
            watchedAt: watchedAt, notes: notes, rating: rating)
        diary.insert(entry, at: 0)
        watched.insert(show.id)
        try? await SupabaseService.shared.markWatched(show: show)
    }

    func updateDiaryEntry(_ entry: DiaryEntry) async throws {
        try await SupabaseService.shared.updateDiaryEntry(entry)
        if let i = diary.firstIndex(where: { $0.id == entry.id }) {
            diary[i] = entry
        }
    }

    func deleteDiaryEntry(id: String) async throws {
        try await SupabaseService.shared.deleteDiaryEntry(id: id)
        diary.removeAll { $0.id == id }
    }

    // MARK: - Episode progress

    func toggleEpisode(show: Show, season: Int, episode: Int,
                       totalEpisodes: Int) async {
        guard isSignedIn else { showAuthSheet = true; return }
        var p = progress[show.id] ?? ShowProgress(
            showId: show.id, watchedEpisodes: [:], totalEpisodes: totalEpisodes)
        let key = "\(season)-\(episode)"
        p.watchedEpisodes[key] = !(p.watchedEpisodes[key] ?? false)
        p.totalEpisodes = totalEpisodes
        progress[show.id] = p
        try? await SupabaseService.shared.updateProgress(
            showId: show.id,
            watchedEpisodes: p.watchedEpisodes,
            totalEpisodes: totalEpisodes)
    }

    func markSeasonWatched(show: Show, season: ShowSeason,
                           totalEpisodes: Int) async {
        guard isSignedIn else { showAuthSheet = true; return }
        var p = progress[show.id] ?? ShowProgress(
            showId: show.id, watchedEpisodes: [:], totalEpisodes: totalEpisodes)
        let allWatched = season.episodes.allSatisfy {
            p.isWatched(season: season.seasonNumber, episode: $0.episodeNumber)
        }
        for ep in season.episodes {
            p.watchedEpisodes["\(season.seasonNumber)-\(ep.episodeNumber)"] = !allWatched
        }
        p.totalEpisodes = totalEpisodes
        progress[show.id] = p
        try? await SupabaseService.shared.updateProgress(
            showId: show.id,
            watchedEpisodes: p.watchedEpisodes,
            totalEpisodes: totalEpisodes)
    }
}
