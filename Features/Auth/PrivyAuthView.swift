import SwiftUI

// MARK: - PrivyAuthView (Phone OTP Flow)
// Placeholder — full implementation in Task 2

struct PrivyAuthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme

    var body: some View {
        ZStack {
            WaterBackgroundView()
            Text("PrivyAuthView — loading...")
                .foregroundColor(.white)
        }
    }
}

#Preview {
    PrivyAuthView()
        .environmentObject(AppState())
}
