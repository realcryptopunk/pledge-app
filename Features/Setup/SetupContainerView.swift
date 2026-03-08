import SwiftUI

struct SetupContainerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme
    @State private var flowState = SetupFlowState()

    var body: some View {
        ZStack {
            WaterBackgroundView()

            Group {
                switch flowState.currentStep {
                case .chooseHabits:
                    ChooseHabitsView(flowState: flowState)
                case .configureHabits:
                    ConfigureHabitsView(flowState: flowState)
                case .setStakes:
                    SetStakesView(flowState: flowState)
                case .riskProfile:
                    RiskProfileView(flowState: flowState)
                case .deposit:
                    SetupDepositView(flowState: flowState)
                case .permissions:
                    PermissionsView(flowState: flowState)
                case .success:
                    SetupSuccessView(flowState: flowState) {
                        commitSetup()
                    }
                }
            }
            .transition(flowState.isNavigatingForward ? .slideIn : .slideBack)
        }
        .animation(.springBounce, value: flowState.currentStep)
    }

    // MARK: - Commit Setup

    private func commitSetup() {
        for type in flowState.selectedTypes {
            guard let config = flowState.configs[type] else { continue }

            let targetValue: Double
            if type.usesTimePicker {
                targetValue = Double(config.targetTimeHour) + Double(config.targetTimeMinute) / 60.0
            } else {
                targetValue = config.targetValue
            }

            let habit = Habit(
                name: type.rawValue,
                icon: type.defaultIcon,
                type: type,
                stakeAmount: config.stakeAmount,
                schedule: Array(config.schedule).sorted(),
                targetValue: targetValue,
                verificationType: type.defaultVerification,
                isActive: true,
                currentStreak: 0,
                successRate: 0
            )
            appState.addHabit(habit)
        }

        appState.riskProfile = flowState.selectedRiskProfile
        appState.vaultBalance = flowState.depositAmount
        appState.hasCompletedSetup = true

        // Schedule notifications for the newly created habits
        NotificationManager.shared.scheduleHabitReminders(habits: appState.habits)
        NotificationManager.shared.scheduleStreakReminder(streakCount: 0)
    }
}
