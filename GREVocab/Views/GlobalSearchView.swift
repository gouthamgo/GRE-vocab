import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var searchText = ""
    @State private var allWords: [Word] = []
    @State private var appearAnimation = false
    @FocusState private var isSearchFocused: Bool

    var filteredWords: [Word] {
        guard !searchText.isEmpty else { return [] }
        let lowercased = searchText.lowercased()
        return allWords.filter {
            $0.term.lowercased().contains(lowercased) ||
            $0.definition.lowercased().contains(lowercased)
        }.sorted { $0.term < $1.term }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.md)

                // Results
                if searchText.isEmpty {
                    emptySearchState
                } else if filteredWords.isEmpty {
                    noResultsState
                } else {
                    searchResults
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.bodyMedium(.semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
        .onAppear {
            loadWords()
            isSearchFocused = true
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8)) {
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

            TextField("Search all words...", text: $searchText)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .tint(AppTheme.Colors.accent)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.shared.lightImpact()
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

    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Search for Words")
                    .font(AppTheme.Typography.headlineSmall(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Find any word by term or definition")
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            // Quick stats
            HStack(spacing: AppTheme.Spacing.xl) {
                QuickSearchStat(count: allWords.count, label: "Total Words")
                QuickSearchStat(count: allWords.filter { $0.status == .mastered }.count, label: "Mastered")
            }
            .padding(.top, AppTheme.Spacing.lg)

            Spacer()
        }
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - No Results State
    private var noResultsState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "questionmark.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("No Results")
                    .font(AppTheme.Typography.headlineSmall(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Try a different search term")
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Search Results
    private var searchResults: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppTheme.Spacing.xs) {
                // Results count
                HStack {
                    Text("\(filteredWords.count) result\(filteredWords.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xs)

                ForEach(filteredWords) { word in
                    SearchResultRow(word: word, searchText: searchText)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers
    private func loadWords() {
        let descriptor = FetchDescriptor<Word>(sortBy: [SortDescriptor(\.term)])
        allWords = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let word: Word
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                // Term with highlight
                Text(word.term)
                    .font(AppTheme.Typography.headlineSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                // Status badge
                statusBadge

                // Difficulty badge
                Text(word.difficulty.rawValue)
                    .font(AppTheme.Typography.labelSmall(.semibold))
                    .foregroundColor(word.difficulty.themeColor)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(word.difficulty.themeColor.opacity(0.15))
                    )
            }

            // Definition
            Text(word.definition)
                .font(AppTheme.Typography.bodySmall())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(2)

            // Part of speech
            Text(word.partOfSpeech)
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
        )
    }

    private var statusBadge: some View {
        Group {
            switch word.status {
            case .mastered:
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppTheme.Colors.success)
            case .learning:
                Image(systemName: "clock.fill")
                    .foregroundColor(AppTheme.Colors.warning)
            case .new:
                Image(systemName: "sparkle")
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .font(.system(size: 14))
    }
}

// MARK: - Quick Search Stat
struct QuickSearchStat: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text("\(count)")
                .font(AppTheme.Typography.headlineMedium(.bold))
                .foregroundColor(AppTheme.Colors.accent)

            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }
}

#Preview {
    GlobalSearchView()
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}
