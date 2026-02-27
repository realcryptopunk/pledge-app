import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calendar placeholder
                    VStack(spacing: 12) {
                        HStack {
                            Button { } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.pledgeBlackAdaptive)
                            }
                            Spacer()
                            Text("February 2026")
                                .pledgeHeadline()
                                .foregroundColor(.pledgeBlackAdaptive)
                            Spacer()
                            Button { } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.pledgeBlackAdaptive)
                            }
                        }
                        
                        // Day headers
                        HStack {
                            ForEach(["M","T","W","T","F","S","S"], id: \.self) { day in
                                Text(day)
                                    .pledgeCaption()
                                    .foregroundColor(.pledgeGray)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Calendar grid (simplified)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(1..<29, id: \.self) { day in
                                VStack(spacing: 4) {
                                    Text("\(day)")
                                        .pledgeCaption()
                                        .foregroundColor(day == 25 ? .pledgeBlue : .pledgeBlackAdaptive)
                                    
                                    Circle()
                                        .fill(day < 25 ? (day % 3 == 0 ? Color.pledgeRed : Color.pledgeGreen) : Color.pledgeGrayLight)
                                        .frame(width: 6, height: 6)
                                }
                                .frame(height: 36)
                            }
                        }
                    }
                    .cleanCard()
                    
                    // Active habits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVE")
                            .pledgeCaption()
                            .foregroundColor(.pledgeGray)
                            .tracking(1)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(appState.habits.enumerated()), id: \.element.id) { index, habit in
                                if index > 0 {
                                    StatRowDivider()
                                }
                                
                                HStack(spacing: 12) {
                                    Text(habit.icon)
                                        .font(.system(size: 20))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(habit.name)
                                            .pledgeHeadline()
                                            .foregroundColor(.pledgeBlackAdaptive)
                                        HStack(spacing: 8) {
                                            Text("🔥 \(habit.currentStreak) days")
                                            Text("·")
                                            Text("\(Int(habit.successRate * 100))%")
                                            Text("·")
                                            Text("$\(Int(habit.stakeAmount))/day")
                                        }
                                        .pledgeCaption()
                                        .foregroundColor(.pledgeGray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.pledgeGrayLight)
                                }
                                .padding(.vertical, 14)
                                .staggerIn(index: index)
                            }
                        }
                        .cleanCard()
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(Color.pledgeBgAdaptive)
            .navigationTitle("My Pledges")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.pledgeBlackAdaptive)
                    }
                }
            }
        }
    }
}

#Preview {
    HabitsView()
        .environmentObject(AppState())
}
