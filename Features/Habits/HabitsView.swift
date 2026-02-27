import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var showAddHabit = false
    @State private var selectedHabit: TodayHabit?

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Calendar Section
                        VStack(spacing: 12) {
                            HStack {
                                Button { } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.primary.opacity(0.7))
                                }
                                Spacer()
                                Text("February 2026")
                                    .pledgeHeadline()
                                    .foregroundColor(.primary)
                                Spacer()
                                Button { } label: {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.primary.opacity(0.7))
                                }
                            }

                            HStack {
                                ForEach(["M","T","W","T","F","S","S"], id: \.self) { day in
                                    Text(day)
                                        .pledgeCaption()
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(1..<29, id: \.self) { day in
                                    VStack(spacing: 4) {
                                        Text("\(day)")
                                            .pledgeCaption()
                                            .foregroundColor(day == 25 ? theme.surface : .primary)

                                        Circle()
                                            .fill(day < 25 ? (day % 3 == 0 ? Color.pledgeRed : Color.pledgeGreen) : Color.primary.opacity(0.1))
                                            .frame(width: 6, height: 6)
                                    }
                                    .frame(height: 36)
                                    .background(
                                        day == 25
                                            ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(theme.buttonTop.opacity(0.2))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .stroke(theme.surface.opacity(0.4), lineWidth: 0.5)
                                                )
                                            : nil
                                    )
                                }
                            }
                        }
                        .cleanCard()

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
}

#Preview {
    HabitsView()
        .environmentObject(AppState())
}
