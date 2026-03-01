import SwiftUI

struct EditHabitView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    let habit: Habit

    // MARK: - Form State

    @State private var stakeAmountString: String
    @State private var selectedDays: Set<Int>
    @State private var showSaved = false

    private let dayLabels: [(Int, String)] = [
        (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S"), (7, "S")
    ]

    private var stakeAmount: Double {
        Double(stakeAmountString) ?? 0
    }

    private var canSave: Bool {
        !selectedDays.isEmpty && stakeAmount >= 1
    }

    private var hasChanges: Bool {
        stakeAmount != habit.stakeAmount || Set(habit.schedule) != selectedDays
    }

    // MARK: - Init

    init(habit: Habit) {
        self.habit = habit
        _stakeAmountString = State(initialValue: "\(Int(habit.stakeAmount))")
        _selectedDays = State(initialValue: Set(habit.schedule))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Habit header
                        habitHeader

                        // Stake amount
                        stakeSection

                        // Schedule
                        scheduleSection

                        // Save button
                        saveButton

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // Success overlay
                if showSaved {
                    savedOverlay
                }
            }
            .navigationTitle("Edit Pledge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: - Habit Header

    private var habitHeader: some View {
        HStack(spacing: 12) {
            Text(habit.icon)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .pledgeTitle()
                    .foregroundColor(.primary)
                Text(habit.type.rawValue)
                    .pledgeCaption()
                    .foregroundColor(.secondary)
            }

            Spacer()

            if habit.isPaused {
                Text("PAUSED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.pledgeOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.pledgeOrange.opacity(0.15))
                    )
            }
        }
        .cleanCard()
    }

    // MARK: - Stake Section

    private var stakeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STAKE AMOUNT")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("$")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(stakeAmountString.isEmpty ? "0" : stakeAmountString)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(stakeAmountString.isEmpty ? .secondary.opacity(0.3) : .primary)
                        .embossed(.raised)
                        .contentTransition(.numericText())
                        .animation(.quickSnap, value: stakeAmountString)

                    Text("/day")
                        .pledgeCallout()
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                }

                HStack(spacing: 10) {
                    ForEach(["1", "5", "10", "25"], id: \.self) { preset in
                        Button {
                            PPHaptic.light()
                            withAnimation(.quickSnap) {
                                stakeAmountString = preset
                            }
                        } label: {
                            Text("$\(preset)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(stakeAmountString == preset ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(stakeAmountString == preset
                                              ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                              : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.primary.opacity(stakeAmountString == preset ? 0.3 : 0.1), lineWidth: 0.5)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }

                NumberPadView(value: $stakeAmountString, maxDigits: 3, allowDecimal: false)
            }
            .frame(maxWidth: .infinity)
        }
        .cleanCard()
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SCHEDULE")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(dayLabels, id: \.0) { day, label in
                    Button {
                        PPHaptic.selection()
                        withAnimation(.quickSnap) {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(selectedDays.contains(day)
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(selectedDays.contains(day) ? Color.white.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .clipShape(Circle())
                    }
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                quickScheduleButton("Every day", days: Set(1...7))
                quickScheduleButton("Weekdays", days: Set(1...5))
                quickScheduleButton("Weekends", days: [6, 7])
            }
        }
        .cleanCard()
    }

    private func quickScheduleButton(_ title: String, days: Set<Int>) -> some View {
        Button {
            PPHaptic.selection()
            withAnimation(.quickSnap) {
                selectedDays = days
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selectedDays == days ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selectedDays == days
                              ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                              : LinearGradient(colors: [Color.primary.opacity(0.06), Color.primary.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(selectedDays == days ? 0.3 : 0.08), lineWidth: 0.5)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            Text(hasChanges ? "Save Changes" : "No Changes")
        }
        .buttonStyle(PrimaryCapsuleStyle(isEnabled: canSave && hasChanges))
        .disabled(!canSave || !hasChanges)
        .padding(.top, 8)
    }

    // MARK: - Saved Overlay

    private var savedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.pledgeGreen)

            Text("Changes saved!")
                .pledgeHeadline()
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
    }

    // MARK: - Actions

    private func saveChanges() {
        var updated = habit
        updated.stakeAmount = min(max(stakeAmount, 1), 999)
        updated.schedule = Array(selectedDays).sorted()

        PPHaptic.success()
        appState.updateHabit(updated)

        withAnimation(.springBounce) {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}
