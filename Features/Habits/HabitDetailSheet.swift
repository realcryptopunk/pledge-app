import SwiftUI

struct HabitDetailSheet: View {
    let todayHabit: TodayHabit
    @Environment(\.themeColors) var theme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived Data

    private var habit: Habit { todayHabit.habit }

    private var scheduleLabel: String {
        if habit.schedule.sorted() == [1, 2, 3, 4, 5, 6, 7] {
            return "Daily"
        } else if habit.schedule.sorted() == [1, 2, 3, 4, 5] {
            return "Weekdays"
        } else if habit.schedule.sorted() == [6, 7] {
            return "Weekends"
        } else {
            return "\(habit.schedule.count) days/week"
        }
    }

    private var verificationLabel: String {
        switch habit.verificationType {
        case .auto: return "Auto"
        case .healthKit: return "HealthKit"
        case .screenTimeAPI: return "Screen Time"
        case .photo: return "Photo"
        case .location: return "Location"
        case .vision: return "Vision"
        case .manual: return "Manual"
        case .inApp: return "In-App"
        }
    }

    private var totalSaved: Double {
        Double(habit.currentStreak) * habit.stakeAmount
    }

    private var totalInvested: Double {
        guard habit.successRate > 0 else { return 0 }
        let totalDays = Double(habit.currentStreak) / habit.successRate
        let failedDays = max(0, Int(totalDays) - habit.currentStreak)
        return Double(failedDays) * habit.stakeAmount
    }

    // MARK: - Week Strip

    /// Returns (dayLetter, status) for each day Mon–Sun.
    /// Mock: Mon–Wed completed, Thu is today, Fri–Sun future.
    private var weekDays: [(letter: String, status: DayStatus)] {
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        // Convert Sunday=1...Saturday=7 to Monday=1...Sunday=7
        let todayIndex = todayWeekday == 1 ? 6 : todayWeekday - 2

        return letters.enumerated().map { index, letter in
            let status: DayStatus
            if index < todayIndex {
                status = .completed
            } else if index == todayIndex {
                status = .today
            } else {
                status = .future
            }
            return (letter, status)
        }
    }

    enum DayStatus {
        case completed, today, future
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Habit Icon
                habitIcon
                    .padding(.top, 8)

                // MARK: - Habit Name
                Text(habit.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                // MARK: - Week Strip
                weekStrip

                // MARK: - Stat Rows
                statRows

                // MARK: - Action Buttons
                actionButtons

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    // MARK: - Habit Icon

    private var habitIcon: some View {
        Text(habit.icon)
            .font(.system(size: 28))
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(theme.light.opacity(0.2))
            )
            .overlay(
                Circle()
                    .stroke(theme.light.opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 4) {
                    Text(day.letter)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    ZStack {
                        Circle()
                            .fill(dayFill(day.status))
                            .frame(width: 32, height: 32)

                        if day.status == .completed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .staggerIn(index: index)
            }
        }
    }

    private func dayFill(_ status: DayStatus) -> Color {
        switch status {
        case .completed: return .pledgeGreen
        case .today: return theme.light.opacity(0.25)
        case .future: return Color.primary.opacity(0.08)
        }
    }

    // MARK: - Stat Rows

    private var statRows: some View {
        VStack(spacing: 0) {
            statRow(icon: "flame.fill", iconColor: .pledgeOrange, label: "Current streak", value: "\(habit.currentStreak) days", valueColor: .pledgeOrange)
            StatRowDivider()
            statRow(icon: "chart.bar.fill", iconColor: .secondary, label: "Success rate", value: "\(Int(habit.successRate * 100))%")
            StatRowDivider()
            statRow(icon: "dollarsign.circle", iconColor: .pledgeGreen, label: "Total saved", value: "$\(Int(totalSaved))", valueColor: .pledgeGreen)
            StatRowDivider()
            statRow(icon: "chart.line.uptrend.xyaxis", iconColor: .pledgeViolet, label: "Total invested", value: "$\(Int(totalInvested))", valueColor: .pledgeViolet)
            StatRowDivider()
            statRow(icon: "clock", iconColor: .secondary, label: "Stake", value: "$\(Int(habit.stakeAmount))/day")
            StatRowDivider()
            statRow(icon: "calendar", iconColor: .secondary, label: "Schedule", value: scheduleLabel)
            StatRowDivider()
            statRow(icon: "magnifyingglass", iconColor: .secondary, label: "Verification", value: verificationLabel)
        }
        .cleanCard()
    }

    private func statRow(icon: String, iconColor: Color = .secondary, label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(label)
                .pledgeHeadline()
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .pledgeMono()
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 0) {
            Button { } label: {
                Text("Edit Habit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pledgeBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }

            StatRowDivider()

            Button { } label: {
                Text("Pause Habit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pledgeOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }

            StatRowDivider()

            Button { } label: {
                Text("Delete Habit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pledgeRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .cleanCard()
    }
}
