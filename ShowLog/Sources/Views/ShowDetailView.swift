import SwiftUI

struct ShowDetailView: View {
    @Environment(AppState.self) var state
    let show: Show

    @State private var loadedShow: Show?
    @State private var selectedTab = 0
    @State private var showLogForm = false
    @State private var expandedSeasons: Set<Int> = []
    @State private var loadingSeasons: Set<Int> = []

    private var detail: Show { loadedShow ?? show }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Backdrop
                backdropHeader

                VStack(alignment: .leading, spacing: 16) {
                    // Title + meta
                    VStack(alignment: .leading, spacing: 6) {
                        Text(detail.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        HStack(spacing: 8) {
                            if !detail.year.isEmpty {
                                Text(detail.year).metaTag()
                            }
                            if let seasons = detail.numberOfSeasons {
                                Text("\(seasons) season\(seasons == 1 ? "" : "s")").metaTag()
                            }
                            if let p = state.progress[detail.id] {
                                Text("\(p.watchedCount)/\(p.totalEpisodes) ep").metaTag()
                                    .foregroundStyle(Color.showGreen)
                            }
                        }

                        if !detail.genreNames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(detail.genreNames, id: \.self) { g in
                                        Text(g)
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color.surface)
                                            .foregroundStyle(Color.textMuted)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.border, lineWidth: 0.5))
                                    }
                                }
                            }
                        }
                    }

                    // Action buttons
                    HStack(spacing: 10) {
                        ActionButton(
                            title: state.isWatched(detail.id) ? "Watched" : "Mark Watched",
                            icon: "checkmark.circle",
                            filled: state.isWatched(detail.id)
                        ) {
                            Task { await state.markWatched(show: detail) }
                        }

                        ActionButton(
                            title: state.isInWatchlist(detail.id) ? "In List" : "Add to List",
                            icon: "list.star",
                            filled: state.isInWatchlist(detail.id)
                        ) {
                            Task { await state.toggleWatchlist(show: detail) }
                        }

                        ActionButton(title: "Log", icon: "book") {
                            showLogForm = true
                        }
                    }

                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        Text("About").tag(0)
                        Text("Cast").tag(1)
                        Text("Seasons").tag(2)
                    }
                    .pickerStyle(.segmented)

                    // Tab content
                    switch selectedTab {
                    case 0: aboutTab
                    case 1: castTab
                    case 2: seasonsTab
                    default: EmptyView()
                    }
                }
                .padding(20)
            }
        }
        .background(Color.background)
        .sheet(isPresented: $showLogForm) {
            LogFormView(show: detail)
        }
        .task {
            if let loaded = try? await TMDBService.shared.detail(id: show.id) {
                loadedShow = loaded
            }
        }
    }

    // MARK: - Backdrop

    private var backdropHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = detail.backdropURL ?? detail.posterURL {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Color.surface
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
            } else {
                Color.surface.frame(height: 220)
            }

            LinearGradient(
                colors: [.clear, Color.background],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - About tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !detail.overview.isEmpty {
                Text(detail.overview)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                if detail.voteAverage > 0 {
                    MetaRow(label: "TMDB Rating",
                            value: String(format: "%.1f / 10  (%d votes)",
                                          detail.voteAverage, detail.voteCount))
                }
                if !detail.networkNames.isEmpty {
                    MetaRow(label: "Network", value: detail.networkNames.joined(separator: ", "))
                }
                if let s = detail.statusText {
                    MetaRow(label: "Status", value: s)
                }
            }
        }
    }

    // MARK: - Cast tab

    private var castTab: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(detail.cast, id: \.id) { member in
                HStack(spacing: 12) {
                    AsyncImage(url: member.profileURL) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Color.surface
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text(member.character)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }
        }
    }

    // MARK: - Seasons tab

    private var seasonsTab: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(detail.seasons.filter { $0.seasonNumber > 0 }) { season in
                SeasonRow(
                    show: detail,
                    season: season,
                    isExpanded: expandedSeasons.contains(season.id),
                    isLoading: loadingSeasons.contains(season.id)
                ) {
                    toggleSeason(season)
                }
            }
        }
    }

    private func toggleSeason(_ season: ShowSeason) {
        if expandedSeasons.contains(season.id) {
            expandedSeasons.remove(season.id)
        } else {
            expandedSeasons.insert(season.id)
            // Lazy-load episodes if not yet fetched
            if season.episodes.isEmpty {
                loadingSeasons.insert(season.id)
                Task {
                    if let episodes = try? await TMDBService.shared.season(
                        showId: detail.id, seasonNumber: season.seasonNumber) {
                        if var s = loadedShow?.seasons.first(where: { $0.id == season.id }) {
                            s.episodes = episodes
                            if let i = loadedShow?.seasons.firstIndex(where: { $0.id == season.id }) {
                                loadedShow?.seasons[i].episodes = episodes
                            }
                        }
                    }
                    loadingSeasons.remove(season.id)
                }
            }
        }
    }
}

// MARK: - Season row

struct SeasonRow: View {
    @Environment(AppState.self) var state
    let show: Show
    let season: ShowSeason
    let isExpanded: Bool
    let isLoading: Bool
    let onToggle: () -> Void

    private var p: ShowProgress? { state.progress[show.id] }

    private var seasonWatchedCount: Int {
        guard let p else { return 0 }
        return p.watchedEpisodes.filter { key, watched in
            watched && key.hasPrefix("\(season.seasonNumber)-")
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Season header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textMuted)
                        .frame(width: 16)

                    Text(season.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Text(seasonWatchedCount == season.episodeCount && season.episodeCount > 0
                         ? "✓ Done"
                         : "\(seasonWatchedCount)/\(season.episodeCount)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(seasonWatchedCount == season.episodeCount && season.episodeCount > 0
                                         ? Color.showGreen : Color.textMuted)

                    // Season checkbox
                    Button {
                        Task {
                            let total = show.seasons.reduce(0) { $0 + $1.episodeCount }
                            await state.markSeasonWatched(show: show, season: season, totalEpisodes: total)
                        }
                    } label: {
                        Image(systemName: seasonWatchedCount == season.episodeCount && season.episodeCount > 0
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(Color.showGreen)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isLoading {
                ProgressView().padding(.vertical, 8)
            } else if isExpanded {
                Divider().background(Color.border)
                ForEach(season.episodes) { ep in
                    HStack {
                        Button {
                            Task {
                                let total = show.seasons.reduce(0) { $0 + $1.episodeCount }
                                await state.toggleEpisode(
                                    show: show,
                                    season: season.seasonNumber,
                                    episode: ep.episodeNumber,
                                    totalEpisodes: total)
                            }
                        } label: {
                            Image(systemName: p?.isWatched(season: season.seasonNumber, episode: ep.episodeNumber) == true
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(Color.showGreen)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)

                        Text("E\(ep.episodeNumber)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textMuted)
                            .frame(width: 32, alignment: .leading)

                        Text(ep.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(.vertical, 7)
                    Divider().background(Color.border)
                }
            }
        }
        .padding(.horizontal, 4)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 0.5))
    }
}

// MARK: - Log form

struct LogFormView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    let show: Show

    @State private var date    = Date()
    @State private var rating  = 0
    @State private var notes   = ""
    @State private var loading = false
    @State private var error   = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Watched") {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color.showGreen)
                }

                Section("Rating") {
                    StarRatingPicker(rating: $rating)
                        .padding(.vertical, 4)
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if !error.isEmpty {
                    Section {
                        Text(error).foregroundStyle(.red).font(.system(size: 13))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("Log \(show.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(rating == 0 || loading)
                        .tint(Color.showGreen)
                }
            }
        }
    }

    private func save() async {
        loading = true; defer { loading = false }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        do {
            try await state.addDiaryEntry(
                show: show,
                watchedAt: f.string(from: date),
                notes: notes,
                rating: rating)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Helpers

private struct ActionButton: View {
    let title: String
    let icon: String
    var filled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(filled ? Color.showGreen : Color.surface)
                .foregroundStyle(filled ? .black : Color.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(filled ? Color.clear : Color.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

private struct MetaRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textMuted)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

private extension Text {
    func metaTag() -> some View {
        self.font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.textMuted)
    }
}
