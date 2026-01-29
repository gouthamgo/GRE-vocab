import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let deck: Deck
    @State private var showFeynmanMode = false
    @State private var searchText = ""
    @State private var selectedStatus: WordStatus? = nil
    @State private var appearAnimation = false

    var filteredWords: [Word] {
        var words = deck.words

        if let status = selectedStatus {
            words = words.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            words = words.filter {
                $0.term.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText)
            }
        }

        return words.sorted { $0.term < $1.term }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero Header
                heroHeader
                    .padding(.bottom, AppTheme.Spacing.lg)

                // Action Buttons
                actionButtons
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)

                // Stats Row
                statsRow
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)

                // Search & Filter
                searchAndFilter
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.md)

                // Words List
                wordsList
                    .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer().frame(height: 40)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(deck.name)
                    .font(AppTheme.Typography.headlineSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
        .fullScreenCover(isPresented: $showFeynmanMode) {
            FeynmanModeView(deck: deck)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    deck.difficulty.themeColor.opacity(0.3),
                    deck.difficulty.themeColor.opacity(0.1),
                    AppTheme.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)

            // Decorative elements
            GeometryReader { geo in
                // Large difficulty icon
                Image(systemName: deck.difficulty.icon)
                    .font(.system(size: 140, weight: .black))
                    .foregroundColor(deck.difficulty.themeColor.opacity(0.1))
                    .offset(x: geo.size.width - 140, y: 10)

                // Geometric shape
                Circle()
                    .fill(deck.difficulty.themeColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .offset(x: 20, y: 40)
            }

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                // Difficulty badge
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: deck.difficulty.icon)
                        .font(.system(size: 12, weight: .bold))
                    Text(deck.difficulty.rawValue.uppercased())
                        .font(AppTheme.Typography.labelSmall(.bold))
                        .tracking(2)
                }
                .foregroundColor(deck.difficulty.themeColor)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(deck.difficulty.themeColor.opacity(0.2))
                )

                // Deck name
                Text(deck.name)
                    .font(AppTheme.Typography.displaySmall(.black))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                // Word count
                Text("\(deck.totalWords) words")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.lg)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Feynman Technique - Deep Learning
            Button {
                HapticManager.shared.mediumImpact()
                showFeynmanMode = true
            } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 20, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feynman Technique")
                            .font(AppTheme.Typography.headlineSmall(.bold))
                        Text("Explain words in your own words to deeply learn")
                            .font(AppTheme.Typography.labelSmall())
                            .opacity(0.9)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.warning, AppTheme.Colors.warning.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: AppTheme.Colors.warning.opacity(0.3), radius: 15, x: 0, y: 8)
            }

            // Info text
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                Text("For daily practice, use the Home tab")
            }
            .font(AppTheme.Typography.labelSmall())
            .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 10)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
    }

    // MARK: - Stats Row (Learning Path)
    private var statsRow: some View {
        let unseenCount = deck.words.filter { $0.learningStage == .unseen }.count
        let previewedCount = deck.words.filter { $0.learningStage == .previewed }.count
        let quizPassedCount = deck.words.filter { $0.learningStage == .quizPassed }.count
        let deepLearnedCount = deck.words.filter { $0.learningStage == .deepLearned }.count

        return HStack(spacing: AppTheme.Spacing.sm) {
            DeckStatBox(
                value: unseenCount,
                label: "New",
                icon: "sparkles",
                color: AppTheme.Colors.textTertiary
            )

            DeckStatBox(
                value: previewedCount,
                label: "Previewed",
                icon: "eye.fill",
                color: AppTheme.Colors.accent
            )

            DeckStatBox(
                value: quizPassedCount,
                label: "Quizzed",
                icon: "checkmark.circle.fill",
                color: AppTheme.Colors.tertiary
            )

            DeckStatBox(
                value: deepLearnedCount,
                label: "Mastered",
                icon: "lightbulb.fill",
                color: AppTheme.Colors.warning
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 10)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
    }

    // MARK: - Search and Filter
    private var searchAndFilter: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Search
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textTertiary)

                TextField("Search words...", text: $searchText)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .tint(AppTheme.Colors.accent)
            }
            .padding(AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surface)
            )

            // Status Filter
            HStack(spacing: AppTheme.Spacing.xs) {
                StatusFilterPill(title: "All", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }

                StatusFilterPill(title: "New", isSelected: selectedStatus == .new, color: AppTheme.Colors.textTertiary) {
                    selectedStatus = .new
                }

                StatusFilterPill(title: "Learning", isSelected: selectedStatus == .learning, color: AppTheme.Colors.warning) {
                    selectedStatus = .learning
                }

                StatusFilterPill(title: "Mastered", isSelected: selectedStatus == .mastered, color: AppTheme.Colors.success) {
                    selectedStatus = .mastered
                }

                Spacer()
            }
        }
    }

    // MARK: - Words List
    private var wordsList: some View {
        LazyVStack(spacing: AppTheme.Spacing.xs) {
            ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                WordRow(word: word)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 10)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                        .delay(0.25 + Double(index) * 0.02),
                        value: appearAnimation
                    )
            }
        }
    }
}

// MARK: - Deck Stat Box
struct DeckStatBox: View {
    let value: Int
    let label: String
    var icon: String? = nil
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            Text("\(value)")
                .font(AppTheme.Typography.headlineSmall(.bold))
                .foregroundColor(color)

            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
        )
    }
}

// MARK: - Status Filter Pill
struct StatusFilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = AppTheme.Colors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.labelSmall(.semibold))
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? color : AppTheme.Colors.surface)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck(name: "Common", difficulty: .medium))
    }
    .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}