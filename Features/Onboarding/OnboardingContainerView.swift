import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @Namespace private var dotNS
    @Environment(\.themeColors) var theme

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)
                    OnboardingPage2()
                        .tag(1)
                    OnboardingPage3 {
                        withAnimation(.springBounce) {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.springBounce, value: currentPage)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        if index == currentPage {
                            Capsule()
                                .fill(theme.surface)
                                .frame(width: 24, height: 8)
                                .shadow(color: theme.surface.opacity(0.5), radius: 4)
                                .matchedGeometryEffect(id: "dot", in: dotNS)
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    withAnimation(.quickSnap) {
                                        currentPage = index
                                    }
                                }
                        }
                    }
                }
                .padding(.bottom, 32)

                if currentPage < 2 {
                    HStack {
                        Button("Skip") {
                            withAnimation(.springBounce) {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                        .buttonStyle(GhostButtonStyle())

                        Spacer()

                        Button("Next") {
                            withAnimation(.quickSnap) {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(GhostButtonStyle(color: .primary))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
