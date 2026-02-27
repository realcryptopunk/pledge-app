import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddFunds = false
    @State private var showAddHabit = false
    @State private var addFundsAmount = ""
    @Environment(\.themeColors) var theme

    var body: some View {
        ZStack {
            WaterBackgroundView()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    streakBadge
                    todayPledgesCard
                    habitListSection
                    recentActivitySection
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showAddFunds) {
            AddFundsSheet(appState: appState)
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
                .environmentObject(appState)
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

                    Text("$\(appState.vaultBalance, specifier: "%.2f")")
                        .pledgeHero(56)
                        .foregroundColor(.primary)
                        .embossed(.raised)
                        .contentTransition(.numericText())

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

            Button {
                PPHaptic.medium()
                showAddFunds = true
            } label: {
                Text("Add funds")
            }
            .buttonStyle(PrimaryCapsuleStyle())
        }
        .padding(.top, 8)
    }

    // MARK: - Today Pledges Card

    private var todayPledgesCard: some View {
        Button { } label: {
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
            .accentCard(theme.buttonTop)
        }
        .buttonStyle(.plain)
        .cardPress()
    }

    // MARK: - Habit List Section

    private var habitListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

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
                        HabitRowView(todayHabit: todayHabit, onVerify: {
                            PPHaptic.success()
                            withAnimation(.springBounce) {
                                appState.verifyHabit(todayHabit.id)
                            }
                        })
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
    @State private var showSuccess = false
    @Environment(\.themeColors) var theme

    private var amount: Double {
        Double(amountString) ?? 0
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

                VStack(spacing: 4) {
                    if showSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.pledgeGreen)
                            .transition(.scale.combined(with: .opacity))

                        Text("Funds added!")
                            .pledgeHeadline()
                            .foregroundColor(.pledgeGreen)
                            .padding(.top, 8)
                    } else {
                        Text("$\(amountString.isEmpty ? "0" : amountString)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(amountString.isEmpty ? .secondary.opacity(0.4) : .primary)
                            .embossed(.raised)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: amountString)

                        Text("Enter amount to deposit")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !showSuccess {
                    HStack(spacing: 10) {
                        ForEach(["25", "50", "100", "250"], id: \.self) { preset in
                            Button {
                                PPHaptic.light()
                                amountString = preset
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

                    NumberPadView(value: $amountString, maxDigits: 5, allowDecimal: true)
                        .padding(.horizontal, 20)

                    Button {
                        guard amount > 0 else { return }
                        PPHaptic.success()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            appState.vaultBalance += amount
                            showSuccess = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            dismiss()
                        }
                    } label: {
                        Text(amount > 0 ? "Add $\(amountString)" : "Enter amount")
                    }
                    .buttonStyle(PrimaryCapsuleStyle(isEnabled: amount > 0))
                    .disabled(amount <= 0)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let todayHabit: TodayHabit
    var onVerify: (() -> Void)? = nil
    @Environment(\.themeColors) var theme

    var statusIcon: some View {
        Group {
            switch todayHabit.status {
            case .verified:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.pledgeGreen)
            case .pending:
                Image(systemName: "clock.fill")
                    .foregroundColor(.pledgeOrange)
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
                        .foregroundColor(.secondary)
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

            if todayHabit.status == .pending && todayHabit.progress == nil && todayHabit.habit.type != .sleep {
                HStack {
                    Spacer()
                    Button("Verify Now") {
                        onVerify?()
                    }
                    .buttonStyle(SmallCapsuleStyle())
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
