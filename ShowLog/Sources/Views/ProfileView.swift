import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) var state
    @State private var editingUsername = false
    @State private var usernameInput   = ""
    @State private var selectedShow: Show?

    private var initial: String {
        let name = state.user?.userMetadata?.username ?? state.user?.email ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    private var displayName: String {
        state.user?.userMetadata?.username
            ?? state.user?.email
            ?? "Guest"
    }

    private var memberSince: String {
        // Supabase doesn't return created_at in basic user metadata; show email domain as fallback
        state.user?.email.flatMap { e in
            e.contains("@") ? String(e.split(separator: "@").last ?? "") : nil
        } ?? ""
    }

    var body: some View {
        NavigationStack {
            if !state.isSignedIn {
                ContentUnavailableView(
                    "Sign in to view your profile",
                    systemImage: "person.circle",
                    description: Text("See your stats and watch history.")
                )
                .overlay(alignment: .bottom) {
                    Button("Sign In") { state.showAuthSheet = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.showGreen)
                        .padding(.bottom, 40)
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        Circle()
                            .fill(Color.showGreen.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(initial)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Color.showGreen)
                            )

                        // Username
                        VStack(spacing: 4) {
                            if editingUsername {
                                HStack {
                                    TextField("Username", text: $usernameInput)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.system(size: 18, weight: .semibold))
                                        .multilineTextAlignment(.center)

                                    Button("Save") {
                                        Task {
                                            try? await state.updateUsername(usernameInput)
                                            editingUsername = false
                                        }
                                    }
                                    .tint(Color.showGreen)

                                    Button("Cancel") { editingUsername = false }
                                        .tint(Color.textMuted)
                                }
                                .padding(.horizontal, 40)
                            } else {
                                HStack(spacing: 6) {
                                    Text(displayName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color.textPrimary)

                                    Button {
                                        usernameInput = state.user?.userMetadata?.username ?? ""
                                        editingUsername = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.textMuted)
                                    }
                                }
                            }

                            if let email = state.user?.email,
                               email != displayName {
                                Text(email)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textMuted)
                            }
                        }

                        // Stats
                        HStack(spacing: 0) {
                            StatCell(value: "\(state.watched.count)", label: "Watched")
                            Divider().frame(height: 40).background(Color.border)
                            StatCell(value: "\(state.diary.count)", label: "Diary")
                            Divider().frame(height: 40).background(Color.border)
                            StatCell(value: "\(state.watchlist.count)", label: "Watchlist")
                        }
                        .padding()
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 0.5))
                        .padding(.horizontal, 20)

                        // Average rating
                        if !state.diary.isEmpty {
                            let avg = Double(state.diary.compactMap { $0.rating }.reduce(0, +))
                                / Double(state.diary.count)
                            HStack(spacing: 8) {
                                Text("Avg Rating")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textMuted)
                                StarRating(rating: Int(avg.rounded()))
                                Text(String(format: "%.1f", avg / 2))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textMuted)
                            }
                        }

                        // Recently watched
                        if !state.watchedShows.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Recently Watched")
                                    .padding(.horizontal, 20)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(state.watchedShows.prefix(6)) { show in
                                            ShowCard(show: show,
                                                     progress: state.progress[show.id])
                                                .onTapGesture { selectedShow = show }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Sign out
                        Button("Sign Out", role: .destructive) {
                            Task { await state.signOut() }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
                .background(Color.background)
                .navigationTitle("Profile")
            }
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
