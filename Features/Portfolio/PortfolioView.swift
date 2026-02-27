import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedRange = 1
    @State private var chartProgress: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero value
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("$\(appState.investmentPoolValue, specifier: "%.2f")")
                                    .pledgeHero(48)
                                    .foregroundColor(.pledgeBlackAdaptive)
                                    .contentTransition(.numericText())
                                
                                Text("↑$14.38 (+\(appState.investmentGrowth, specifier: "%.1f")%)")
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeGreen)
                                
                                Text("past month")
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeGray)
                            }
                            
                            Spacer()
                            
                            // Coin icons
                            ZStack {
                                Circle()
                                    .fill(Color.pledgeOrange)
                                    .frame(width: 36, height: 36)
                                    .overlay(Text("₿").font(.system(size: 18, weight: .bold)).foregroundColor(.white))
                                
                                Circle()
                                    .fill(Color.pledgeBlue)
                                    .frame(width: 36, height: 36)
                                    .overlay(Text("Ξ").font(.system(size: 18, weight: .bold)).foregroundColor(.white))
                                    .offset(x: 20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Chart
                    ChartLineView(progress: chartProgress)
                        .frame(height: 180)
                        .flatCard()
                        .padding(.horizontal, 20)
                    
                    // Time range pills
                    PillToggle(
                        options: ["1W", "1M", "3M", "1Y", "ALL"],
                        selected: $selectedRange
                    )
                    
                    // Stats
                    VStack(spacing: 0) {
                        HStack {
                            Text("Stats")
                                .pledgeHeadline()
                                .foregroundColor(.pledgeBlackAdaptive)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.pledgeBlue)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeBlue)
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
                    
                    // Dual CTA
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
            .background(Color.pledgeBgAdaptive)
            .navigationTitle("Investment Pool")
            .navigationBarTitleDisplayMode(.inline)
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
