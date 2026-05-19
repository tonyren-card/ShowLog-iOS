import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if !state.isSignedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "list.star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.border)
                        Text("Sign in to see your watchlist")
                            .font(.title2).fontWeight(.semibold)
                        Text("Track shows you want to watch.")
                            .font(.subheadline)
                            .foregroundColor(Color.textMuted)
                        Button("Sign In") { state.showAuthSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.showGreen)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if state.watchlist.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.border)
                        Text("Nothing in your list")
                            .font(.title2).fontWeight(.semibold)
                        Text("Add shows you want to watch.")
                            .font(.subheadline)
                            .foregroundColor(Color.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            ShowDetailView(show: show).environmentObject(state)
        }
        .sheet(isPresented: Binding(get: { state.showAuthSheet },
                                    set: { state.showAuthSheet = $0 })) {
            AuthView().environmentObject(state)
        }
    }
}
