import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) var state
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if state.isSearching {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !state.searchQuery.isEmpty && state.searchResults.isEmpty {
                    ContentUnavailableView.search(text: state.searchQuery)
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
            .background(Color.background)
            .navigationTitle("Search")
            .searchable(
                text: Binding(
                    get: { state.searchQuery },
                    set: { state.searchQuery = $0; state.search($0) }
                ),
                prompt: "TV shows…"
            )
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(show: show).environment(state)
        }
    }
}
