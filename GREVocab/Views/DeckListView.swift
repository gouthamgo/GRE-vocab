import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: DeckViewModel
    @State private var selectedFilter: Difficulty? = nil
    @State private var searchText = ""
    @State private var appearAnimation = false

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

                    // Deck Grid
                    deckGrid

                    // Bottom padding
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Decks")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        }
        .onAppear {
            viewModel.loadDecks(modelContext: modelContext)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
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
            if filteredDecks.isEmpty {
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
                    NavigationLink {
                        DeckDetailView(deck: deck)
                    } label: {
                        DeckCard(deck: deck)
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
                        .font(.system(size: 10, weight: .bold))
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
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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