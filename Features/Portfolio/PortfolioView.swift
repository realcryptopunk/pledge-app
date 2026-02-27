import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedRange = 1
    @State private var chartProgress: CGFloat = 0
    @Environment(\.themeColors) var theme

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    RollingCounterView(
                                        value: appState.investmentPoolValue,
                                        decimalPlaces: 2,
                                        mainSize: 42,
                                        decimalSize: 24,
                                        trailingSize: 20
                                    )
                                    .embossed(.raised)

                                    Text("↑$14.38 (+\(appState.investmentGrowth, specifier: "%.1f")%)")
                                        .pledgeCaption()
                                        .foregroundColor(.pledgeGreen)

                                    Text("past month")
                                        .pledgeCaption()
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                ZStack {
                                    Circle()
                                        .fill(Color.pledgeOrange)
                                        .frame(width: 36, height: 36)
                                        .overlay(Text("₿").font(.system(size: 18, weight: .bold)).foregroundColor(.white))

                                    Circle()
                                        .fill(theme.buttonTop)
                                        .frame(width: 36, height: 36)
                                        .overlay(Text("Ξ").font(.system(size: 18, weight: .bold)).foregroundColor(.white))
                                        .offset(x: 20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        ChartLineView(progress: chartProgress)
                            .frame(height: 180)
                            .flatCard()
                            .padding(.horizontal, 20)

                        PillToggle(
                            options: ["1W", "1M", "3M", "1Y", "ALL"],
                            selected: $selectedRange
                        )

                        VStack(spacing: 0) {
                            HStack {
                                Text("Stats")
                                    .pledgeHeadline()
                                    .foregroundColor(.primary)
                                    .embossed(.raised)
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(theme.surface)
                                        .frame(width: 6, height: 6)
                                    Text("Live")
                                        .pledgeCaption()
                                        .foregroundColor(theme.surface)
                                }
                            }
                            .padding(.bottom, 8)

                            StatRowDivider()
                            StatRow(icon: "📊", label: "24h change", value: "+$3.21 +1.2%", valueColor: .pledgeGreen)
                            StatRowDivider()
                            StatRow(icon: "📈", label: "Total invested", value: "$247.00")
                            StatRowDivider()
                            StatRow(icon: "🏦", label: "Allocation", value: "40 / 30 / 30", showChevron: true)
                            StatRowDivider()
                            StatRow(icon: "🔒", label: "Vault unlock", value: "47 days")
                            StatRowDivider()
                            StatRow(icon: "💸", label: "Platform fees", value: "$47.00")
                            StatRowDivider()
                            StatRow(icon: "🔄", label: "Transactions", value: "12", showChevron: true)
                        }
                        .padding(.horizontal, 20)

                        DualCTAView(
                            leftTitle: "↓ Withdraw",
                            rightTitle: "↑ Deposit",
                            leftAction: { },
                            rightAction: { }
                        )
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Investment Pool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                    chartProgress = 1.0
                }
            }
        }
    }
}

#Preview {
    PortfolioView()
        .environmentObject(AppState())
}
