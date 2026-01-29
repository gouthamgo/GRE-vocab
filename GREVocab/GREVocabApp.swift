import SwiftUI
import SwiftData

@main
struct GREVocabApp: App {
    @StateObject private var container = DIContainer()
    @State private var showError = false
    @State private var errorMessage = ""

    var sharedModelContainer: ModelContainer? = {
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
            print("Failed to create ModelContainer: \(error)")
            return nil
        }
    }()

    var body: some Scene {
        WindowGroup {
            if let modelContainer = sharedModelContainer {
                ContentView()
                    .environmentObject(container)
                    .modelContainer(modelContainer)
            } else {
                DatabaseErrorView()
            }
        }
    }
}

// MARK: - Database Error View
struct DatabaseErrorView: View {
    var body: some View {
        ZStack {
            Color(red: 0.067, green: 0.067, blue: 0.075)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)

                Text("Unable to Load Data")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("There was a problem initializing the app's database. Please try restarting the app or reinstalling if the problem persists.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    // Attempt to restart by exiting (user will relaunch)
                    exit(0)
                } label: {
                    Text("Restart App")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.top, 16)
            }
        }
        .preferredColorScheme(.dark)
    }
}
