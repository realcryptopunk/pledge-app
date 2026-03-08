import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddFunds = false
    @State private var showAddHabit = false
    @State private var addFundsAmount = ""
    @State private var exerciseHabit: TodayHabit?
    @State private var photoHabit: TodayHabit?
    @State private var showHabitDetail: TodayHabit?
    @State private var scrollProxy: ScrollViewProxy?
    @Environment(\.themeColors) var theme

    var body: some View {
        ZStack {
            WaterBackgroundView()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        streakBadge
                        todayPledgesCard
                        habitListSection
                            .id("habitList")
                        recentActivitySection
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear { scrollProxy = proxy }
            }

            // Investment toast banner
            if let toast = appState.investmentToast {
                VStack {
                    HStack(spacing: 8) {
                        Text("\u{1F4C8}")
                            .font(.system(size: 16))
                        Text(toast)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pledgeGreen.opacity(0.9), Color.pledgeBlue.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.springBounce, value: appState.investmentToast)
                .zIndex(100)
            }
        }
        .task {
            await appState.verifyTodayHabits()
            await appState.refreshOnChainBalance()
        }
        .refreshable {
            await appState.refreshOnChainBalance()
        }
        .sheet(isPresented: $showAddFunds) {
            AddFundsSheet(appState: appState)
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
                .environmentObject(appState)
        }
        .sheet(item: $showHabitDetail) { todayHabit in
            HabitDetailSheet(todayHabit: todayHabit)
        }
        .fullScreenCover(item: $photoHabit) { todayHabit in
            BeRealVerificationView(todayHabit: todayHabit) {
                PPHaptic.success()
                withAnimation(.springBounce) {
                    appState.manuallyVerifyHabit(todayHabit.id)
                }
            }
        }
        .fullScreenCover(item: $exerciseHabit) { todayHabit in
            if let exerciseType = ExerciseType(habitType: todayHabit.habit.type) {
                ExerciseCounterView(
                    exerciseType: exerciseType,
                    targetReps: Int(todayHabit.habit.targetValue)
                ) { count in
                    PPHaptic.success()
                    withAnimation(.springBounce) {
                        appState.manuallyVerifyHabit(todayHabit.id)
                    }
                    exerciseHabit = nil
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance")
                        .pledgeCaption()
                        .foregroundColor(.secondary)

                    RollingCounterView(
                        value: appState.vaultBalance,
                        decimalPlaces: 2,
                        mainSize: 48,
                        decimalSize: 28,
                        trailingSize: 20
                    )
                    .embossed(.raised)

                    Text("+\(appState.todayChangePercent, specifier: "%.1f")% this month")
                        .pledgeCaption()
                        .foregroundColor(.pledgeGreen)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button { } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(.primary.opacity(0.7))
                    }

                    Button { } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    PPHaptic.medium()
                    showAddFunds = true
                } label: {
                    Text("Add Funds")
                }
                .buttonStyle(PrimaryCapsuleStyle())

                Button {
                    PPHaptic.medium()
                    showAddHabit = true
                } label: {
                    Text("Add Habit")
                }
                .buttonStyle(AccentCapsuleStyle())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Today Pledges Card

    private var todayPledgesCard: some View {
        Button {
            PPHaptic.light()
            withAnimation(.springBounce) {
                scrollProxy?.scrollTo("habitList", anchor: .top)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Pledges")
                        .pledgeHeadline()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }

                Text("$\(appState.todayStakeTotal, specifier: "%.2f")")
                    .pledgeDisplay(36)
                    .contentTransition(.numericText())

                HStack(spacing: 24) {
                    Label("At stake", systemImage: "chart.bar.fill")
                        .pledgeCaption()
                    Spacer()
                    Text("$\(appState.todayStakeTotal, specifier: "%.2f")")
                        .pledgeMonoSmall()
                }

                HStack(spacing: 24) {
                    Label("Verified", systemImage: "checkmark.circle.fill")
                        .pledgeCaption()
                    Spacer()
                    Text("\(appState.todayVerifiedCount) of \(appState.todayHabits.count)")
                        .pledgeMonoSmall()
                }
            }
            .accentCard(theme.deep)
        }
        .buttonStyle(.plain)
        .cardPress()
    }

    // MARK: - Habit List Section

    /// Whether this habit type uses HealthKit for auto-verification.
    private func isHealthKitType(_ type: HabitType) -> Bool {
        type == .steps || type == .sleep || type == .workout || type == .gym
    }

    private var habitListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY")
                    .pledgeCaption()
                    .foregroundColor(.secondary)
                    .tracking(1)

                if appState.isVerifying {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, 4)
                }
            }

            if appState.todayHabits.isEmpty {
                // MARK: Empty State
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))

                    Text("No pledges today")
                        .pledgeHeadline()
                        .foregroundColor(.secondary)

                    Text(appState.habits.isEmpty
                         ? "Create your first pledge to get started"
                         : "No habits scheduled for today")
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)

                    if appState.habits.isEmpty {
                        Button {
                            PPHaptic.light()
                            showAddHabit = true
                        } label: {
                            Text("Add Pledge")
                        }
                        .buttonStyle(SmallCapsuleStyle())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .cleanCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.todayHabits.enumerated()), id: \.element.id) { index, todayHabit in
                        if index > 0 {
                            StatRowDivider()
                                .padding(.horizontal, 4)
                        }
                        HabitRowView(
                            todayHabit: todayHabit,
                            isHealthKit: isHealthKitType(todayHabit.habit.type),
                            isVision: todayHabit.habit.verificationType == .vision,
                            isPhoto: todayHabit.habit.verificationType == .photo,
                            isVerifying: appState.isVerifying,
                            onVerify: {
                                PPHaptic.success()
                                withAnimation(.springBounce) {
                                    appState.manuallyVerifyHabit(todayHabit.id)
                                }
                            },
                            onRefresh: {
                                PPHaptic.light()
                                Task {
                                    await appState.verifyTodayHabits()
                                }
                            },
                            onOpenCamera: {
                                PPHaptic.medium()
                                if todayHabit.habit.verificationType == .photo {
                                    photoHabit = todayHabit
                                } else {
                                    exerciseHabit = todayHabit
                                }
                            },
                            onFail: {
                                PPHaptic.heavy()
                                withAnimation(.springBounce) {
                                    #if DEBUG
                                    appState.forceFailHabit(todayHabit.id)
                                    #endif
                                }
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            PPHaptic.light()
                            showHabitDetail = todayHabit
                        }
                        .staggerIn(index: index)
                    }
                }
                .cleanCard()
            }
        }
    }

    // MARK: - Streak Badge

    private var activeHabitCount: Int {
        appState.habits.filter { $0.isActive }.count
    }

    private var streakBadge: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.orange, .red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                Text("\(appState.streakCount)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .contentTransition(.numericText())

                Text("day streak")
                    .pledgeCaption()
                    .foregroundColor(.secondary)
            }

            Spacer()

            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 1, height: 24)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.pledgeGreen)

                Text("\(activeHabitCount)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .contentTransition(.numericText())

                Text("active")
                    .pledgeCaption()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .aquaGlass(cornerRadius: 16)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            if appState.recentActivity.isEmpty {
                // MARK: Empty State
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.4))

                    Text("No activity yet")
                        .pledgeCallout()
                        .foregroundColor(.secondary)

                    Text("Your verification history will appear here")
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .cleanCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.recentActivity.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            StatRowDivider()
                                .padding(.horizontal, 4)
                        }

                        HStack(spacing: 12) {
                            Text(item.icon)
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .pledgeCallout()
                                    .foregroundColor(.primary)
                                Text(item.detail)
                                    .pledgeCaption()
                                    .foregroundColor(item.isFailure ? .pledgeRed : .pledgeGreen)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .staggerIn(index: index)
                    }
                }
                .cleanCard()
            }
        }
    }
}

// MARK: - Add Funds Sheet

struct AddFundsSheet: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var amountString = ""
    @State private var isFetchingToken = false
    @State private var showOnramp = false
    @State private var sessionToken: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPaymentMethods = false
    @Environment(\.themeColors) var theme

    private let quickAmounts = ["50", "100", "200", "500"]

    private var amount: Double {
        Double(amountString) ?? 0
    }

    private var canDeposit: Bool {
        amount >= 1
    }

    var body: some View {
        ZStack {
            WaterBackgroundView()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                HStack {
                    Text("Add Funds")
                        .pledgeTitle()
                        .foregroundColor(.primary)
                        .embossed(.raised)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 8) {
                    Text("FUND YOUR WALLET")
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(amountString.isEmpty ? "0" : amountString)
                            .pledgeXL(72)
                            .foregroundColor(amountString.isEmpty ? .secondary.opacity(0.3) : .primary)
                            .embossed(.raised)
                            .contentTransition(.numericText())
                            .animation(.quickSnap, value: amountString)
                    }

                    Text("No minimum deposit")
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.6))
                }

                Spacer().frame(height: 24)

                HStack(spacing: 10) {
                    ForEach(quickAmounts, id: \.self) { preset in
                        Button {
                            PPHaptic.light()
                            withAnimation(.quickSnap) {
                                amountString = preset
                            }
                        } label: {
                            Text("$\(preset)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(amountString == preset ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(amountString == preset
                                              ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                              : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.primary.opacity(amountString == preset ? 0.3 : 0.1), lineWidth: 0.5)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.bottom, 20)

                NumberPadView(value: $amountString, maxDigits: 5, allowDecimal: false)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 24)

                Button {
                    PPHaptic.heavy()
                    showPaymentMethods = true
                } label: {
                    Text("Deposit")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.buttonTop, theme.buttonBottom],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .clipShape(Capsule())
                        .shadow(color: theme.surface.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(!canDeposit)
                .opacity(canDeposit ? 1.0 : 0.35)
                .padding(.horizontal, 20)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 10))
                    Text("Secured & encrypted · Powered by Robinhood Chain")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showOnramp) {
            if let token = sessionToken {
                CoinbaseOnrampView(
                    walletAddress: appState.walletAddress,
                    amount: amount,
                    sessionToken: token,
                    onDismiss: {
                        showOnramp = false
                        dismiss()
                    }
                )
            }
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodsView(depositAmount: amount) { method in
                showPaymentMethods = false
                switch method {
                case .applePay, .robinhood:
                    let depositAmount = amount
                    let wallet = appState.walletAddress
                    appState.vaultBalance += depositAmount
                    dismiss()
                    // Mint MockUSDC on-chain, then refresh balance
                    if !wallet.isEmpty {
                        Task {
                            do {
                                let result = try await MintUSDCService.mint(toWallet: wallet, usdcAmount: depositAmount)
                                print("[AddFunds] Minted \(depositAmount) USDC: \(result.txHash)")
                            } catch {
                                print("[AddFunds] Mint failed (non-blocking): \(error.localizedDescription)")
                            }
                            await appState.refreshOnChainBalance()
                        }
                    }
                case .coinbase:
                    fundWithCoinbase()
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Deposit Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Fund with Coinbase

    private func fundWithCoinbase() {
        isFetchingToken = true
        Task {
            do {
                let token = try await OnrampService.fetchSessionToken(
                    walletAddress: appState.walletAddress,
                    amount: amount
                )
                await MainActor.run {
                    sessionToken = token
                    isFetchingToken = false
                    showOnramp = true
                }
            } catch {
                await MainActor.run {
                    isFetchingToken = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let todayHabit: TodayHabit
    var isHealthKit: Bool = false
    var isVision: Bool = false
    var isPhoto: Bool = false
    var isVerifying: Bool = false
    var onVerify: (() -> Void)? = nil
    var onRefresh: (() -> Void)? = nil
    var onOpenCamera: (() -> Void)? = nil
    var onFail: (() -> Void)? = nil
    @Environment(\.themeColors) var theme

    var statusIcon: some View {
        Group {
            switch todayHabit.status {
            case .verified:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.pledgeGreen)
            case .pending:
                if isVerifying && isHealthKit {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.pledgeOrange)
                }
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.pledgeRed)
            case .skipped:
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .font(.system(size: 18))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(todayHabit.habit.icon)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 2) {
                    Text(todayHabit.habit.name)
                        .pledgeHeadline()
                        .foregroundColor(.primary)
                    Text(todayHabit.detail)
                        .pledgeCaption()
                        .foregroundColor(todayHabit.status == .failed ? .pledgeRed :
                                         todayHabit.status == .verified ? .pledgeGreen : .secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(todayHabit.habit.stakeAmount))")
                        .pledgeMono()
                        .foregroundColor(.primary)
                    statusIcon
                }
            }

            if let progress = todayHabit.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.light)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            if todayHabit.status == .pending {
                HStack {
                    Spacer()
                    if isPhoto {
                        // Photo habits open BeReal-style camera
                        Button {
                            onOpenCamera?()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Photo Verify")
                            }
                        }
                        .buttonStyle(SmallCapsuleStyle())
                    } else if isVision {
                        // Vision habits open the camera for rep counting
                        Button {
                            onOpenCamera?()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Open Camera")
                            }
                        }
                        .buttonStyle(SmallCapsuleStyle())
                    } else if isHealthKit {
                        // HealthKit habits get a Refresh button to re-run auto-verification
                        Button {
                            onRefresh?()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(SmallCapsuleStyle())
                        .disabled(isVerifying)
                    } else {
                        // Manual habits get a Verify Now button
                        Button("Verify Now") {
                            onVerify?()
                        }
                        .buttonStyle(SmallCapsuleStyle())
                    }

                    #if DEBUG
                    Button {
                        onFail?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Fail")
                        }
                    }
                    .buttonStyle(SmallCapsuleStyle())
                    .tint(.pledgeRed)
                    #endif
                }
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
