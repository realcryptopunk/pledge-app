import SwiftUI

struct ConfigureHabitsView: View {
    @Bindable var flowState: SetupFlowState
    @Environment(\.themeColors) var theme

    private var currentType: HabitType {
        flowState.selectedTypes[flowState.configPageIndex]
    }

    private var currentConfig: Binding<HabitSetupConfig> {
        Binding(
            get: { flowState.configs[currentType] ?? HabitSetupConfig(type: currentType) },
            set: { flowState.configs[currentType] = $0 }
        )
    }

    private let dayLabels: [(Int, String)] = [
        (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S"), (7, "S")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar
            HStack {
                Button {
                    PPHaptic.light()
                    if flowState.configPageIndex > 0 {
                        withAnimation(.springBounce) {
                            flowState.configPageIndex -= 1
                        }
                    } else {
                        flowState.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("Habit \(flowState.configPageIndex + 1) of \(flowState.selectedTypes.count)")
                    .pledgeHeadline()
                    .foregroundColor(.primary)

                Spacer()

                // Invisible spacer for alignment
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Progress bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [theme.buttonTop, theme.buttonBottom],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progressFraction)
                            .animation(.springBounce, value: flowState.configPageIndex)
                    }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)

            // MARK: - Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Habit icon + name
                    VStack(spacing: 12) {
                        Text(currentType.defaultIcon)
                            .font(.system(size: 56))
                            .frame(width: 96, height: 96)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [currentType.accentColor.opacity(0.4), currentType.accentColor.opacity(0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .clipShape(Circle())

                        Text(currentType.rawValue)
                            .pledgeTitle()
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 16)

                    // Config card
                    configSection
                        .cleanCard()

                    // Schedule section
                    scheduleSection
                        .cleanCard()

                    // Verification info
                    verificationPill

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
            }

            // MARK: - Bottom Button
            Button {
                PPHaptic.medium()
                if flowState.configPageIndex < flowState.selectedTypes.count - 1 {
                    withAnimation(.springBounce) {
                        flowState.configPageIndex += 1
                    }
                } else {
                    flowState.goForward()
                }
            } label: {
                Text(flowState.configPageIndex < flowState.selectedTypes.count - 1 ? "Next \u{2192}" : "Set Stakes \u{2192}")
            }
            .buttonStyle(PrimaryCapsuleStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Progress

    private var progressFraction: CGFloat {
        let total = flowState.selectedTypes.count
        guard total > 0 else { return 0 }
        return CGFloat(flowState.configPageIndex + 1) / CGFloat(total)
    }

    // MARK: - Config Section

    @ViewBuilder
    private var configSection: some View {
        if currentType.usesTimePicker {
            timePickerSection
        } else if let presets = currentType.durationPresets {
            durationPresetsSection(presets: presets)
        } else if currentType.targetConfig != nil {
            stepperSection
        } else {
            manualConfirmSection
        }
    }

    // MARK: - Time Picker (wakeUp / sleep)

    private var timePickerSection: some View {
        VStack(spacing: 8) {
            Text(currentType == .sleep ? "I'll sleep by" : "Wake up by")
                .pledgeCallout()
                .foregroundColor(.primary)

            HStack(spacing: 4) {
                let hourRange = currentType == .sleep ? 8..<13 : 3..<13
                Picker("Hour", selection: currentConfig.targetTimeHour) {
                    ForEach(hourRange, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 120)
                .clipped()

                Text(":")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Picker("Minute", selection: currentConfig.targetTimeMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 120)
                .clipped()

                Text(currentType == .sleep ? "PM" : "AM")
                    .fixedSize()
                    .pledgeHeadline()
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Duration Presets (workout, meditate, read)

    private func durationPresetsSection(presets: [Double]) -> some View {
        VStack(spacing: 12) {
            Text(currentType.targetConfig?.label ?? "Duration")
                .pledgeCallout()
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { value in
                    Button {
                        PPHaptic.light()
                        withAnimation(.quickSnap) {
                            currentConfig.wrappedValue.targetValue = value
                        }
                    } label: {
                        Text("\(Int(value)) min")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(currentConfig.wrappedValue.targetValue == value ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(currentConfig.wrappedValue.targetValue == value
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(currentConfig.wrappedValue.targetValue == value ? 0.3 : 0.1), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stepper (steps, screenTime, water)

    private var stepperSection: some View {
        let config = currentType.targetConfig!

        return VStack(spacing: 8) {
            Text(config.label)
                .pledgeCallout()
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                Button {
                    PPHaptic.light()
                    if currentConfig.wrappedValue.targetValue > config.min {
                        withAnimation(.quickSnap) {
                            currentConfig.wrappedValue.targetValue -= config.step
                        }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(currentConfig.wrappedValue.targetValue > config.min ? theme.surface : .secondary.opacity(0.3))
                }

                Text("\(Int(currentConfig.wrappedValue.targetValue))")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .embossed(.raised)
                    .contentTransition(.numericText())
                    .frame(minWidth: 80)

                Button {
                    PPHaptic.light()
                    if currentConfig.wrappedValue.targetValue < config.max {
                        withAnimation(.quickSnap) {
                            currentConfig.wrappedValue.targetValue += config.step
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(currentConfig.wrappedValue.targetValue < config.max ? theme.surface : .secondary.opacity(0.3))
                }
            }

            Text(config.unit)
                .pledgeCaption()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Manual Confirm (coldShower, journal, noJunkFood)

    private var manualConfirmSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.buttonTop, theme.buttonBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("Just do it")
                .pledgeHeadline()
                .foregroundColor(.primary)

            Text("We'll ask you to verify daily")
                .pledgeCallout()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHICH DAYS?")
                .pledgeCaption()
                .foregroundColor(.secondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(dayLabels, id: \.0) { day, label in
                    Button {
                        PPHaptic.selection()
                        withAnimation(.quickSnap) {
                            if currentConfig.wrappedValue.schedule.contains(day) {
                                currentConfig.wrappedValue.schedule.remove(day)
                            } else {
                                currentConfig.wrappedValue.schedule.insert(day)
                            }
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(currentConfig.wrappedValue.schedule.contains(day) ? .white : .primary)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(currentConfig.wrappedValue.schedule.contains(day)
                                          ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(currentConfig.wrappedValue.schedule.contains(day) ? Color.white.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .clipShape(Circle())
                    }
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                quickScheduleButton("Daily", days: Set(1...7))
                quickScheduleButton("Weekdays", days: Set(1...5))
                quickScheduleButton("Weekends", days: [6, 7])
            }
        }
    }

    private func quickScheduleButton(_ title: String, days: Set<Int>) -> some View {
        Button {
            PPHaptic.selection()
            withAnimation(.quickSnap) {
                currentConfig.wrappedValue.schedule = days
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(currentConfig.wrappedValue.schedule == days ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(currentConfig.wrappedValue.schedule == days
                              ? LinearGradient(colors: [theme.buttonTop, theme.buttonBottom], startPoint: .top, endPoint: .bottom)
                              : LinearGradient(colors: [Color.primary.opacity(0.06), Color.primary.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(currentConfig.wrappedValue.schedule == days ? 0.3 : 0.08), lineWidth: 0.5)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Verification Pill

    private var verificationPill: some View {
        HStack(spacing: 8) {
            Image(systemName: currentType.verificationIcon)
                .font(.system(size: 12))
            Text("Verified via: \(currentType.verificationLabel)")
                .pledgeCallout()
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .flatCard()
    }
}
