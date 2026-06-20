import SwiftUI

struct HomeView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if !state.searchQuery.isEmpty {
                    searchContent
                } else {
                    browseContent
                }
            }
            .background(Color.background)
            .navigationTitle("ShowLog")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Binding(
                    get: { state.searchQuery },
                    set: { state.searchQuery = $0; state.search($0) }
                ),
                prompt: "TV shows…"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if state.isSignedIn {
                        Button { state.selectedTab = 4 } label: {
                            if let urlStr = state.avatarUrl, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image.resizable().scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    } else {
                                        toolbarBadge
                                    }
                                }
                            } else {
                                toolbarBadge
                            }
                        }
                    } else {
                        Button("Sign In") { state.showAuthSheet = true }
                            .tint(Color.showGreen)
                    }
                }
            }
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(show: show)
                .environmentObject(state)
        }
        .sheet(isPresented: Binding(get: { state.showAuthSheet },
                                    set: { state.showAuthSheet = $0 })) {
            AuthView().environmentObject(state)
        }
        .task { await state.loadBrowse() }
    }

    // MARK: - Browse (default Home content)

    private var browseContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if state.isLoadingBrowse {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    // Recent searches
                    if !state.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Searches")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.textMuted)
                                    .textCase(.uppercase)
                                    .tracking(1.5)
                                Spacer()
                                Button("Clear") { state.clearRecentSearches() }
                                    .font(.caption)
                                    .foregroundColor(Color.textMuted)
                            }
                            .padding(.horizontal, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(state.recentSearches, id: \.self) { query in
                                        Button(query) {
                                            state.searchQuery = query
                                            state.search(query)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(Color.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color.surface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.border, lineWidth: 1))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Continue Watching (from watchlist with progress)
                    let inProgress = state.watchlist.filter {
                        state.progress[$0.id] != nil
                    }
                    if !inProgress.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Continue Watching")
                                .padding(.horizontal, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(inProgress) { show in
                                        ShowCard(show: show, progress: state.progress[show.id])
                                            .onTapGesture { selectedShow = show }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Recently Watched
                    if !state.watchedShows.isEmpty {
                        showRow(title: "Recently Watched",
                                shows: Array(state.watchedShows.prefix(6)))
                    }

                    // Popular with Friends
                    if !state.popularWithFriends.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Popular with Friends")
                                .padding(.horizontal, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(state.popularWithFriends) { entry in
                                        VStack(spacing: 6) {
                                            ShowCard(show: entry.show)
                                                .onTapGesture { selectedShow = entry.show }
                                            Text("\(entry.watcherCount) friend\(entry.watcherCount == 1 ? "" : "s") watched")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundStyle(Color.textMuted)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    showRow(title: "Trending", shows: state.trending)
                    showRow(title: "Popular", shows: state.popular)
                    showRow(title: "Top Rated", shows: state.topRated)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Search (embedded via .searchable)

    @ViewBuilder private var searchContent: some View {
        if state.isSearching {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if state.searchResults.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color.border)
                Text("No results for “\(state.searchQuery)”")
                    .font(.title2).fontWeight(.semibold)
                Text("Try searching for a different show.")
                    .font(.subheadline)
                    .foregroundColor(Color.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                    spacing: 16
                ) {
                    ForEach(state.searchResults) { show in
                        ShowCard(show: show, progress: state.progress[show.id])
                            .onTapGesture { selectedShow = show }
                    }
                }
                .padding(20)
            }
        }
    }

    private var toolbarBadge: some View {
        Circle()
            .fill(Color.showGreen.opacity(0.2))
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(state.user?.userMetadata?.username?.prefix(1)
                     ?? state.user?.email?.prefix(1) ?? "?").uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.showGreen)
            )
    }

    private func showRow(title: String, shows: [Show]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title).padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shows.prefix(10)) { show in
                        ShowCard(show: show, progress: state.progress[show.id])
                            .onTapGesture { selectedShow = show }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
