import SwiftUI

struct WatchlistView: View {
    @Environment(AppState.self) var state
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if !state.isSignedIn {
                    ContentUnavailableView(
                        "Sign in to see your watchlist",
                        systemImage: "list.star",
                        description: Text("Track shows you want to watch.")
                    )
                    .overlay(alignment: .bottom) {
                        Button("Sign In") { state.showAuthSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.showGreen)
                            .padding(.bottom, 40)
                    }
                } else if state.watchlist.isEmpty {
                    ContentUnavailableView(
                        "Nothing in your list",
                        systemImage: "list.star",
                        description: Text("Add shows you want to watch.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                            spacing: 16
                        ) {
                            ForEach(state.watchlist) { show in
                                ShowCard(show: show,
                                         progress: state.progress[show.id],
                                         width: 140, height: 200)
                                    .onTapGesture { selectedShow = show }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color.background)
            .navigationTitle("Watchlist")
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(show: show).environment(state)
        }
        .sheet(isPresented: Binding(get: { state.showAuthSheet },
                                    set: { state.showAuthSheet = $0 })) {
            AuthView().environment(state)
        }
    }
}
