import Foundation

@MainActor
final class AppState: ObservableObject {

    // MARK: - Auth
    @Published var user: AuthUser?
    var isSignedIn: Bool { user != nil }

    // MARK: - Browse
    @Published var trending:  [Show] = []
    @Published var popular:   [Show] = []
    @Published var topRated:  [Show] = []

    // MARK: - Search
    @Published var searchQuery      = ""
    @Published var searchResults:   [Show] = []
    @Published var isSearching      = false
    @Published var recentSearches:  [String] = UserDefaults.standard.stringArray(forKey: "showlog_recent_searches") ?? []

    // MARK: - User data
    @Published var watchlist:     [Show] = []
    @Published var watched:       Set<Int> = []
    @Published var watchedShows:  [Show] = []   // ordered most-recent first, includes show data
    @Published var diary:         [DiaryEntry] = []
    @Published var progress:      [Int: ShowProgress] = [:]  // showId → progress

    // MARK: - UI state
    @Published var selectedShow:  Show?
    @Published var showAuthSheet  = false
    @Published var errorMessage:  String?
    @Published var selectedTab    = 0

    var avatarUrl: String? { user?.userMetadata?.avatarUrl }
    @Published var isLoadingBrowse = false

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
        let watchedResult = try? await wd
        watched      = watchedResult?.ids ?? []
        watchedShows = watchedResult?.shows ?? []
        diary     = (try? await d)  ?? []
        let prList = (try? await pr) ?? []
        progress  = Dictionary(uniqueKeysWithValues: prList.map { ($0.showId, $0) })
    }

    func clearUserData() {
        watchlist = []
        watched = []
        watchedShows = []
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
        if let u = try await SupabaseService.shared.signUp(email: email, password: password) {
            user = u
            await loadUserData()
        }
        // nil means confirmation email sent — caller shows the confirmation message
    }

    func signOut() async {
        await SupabaseService.shared.signOut()
        clearUserData()
    }

    func deleteAccount() async throws {
        try await SupabaseService.shared.deleteAccount()
        clearUserData()
    }

    func updateUsername(_ name: String) async throws {
        try await SupabaseService.shared.updateUsername(name)
        user?.userMetadata?.username = name
    }

    func uploadAvatar(_ imageData: Data) async throws {
        guard let userId = user?.id else { return }
        let url = try await SupabaseService.shared.uploadAvatar(imageData: imageData, userId: userId)
        try await SupabaseService.shared.updateAvatarUrl(url)
        user = await SupabaseService.shared.currentUser
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
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            var updated = [trimmed] + recentSearches.filter { $0 != trimmed }
            if updated.count > 10 { updated = Array(updated.prefix(10)) }
            recentSearches = updated
            UserDefaults.standard.set(updated, forKey: "showlog_recent_searches")
        }
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "showlog_recent_searches")
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
        if watched.contains(show.id) {
            watched.remove(show.id)
            watchedShows.removeAll { $0.id == show.id }
            try? await SupabaseService.shared.removeWatched(showId: show.id)
        } else {
            watched.insert(show.id)
            watchedShows.insert(show, at: 0)
            try? await SupabaseService.shared.markWatched(show: show)
        }
    }

    func isWatched(_ showId: Int) -> Bool { watched.contains(showId) }

    // MARK: - Diary

    func addDiaryEntry(show: Show, watchedAt: String,
                       notes: String, rating: Int) async throws {
        guard isSignedIn else { showAuthSheet = true; return }
        let entry = try await SupabaseService.shared.addDiaryEntry(
            showId: show.id, show: show,
            watchedAt: watchedAt, notes: notes, rating: rating)
        diary.append(entry)
        diary.sort { $0.watchedAt > $1.watchedAt }
        watched.insert(show.id)
        try? await SupabaseService.shared.markWatched(show: show)
    }

    func updateDiaryEntry(_ entry: DiaryEntry) async throws {
        try await SupabaseService.shared.updateDiaryEntry(entry)
        if let i = diary.firstIndex(where: { $0.id == entry.id }) {
            diary[i] = entry
        }
        diary.sort { $0.watchedAt > $1.watchedAt }
    }

    func deleteDiaryEntry(id: String) async throws {
        try await SupabaseService.shared.deleteDiaryEntry(id: id)
        diary.removeAll { $0.id == id }
    }

    // MARK: - Episode progress

    func toggleEpisode(show: Show, season: Int, episode: Int,
                       totalEpisodes: Int) async {
        guard isSignedIn else { showAuthSheet = true; return }
        var p = progress[show.id] ?? ShowProgress(showId: show.id, watchedEpisodes: [:], totalEpisodes: totalEpisodes)
        let key = "\(season)-\(episode)"
        p.watchedEpisodes[key] = !(p.watchedEpisodes[key] ?? false)
        p.totalEpisodes = totalEpisodes
        progress[show.id] = p
        do {
            try await SupabaseService.shared.updateProgress(
                showId: show.id,
                watchedEpisodes: p.watchedEpisodes,
                totalEpisodes: totalEpisodes)
        } catch {
            print("[AppState] toggleEpisode save failed: \(error)")
        }
    }

    func markSeasonWatched(show: Show, season: ShowSeason,
                           totalEpisodes: Int) async {
        guard isSignedIn else { showAuthSheet = true; return }
        var p = progress[show.id] ?? ShowProgress(showId: show.id, watchedEpisodes: [:], totalEpisodes: totalEpisodes)
        var episodes = season.episodes
        if episodes.isEmpty && season.episodeCount > 0 {
            episodes = (try? await TMDBService.shared.season(showId: show.id, seasonNumber: season.seasonNumber)) ?? []
        }
        let episodeNumbers = !episodes.isEmpty
            ? episodes.map { $0.episodeNumber }
            : season.episodeCount > 0 ? Array(1...season.episodeCount) : []
        guard !episodeNumbers.isEmpty else { return }
        let allWatched = episodeNumbers.allSatisfy { p.isWatched(season: season.seasonNumber, episode: $0) }
        for ep in episodeNumbers {
            p.watchedEpisodes["\(season.seasonNumber)-\(ep)"] = !allWatched
        }
        p.totalEpisodes = totalEpisodes
        progress[show.id] = p
        do {
            try await SupabaseService.shared.updateProgress(
                showId: show.id,
                watchedEpisodes: p.watchedEpisodes,
                totalEpisodes: totalEpisodes)
        } catch {
            print("[AppState] markSeasonWatched save failed: \(error)")
        }
    }

    func markAllEpisodesWatched(show: Show, seasons: [ShowSeason], totalEpisodes: Int) async {
        guard isSignedIn else { showAuthSheet = true; return }
        var p = progress[show.id] ?? ShowProgress(showId: show.id, watchedEpisodes: [:], totalEpisodes: totalEpisodes)
        var allPairs: [(season: Int, episode: Int)] = []
        for season in seasons {
            var episodes = season.episodes
            if episodes.isEmpty && season.episodeCount > 0 {
                episodes = (try? await TMDBService.shared.season(showId: show.id, seasonNumber: season.seasonNumber)) ?? []
            }
            if !episodes.isEmpty {
                for ep in episodes { allPairs.append((season.seasonNumber, ep.episodeNumber)) }
            } else if season.episodeCount > 0 {
                for ep in 1...season.episodeCount { allPairs.append((season.seasonNumber, ep)) }
            }
        }
        guard !allPairs.isEmpty else { return }
        let allWatched = allPairs.allSatisfy { p.isWatched(season: $0.season, episode: $0.episode) }
        for pair in allPairs {
            p.watchedEpisodes["\(pair.season)-\(pair.episode)"] = !allWatched
        }
        p.totalEpisodes = totalEpisodes
        progress[show.id] = p
        do {
            try await SupabaseService.shared.updateProgress(
                showId: show.id,
                watchedEpisodes: p.watchedEpisodes,
                totalEpisodes: totalEpisodes)
        } catch {
            print("[AppState] markAllEpisodesWatched save failed: \(error)")
        }
    }
}
