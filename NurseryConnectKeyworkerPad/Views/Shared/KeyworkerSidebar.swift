import SwiftUI

struct KeyworkerSidebar: View {
    @Binding var selection: KeyworkerSection
    @Environment(AppState.self) private var appState

    private var optionalSelection: Binding<KeyworkerSection?> {
        Binding(
            get: { selection },
            set: { if let new = $0 { selection = new } }
        )
    }

    var body: some View {
        List(selection: optionalSelection) {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppPalette.brandGradient)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(initialsOf(appState.keyworkerName))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.keyworkerName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppPalette.textPrimary)
                            Text("Keyworker · \(appState.room)")
                                .font(.system(size: 11))
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                    }
                    Text(appState.nurseryName)
                        .font(.system(size: 10))
                        .foregroundStyle(AppPalette.textSecondary.opacity(0.8))
                }
                .padding(.vertical, 4)
            }

            Section("Workspace") {
                ForEach(KeyworkerSection.allCases) { section in
                    HStack(spacing: 10) {
                        Image(systemName: section.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(section.color)
                            .frame(width: 22)
                        Text(section.title)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .tag(section)
                }
            }

            Section("Quick Actions") {
                Button {
                    appState.showNewDiaryEntry = true
                } label: {
                    Label("New Diary Entry", systemImage: "square.and.pencil")
                }
                Button {
                    appState.showNewIncident = true
                } label: {
                    Label("Report Incident", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .navigationTitle("Keyworker")
        .listStyle(.sidebar)
    }

    private func initialsOf(_ name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let i = parts.compactMap { $0.first }.prefix(2).map { String($0) }.joined()
        return i.uppercased()
    }
}
