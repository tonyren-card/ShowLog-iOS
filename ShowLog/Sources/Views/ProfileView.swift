import SwiftUI

// Assuming AppState is an ObservableObject for use with @EnvironmentObject
struct ProfileView: View {
    @EnvironmentObject var state: AppState
    @State private var editingUsername = false
    @State private var usernameInput   = ""
    @State private var selectedShow: Show?
    @State private var showDeleteConfirm = false
    @State private var deleteConfirmText = ""
    @State private var deleting          = false
    @State private var deleteError: String?

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
                VStack(spacing: 16) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color.border)
                    Text("Sign in to view your profile")
                        .font(.title2).fontWeight(.semibold)
                    Text("See your stats and watch history.")
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

                        // Delete account
                        if !showDeleteConfirm {
                            Button("Delete Account") {
                                showDeleteConfirm = true
                                deleteConfirmText = ""
                                deleteError = nil
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 0.63, green: 0.31, blue: 0.31))
                        }

                        if showDeleteConfirm {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Delete your account?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.99, green: 0.64, blue: 0.64))

                                Text("This will permanently delete your account and all data — watchlist, diary, and episode progress. This cannot be undone.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textMuted)

                                Text("Type DELETE to confirm:")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.textMuted)

                                TextField("DELETE", text: $deleteConfirmText)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.99, green: 0.64, blue: 0.64))
                                    .padding(10)
                                    .background(Color.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.35, green: 0.13, blue: 0.13), lineWidth: 1))

                                if let err = deleteError {
                                    Text(err)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.red)
                                }

                                HStack(spacing: 10) {
                                    Button {
                                        guard deleteConfirmText == "DELETE" else {
                                            deleteError = "Type DELETE to confirm."
                                            return
                                        }
                                        deleting = true
                                        deleteError = nil
                                        Task {
                                            do {
                                                try await state.deleteAccount()
                                            } catch {
                                                deleteError = error.localizedDescription
                                                deleting = false
                                            }
                                        }
                                    } label: {
                                        Text(deleting ? "Deleting…" : "Yes, delete my account")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Color(red: 0.99, green: 0.64, blue: 0.64))
                                    }
                                    .disabled(deleting)

                                    Button("Cancel") {
                                        showDeleteConfirm = false
                                        deleteConfirmText = ""
                                        deleteError = nil
                                    }
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textMuted)
                                }
                            }
                            .padding(16)
                            .background(Color(red: 0.1, green: 0.04, blue: 0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.35, green: 0.13, blue: 0.13), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
                .background(Color.background)
                .navigationTitle("Profile")
            }
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
