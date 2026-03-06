import UserNotifications

@MainActor
class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await checkCurrentStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                scheduleWelcomeNotification()
            }
        } catch {
            print("[NotificationManager] Authorization failed: \(error.localizedDescription)")
            isAuthorized = false
        }
    }

    private func checkCurrentStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Welcome Notification

    private func scheduleWelcomeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pledge is active!"
        content.body = "Your habits are being tracked. \u{1F512}"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "welcome", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Habit Reminders

    func scheduleHabitReminders(habits: [Habit]) {
        // Remove old habit reminders before scheduling new ones
        let identifiers = habits.map { "habit-reminder-\($0.id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for habit in habits where habit.isActive && !habit.isPaused {
            let content = UNMutableNotificationContent()
            content.title = "\(habit.icon) Time for \(habit.name)!"
            content.body = "$\(Int(habit.stakeAmount)) on the line. Don't lose your streak!"
            content.sound = .default

            let (hour, minute) = reminderTime(for: habit)

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "habit-reminder-\(habit.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func reminderTime(for habit: Habit) -> (hour: Int, minute: Int) {
        switch habit.type {
        case .wakeUp:
            // 15 min before target time
            let targetHour = Int(habit.targetValue)
            let targetMinute = Int((habit.targetValue - Double(targetHour)) * 60)
            var reminderMinute = targetMinute - 15
            var reminderHour = targetHour
            if reminderMinute < 0 {
                reminderMinute += 60
                reminderHour -= 1
                if reminderHour < 0 { reminderHour = 23 }
            }
            return (reminderHour, reminderMinute)

        case .sleep:
            // 30 min before target bedtime
            let targetHour = Int(habit.targetValue)
            let targetMinute = Int((habit.targetValue - Double(targetHour)) * 60)
            var reminderMinute = targetMinute - 30
            var reminderHour = targetHour
            if reminderMinute < 0 {
                reminderMinute += 60
                reminderHour -= 1
                if reminderHour < 0 { reminderHour = 23 }
            }
            return (reminderHour, reminderMinute)

        case .screenTime, .noSocial:
            return (20, 0) // 8 PM wind down

        case .workout, .gym, .pushups, .pullUps, .jumpingJacks:
            return (8, 0) // 8 AM

        default:
            return (9, 0) // 9 AM default
        }
    }

    // MARK: - Streak Reminder

    func scheduleStreakReminder(streakCount: Int) {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])

        let content = UNMutableNotificationContent()
        if streakCount > 0 {
            content.title = "\u{1F525} Don't break your \(streakCount)-day streak!"
            content.body = "You haven't verified today's habits yet. Open Pledge now."
        } else {
            content.title = "You still have habits to verify today!"
            content.body = "Open Pledge and keep your pledges safe."
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streak-reminder", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Motivational Quote

    func scheduleMotivationalQuote() {
        center.removePendingNotificationRequests(withIdentifiers: ["motivational-quote"])

        let quotes = [
            "Discipline is choosing between what you want now and what you want most.",
            "Small daily improvements are the key to staggering long-term results.",
            "The secret of getting ahead is getting started.",
            "You don't have to be extreme, just consistent.",
            "Success is the sum of small efforts repeated day in and day out.",
            "Your future self will thank you.",
            "Every day is a new chance to get it right.",
        ]

        let content = UNMutableNotificationContent()
        content.title = "\u{1F4AA} Daily Motivation"
        content.body = quotes.randomElement() ?? quotes[0]
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "motivational-quote", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Cancel

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelStreakReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])
    }

    func cancelMotivationalQuote() {
        center.removePendingNotificationRequests(withIdentifiers: ["motivational-quote"])
    }
}
