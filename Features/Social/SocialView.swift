import SwiftUI

struct SocialView: View {
    @State private var selectedSegment = 0
    @Environment(\.themeColors) var theme

    private let friends: [(name: String, status: String, streak: Int, dot: Color)] = [
        ("Jake M.", "All done today", 45, .pledgeGreen),
        ("Sarah K.", "2 of 3 pending", 12, .pledgeOrange),
        ("Mike R.", "Missed gym", 0, .pledgeRed),
    ]

    private let activity: [(icon: String, text: String, detail: String)] = [
        ("😂", "Mike missed his 6am alarm", "$10 invested · 2h ago"),
        ("💪", "Jake hit 30-day streak!", "$0 invested this month 🏆"),
        ("✅", "Sarah finished all habits", "$45 saved · 1h ago"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        PillToggle(options: ["Friends", "Leaderboard"], selected: $selectedSegment)

                        if selectedSegment == 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PARTNERS")
                                    .pledgeCaption()
                                    .foregroundColor(.secondary)
                                    .tracking(1)

                                VStack(spacing: 0) {
                                    ForEach(Array(friends.enumerated()), id: \.offset) { index, friend in
                                        if index > 0 { StatRowDivider() }

                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(friend.dot)
                                                .frame(width: 10, height: 10)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(friend.name)
                                                    .pledgeHeadline()
                                                    .foregroundColor(.primary)
                                                Text(friend.status)
                                                    .pledgeCaption()
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Text("🔥 \(friend.streak) days")
                                                .pledgeMonoSmall()
                                                .foregroundColor(.pledgeOrange)
                                        }
                                        .padding(.vertical, 14)
                                        .staggerIn(index: index)
                                    }
                                }
                                .cleanCard()
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("ACTIVITY")
                                    .pledgeCaption()
                                    .foregroundColor(.secondary)
                                    .tracking(1)

                                VStack(spacing: 0) {
                                    ForEach(Array(activity.enumerated()), id: \.offset) { index, item in
                                        if index > 0 { StatRowDivider() }

                                        HStack(spacing: 12) {
                                            Text(item.icon)
                                                .font(.system(size: 20))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.text)
                                                    .pledgeCallout()
                                                    .foregroundColor(.primary)
                                                Text(item.detail)
                                                    .pledgeCaption()
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 12)
                                        .staggerIn(index: index)
                                    }
                                }
                                .cleanCard()
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("THIS WEEK")
                                    .pledgeCaption()
                                    .foregroundColor(.secondary)
                                    .tracking(1)

                                VStack(spacing: 0) {
                                    leaderboardRow("🥇", "Jake M.", "7/7 perfect", 0)
                                    StatRowDivider()
                                    leaderboardRow("🥈", "You", "5/7 days", 1)
                                    StatRowDivider()
                                    leaderboardRow("🥉", "Sarah K.", "4/7 days", 2)
                                    StatRowDivider()
                                    leaderboardRow("4.", "Mike R.", "2/7 days", 3)
                                }
                                .cleanCard()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Community")
            .toolbarColorScheme(theme.isLight ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private func leaderboardRow(_ rank: String, _ name: String, _ stat: String, _ index: Int) -> some View {
        HStack(spacing: 12) {
            Text(rank)
                .font(.system(size: 18))
                .frame(width: 30)

            Text(name)
                .pledgeHeadline()
                .foregroundColor(.primary)

            Spacer()

            Text(stat)
                .pledgeMonoSmall()
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 14)
        .staggerIn(index: index)
    }
}

#Preview {
    SocialView()
        .environmentObject(AppState())
}
