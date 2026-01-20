import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var container: DIContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .home
    @State private var deckViewModel = DeckViewModel()
    @State private var progressViewModel = ProgressViewModel()
    @State private var showSettings = false
    @State private var showSearch = false

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case decks = "rectangle.stack.fill"
        case progress = "chart.bar.fill"

        var title: String {
            switch self {
            case .home: return "Home"
            case .decks: return "Decks"
            case .progress: return "Progress"
            }
        }
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainContent
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mainContent: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView(selectedTab: $selectedTab, deckViewModel: deckViewModel, progressViewModel: progressViewModel, showSettings: $showSettings, showSearch: $showSearch)
            case .decks:
                DeckListView(viewModel: deckViewModel)
            case .progress:
                StatsProgressView(viewModel: progressViewModel)
            }
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            container.dataService.initializeDataIfNeeded(modelContext: modelContext)
            deckViewModel.loadDecks(modelContext: modelContext)
            progressViewModel.load(modelContext: modelContext)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.tabChange()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView()
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.sm)
    }
}

struct TabBarButton: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.accent.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .matchedGeometryEffect(id: "TAB_BG", in: animation)
                    }

                    Image(systemName: tab.rawValue)
                        .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                }
                .frame(width: 48, height: 48)

                Text(tab.title)
                    .font(AppTheme.Typography.labelSmall(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}