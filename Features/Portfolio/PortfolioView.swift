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
    let fixedAPY: Double
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
    @State private var chartData: [PortfolioDataPoint] = []
    @State private var cachedTransactions: [TransactionItem] = []
    @State private var appeared = false
    @Environment(\.themeColors) var theme

    static let allocations: [AllocationItem] = [
        AllocationItem(symbol: "PT-sUSDai", name: "Pendle sUSDai", icon: "🔒", percentage: 0.35, fixedAPY: 9.0, color: .pledgeBlue),
        AllocationItem(symbol: "PT-USDai", name: "Pendle USDai", icon: "🏦", percentage: 0.25, fixedAPY: 5.5, color: .pledgeViolet),
        AllocationItem(symbol: "PT-thBILL", name: "Pendle T-Bills", icon: "📜", percentage: 0.20, fixedAPY: 5.7, color: .pledgeGreen),
        AllocationItem(symbol: "PT-weETH", name: "Pendle weETH", icon: "⟠", percentage: 0.12, fixedAPY: 2.7, color: .pledgeOrange),
        AllocationItem(symbol: "PT-gUSDC", name: "Pendle gUSDC", icon: "💵", percentage: 0.08, fixedAPY: 6.6, color: .cyan),
    ]

    private var weightedAPY: Double {
        Self.allocations.reduce(0) { $0 + $1.percentage * $1.fixedAPY }
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

    private var hasPortfolioData: Bool {
        appState.investmentPoolValue > 0 || !appState.habits.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 20) {
                        if hasPortfolioData {
                            portfolioHeader
                            chartSection
                            rangeToggle
                            allocationPreview
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
                    allocations: Self.allocations,
                    totalValue: appState.investmentPoolValue
                )
            }
            .sheet(isPresented: $showTransactions) {
                TransactionHistoryView(transactions: cachedTransactions)
            }
            .onAppear {
                if !appeared {
                    appeared = true
                    rebuildChartData()
                    buildTransactions()
                }
            }
            .onChange(of: selectedRange) { _, _ in
                rebuildChartData()
            }
        }
    }

    // MARK: - Portfolio Header

    private var portfolioHeader: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("INVESTMENT POOL")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                Text("$\(appState.investmentPoolValue, specifier: "%.2f")")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("+$14.38 (\(appState.investmentGrowth, specifier: "%.1f")%)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.pledgeGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.pledgeGreen.opacity(0.12))
                .clipShape(Capsule())
            }

            // Allocation pill row
            HStack(spacing: 6) {
                ForEach(Self.allocations) { alloc in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(alloc.color)
                            .frame(width: 6, height: 6)
                        Text("\(Int(alloc.percentage * 100))%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(spacing: 0) {
            if chartData.isEmpty {
                ProgressView()
                    .frame(height: 180)
            } else {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pledgeBlue, .pledgeViolet],
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
                            colors: [Color.pledgeBlue.opacity(0.2), Color.pledgeBlue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("$\(Int(v))")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.primary.opacity(0.06))
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.6))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Range Toggle

    private var rangeToggle: some View {
        PillToggle(
            options: ["1W", "1M", "3M", "1Y", "ALL"],
            selected: $selectedRange
        )
    }

    // MARK: - Allocation Preview

    private var allocationPreview: some View {
        Button {
            PPHaptic.light()
            showAllocation = true
        } label: {
            VStack(spacing: 12) {
                HStack {
                    Text("Yield Allocation")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(weightedAPY, specifier: "%.1f")% avg APY")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.pledgeGreen)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                }

                // Stacked bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(Self.allocations) { alloc in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(alloc.color)
                                .frame(width: max(8, (geo.size.width - CGFloat(Self.allocations.count - 1) * 2) * alloc.percentage))
                        }
                    }
                }
                .frame(height: 8)

                // Labels
                HStack(spacing: 0) {
                    ForEach(Self.allocations) { alloc in
                        VStack(spacing: 2) {
                            Text(alloc.icon)
                                .font(.system(size: 16))
                            Text(alloc.symbol.replacingOccurrences(of: "PT-", with: ""))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(alloc.fixedAPY, specifier: "%.1f")%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(alloc.color)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.6))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 0) {
            StatRow(icon: "📈", label: "Total invested", value: "$\(Int(appState.investmentPoolValue))")
            StatRowDivider()
            StatRow(icon: "💰", label: "Weighted APY", value: "\(String(format: "%.1f", weightedAPY))%", valueColor: .pledgeGreen)
            StatRowDivider()
            StatRow(icon: "🔒", label: "Vault unlock", value: "47 days")
            StatRowDivider()
            StatRow(icon: "💸", label: "Platform fee (2%)", value: "$\(String(format: "%.2f", appState.investmentPoolValue * 0.02))")
            StatRowDivider()

            Button {
                PPHaptic.light()
                showTransactions = true
            } label: {
                StatRow(icon: "🔄", label: "Transactions", value: "\(cachedTransactions.count)", showChevron: true)
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
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.pledgeBlue.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.pledgeBlue.opacity(0.5))
            }

            Text("No investments yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("When you miss a habit pledge, your stake gets invested into yield-generating Pendle PTs on Arbitrum.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Show what they'd earn
            VStack(spacing: 8) {
                Text("Avg fixed yield")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\(weightedAPY, specifier: "%.1f")% APY")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.pledgeGreen)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pledgeGreen.opacity(0.08))
            )
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Data Generation (called once)

    private func rebuildChartData() {
        let days = daysForRange
        let baseValue = appState.investmentPoolValue
        guard baseValue > 0 else {
            chartData = (0..<days).map { PortfolioDataPoint(day: $0, value: 0) }
            return
        }

        var points: [PortfolioDataPoint] = []
        let startValue = baseValue * 0.75
        let growthPerDay = (baseValue - startValue) / Double(days)
        var value = startValue

        for day in 0..<days {
            let noise = sin(Double(day) * 0.8) * (baseValue * 0.02) +
                        cos(Double(day) * 1.3) * (baseValue * 0.015)
            value += growthPerDay + noise
            value = max(startValue * 0.9, value)
            points.append(PortfolioDataPoint(day: day, value: value))
        }
        if let last = points.indices.last {
            points[last] = PortfolioDataPoint(day: days - 1, value: baseValue)
        }
        chartData = points
    }

    private func buildTransactions() {
        var items: [TransactionItem] = []
        let cal = Calendar.current

        for (i, activity) in appState.recentActivity.prefix(10).enumerated() {
            let amt = activity.isFailure ? "+$\(5 + (i * 3) % 20)" : "$0"
            items.append(TransactionItem(
                icon: activity.icon,
                title: activity.title,
                detail: activity.detail,
                amount: amt,
                isPositive: activity.isFailure,
                date: cal.date(byAdding: .hour, value: -(i * 3), to: Date()) ?? Date()
            ))
        }

        if items.count < 3 {
            let baseTx: [(String, String, String, String)] = [
                ("📈", "Portfolio rebalance", "Auto-rebalanced allocation", "$0"),
                ("🔒", "Vault deposit", "Initial stake deposit", "+$50"),
                ("💰", "Yield earned", "Daily PT yield", "+$0.47"),
            ]
            for (i, tx) in baseTx.enumerated() {
                items.append(TransactionItem(
                    icon: tx.0, title: tx.1, detail: tx.2,
                    amount: tx.3, isPositive: true,
                    date: cal.date(byAdding: .day, value: -(i + 1), to: Date()) ?? Date()
                ))
            }
        }
        cachedTransactions = items
    }
}

// MARK: - Allocation Detail View

struct AllocationDetailView: View {
    let allocations: [AllocationItem]
    let totalValue: Double
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    private var weightedAPY: Double {
        allocations.reduce(0) { $0 + $1.percentage * $1.fixedAPY }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()
                    .environmentObject(AppState())

                ScrollView {
                    VStack(spacing: 24) {
                        allocationRing
                            .padding(.top, 8)

                        // Weighted APY banner
                        HStack(spacing: 8) {
                            Image(systemName: "percent")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.pledgeGreen)
                            Text("Weighted avg: \(weightedAPY, specifier: "%.1f")% fixed APY")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.pledgeGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.pledgeGreen.opacity(0.1))
                        .clipShape(Capsule())

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
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("\(alloc.fixedAPY, specifier: "%.1f")% fixed APY")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.pledgeGreen)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(String(format: "%.2f", totalValue * alloc.percentage))")
                                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.primary)
                                        Text("\(Int(alloc.percentage * 100))%")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(alloc.color)
                                    }
                                }
                                .padding(.vertical, 14)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground).opacity(0.6))
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        )
                        .padding(.horizontal, 20)

                        // Info
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("All yields are fixed-rate via Pendle Principal Tokens on Arbitrum. Auto-rebalances weekly.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("Principal protected — PTs mature at full face value regardless of market conditions.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
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
                    .font(.system(size: 12, weight: .medium))
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
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                                if index > 0 { StatRowDivider() }

                                HStack(spacing: 12) {
                                    Text(tx.icon)
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tx.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(tx.detail)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(tx.amount)
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(tx.isPositive ? .pledgeGreen : .secondary)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground).opacity(0.6))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                    )
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
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
