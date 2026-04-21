import SwiftUI

struct ContentView: View {
    @State private var state = AppState()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home",      systemImage: "circle.grid.2x2.fill") }
            SearchView()
                .tabItem { Label("Search",    systemImage: "magnifyingglass") }
            WatchlistView()
                .tabItem { Label("Watchlist", systemImage: "list.star") }
            DiaryView()
                .tabItem { Label("Diary",     systemImage: "book.fill") }
            ProfileView()
                .tabItem { Label("Profile",   systemImage: "person.fill") }
        }
        .tint(Color.showGreen)
        .environment(state)
        .task { await state.restoreSession() }
    }
}
