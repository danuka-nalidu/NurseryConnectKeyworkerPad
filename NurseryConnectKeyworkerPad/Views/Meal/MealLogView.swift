import SwiftUI
import SwiftData

struct MealLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.fullName) private var allChildren: [Child]
    @Query(sort: \MealRecord.date, order: .reverse) private var mealRecords: [MealRecord]
    @Query(sort: \MealPlanItem.dayOfWeek) private var mealPlanItems: [MealPlanItem]

    @State private var vm = MealLogViewModel(keyworkerName: "")

    let mealTypes = ["breakfast", "morning_snack", "lunch", "afternoon_snack"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                todaysMenuSection

                HStack(spacing: 0) {
                    ForEach(mealTypes, id: \.self) { type in
                        Button { vm.selectedMealType = type } label: {
                            Text(vm.mealTypeLabel(type))
                                .font(.system(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(vm.selectedMealType == type ? AppPalette.orange.opacity(0.15) : Color.clear)
                                .foregroundStyle(vm.selectedMealType == type ? AppPalette.orange : AppPalette.textSecondary)
                        }
                    }
                }
                .background(AppPalette.tileBg, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(vm.mealTypeLabel(vm.selectedMealType)) — My Children")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button { vm.showLogSheet = true } label: {
                            Label("Log Meal", systemImage: "plus.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(vm.myChildren(from: allChildren)) { child in
                            MealChildCard(child: child, mealType: vm.selectedMealType, todaysMeals: vm.todaysMeals(from: mealRecords, children: allChildren))
                        }
                    }
                }
                .tileStyle()
                .padding(.horizontal, 24)

                allergenSection.padding(.horizontal, 24)
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(AppPalette.background)
        .navigationTitle("Meals — \(Date().dayMonthString)")
        .onAppear { vm.keyworkerName = appState.currentUserName }
        .onChange(of: appState.currentUserName) { _, new in vm.keyworkerName = new }
        .sheet(isPresented: $vm.showLogSheet) {
            MealLogFormView(mealType: vm.selectedMealType)
        }
    }

    private var todaysMenuSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Menu")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppPalette.orange)
            let todaysItems = mealPlanItems.filter { $0.dayOfWeek == vm.todayDayOfWeek }
            if todaysItems.isEmpty {
                Text("No menu planned for today").font(.system(size: 13)).foregroundStyle(AppPalette.textSecondary)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(mealTypes, id: \.self) { type in
                        let items = todaysItems.filter { $0.mealType == type }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.mealTypeLabel(type)).font(.system(size: 11, weight: .bold)).foregroundStyle(AppPalette.textSecondary)
                            ForEach(items) { item in
                                Text(item.foodItem).font(.system(size: 12))
                                if !item.allergens.isEmpty {
                                    HStack(spacing: 2) {
                                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 8))
                                        Text(item.allergens).font(.system(size: 9))
                                    }
                                    .foregroundStyle(.orange)
                                }
                            }
                            if items.isEmpty {
                                Text("—").font(.system(size: 12)).foregroundStyle(AppPalette.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .tileStyle()
        .padding(.horizontal, 24)
    }

    private var allergenSection: some View {
        let allergenChildren = vm.myChildren(from: allChildren).filter { $0.hasAllergens }
        return Group {
            if !allergenChildren.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Allergen Alerts", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.orange)
                    ForEach(allergenChildren) { child in
                        HStack(spacing: 10) {
                            Text(child.preferredName).font(.system(size: 13, weight: .semibold))
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(child.allergens.prefix(3), id: \.self) { a in
                                    Text(a)
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(.orange.opacity(0.15), in: Capsule())
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .tileStyle()
            }
        }
    }

}

struct MealChildCard: View {
    let child: Child
    let mealType: String
    let todaysMeals: [MealRecord]

    private var hasMealLogged: Bool {
        todaysMeals.contains { $0.childId == child.id && $0.mealType == mealType }
    }
    private var mealRecord: MealRecord? {
        todaysMeals.first { $0.childId == child.id && $0.mealType == mealType }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(hasMealLogged ? AppPalette.orange : Color.gray.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(child.initials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(hasMealLogged ? .white : AppPalette.textSecondary)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(child.preferredName).font(.system(size: 13, weight: .semibold))
                if let rec = mealRecord {
                    Text("Ate \(rec.foodConsumed)").font(.system(size: 10)).foregroundStyle(.green)
                } else {
                    Text("Not logged").font(.system(size: 10)).foregroundStyle(AppPalette.textSecondary)
                }
            }
            Spacer()
            Image(systemName: hasMealLogged ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(hasMealLogged ? .green : .gray.opacity(0.4))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(hasMealLogged ? Color.green.opacity(0.05) : Color.gray.opacity(0.03)))
    }
}

struct MealLogFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Child.fullName) private var allChildren: [Child]

    let mealType: String
    @State private var selectedChildId: UUID?
    @State private var foodOffered: String = ""
    @State private var foodConsumed: String = "most"
    @State private var notes: String = ""

    private var myChildren: [Child] {
        allChildren.filter { $0.keyworkerName == appState.currentUserName }
    }

    let consumptionLevels = ["all", "most", "some", "little", "none"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    Picker("Select Child", selection: $selectedChildId) {
                        Text("Choose…").tag(nil as UUID?)
                        ForEach(myChildren) { Text($0.preferredName).tag($0.id as UUID?) }
                    }
                    if let id = selectedChildId,
                       let child = myChildren.first(where: { $0.id == id }),
                       child.hasAllergens {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            Text("Allergens: \(child.allergenList)")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                Section("Food Offered") {
                    TextField("What was offered? (e.g. Pasta bake, fruit)", text: $foodOffered)
                }
                Section("How much did they eat?") {
                    Picker("Consumption", selection: $foodConsumed) {
                        ForEach(consumptionLevels, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Notes (optional)") {
                    TextField("Any observations…", text: $notes)
                }
            }
            .navigationTitle("Log Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMeal(); dismiss() }
                        .disabled(selectedChildId == nil)
                }
            }
        }
        .frame(minWidth: 450, minHeight: 400)
    }

    private func saveMeal() {
        guard let id = selectedChildId,
              let child = myChildren.first(where: { $0.id == id }) else { return }
        let rec = MealRecord(childId: id, childName: child.preferredName, mealType: mealType)
        rec.foodOffered = foodOffered
        rec.foodConsumed = foodConsumed
        rec.notes = notes
        rec.keyworkerName = appState.currentUserName
        modelContext.insert(rec)
        let entry = DiaryEntry(childId: id, childName: child.preferredName, entryType: "meal",
                               description: "\(mealLabel(mealType)): ate \(foodConsumed). \(notes)".trimmingCharacters(in: .whitespaces),
                               keyworkerName: appState.currentUserName)
        entry.foodConsumed = foodConsumed
        modelContext.insert(entry)
        try? modelContext.save()
    }

    private func mealLabel(_ type: String) -> String {
        switch type {
        case "breakfast":       return "Breakfast"
        case "morning_snack":   return "AM Snack"
        case "lunch":           return "Lunch"
        case "afternoon_snack": return "PM Snack"
        default:                return type.capitalized
        }
    }
}
