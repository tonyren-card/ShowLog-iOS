import SwiftUI

struct FeedView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if !state.isSignedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.border)
                        Text("Follow people to see their activity")
                            .font(.title2).fontWeight(.semibold)
                        Text("Sign in to find people and build your feed.")
                            .font(.subheadline)
                            .foregroundColor(Color.textMuted)
                        Button("Sign In") { state.showAuthSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.showGreen)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            findPeopleSection
                            if !state.following.isEmpty {
                                followingChips
                            }
                            feedSection
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color.background)
            .navigationTitle("Feed")
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(show: show).environmentObject(state)
        }
        .sheet(isPresented: Binding(get: { state.showAuthSheet },
                                    set: { state.showAuthSheet = $0 })) {
            AuthView().environmentObject(state)
        }
    }

    // MARK: - Find people

    private var findPeopleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Find people…", text: Binding(
                get: { state.peopleQuery },
                set: { state.peopleQuery = $0; state.searchPeople($0) }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 20)

            if !state.peopleQuery.isEmpty {
                if state.isSearchingPeople {
                    ProgressView().padding(.horizontal, 20)
                } else if state.peopleResults.isEmpty {
                    Text("No public profiles found.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textMuted)
                        .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(state.peopleResults) { profile in
                            PersonRow(profile: profile)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Following chips

    private var followingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(state.following).sorted(), id: \.self) { id in
                    let profile = state.followingProfiles[id]
                    HStack(spacing: 6) {
                        AvatarView(profile: profile, size: 20)
                        Text(profile?.displayName ?? "Private account")
                            .font(.system(size: 12))
                            .foregroundStyle(profile != nil ? Color.textPrimary : Color.textMuted)
                        Button {
                            Task { await state.unfollowUser(id) }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.border, lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Feed list

    @ViewBuilder private var feedSection: some View {
        if state.feed.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "heart")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.border)
                Text(state.following.isEmpty ? "Follow people to see their activity" : "No activity yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(state.feed) { entry in
                    FeedRow(entry: entry, profile: entry.userId.flatMap { state.followingProfiles[$0] })
                        .contentShape(Rectangle())
                        .onTapGesture { selectedShow = entry.showData }
                        .padding(.horizontal, 20)
                    Divider().background(Color.border).padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Person row (search result)

private struct PersonRow: View {
    @EnvironmentObject var state: AppState
    let profile: Profile

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(profile: profile, size: 28)
            Text(profile.displayName)
                .font(.system(size: 14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if state.following.contains(profile.id) {
                Button("Following") { Task { await state.unfollowUser(profile.id) } }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.showGreen)
            } else {
                Button("Follow") { Task { await state.followUser(profile) } }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(10)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Feed row

struct FeedRow: View {
    let entry: DiaryEntry
    let profile: Profile?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(profile: profile, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(profile?.displayName ?? "Someone") logged \(entry.showData.name)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    StarRatingSmall(rating: entry.rating)
                    Text(entry.formattedDate)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.textMuted)
                }

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            AsyncImage(url: entry.showData.posterURL) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    Color.surface
                }
            }
            .frame(width: 36, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 8)
    }
}
