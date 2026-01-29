import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var container: DIContainer

    @State private var selectedTab: Tab = .home
    @State private var showSettings = false
    @State private var showStudySession = false
    @State private var deckViewModel = DeckViewModel()
    @State private var progressViewModel = ProgressViewModel()

    @Query private var allWords: [Word]
    @Query private var userProgressList: [UserProgress]

    private var userProgress: UserProgress? {
        userProgressList.first
    }

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case words = "book.fill"
        case stats = "chart.bar.fill"

        var title: String {
            switch self {
            case .home: return "Learn"
            case .words: return "Words"
            case .stats: return "Stats"
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    homeContent
                case .words:
                    DeckListView(viewModel: deckViewModel)
                case .stats:
                    StatsProgressView(viewModel: progressViewModel)
                }
            }

            VStack {
                Spacer()
                tabBar
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            container.dataService.initializeDataIfNeeded(modelContext: modelContext)
            deckViewModel.loadDecks(modelContext: modelContext)
            progressViewModel.load(modelContext: modelContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showStudySession) {
            if !deckViewModel.decks.isEmpty {
                FlashcardView(decks: deckViewModel.decks, isPreviewMode: false)
            }
        }
    }

    // MARK: - Home Content
    private var homeContent: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    mainStudyButton
                    progressSection
                    levelCardsSection
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(AppTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("GRE Vocab")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    HapticManager.shared.lightImpact()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            AppTheme.Colors.surface
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
    }

    // MARK: - Home Sections
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if wordsToReview > 0 {
                    Text("\(wordsToReview) words ready to review")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.accent)
                } else if newWords > 0 {
                    Text("\(newWords) new words to learn")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.success)
                }
            }

            Spacer()

            if currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.Colors.warning)
                    Text("\(currentStreak)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.warning.opacity(0.15))
                )
            }
        }
    }

    private var mainStudyButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
            showStudySession = true
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                Text("Start Learning")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text(studyButtonSubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.accent, AppTheme.Colors.tertiary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 15, y: 8)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text("\(masteredWords)/\(totalWords)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.Colors.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.Colors.surfaceHighlight)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.success, AppTheme.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)

            HStack(spacing: 0) {
                HomeStatItem(value: "\(newWords)", label: "New", color: AppTheme.Colors.textTertiary)
                HomeStatItem(value: "\(learningWords)", label: "Learning", color: AppTheme.Colors.warning)
                HomeStatItem(value: "\(masteredWords)", label: "Mastered", color: AppTheme.Colors.success)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.surface)
        )
    }

    private var levelCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study by Level")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)

            ForEach(deckViewModel.decks, id: \.name) { deck in
                HomeLevelCard(deck: deck)
            }
        }
    }

    // MARK: - Computed Properties
    private var totalWords: Int { allWords.count }
    private var masteredWords: Int { allWords.filter { $0.status == .mastered }.count }
    private var learningWords: Int { allWords.filter { $0.status == .learning }.count }
    private var newWords: Int { allWords.filter { $0.status == .new }.count }

    private var wordsToReview: Int {
        allWords.filter { $0.isDueForReview && $0.status != .new }.count
    }

    private var progress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }

    private var currentStreak: Int {
        userProgress?.currentStreak ?? 0
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hello"
        }
    }

    private var studyButtonSubtitle: String {
        if wordsToReview > 0 {
            return "\(min(wordsToReview, 10)) words to review"
        } else if newWords > 0 {
            return "Learn \(min(newWords, 10)) new words"
        } else {
            return "Practice your vocabulary"
        }
    }
}

// MARK: - Home Stat Item
struct HomeStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Home Level Card
struct HomeLevelCard: View {
    let deck: Deck

    private var levelColor: Color {
        deck.difficulty.themeColor
    }

    private var progress: Double {
        deck.progress
    }

    var body: some View {
        NavigationLink(destination: DeckDetailView(deck: deck)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(levelColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: deck.difficulty.icon)
                        .font(.system(size: 20))
                        .foregroundColor(levelColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("\(deck.masteredCount)/\(deck.totalWords) mastered")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(levelColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.Colors.surface)
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
        .environmentObject(DIContainer())
}
