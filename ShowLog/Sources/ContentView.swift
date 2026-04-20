import SwiftUI

// MARK: - Theme

extension Color {
    static let showGreen   = Color(red: 0/255, green: 224/255, blue: 84/255)
    static let background  = Color(red: 13/255, green: 17/255, blue: 23/255)
    static let surface     = Color(red: 20/255, green: 24/255, blue: 28/255)
    static let border      = Color(red: 44/255, green: 52/255, blue: 64/255)
    static let textPrimary = Color(red: 204/255, green: 221/255, blue: 238/255)
    static let textMuted   = Color(red: 102/255, green: 119/255, blue: 136/255)
}

// MARK: - Models

struct TVShow: Identifiable {
    let id = UUID()
    let title: String
    let year: String
    let genre: String
    var status: WatchStatus
    var rating: Int?
    var currentSeason: Int?
    var currentEpisode: Int?
    let posterColor: Color
}

enum WatchStatus: String, CaseIterable {
    case watching   = "Watching"
    case completed  = "Completed"
    case queued     = "Queue"
    case dropped    = "Dropped"

    var icon: String {
        switch self {
        case .watching:  return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .queued:    return "clock.fill"
        case .dropped:   return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .watching:  return .showGreen
        case .completed: return .blue
        case .queued:    return .textMuted
        case .dropped:   return .red
        }
    }
}

// MARK: - Sample Data

extension TVShow {
    static let samples: [TVShow] = [
        TVShow(title: "Severance",       year: "2022", genre: "Thriller",  status: .watching,   rating: 5, currentSeason: 2, currentEpisode: 7, posterColor: Color(red: 0.1, green: 0.15, blue: 0.25)),
        TVShow(title: "The Bear",        year: "2022", genre: "Drama",     status: .watching,   rating: 5, currentSeason: 3, currentEpisode: 4, posterColor: Color(red: 0.25, green: 0.12, blue: 0.08)),
        TVShow(title: "Slow Horses",     year: "2022", genre: "Thriller",  status: .completed,  rating: 4, posterColor: Color(red: 0.08, green: 0.12, blue: 0.08)),
        TVShow(title: "White Lotus",     year: "2021", genre: "Drama",     status: .completed,  rating: 4, posterColor: Color(red: 0.2, green: 0.15, blue: 0.08)),
        TVShow(title: "Andor",           year: "2022", genre: "Sci-Fi",    status: .completed,  rating: 5, posterColor: Color(red: 0.05, green: 0.1, blue: 0.2)),
        TVShow(title: "The Penguin",     year: "2024", genre: "Crime",     status: .queued,     rating: nil, posterColor: Color(red: 0.08, green: 0.08, blue: 0.12)),
        TVShow(title: "Shogun",          year: "2024", genre: "Historical",status: .queued,     rating: nil, posterColor: Color(red: 0.15, green: 0.08, blue: 0.05)),
        TVShow(title: "Silo",            year: "2023", genre: "Sci-Fi",    status: .dropped,    rating: 2, posterColor: Color(red: 0.12, green: 0.1, blue: 0.05)),
    ]
}

// MARK: - Views

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home",     systemImage: "circle.grid.2x2.fill") }
                .tag(0)
            DiaryView()
                .tabItem { Label("Diary",    systemImage: "book.fill") }
                .tag(1)
            WatchlistView()
                .tabItem { Label("Watchlist", systemImage: "list.star") }
                .tag(2)
            ProfileView()
                .tabItem { Label("Profile",  systemImage: "person.fill") }
                .tag(3)
        }
        .tint(.showGreen)
        .background(Color.background)
    }
}

// MARK: - Home

struct HomeView: View {
    let shows = TVShow.samples

    var watching: [TVShow]  { shows.filter { $0.status == .watching } }
    var completed: [TVShow] { shows.filter { $0.status == .completed } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Currently Watching
                    if !watching.isEmpty {
                        SectionHeader(title: "Continue Watching")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(watching) { show in
                                    ContinueCard(show: show)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Recent Activity
                    SectionHeader(title: "Recently Completed")
                        .padding(.horizontal, 20)
                    ForEach(completed.prefix(3)) { show in
                        ActivityRow(show: show)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
            .background(Color.background)
            .navigationTitle("ShowLog")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.textMuted)
            .textCase(.uppercase)
            .tracking(1)
            .padding(.horizontal, 20)
    }
}

struct ContinueCard: View {
    let show: TVShow
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(show.posterColor)
                .frame(width: 120, height: 170)
                .overlay(alignment: .bottomLeading) {
                    if let s = show.currentSeason, let e = show.currentEpisode {
                        Text("S\(s) E\(e)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(6)
                            .background(.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(6)
                    }
                }

            Text(show.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
        }
    }
}

struct ActivityRow: View {
    let show: TVShow
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(show.posterColor)
                .frame(width: 44, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(show.year) · \(show.genre)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textMuted)
                if let rating = show.rating {
                    StarRating(rating: rating)
                }
            }
            Spacer()
            Image(systemName: show.status.icon)
                .foregroundStyle(show.status.color)
                .font(.system(size: 18))
        }
        .padding(12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 0.5))
    }
}

struct StarRating: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(i <= rating ? Color.showGreen : Color.border)
            }
        }
    }
}

// MARK: - Diary

struct DiaryView: View {
    let shows = TVShow.samples.filter { $0.status != .queued }

    var body: some View {
        NavigationStack {
            List {
                ForEach(shows) { show in
                    DiaryRow(show: show)
                        .listRowBackground(Color.surface)
                        .listRowSeparatorTint(Color.border)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("Diary")
        }
    }
}

struct DiaryRow: View {
    let show: TVShow
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(show.posterColor)
                .frame(width: 40, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if let rating = show.rating {
                    StarRating(rating: rating)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: show.status.icon)
                    .foregroundStyle(show.status.color)
                Text(show.status.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Watchlist

struct WatchlistView: View {
    let queued = TVShow.samples.filter { $0.status == .queued }

    var body: some View {
        NavigationStack {
            List {
                ForEach(queued) { show in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(show.posterColor)
                            .frame(width: 40, height: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(show.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text("\(show.year) · \(show.genre)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textMuted)
                        }
                        Spacer()
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.surface)
                    .listRowSeparatorTint(Color.border)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("Watchlist")
            .overlay {
                if queued.isEmpty {
                    ContentUnavailableView("Nothing queued", systemImage: "list.star", description: Text("Add shows you want to watch."))
                }
            }
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    let shows = TVShow.samples

    var totalShows:     Int { shows.filter { $0.status == .completed }.count }
    var totalWatching:  Int { shows.filter { $0.status == .watching  }.count }
    var avgRating:   Double {
        let rated = shows.compactMap(\.rating)
        return rated.isEmpty ? 0 : Double(rated.reduce(0, +)) / Double(rated.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    Circle()
                        .fill(Color.showGreen.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay(Text("T").font(.system(size: 32, weight: .bold)).foregroundStyle(Color.showGreen))

                    Text("tonyren")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    // Stats row
                    HStack(spacing: 0) {
                        StatCell(value: "\(totalShows)",    label: "Completed")
                        Divider().frame(height: 40).background(Color.border)
                        StatCell(value: "\(totalWatching)", label: "Watching")
                        Divider().frame(height: 40).background(Color.border)
                        StatCell(value: String(format: "%.1f", avgRating), label: "Avg Rating")
                    }
                    .padding()
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 0.5))
                    .padding(.horizontal, 20)
                }
                .padding(.top, 32)
            }
            .background(Color.background)
            .navigationTitle("Profile")
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.showGreen)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
