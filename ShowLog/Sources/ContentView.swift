import SwiftUI

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        TabView(selection: $state.selectedTab) {
            HomeView()
                .environmentObject(state)
                .tabItem { Label("Home",      systemImage: "circle.grid.2x2.fill") }
                .tag(0)
            FeedView()
                .environmentObject(state)
                .tabItem { Label("Feed",      systemImage: "heart") }
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
        .task {
            await state.restoreSession()
            state.checkSocialFeedOnboarding()
        }
        .sheet(isPresented: $state.showSocialFeedOnboarding) {
            SocialFeedOnboardingView().environmentObject(state)
        }
    }
}
