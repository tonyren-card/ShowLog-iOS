import SwiftUI

/// One-time announcement shown to existing users after updating to the version
/// that introduced the Social Feed (FEA-11). See `AppState.checkSocialFeedOnboarding()`.
struct SocialFeedOnboardingView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.showGreen)

            VStack(spacing: 10) {
                Text("Introducing the Social Feed")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Follow other users, share what you're watching, and discover new shows through friends.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            VStack(alignment: .leading, spacing: 20) {
                OnboardingRow(icon: "magnifyingglass", title: "Find People",
                              text: "Search by username or email to find friends on ShowLog.")
                OnboardingRow(icon: "heart", title: "Feed",
                              text: "See what people you follow are watching and rating.")
                OnboardingRow(icon: "text.bubble", title: "Reviews",
                              text: "Every show has a Reviews tab with public ratings and notes from the community.")
                OnboardingRow(icon: "lock", title: "Your privacy, your choice",
                              text: "Switch your profile to Private anytime from the Profile tab to hide your diary from everyone.")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    state.selectedTab = 1
                    dismiss()
                } label: {
                    Text("Explore the Feed")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.showGreen)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Maybe later") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 20)
        .background(Color.background)
    }
}

private struct OnboardingRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.showGreen)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textMuted)
            }
        }
    }
}
