import SwiftUI
import SwiftData

@main
struct GREVocabApp: App {
    @StateObject private var container = DIContainer()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Word.self,
            Deck.self,
            UserProgress.self,
            StudySession.self,
            Achievement.self,
            DailyChallenge.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
        }
        .modelContainer(sharedModelContainer)
    }
}
