import SwiftUI
import SwiftData

struct RosterView: View {
    @Query(sort: \Child.fullName) private var children: [Child]
    @State private var searchText: String = ""

    private var filtered: [Child] {
        searchText.isEmpty
            ? children
            : children.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns = [GridItem(.adaptive(minimum: 280), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summary
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filtered) { child in
                        NavigationLink(value: child) {
                            ChildCard(child: child)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
        .background(AppPalette.background)
        .navigationTitle("My Key Children")
        .searchable(text: $searchText, prompt: "Search by name")
        .navigationDestination(for: Child.self) { ChildDetailView(child: $0) }
    }

    private var summary: some View {
        let total = children.count
        let in_ = children.filter(\.isCheckedIn).count
        let allergen = children.filter(\.hasAllergens).count
        return HStack(spacing: 16) {
            SummaryTile(title: "Children", value: "\(total)", systemImage: "person.3.fill", colour: AppPalette.primary)
            SummaryTile(title: "Checked in", value: "\(in_)", systemImage: "checkmark.seal.fill", colour: AppPalette.green)
            SummaryTile(title: "Allergen risks", value: "\(allergen)", systemImage: "exclamationmark.triangle.fill", colour: AppPalette.red)
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let systemImage: String
    let colour: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage).foregroundStyle(colour)
            Text(value).font(.largeTitle.bold()).foregroundStyle(AppPalette.textPrimary)
            Text(title).font(.subheadline).foregroundStyle(AppPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tileStyle()
    }
}

private struct ChildCard: View {
    let child: Child
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(AppPalette.gradient(AppPalette.primary)).frame(width: 48, height: 48)
                    Text(child.initials).font(.headline).foregroundStyle(.white)
                }
                VStack(alignment: .leading) {
                    Text(child.fullName).font(.headline).foregroundStyle(AppPalette.textPrimary)
                    Text(child.displayAge + " · " + child.room).font(.caption).foregroundStyle(AppPalette.textSecondary)
                }
                Spacer()
                if child.isCheckedIn {
                    Text("IN").font(.caption.bold()).padding(.horizontal,8).padding(.vertical,4)
                        .background(AppPalette.green.opacity(0.18)).foregroundStyle(AppPalette.green)
                        .clipShape(Capsule())
                } else {
                    Text("OUT").font(.caption.bold()).padding(.horizontal,8).padding(.vertical,4)
                        .background(AppPalette.secondary.opacity(0.15)).foregroundStyle(AppPalette.secondary)
                        .clipShape(Capsule())
                }
            }
            AllergenBanner(child: child)
        }
        .tileStyle()
    }
}
