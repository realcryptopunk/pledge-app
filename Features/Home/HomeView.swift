import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Header
                headerSection
                
                // MARK: - Orbs + Add Funds
                orbSection
                
                // MARK: - Today's Pledges (Blue Card)
                todayPledgesCard
                
                // MARK: - Habit List
                habitListSection
                
                // MARK: - Streak + Pool Cards
                statCardsRow
                
                // MARK: - Recent Activity
                recentActivitySection
                
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.pledgeBgAdaptive)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Balance")
                    .pledgeCaption()
                    .foregroundColor(.pledgeGray)
                
                Text("$\(appState.vaultBalance, specifier: "%.2f")")
                    .pledgeHero(56)
                    .foregroundColor(.pledgeBlackAdaptive)
                    .contentTransition(.numericText())
                
                Text("+\(appState.todayChangePercent, specifier: "%.1f")% this month")
                    .pledgeCaption()
                    .foregroundColor(.pledgeGreen)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button { } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(.pledgeBlackAdaptive)
                }
                
                Button { } label: {
                    Image(systemName: "person.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.pledgeBlackAdaptive)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Floating Orbs
    
    private var orbSection: some View {
        ZStack {
            FloatingOrbsView(height: 160)
            
            Button {
                PPHaptic.medium()
            } label: {
                Text("Add funds")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.pledgeBlackAdaptive)
                    .clipShape(Capsule())
            }
        }
        .frame(height: 160)
    }
    
    // MARK: - Today's Pledges Card
    
    private var todayPledgesCard: some View {
        Button { } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Pledges")
                        .pledgeHeadline()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Text("$\(appState.todayStakeTotal, specifier: "%.2f")")
                    .pledgeDisplay(36)
                    .contentTransition(.numericText())
                
                HStack(spacing: 24) {
                    Label("At stake", systemImage: "chart.bar.fill")
                        .pledgeCaption()
                    Spacer()
                    Text("$\(appState.todayStakeTotal, specifier: "%.2f")")
                        .pledgeMonoSmall()
                }
                
                HStack(spacing: 24) {
                    Label("Verified", systemImage: "checkmark.circle.fill")
                        .pledgeCaption()
                    Spacer()
                    Text("\(appState.todayVerifiedCount) of \(appState.todayHabits.count)")
                        .pledgeMonoSmall()
                }
            }
            .accentCard(.pledgeBlue)
        }
        .buttonStyle(.plain)
        .cardPress()
    }
    
    // MARK: - Habit List
    
    private var habitListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY")
                .pledgeCaption()
                .foregroundColor(.pledgeGray)
                .tracking(1)
            
            VStack(spacing: 0) {
                ForEach(Array(appState.todayHabits.enumerated()), id: \.element.id) { index, todayHabit in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.pledgeGrayLight)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                    }
                    
                    HabitRowView(todayHabit: todayHabit)
                        .staggerIn(index: index)
                }
            }
            .cleanCard()
        }
    }
    
    // MARK: - Stat Cards
    
    private var statCardsRow: some View {
        HStack(spacing: 12) {
            // Streak card (orange)
            Button { } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 Streak")
                        .pledgeCaption()
                    Spacer()
                    Text("\(appState.streakCount)")
                        .pledgeDisplay(32)
                        .contentTransition(.numericText())
                    Text("days")
                        .pledgeCaption()
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accentCard(.pledgeOrange)
            }
            .buttonStyle(.plain)
            .cardPress()
            
            // Pool card (violet)
            Button { } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💰 Pool")
                        .pledgeCaption()
                    Spacer()
                    Text("$\(Int(appState.investmentPoolValue))")
                        .pledgeDisplay(32)
                        .contentTransition(.numericText())
                    Text("+\(appState.investmentGrowth, specifier: "%.1f")%")
                        .pledgeCaption()
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accentCard(.pledgeViolet)
            }
            .buttonStyle(.plain)
            .cardPress()
        }
        .frame(height: 130)
    }
    
    // MARK: - Recent Activity
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT")
                .pledgeCaption()
                .foregroundColor(.pledgeGray)
                .tracking(1)
            
            VStack(spacing: 0) {
                ForEach(Array(appState.recentActivity.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.pledgeGrayLight)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                    }
                    
                    HStack(spacing: 12) {
                        Text(item.icon)
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .pledgeCallout()
                                .foregroundColor(.pledgeBlackAdaptive)
                            Text(item.detail)
                                .pledgeCaption()
                                .foregroundColor(item.isFailure ? .pledgeRed : .pledgeGreen)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .staggerIn(index: index)
                }
            }
            .cleanCard()
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let todayHabit: TodayHabit
    
    var statusIcon: some View {
        Group {
            switch todayHabit.status {
            case .verified:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.pledgeGreen)
            case .pending:
                Image(systemName: "clock.fill")
                    .foregroundColor(.pledgeOrange)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.pledgeRed)
            case .skipped:
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.pledgeGray)
            }
        }
        .font(.system(size: 18))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(todayHabit.habit.icon)
                    .font(.system(size: 22))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(todayHabit.habit.name)
                        .pledgeHeadline()
                        .foregroundColor(.pledgeBlackAdaptive)
                    Text(todayHabit.detail)
                        .pledgeCaption()
                        .foregroundColor(.pledgeGray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(todayHabit.habit.stakeAmount))")
                        .pledgeMono()
                        .foregroundColor(.pledgeBlackAdaptive)
                    statusIcon
                }
            }
            
            // Progress bar for screen time
            if let progress = todayHabit.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.pledgeGrayLight)
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.pledgeBlue)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            // Verify button for pending
            if todayHabit.status == .pending && todayHabit.progress == nil && todayHabit.habit.type != .sleep {
                HStack {
                    Spacer()
                    Button("Verify Now") {
                        PPHaptic.light()
                    }
                    .buttonStyle(SmallCapsuleStyle())
                }
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
