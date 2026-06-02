import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var state = appState
        NavigationSplitView(columnVisibility: $columnVisibility) {
            KeyworkerSidebar(selection: $state.selectedSection)
                .navigationSplitViewColumnWidth(min: 260, ideal: 290, max: 340)
        } detail: {
            NavigationStack {
                detail
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(AppPalette.background)
        .sheet(item: $state.pendingAction) { action in
            switch action {
            case .newDiary:    NewDiaryEntryFormView()
            case .newIncident: IncidentDraftView()
            }
        }
        .sheet(isPresented: $state.showNewDiaryEntry) { NewDiaryEntryFormView() }
        .sheet(isPresented: $state.showNewIncident)   { IncidentDraftView() }
    }

    @ViewBuilder private var detail: some View {
        switch appState.selectedSection {
        case .dashboard:   KeyworkerDashboardView()
        case .roster:      RosterView()
        case .attendance:  AttendanceView()
        case .diary:       DiaryView()
        case .meal:        MealLogView()
        case .incident:    IncidentDraftView()
        case .development: DevelopmentView()
        case .reports:     ReportGeneratorView()
        }
    }
}
