import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var showAddHabit = false
    @State private var selectedHabit: TodayHabit?
    @State private var selectedActivityHabit: Habit?

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Activity Grid Section
                        if !appState.habits.isEmpty {
                            VStack(spacing: 14) {
                                // Habit selector pills
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(appState.habits) { habit in
                                            let isSelected = (selectedActivityHabit?.id ?? appState.habits.first?.id) == habit.id
                                            Button {
                                                PPHaptic.light()
                                                withAnimation(.quickSnap) {
                                                    selectedActivityHabit = habit
                                                }
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Text(habit.icon)
                                                        .font(.system(size: 14))
                                                    Text(habit.name)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .lineLimit(1)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule(style: .continuous)
                                                        .fill(isSelected ? theme.surface.opacity(0.25) : Color.primary.opacity(0.06))
                                                )
                                                .overlay(
                                                    Capsule(style: .continuous)
                                                        .stroke(isSelected ? theme.surface.opacity(0.5) : Color.clear, lineWidth: 1)
                                                )
                                                .foregroundColor(isSelected ? .primary : .secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                // Stats row for selected habit
                                if let habit = selectedActivityHabit ?? appState.habits.first {
                                    HStack(spacing: 16) {
                                        activityStat(value: "\(habit.currentStreak)", label: "streak")
                                        activityStat(value: "\(Int(habit.successRate * 100))%", label: "success")
                                        activityStat(value: "$\(Int(habit.stakeAmount))", label: "daily")
                                    }
                                    .padding(.horizontal, 4)

                                    // Activity grid
                                    HabitActivityGrid(habit: habit)
                                        .id(habit.id)
                                        .transition(.opacity)
                                }
                            }
                            .cleanCard()
                        }

                        // MARK: - Active Habits Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACTIVE")
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                                .tracking(1)

                            if appState.habits.isEmpty {
                                // MARK: - Empty State
                                VStack(spacing: 16) {
                                    Image(systemName: "plus.circle.dashed")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary.opacity(0.4))

                                    Text("No pledges yet")
                                        .pledgeHeadline()
                                        .foregroundColor(.secondary)

                                    Text("Create your first habit pledge to get started")
                                        .pledgeCaption()
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .multilineTextAlignment(.center)

                                    Button {
                                        PPHaptic.light()
                                        showAddHabit = true
                                    } label: {
                                        Text("Add Pledge")
                                    }
                                    .buttonStyle(SmallCapsuleStyle())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .cleanCard()
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(appState.habits.enumerated()), id: \.element.id) { index, habit in
                                        if index > 0 {
                                            StatRowDivider()
                                        }

                                        HStack(spacing: 12) {
                                            Text(habit.icon)
                                                .font(.system(size: 20))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(habit.name)
                                                    .pledgeHeadline()
                                                    .foregroundColor(.primary)
                                                HStack(spacing: 8) {
                                                    Text("🔥 \(habit.currentStreak) days")
                                                    Text("·")
                                                    Text("\(Int(habit.successRate * 100))%")
                                                    Text("·")
                                                    Text("$\(Int(habit.stakeAmount))/day")
                                                }
                                                .pledgeCaption()
                                                .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary.opacity(0.5))
                                        }
                                        .padding(.vertical, 14)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            PPHaptic.light()
                                            let todayMatch = appState.todayHabits.first { $0.habit.id == habit.id }
                                            selectedHabit = todayMatch ?? TodayHabit(
                                                id: UUID(),
                                                habit: habit,
                                                status: .pending,
                                                detail: "",
                                                verifiedAt: nil,
                                                progress: nil
                                            )
                                        }
                                        .staggerIn(index: index)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                PPHaptic.warning()
                                                withAnimation(.quickSnap) {
                                                    appState.deleteHabit(habit)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .cleanCard()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("My Pledges")
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        PPHaptic.light()
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView()
                    .environmentObject(appState)
            }
            .sheet(item: $selectedHabit) { todayHabit in
                HabitDetailSheet(todayHabit: todayHabit)
            }
        }
    }

    // MARK: - Activity Stat

    private func activityStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HabitsView()
        .environmentObject(AppState())
}
