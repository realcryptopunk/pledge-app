import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("streakRemindersEnabled") private var streakRemindersEnabled = true
    @AppStorage("motivationalQuotesEnabled") private var motivationalQuotesEnabled = false

    // Per-habit custom times stored as JSON in UserDefaults
    @State private var habitReminderTimes: [UUID: Date] = [:]

    private let notifications = NotificationManager.shared

    var body: some View {
        ZStack {
            WaterBackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Global Toggle
                    section("NOTIFICATIONS") {
                        toggleRow(
                            icon: "bell.fill",
                            label: "Enable Notifications",
                            isOn: $notificationsEnabled
                        )
                    }

                    if notificationsEnabled {
                        // MARK: - Reminder Types
                        section("REMINDER TYPES") {
                            toggleRow(
                                icon: "flame.fill",
                                label: "Streak Reminders",
                                subtitle: "Evening reminder if you haven't verified",
                                isOn: $streakRemindersEnabled
                            )
                            StatRowDivider()
                            toggleRow(
                                icon: "quote.opening",
                                label: "Motivational Quotes",
                                subtitle: "Daily inspiration at 7 AM",
                                isOn: $motivationalQuotesEnabled
                            )
                        }

                        // MARK: - Per-Habit Times
                        let activeHabits = appState.habits.filter { $0.isActive && !$0.isPaused }
                        if !activeHabits.isEmpty {
                            section("HABIT REMINDERS") {
                                ForEach(Array(activeHabits.enumerated()), id: \.element.id) { index, habit in
                                    if index > 0 {
                                        StatRowDivider()
                                    }
                                    habitTimeRow(habit: habit)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Notifications")
        .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
        .onAppear { loadHabitTimes() }
        .onChange(of: notificationsEnabled) { _, enabled in
            if enabled {
                applyAllSettings()
            } else {
                notifications.cancelAllReminders()
            }
        }
        .onChange(of: streakRemindersEnabled) { _, enabled in
            if enabled {
                notifications.scheduleStreakReminder(streakCount: appState.streakCount)
            } else {
                notifications.cancelStreakReminder()
            }
        }
        .onChange(of: motivationalQuotesEnabled) { _, enabled in
            if enabled {
                notifications.scheduleMotivationalQuote()
            } else {
                notifications.cancelMotivationalQuote()
            }
        }
    }

    // MARK: - Habit Time Row

    private func habitTimeRow(habit: Habit) -> some View {
        HStack(spacing: 12) {
            Text(habit.icon)
            Text(habit.name)
                .pledgeHeadline()
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            DatePicker(
                "",
                selection: binding(for: habit),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(theme.light)
        }
        .padding(.vertical, 6)
    }

    private func binding(for habit: Habit) -> Binding<Date> {
        Binding(
            get: {
                habitReminderTimes[habit.id] ?? defaultDate(for: habit)
            },
            set: { newValue in
                habitReminderTimes[habit.id] = newValue
                saveHabitTimes()
                notifications.scheduleHabitReminders(habits: appState.habits)
            }
        )
    }

    private func defaultDate(for habit: Habit) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        switch habit.type {
        case .wakeUp:
            let h = Int(habit.targetValue)
            let m = Int((habit.targetValue - Double(h)) * 60) - 15
            components.hour = m < 0 ? h - 1 : h
            components.minute = m < 0 ? m + 60 : m
        case .sleep:
            let h = Int(habit.targetValue)
            let m = Int((habit.targetValue - Double(h)) * 60) - 30
            components.hour = m < 0 ? h - 1 : h
            components.minute = m < 0 ? m + 60 : m
        case .screenTime:
            components.hour = 20; components.minute = 0
        case .workout, .gym, .pushups, .pullUps, .jumpingJacks:
            components.hour = 8; components.minute = 0
        default:
            components.hour = 9; components.minute = 0
        }
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Persistence

    private static let habitTimesKey = "habitReminderTimes"

    private func loadHabitTimes() {
        guard let data = UserDefaults.standard.data(forKey: Self.habitTimesKey),
              let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else { return }
        var times: [UUID: Date] = [:]
        for (key, value) in decoded {
            if let uuid = UUID(uuidString: key) {
                times[uuid] = value
            }
        }
        habitReminderTimes = times
    }

    private func saveHabitTimes() {
        var dict: [String: Date] = [:]
        for (uuid, date) in habitReminderTimes {
            dict[uuid.uuidString] = date
        }
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: Self.habitTimesKey)
        }
    }

    private func applyAllSettings() {
        notifications.scheduleHabitReminders(habits: appState.habits)
        if streakRemindersEnabled {
            notifications.scheduleStreakReminder(streakCount: appState.streakCount)
        }
        if motivationalQuotesEnabled {
            notifications.scheduleMotivationalQuote()
        }
    }

    // MARK: - Helpers

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            VStack(spacing: 0) {
                content()
            }
            .cleanCard()
        }
    }

    private func toggleRow(icon: String, label: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.light)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .pledgeHeadline()
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(theme.light)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environmentObject(AppState())
}
