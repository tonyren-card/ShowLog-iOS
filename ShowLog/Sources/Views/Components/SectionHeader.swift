import SwiftUI

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.textMuted)
            .textCase(.uppercase)
            .tracking(1)
    }
}
