import SwiftUI
import SwiftData

@main
struct NurseryConnectKeyworkerPadApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Child.self,
            DiaryEntry.self,
            IncidentReport.self,
            AttendanceRecord.self,
            MealRecord.self,
            Message.self,
            MealPlanItem.self,
            TransportRun.self,
            StockItem.self,
            MediaPhoto.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task { SampleData.populateIfEmpty(in: sharedModelContainer.mainContext) }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Diary Entry") { appState.pendingAction = .newDiary }
                    .keyboardShortcut("n", modifiers: [.command])
                Button("Log Incident") { appState.pendingAction = .newIncident }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
            }
            CommandMenu("Section") {
                ForEach(KeyworkerSection.allCases) { section in
                    Button(section.title) { appState.selectedSection = section }
                        .keyboardShortcut(KeyEquivalent(section.shortcutKey), modifiers: [.command])
                }
            }
        }
    }
}
