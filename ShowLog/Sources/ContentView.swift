import SwiftUI

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        TabView(selection: $state.selectedTab) {
            HomeView()
                .environmentObject(state)
                .tabItem { Label("Home",      systemImage: "circle.grid.2x2.fill") }
                .tag(0)
            SearchView()
                .environmentObject(state)
                .tabItem { Label("Search",    systemImage: "magnifyingglass") }
                .tag(1)
            WatchlistView()
                .environmentObject(state)
                .tabItem { Label("Watchlist", systemImage: "list.star") }
                .tag(2)
            DiaryView()
                .environmentObject(state)
                .tabItem { Label("Diary",     systemImage: "book.fill") }
                .tag(3)
            ProfileView()
                .environmentObject(state)
                .tabItem { Label("Profile",   systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color.showGreen)
        .task { await state.restoreSession() }
    }
}
