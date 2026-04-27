import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) var state
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if state.isLoadingBrowse {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
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

                        showRow(title: "Trending", shows: state.trending)
                        showRow(title: "Popular", shows: state.popular)
                        showRow(title: "Top Rated", shows: state.topRated)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.background)
            .navigationTitle("ShowLog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if state.isSignedIn {
                        Circle()
                            .fill(Color.showGreen.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(state.user?.userMetadata?.username?.prefix(1)
                                     ?? state.user?.email?.prefix(1) ?? "?").uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.showGreen)
                            )
                    } else {
                        Button("Sign In") { state.showAuthSheet = true }
                            .tint(Color.showGreen)
                    }
                }
            }
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(show: show)
                .environment(state)
        }
        .sheet(isPresented: Binding(get: { state.showAuthSheet },
                                    set: { state.showAuthSheet = $0 })) {
            AuthView().environment(state)
        }
        .task { await state.loadBrowse() }
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
