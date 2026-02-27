import SwiftUI
import MapKit

// MARK: - Page State

enum CelebrationPage: Equatable {
    case form, celebration, streak
}

struct AddHabitView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) var theme

    // MARK: - Page State

    @State private var currentPage: CelebrationPage = .form
    @State private var createdHabit: Habit?
    @State private var isFirstPledge = false

    // MARK: - Form State

    @State private var habitName = ""
    @State private var selectedIcon = "🏃"
    @State private var selectedType: HabitType = .workout
    @State private var selectedVerification: VerificationType = .manual
    @State private var targetValue: Double = 30
    @State private var targetTimeHour: Int = 6
    @State private var targetTimeMinute: Int = 0
    @State private var stakeAmountString = "10"
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    // MARK: - Location State

    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var locationRadius: Double? = 150
    @State private var locationName: String?
    @State private var showLocationPicker = false

    // MARK: - Icon Data

    private let iconCategories: [(String, [String])] = [
        ("Fitness", ["🏃", "💪", "🏋️", "🧘", "🚴", "🏊"]),
        ("Health", ["💤", "💧", "🥗", "🧊", "💊", "🫁"]),
        ("Mind", ["📚", "🧠", "📝", "🎯", "⏰", "📵"])
    ]

    // MARK: - Day Labels

    private let dayLabels: [(Int, String)] = [
        (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S"), (7, "S")
    ]

    // MARK: - Computed

    private var stakeAmount: Double {
        Double(stakeAmountString) ?? 0
    }

    private var canCreate: Bool {
        !habitName.trimmingCharacters(in: .whitespaces).isEmpty
        && !selectedDays.isEmpty
        && stakeAmount >= 1
        && (selectedVerification != .location || locationLatitude != nil)
    }

    private var resolvedTargetValue: Double {
        switch selectedType {
        case .wakeUp:
            return Double(targetTimeHour) + Double(targetTimeMinute) / 60.0
        default:
            return targetValue
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch currentPage {
            case .form:
                formView
                    .transition(.slideBack)
            case .celebration:
                if let habit = createdHabit {
                    PledgeCelebrationView(habit: habit, isFirstPledge: isFirstPledge) {
                        withAnimation(.springBounce) { currentPage = .streak }
                    }
                    .transition(.slideIn)
                }
            case .streak:
                if let habit = createdHabit {
                    PledgeStreakStartView(
                        habit: habit,
                        totalPledgeCount: appState.habits.count,
                        onAddAnother: {
                            resetForm()
                            withAnimation(.springBounce) { currentPage = .form }
                        },
                        onDone: { dismiss() }
                    )
                    .transition(.slideIn)
                }
            }
        }
        .animation(.springBounce, value: currentPage)
    }

    // MARK: - Form View

    private var formView: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        nameAndIconSection
                        habitTypeSection
                        verificationSection
                        if selectedVerification == .location {
                            locationSection
                        }
                        targetValueSection
                        stakeAmountSection
                        scheduleSection
                        createButton
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("New Pledge")
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
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    latitude: $locationLatitude,
                    longitude: $locationLongitude,
                    radius: $locationRadius,
                    locationName: $locationName
                )
            }
        }
    }

    // MARK: - Name & Icon Section

    private var nameAndIconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NAME & ICON")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            TextField("Habit name", text: $habitName)
                .pledgeHeadline()
                .foregroundColor(.primary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )

            ForEach(iconCategories, id: \.0) { category, icons in
                VStack(alignment: .leading, spacing: 6) {
                    Text(category)
                        .pledgeCaption()
                        .foregroundColor(.secondary.opacity(0.7))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    PPHaptic.selection()
                                    withAnimation(.quickSnap) {
                                        selectedIcon = icon
                                    }
                                } label: {
                                    Text(icon)
                                        .font(.system(size: 24))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(selectedIcon == icon
                                                      ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                                      : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(selectedIcon == icon ? Color.white.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .cleanCard()
    }

    // MARK: - Habit Type Section

    private var habitTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HABIT TYPE")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(HabitType.allCases, id: \.self) { type in
                    Button {
                        PPHaptic.selection()
                        withAnimation(.quickSnap) {
                            selectedType = type
                            selectedVerification = defaultVerification(for: type)
                            targetValue = defaultTargetValue(for: type)
                        }
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedType == type ? .white : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(selectedType == type
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedType == type ? Color.white.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .cleanCard()
    }

    // MARK: - Verification Section

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VERIFICATION")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            ForEach(availableVerifications(for: selectedType), id: \.self) { method in
                Button {
                    PPHaptic.selection()
                    withAnimation(.quickSnap) {
                        selectedVerification = method
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: verificationIcon(for: method))
                            .font(.system(size: 16))
                            .foregroundColor(selectedVerification == method ? theme.surface : .secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(verificationTitle(for: method))
                                .pledgeCallout()
                                .foregroundColor(.primary)
                            Text(verificationDescription(for: method))
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: selectedVerification == method ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(selectedVerification == method ? theme.surface : .secondary.opacity(0.4))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .cleanCard()
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LOCATION")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            if let lat = locationLatitude, let lng = locationLongitude {
                // Location is set — show name, map preview, and change button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.surface)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationName ?? "Selected Location")
                                .pledgeHeadline()
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text("\(Int(locationRadius ?? 150))m radius")
                                .pledgeCaption()
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // Map preview
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    let previewRadius = locationRadius ?? 150

                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coord,
                        latitudinalMeters: max(previewRadius * 4, 1000),
                        longitudinalMeters: max(previewRadius * 4, 1000)
                    ))) {
                        Annotation("", coordinate: coord) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.surface)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }

                        MapCircle(center: coord, radius: previewRadius)
                            .foregroundStyle(theme.surface.opacity(0.15))
                            .stroke(theme.surface.opacity(0.4), lineWidth: 1.5)
                    }
                    .mapStyle(.standard(elevation: .flat))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .allowsHitTesting(false)

                    Button {
                        PPHaptic.selection()
                        showLocationPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text("Change Location")
                        }
                    }
                    .buttonStyle(GhostButtonStyle())
                }
            } else {
                // No location set — show set location button
                Button {
                    PPHaptic.selection()
                    showLocationPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(theme.surface)

                        Text("Set Location")
                            .pledgeCallout()
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .cleanCard()
    }

    // MARK: - Target Value Section

    private var targetValueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TARGET")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            if selectedType == .wakeUp {
                wakeUpTimePicker
            } else if let config = targetConfig(for: selectedType) {
                VStack(spacing: 8) {
                    Text(config.label)
                        .pledgeCallout()
                        .foregroundColor(.primary)

                    HStack(spacing: 16) {
                        Button {
                            PPHaptic.light()
                            if targetValue > config.min {
                                withAnimation(.quickSnap) {
                                    targetValue -= config.step
                                }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(targetValue > config.min ? theme.surface : .secondary.opacity(0.3))
                        }

                        Text("\(Int(targetValue))")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .embossed(.raised)
                            .contentTransition(.numericText())
                            .frame(minWidth: 80)

                        Button {
                            PPHaptic.light()
                            if targetValue < config.max {
                                withAnimation(.quickSnap) {
                                    targetValue += config.step
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(targetValue < config.max ? theme.surface : .secondary.opacity(0.3))
                        }
                    }

                    Text(config.unit)
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("No target needed for this habit")
                    .pledgeCallout()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .cleanCard()
    }

    private var wakeUpTimePicker: some View {
        VStack(spacing: 8) {
            Text("Wake up by")
                .pledgeCallout()
                .foregroundColor(.primary)

            HStack(spacing: 4) {
                Picker("Hour", selection: $targetTimeHour) {
                    ForEach(3..<13, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 120)
                .clipped()

                Text(":")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Picker("Minute", selection: $targetTimeMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 120)
                .clipped()

                Text("AM")
                    .pledgeHeadline()
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stake Amount Section

    private var stakeAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STAKE")
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

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            createHabit()
        } label: {
            Text("Create Pledge")
        }
        .buttonStyle(PrimaryCapsuleStyle(isEnabled: canCreate))
        .disabled(!canCreate)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func createHabit() {
        let habit = Habit(
            name: habitName.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            type: selectedType,
            stakeAmount: min(max(stakeAmount, 1), 100),
            schedule: Array(selectedDays).sorted(),
            targetValue: resolvedTargetValue,
            verificationType: selectedVerification,
            isActive: true,
            currentStreak: 0,
            successRate: 0,
            locationLatitude: selectedVerification == .location ? locationLatitude : nil,
            locationLongitude: selectedVerification == .location ? locationLongitude : nil,
            locationRadius: selectedVerification == .location ? locationRadius : nil,
            locationName: selectedVerification == .location ? locationName : nil
        )
        isFirstPledge = appState.habits.isEmpty
        appState.addHabit(habit)
        createdHabit = habit
        withAnimation(.springBounce) { currentPage = .celebration }
    }

    private func resetForm() {
        habitName = ""
        selectedIcon = "🏃"
        selectedType = .workout
        selectedVerification = .manual
        targetValue = 30
        targetTimeHour = 6
        targetTimeMinute = 0
        stakeAmountString = "10"
        selectedDays = Set(1...7)
        createdHabit = nil
        isFirstPledge = false
        locationLatitude = nil
        locationLongitude = nil
        locationRadius = 150
        locationName = nil
        showLocationPicker = false
    }

    // MARK: - Helpers

    private func defaultVerification(for type: HabitType) -> VerificationType {
        switch type {
        case .steps, .sleep, .workout:
            return .healthKit
        case .screenTime:
            return .manual
        case .wakeUp:
            return .manual
        default:
            return .manual
        }
    }

    private func availableVerifications(for type: HabitType) -> [VerificationType] {
        switch type {
        case .steps, .sleep:
            return [.healthKit, .manual]
        case .workout:
            return [.healthKit, .location, .manual]
        case .screenTime:
            return [.manual]
        case .wakeUp:
            return [.manual]
        case .meditate, .read, .journal:
            return [.manual]
        case .coldShower:
            return [.manual, .photo]
        case .noJunkFood:
            return [.location, .manual]
        case .noSocial:
            return [.manual]
        case .water:
            return [.manual]
        }
    }

    private func verificationIcon(for method: VerificationType) -> String {
        switch method {
        case .healthKit: return "heart.fill"
        case .manual: return "hand.tap.fill"
        case .photo: return "camera.fill"
        case .location: return "location.fill"
        case .screenTimeAPI: return "hourglass"
        case .auto: return "gearshape.fill"
        case .inApp: return "iphone"
        }
    }

    private func verificationTitle(for method: VerificationType) -> String {
        switch method {
        case .healthKit: return "Apple Health"
        case .manual: return "Manual"
        case .photo: return "Photo Proof"
        case .location: return "Location"
        case .screenTimeAPI: return "Screen Time"
        case .auto: return "Automatic"
        case .inApp: return "In-App"
        }
    }

    private func verificationDescription(for method: VerificationType) -> String {
        switch method {
        case .healthKit: return "Automatic via Apple Health"
        case .manual: return "Self-report daily"
        case .photo: return "Upload a photo to verify"
        case .location: return "Auto-verify by GPS location"
        case .screenTimeAPI: return "Reads Screen Time data"
        case .auto: return "Verified automatically"
        case .inApp: return "Track within the app"
        }
    }

    private struct TargetConfig {
        let label: String
        let unit: String
        let min: Double
        let max: Double
        let step: Double
    }

    private func targetConfig(for type: HabitType) -> TargetConfig? {
        switch type {
        case .steps:
            return TargetConfig(label: "Daily step goal", unit: "steps", min: 1000, max: 50000, step: 1000)
        case .sleep:
            return TargetConfig(label: "Hours of sleep", unit: "hours", min: 4, max: 12, step: 1)
        case .workout:
            return TargetConfig(label: "Workout duration", unit: "minutes", min: 10, max: 120, step: 5)
        case .screenTime:
            return TargetConfig(label: "Max screen time", unit: "hours", min: 1, max: 12, step: 1)
        case .water:
            return TargetConfig(label: "Glasses of water", unit: "glasses", min: 1, max: 20, step: 1)
        case .meditate:
            return TargetConfig(label: "Meditation duration", unit: "minutes", min: 5, max: 60, step: 5)
        case .read:
            return TargetConfig(label: "Reading time", unit: "minutes", min: 5, max: 120, step: 5)
        default:
            return nil
        }
    }

    private func defaultTargetValue(for type: HabitType) -> Double {
        switch type {
        case .steps: return 10000
        case .sleep: return 7
        case .workout: return 30
        case .screenTime: return 2
        case .water: return 8
        case .meditate: return 10
        case .read: return 30
        default: return 0
        }
    }
}

#Preview {
    AddHabitView()
        .environmentObject(AppState())
}
