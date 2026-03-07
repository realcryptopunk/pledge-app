import SwiftUI

struct SocialView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSegment = 0
    @Environment(\.themeColors) var theme

    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        PillToggle(options: ["Friends", "Leaderboard"], selected: $selectedSegment)

                        if selectedSegment == 0 {
                            FriendsTabView()
                        } else {
                            LeaderboardTabView()
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
}

// MARK: - Leaderboard Tab

struct LeaderboardTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme

    @State private var selectedType = 0
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    private let types = ["Streaks", "Consistency", "Staked"]
    private let typeKeys = ["streaks", "consistency", "staked"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Segmented control for leaderboard types
            HStack(spacing: 8) {
                ForEach(Array(types.enumerated()), id: \.offset) { index, typeName in
                    Button {
                        withAnimation(.quickSnap) {
                            selectedType = index
                        }
                        PPHaptic.selection()
                        loadLeaderboard()
                    } label: {
                        Text(typeName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedType == index ? .white : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                if selectedType == index {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.buttonTop, theme.buttonBottom],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                                } else {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                }
                            }
                    }
                }
            }
            .staggerIn(index: 0)

            // Content
            if isLoading {
                // Loading skeleton
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        if index > 0 { StatRowDivider() }
                        LeaderboardSkeletonRow()
                            .staggerIn(index: index)
                    }
                }
                .cleanCard()
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(error)
                        .pledgeBody()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadLeaderboard()
                    }
                    .buttonStyle(SmallCapsuleStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .cleanCard()
            } else if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No data yet")
                        .pledgeHeadline()
                        .foregroundColor(.primary)
                    Text("Start verifying habits to appear on the leaderboard!")
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .cleanCard()
                .staggerIn(index: 1)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { StatRowDivider() }
                        LeaderboardRow(
                            entry: entry,
                            isCurrentUser: entry.userId.uuidString == appState.supabaseUserId
                        )
                        .staggerIn(index: index)
                    }
                }
                .cleanCard()
            }
        }
        .onAppear {
            loadLeaderboard()
        }
        .refreshable {
            await refreshLeaderboard()
        }
    }

    private func loadLeaderboard() {
        isLoading = true
        errorMessage = nil
        Task {
            await refreshLeaderboard()
        }
    }

    @MainActor
    private func refreshLeaderboard() async {
        guard let service = appState.currentSupabaseService else {
            isLoading = false
            errorMessage = "Not authenticated"
            return
        }
        do {
            let result = try await service.fetchLeaderboard(type: typeKeys[selectedType])
            entries = result
            errorMessage = nil
        } catch {
            errorMessage = "Could not load leaderboard"
            print("[SocialView] Leaderboard fetch error: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    @Environment(\.themeColors) var theme

    private var rankDisplay: String {
        switch entry.rank {
        case 1: return "1"
        case 2: return "2"
        case 3: return "3"
        default: return "\(entry.rank)"
        }
    }

    private var medalEmoji: String? {
        switch entry.rank {
        case 1: return "gold"
        case 2: return "silver"
        case 3: return "bronze"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 30, height: 30)
                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("\(entry.rank)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                }
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        isCurrentUser
                            ? LinearGradient(colors: [theme.light, theme.buttonTop], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 36, height: 36)

                Text(String(entry.username.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentUser ? .white : .primary)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("@\(entry.username)")
                        .pledgeHeadline()
                        .foregroundColor(isCurrentUser ? theme.surface : .primary)

                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.buttonTop, theme.buttonBottom],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                }

                if let displayName = entry.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Value
            Text(entry.label)
                .pledgeMonoSmall()
                .foregroundColor(isCurrentUser ? theme.surface : .secondary)
        }
        .padding(.vertical, 14)
        .background(
            isCurrentUser
                ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.surface.opacity(0.08))
                    .padding(.horizontal, -8)
                : nil
        )
    }

    private var rankGradient: LinearGradient {
        switch entry.rank {
        case 1:
            return LinearGradient(
                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:
            return LinearGradient(
                colors: [Color(hex: "C0C0C0"), Color(hex: "A0A0A0")],
                startPoint: .top,
                endPoint: .bottom
            )
        case 3:
            return LinearGradient(
                colors: [Color(hex: "CD7F32"), Color(hex: "A0522D")],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Skeleton Loading Row

struct LeaderboardSkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 30, height: 30)

            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 100, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 70, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 80, height: 12)
        }
        .padding(.vertical, 14)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Friends Tab

struct FriendsTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.themeColors) var theme

    @State private var friends: [FriendshipDTO] = []
    @State private var isLoading = true
    @State private var showAddFriend = false
    @State private var searchText = ""
    @State private var searchResults: [UserProfileDTO] = []
    @State private var isSearching = false
    @State private var pendingRequests: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add friend button
            Button {
                showAddFriend.toggle()
                PPHaptic.light()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Friend")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(SmallCapsuleStyle())
            .staggerIn(index: 0)

            // Search sheet
            if showAddFriend {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FIND FRIENDS")
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                        .tracking(1)

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))

                        TextField("Search by username...", text: $searchText)
                            .font(.system(size: 16, weight: .medium))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: searchText) { _, newValue in
                                debounceSearch(newValue)
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if isSearching {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if !searchResults.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchResults, id: \.id) { user in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Text(String((user.username ?? "?").prefix(1)).uppercased())
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("@\(user.username ?? "unknown")")
                                            .pledgeHeadline()
                                            .foregroundColor(.primary)
                                        if let displayName = user.displayName, !displayName.isEmpty {
                                            Text(displayName)
                                                .pledgeCaption()
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if pendingRequests.contains(user.id) {
                                        Text("Sent")
                                            .pledgeCaption()
                                            .foregroundColor(.secondary)
                                    } else {
                                        Button {
                                            sendRequest(to: user.id)
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(theme.surface)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                        }
                    } else if !searchText.isEmpty && !isSearching {
                        Text("No users found")
                            .pledgeCaption()
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .cleanCard()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Friends list
            if isLoading {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        if index > 0 { StatRowDivider() }
                        LeaderboardSkeletonRow()
                    }
                }
                .cleanCard()
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No friends yet")
                        .pledgeHeadline()
                        .foregroundColor(.primary)
                    Text("Add friends to see their progress")
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .cleanCard()
                .staggerIn(index: 1)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PARTNERS")
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                        .tracking(1)

                    VStack(spacing: 0) {
                        ForEach(Array(friends.enumerated()), id: \.element.id) { index, friendship in
                            if index > 0 { StatRowDivider() }
                            FriendRow(friendship: friendship, currentUserId: appState.supabaseUserId)
                                .staggerIn(index: index)
                        }
                    }
                    .cleanCard()
                }
            }
        }
        .onAppear {
            loadFriends()
        }
        .refreshable {
            await refreshFriends()
        }
        .animation(.springBounce, value: showAddFriend)
    }

    // MARK: - Data Loading

    private func loadFriends() {
        isLoading = true
        Task {
            await refreshFriends()
        }
    }

    @MainActor
    private func refreshFriends() async {
        guard let service = appState.currentSupabaseService else {
            isLoading = false
            return
        }
        do {
            friends = try await service.fetchFriends()
        } catch {
            print("[SocialView] Friends fetch error: \(error)")
        }
        isLoading = false
    }

    // MARK: - Search

    @State private var searchTask: Task<Void, Never>? = nil

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query)
        }
    }

    @MainActor
    private func performSearch(_ query: String) async {
        guard let service = appState.currentSupabaseService else { return }
        isSearching = true
        do {
            searchResults = try await service.searchUsers(prefix: query.lowercased())
        } catch {
            print("[SocialView] Search error: \(error)")
            searchResults = []
        }
        isSearching = false
    }

    // MARK: - Friend Request

    private func sendRequest(to userId: UUID) {
        guard let service = appState.currentSupabaseService else { return }
        PPHaptic.medium()
        pendingRequests.insert(userId)
        Task {
            do {
                try await service.sendFriendRequest(to: userId)
                PPHaptic.success()
            } catch {
                pendingRequests.remove(userId)
                PPHaptic.error()
                print("[SocialView] Friend request error: \(error)")
            }
        }
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friendship: FriendshipDTO
    let currentUserId: String?
    @Environment(\.themeColors) var theme

    private var friendProfile: FriendProfileDTO? {
        // Show the OTHER user in the friendship
        if friendship.userId.uuidString == currentUserId {
            return friendship.friend
        } else {
            return friendship.user
        }
    }

    private var statusColor: Color {
        switch friendship.status {
        case "accepted": return .pledgeGreen
        case "pending": return .pledgeOrange
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(friendProfile?.username ?? "unknown")")
                    .pledgeHeadline()
                    .foregroundColor(.primary)
                if let displayName = friendProfile?.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .pledgeCaption()
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(friendship.status == "pending" ? "Pending" : "Friend")
                .pledgeCaption()
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    SocialView()
        .environmentObject(AppState())
}
