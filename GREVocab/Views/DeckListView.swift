import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: DeckViewModel
    @Query private var userProgressItems: [UserProgress]
    @State private var selectedFilter: Difficulty? = nil
    @State private var searchText = ""
    @State private var appearAnimation = false
    @State private var showPaywall = false
    @State private var selectedLockedDeck: Deck? = nil
    @State private var isLoading = true

    private var userProgress: UserProgress? {
        userProgressItems.first
    }

    private var hasPremiumAccess: Bool {
        userProgress?.hasPremiumAccess ?? false
    }

    var filteredDecks: [Deck] {
        var decks = viewModel.decks

        if let filter = selectedFilter {
            decks = decks.filter { $0.difficulty == filter }
        }

        if !searchText.isEmpty {
            decks = decks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return decks
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Search Bar
                    searchBar
                        .padding(.top, AppTheme.Spacing.md)

                    // Filter Chips
                    filterChips

                    // Stats Overview
                    statsOverview

                    // Premium Upsell Banner
                    premiumUpsellBanner
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 10)

                    // Deck Grid
                    deckGrid

                    // Bottom padding
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .refreshable {
                await refreshDecks()
            }
            .navigationTitle("Words")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                if let userProgress = userProgress {
                    PaywallView(userProgress: userProgress)
                }
            }
        }
        .onAppear {
            viewModel.loadDecks(modelContext: modelContext)
            // Simulate brief loading then show content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(AppTheme.Motion.standard) {
                    isLoading = false
                }
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Premium Upsell Banner
    @ViewBuilder
    private var premiumUpsellBanner: some View {
        if !hasPremiumAccess && lockedDecksCount > 0 {
            Button {
                showPaywall = true
                HapticManager.shared.lightImpact()
            } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.warning.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.Colors.warning)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock \(lockedWordsCount)+ Words")
                            .font(AppTheme.Typography.bodyMedium(.bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("\(lockedDecksCount) premium pack\(lockedDecksCount == 1 ? "" : "s") waiting")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.warning)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.warning.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                .stroke(AppTheme.Colors.warning.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.textTertiary)

            TextField("Search decks...", text: $searchText)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .tint(AppTheme.Colors.accent)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 1)
                )
        )
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                FilterChip(
                    title: "All",
                    count: viewModel.decks.count,
                    isSelected: selectedFilter == nil,
                    color: AppTheme.Colors.accent
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = nil
                    }
                }

                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    let count = viewModel.decks.filter { $0.difficulty == difficulty }.count
                    FilterChip(
                        title: difficulty.rawValue,
                        count: count,
                        isSelected: selectedFilter == difficulty,
                        color: difficulty.themeColor,
                        icon: difficulty.icon
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = difficulty
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats Overview
    private var statsOverview: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            OverviewStatPill(
                value: "\(viewModel.totalWords)",
                label: "Total Words",
                icon: "textformat.abc",
                color: AppTheme.Colors.accent
            )

            OverviewStatPill(
                value: "\(viewModel.totalMastered)",
                label: "Mastered",
                icon: "checkmark.seal.fill",
                color: AppTheme.Colors.success
            )

            OverviewStatPill(
                value: "\(Int(viewModel.overallProgress * 100))%",
                label: "Progress",
                icon: "chart.line.uptrend.xyaxis",
                color: AppTheme.Colors.tertiary
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 10)
    }

    // MARK: - Deck Grid
    private var deckGrid: some View {
        LazyVStack(spacing: AppTheme.Spacing.md) {
            if isLoading {
                // Skeleton loading state
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonDeckCard()
                }
            } else if filteredDecks.isEmpty {
                EmptyStateView(
                    icon: "rectangle.stack.badge.minus",
                    title: "No Decks Found",
                    subtitle: searchText.isEmpty
                        ? "Select a different filter to view decks"
                        : "Try a different search term"
                )
                .padding(.top, AppTheme.Spacing.xxl)
            } else {
                ForEach(Array(filteredDecks.enumerated()), id: \.element.id) { index, deck in
                    let isLocked = deck.difficulty.isPremium && !hasPremiumAccess

                    if isLocked {
                        // Locked deck - show paywall on tap
                        Button {
                            selectedLockedDeck = deck
                            showPaywall = true
                            HapticManager.shared.lightImpact()
                        } label: {
                            DeckCard(deck: deck, isLocked: true)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: appearAnimation
                        )
                    } else {
                        // Unlocked deck - navigate to detail
                        NavigationLink {
                            DeckDetailView(deck: deck)
                        } label: {
                            DeckCard(deck: deck, isLocked: false)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: appearAnimation
                        )
                    }
                }
            }
        }
    }

    // MARK: - Refresh
    private func refreshDecks() async {
        isLoading = true
        viewModel.loadDecks(modelContext: modelContext)
        // Small delay to show refresh indicator
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(AppTheme.Motion.standard) {
            isLoading = false
        }
    }

    // MARK: - Locked count
    private var lockedDecksCount: Int {
        viewModel.decks.filter { $0.difficulty.isPremium && !hasPremiumAccess }.count
    }

    private var lockedWordsCount: Int {
        viewModel.decks
            .filter { $0.difficulty.isPremium && !hasPremiumAccess }
            .reduce(0) { $0 + $1.totalWords }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold)) // Increased from 10 to 12
                }

                Text(title)
                    .font(AppTheme.Typography.labelMedium(.semibold))

                Text("\(count)")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.2) : color.opacity(0.2))
                    )
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .frame(minHeight: AppTheme.minTapTarget) // Ensure minimum tap target
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : color.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Capsule()) // Expand tap area to full shape
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(title), \(count) items\(isSelected ? ", selected" : "")")
    }
}

// MARK: - Overview Stat Pill
struct OverviewStatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(AppTheme.Typography.headlineSmall(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DeckListView(viewModel: DeckViewModel())
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}