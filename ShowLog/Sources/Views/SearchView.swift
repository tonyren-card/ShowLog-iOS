import SwiftUI

struct SearchView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if state.isSearching {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !state.searchQuery.isEmpty && state.searchResults.isEmpty {
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
            ShowDetailView(show: show).environmentObject(state)
        }
    }
}
