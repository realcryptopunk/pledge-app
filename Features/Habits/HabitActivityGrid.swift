import SwiftUI

// MARK: - Activity Grid (GitHub-style contribution graph)

struct HabitActivityGrid: View {
    let habit: Habit
    @Environment(\.themeColors) var theme

    private let columns = 15 // weeks to show
    private let rows = 7    // days per week (Mon-Sun)
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3

    // Generate deterministic mock data from habit properties
    private var activityData: [[DayStatus]] {
        var grid: [[DayStatus]] = []
        let seed = habit.name.hashValue
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))

        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...
        // Convert to Mon=0 index
        let todayDayIndex = (todayWeekday + 5) % 7

        for week in 0..<columns {
            var weekData: [DayStatus] = []
            for day in 0..<rows {
                // Check if this cell is in the future
                let weeksAgo = columns - 1 - week
                let daysFromToday = weeksAgo * 7 + (todayDayIndex - day)

                if daysFromToday < 0 {
                    // Future day
                    weekData.append(.future)
                } else if daysFromToday == 0 {
                    // Today
                    weekData.append(.today)
                } else {
                    // Check if this day is in the habit's schedule
                    // schedule uses 1=Mon(0), 7=Sun(6)
                    let scheduleDay = day + 1
                    if habit.schedule.contains(scheduleDay) {
                        let roll = rng.next() % 100
                        let successThreshold = UInt64(habit.successRate * 100)
                        if roll < successThreshold {
                            weekData.append(.verified)
                        } else {
                            weekData.append(.failed)
                        }
                    } else {
                        weekData.append(.off)
                    }
                }
            }
            grid.append(weekData)
        }
        return grid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Day labels + Grid
            HStack(alignment: .top, spacing: cellSpacing) {
                // Day labels
                VStack(spacing: cellSpacing) {
                    ForEach(["M","T","W","T","F","S","S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                            .frame(width: 14, height: cellSize)
                    }
                }

                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<activityData.count, id: \.self) { week in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<activityData[week].count, id: \.self) { day in
                                    cellView(for: activityData[week][day])
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Legend
            HStack(spacing: 12) {
                Spacer()
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                    legendCell(opacity: 0.0)
                    legendCell(opacity: 0.3)
                    legendCell(opacity: 0.6)
                    legendCell(opacity: 1.0)
                    Text("More")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.pledgeRed.opacity(0.7))
                        .frame(width: 10, height: 10)
                    Text("Missed")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(for status: DayStatus) -> some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(cellColor(for: status))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                status == .today
                    ? RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .stroke(theme.surface, lineWidth: 1.5)
                    : nil
            )
    }

    private func cellColor(for status: DayStatus) -> Color {
        switch status {
        case .verified:
            return Color.pledgeGreen.opacity(0.85)
        case .failed:
            return Color.pledgeRed.opacity(0.7)
        case .off:
            return Color.primary.opacity(0.04)
        case .future:
            return Color.primary.opacity(0.04)
        case .today:
            return theme.surface.opacity(0.3)
        }
    }

    @ViewBuilder
    private func legendCell(opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(opacity == 0 ? Color.primary.opacity(0.06) : Color.pledgeGreen.opacity(opacity))
            .frame(width: 10, height: 10)
    }
}

// MARK: - Day Status

enum DayStatus {
    case verified
    case failed
    case off     // not scheduled
    case future
    case today
}

// MARK: - Seeded RNG for deterministic mock data

struct SeededRNG {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
