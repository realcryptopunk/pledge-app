import SwiftUI
import Charts

// MARK: - Portfolio Data Models

struct PortfolioDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let value: Double
}

struct AllocationItem: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let icon: String
    let percentage: Double
    let color: Color
}

struct TransactionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let amount: String
    let isPositive: Bool
    let date: Date
}

// MARK: - Portfolio View

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedRange = 1
    @State private var showAllocation = false
    @State private var showTransactions = false
    @State private var selectedDataPoint: PortfolioDataPoint?
    @Environment(\.themeColors) var theme

    private let allocations: [AllocationItem] = [
        AllocationItem(symbol: "BTC", name: "Bitcoin", icon: "₿", percentage: 0.40, color: .pledgeOrange),
        AllocationItem(symbol: "ETH", name: "Ethereum", icon: "Ξ", percentage: 0.30, color: .pledgeViolet),
        AllocationItem(symbol: "SOL", name: "Solana", icon: "◎", percentage: 0.20, color: .pledgeGreen),
        AllocationItem(symbol: "Other", name: "Mixed Index", icon: "◆", percentage: 0.10, color: .pledgeBlue),
    ]

    private var chartData: [PortfolioDataPoint] {
        generateChartData(days: daysForRange, baseValue: appState.investmentPoolValue)
    }

    private var daysForRange: Int {
        switch selectedRange {
        case 0: return 7
        case 1: return 30
        case 2: return 90
        case 3: return 365
        default: return 365
        }
    }

    private var transactions: [TransactionItem] {
        var items: [TransactionItem] = []
        let cal = Calendar.current
        // Generate simulated transactions from recent activity
        for (i, activity) in appState.recentActivity.prefix(10).enumerated() {
            items.append(TransactionItem(
                icon: activity.icon,
                title: activity.title,
                detail: activity.detail,
                amount: activity.isFailure ? "+$\(Int.random(in: 5...25))" : "-$0",
                isPositive: activity.isFailure,
                date: cal.date(byAdding: .hour, value: -(i * 3), to: Date()) ?? Date()
            ))
        }
        // Add some baseline transactions if few exist
        if items.count < 3 {
            let baseTx: [(String, String, String, String)] = [
                ("📈", "Portfolio rebalance", "Auto-rebalanced allocation", "+$0"),
                ("🔒", "Vault deposit", "Initial stake deposit", "+$50"),
                ("💰", "Yield earned", "Daily DeFi yield", "+$0.12"),
            ]
            for (i, tx) in baseTx.enumerated() {
                items.append(TransactionItem(
                    icon: tx.0, title: tx.1, detail: tx.2,
                    amount: tx.3, isPositive: true,
                    date: cal.date(byAdding: .day, value: -(i + 1), to: Date()) ?? Date()
                ))
            }
        }
        return items
    }

    private var hasPortfolioData: Bool {
        appState.investmentPoolValue > 0 || !appState.habits.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        if hasPortfolioData {
                            portfolioHeader
                            chartSection
                            rangeToggle
                            statsSection
                            ctaButtons
                        } else {
                            emptyState
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Investment Pool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .sheet(isPresented: $showAllocation) {
                AllocationDetailView(
                    allocations: allocations,
                    totalValue: appState.investmentPoolValue
                )
            }
            .sheet(isPresented: $showTransactions) {
                TransactionHistoryView(transactions: transactions)
            }
        }
    }

    // MARK: - Portfolio Header

    private var portfolioHeader: some View {
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
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(spacing: 0) {
            Chart(chartData) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.surface, theme.light],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.surface.opacity(0.25), theme.surface.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v))")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.primary.opacity(0.08))
                }
            }
            .frame(height: 180)
        }
        .flatCard()
        .padding(.horizontal, 20)
    }

    // MARK: - Range Toggle

    private var rangeToggle: some View {
        PillToggle(
            options: ["1W", "1M", "3M", "1Y", "ALL"],
            selected: $selectedRange
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
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
            StatRow(icon: "📈", label: "Total invested", value: "$\(Int(appState.investmentPoolValue))")
            StatRowDivider()

            Button {
                PPHaptic.light()
                showAllocation = true
            } label: {
                StatRow(icon: "🏦", label: "Allocation", value: "40 / 30 / 20 / 10", showChevron: true)
            }
            .buttonStyle(.plain)

            StatRowDivider()
            StatRow(icon: "🔒", label: "Vault unlock", value: "47 days")
            StatRowDivider()
            StatRow(icon: "💸", label: "Platform fees", value: "$\(String(format: "%.2f", appState.investmentPoolValue * 0.02))")
            StatRowDivider()

            Button {
                PPHaptic.light()
                showTransactions = true
            } label: {
                StatRow(icon: "🔄", label: "Transactions", value: "\(transactions.count)", showChevron: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - CTA Buttons

    private var ctaButtons: some View {
        DualCTAView(
            leftTitle: "↓ Withdraw",
            rightTitle: "↑ Deposit",
            leftAction: { },
            rightAction: { }
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No investments yet")
                .pledgeTitle()
                .foregroundColor(.primary)

            Text("When you miss a habit pledge, your stake gets invested into a diversified crypto portfolio. Start by creating habits!")
                .pledgeBody()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(allocations) { alloc in
                        VStack(spacing: 4) {
                            Text(alloc.icon)
                                .font(.system(size: 24))
                            Text(alloc.symbol)
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                            Text("\(Int(alloc.percentage * 100))%")
                                .pledgeMonoSmall()
                                .foregroundColor(alloc.color)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 16)
                .cleanCard()
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Chart Data Generation

    private func generateChartData(days: Int, baseValue: Double) -> [PortfolioDataPoint] {
        guard baseValue > 0 else {
            return (0..<days).map { PortfolioDataPoint(day: $0, value: 0) }
        }

        var points: [PortfolioDataPoint] = []
        // Start from a lower value and grow to current value
        let startValue = baseValue * 0.75
        let growthPerDay = (baseValue - startValue) / Double(days)

        // Use seeded randomness for consistent chart
        var value = startValue
        for day in 0..<days {
            let trend = growthPerDay
            // Deterministic "noise" based on day index
            let noise = sin(Double(day) * 0.8) * (baseValue * 0.02) +
                        cos(Double(day) * 1.3) * (baseValue * 0.015)
            value += trend + noise
            value = max(startValue * 0.9, value) // floor
            points.append(PortfolioDataPoint(day: day, value: value))
        }
        // Ensure last point matches current value
        if let last = points.indices.last {
            points[last] = PortfolioDataPoint(day: days - 1, value: baseValue)
        }
        return points
    }
}

// MARK: - Allocation Detail View

struct AllocationDetailView: View {
    let allocations: [AllocationItem]
    let totalValue: Double
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()
                    .environmentObject(AppState())

                ScrollView {
                    VStack(spacing: 24) {
                        // Donut-style visual
                        allocationRing
                            .padding(.top, 8)

                        // Allocation breakdown
                        VStack(spacing: 0) {
                            ForEach(Array(allocations.enumerated()), id: \.element.id) { index, alloc in
                                if index > 0 { StatRowDivider() }

                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(alloc.color)
                                        .frame(width: 12, height: 12)

                                    Text(alloc.icon)
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(alloc.name)
                                            .pledgeHeadline()
                                            .foregroundColor(.primary)
                                        Text(alloc.symbol)
                                            .pledgeCaption()
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(String(format: "%.2f", totalValue * alloc.percentage))")
                                            .pledgeMono()
                                            .foregroundColor(.primary)
                                        Text("\(Int(alloc.percentage * 100))%")
                                            .pledgeCaption()
                                            .foregroundColor(alloc.color)
                                    }
                                }
                                .padding(.vertical, 14)
                                .staggerIn(index: index)
                            }
                        }
                        .cleanCard()
                        .padding(.horizontal, 20)

                        // Info note
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Allocation auto-rebalances weekly to maintain target weights.")
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var allocationRing: some View {
        ZStack {
            ForEach(Array(allocations.enumerated()), id: \.element.id) { index, alloc in
                let startAngle = allocations.prefix(index).reduce(0.0) { $0 + $1.percentage }
                Circle()
                    .trim(from: startAngle, to: startAngle + alloc.percentage - 0.005)
                    .stroke(alloc.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("$\(Int(totalValue))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("total")
                    .pledgeCaption()
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 160, height: 160)
    }
}

// MARK: - Transaction History View

struct TransactionHistoryView: View {
    let transactions: [TransactionItem]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()
                    .environmentObject(AppState())

                ScrollView {
                    VStack(spacing: 0) {
                        if transactions.isEmpty {
                            VStack(spacing: 16) {
                                Spacer().frame(height: 40)
                                Image(systemName: "arrow.left.arrow.right.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("No transactions yet")
                                    .pledgeHeadline()
                                    .foregroundColor(.secondary)
                                Text("Transactions will appear when stakes are invested")
                                    .pledgeCaption()
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                                if index > 0 { StatRowDivider() }

                                HStack(spacing: 12) {
                                    Text(tx.icon)
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tx.title)
                                            .pledgeCallout()
                                            .foregroundColor(.primary)
                                        Text(tx.detail)
                                            .pledgeCaption()
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(tx.amount)
                                        .pledgeMono()
                                        .foregroundColor(tx.isPositive ? .pledgeGreen : .secondary)
                                }
                                .padding(.vertical, 12)
                                .staggerIn(index: index)
                            }
                        }
                    }
                    .cleanCard()
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PortfolioView()
        .environmentObject(AppState())
}
