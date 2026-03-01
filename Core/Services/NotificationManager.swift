import UserNotifications

@MainActor
class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {
        Task { await checkCurrentStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("[NotificationManager] Authorization failed: \(error.localizedDescription)")
            isAuthorized = false
        }
    }

    private func checkCurrentStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
}
