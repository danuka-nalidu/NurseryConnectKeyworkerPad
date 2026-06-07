import SwiftUI
import SwiftData
import Observation

@Observable
class MealLogViewModel {
    var selectedMealType: String = "lunch"
    var showLogSheet: Bool = false
    var keyworkerName: String = ""

    init(keyworkerName: String) {
        self.keyworkerName = keyworkerName
    }

    func myChildren(from all: [Child]) -> [Child] {
        all.filter { $0.keyworkerName == keyworkerName }
    }

    func todaysMeals(from records: [MealRecord], children: [Child]) -> [MealRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        let ids = Set(myChildren(from: children).map { $0.id })
        return records.filter { rec in
            Calendar.current.isDate(rec.date, inSameDayAs: today) && ids.contains(rec.childId)
        }
    }

    var todayDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return max(0, min(4, weekday == 1 ? 4 : weekday - 2))
    }

    func mealTypeLabel(_ type: String) -> String {
        switch type {
        case "breakfast":       return "Breakfast"
        case "morning_snack":   return "AM Snack"
        case "lunch":           return "Lunch"
        case "afternoon_snack": return "PM Snack"
        default:                return type.capitalized
        }
    }

    func saveMeal(childId: UUID, children: [Child], foodOffered: String, foodConsumed: String, notes: String, context: ModelContext) {
        guard let child = children.first(where: { $0.id == childId }) else { return }
        let rec = MealRecord(childId: childId, childName: child.preferredName, mealType: selectedMealType)
        rec.foodOffered = foodOffered
        rec.foodConsumed = foodConsumed
        rec.notes = notes
        rec.keyworkerName = keyworkerName
        context.insert(rec)
        let entry = DiaryEntry(
            childId: childId,
            childName: child.preferredName,
            entryType: "meal",
            description: "\(mealTypeLabel(selectedMealType)): ate \(foodConsumed). \(notes)".trimmingCharacters(in: .whitespaces),
            keyworkerName: keyworkerName
        )
        entry.foodConsumed = foodConsumed
        context.insert(entry)
        try? context.save()
    }
}
