import Foundation
import SwiftData

enum SampleData {
    static func populateIfEmpty(in context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<Child>())
        if let existing, !existing.isEmpty { return }
        populate(in: context)
    }

    static func populate(in context: ModelContext) {
        let keyworker = "Nuwani Wijerathne"
        let cal = Calendar.current
        let today = Date()

        let kids: [(String, String, Int, String, String)] = [
            ("Sethmi Wickramasinghe", "Sethmi", 36, "milk,egg", "anaphylactic"),
            ("Ranudi Senanayake",     "Ranudi", 30, "peanut", "allergy"),
            ("Vihaga Jayasuriya",     "Vihaga", 42, "", "none"),
            ("Tharushi Bandara",      "Tharu",  28, "soy", "intolerance"),
            ("Kavindu Perera",        "Kavindu", 48, "", "none"),
            ("Imaya Fernando",        "Imaya",  34, "wheat,gluten", "allergy"),
            ("Nethum Rajapaksha",     "Nethum", 26, "", "none"),
            ("Sahanya Mendis",        "Sahanya", 39, "egg", "intolerance")
        ]

        var createdChildren: [Child] = []
        for (full, pref, months, allergens, severity) in kids {
            let dob = cal.date(byAdding: .month, value: -months, to: today) ?? today
            let child = Child(
                fullName: full,
                preferredName: pref,
                dateOfBirth: dob,
                keyworkerName: keyworker,
                room: "Daisy Room"
            )
            child.allergenList = allergens
            child.allergenSeverity = severity
            child.isCheckedIn = Bool.random()
            if child.isCheckedIn {
                child.checkInTime = cal.date(byAdding: .minute, value: -Int.random(in: 30...180), to: today)
                child.checkInBy = "Mother"
            }
            child.parentOneName = "Parent of \(pref)"
            child.parentOnePhone = "+94 77 \(Int.random(in: 1_000_000...9_999_999))"
            child.dietaryRequirements = severity == "anaphylactic" ? "Strict allergen exclusion" : ""
            context.insert(child)
            createdChildren.append(child)
        }

        // Diary entries (last 24h)
        let entryTypes = ["activity", "sleep", "nappy", "meal", "wellbeing", "milestone"]
        let notes = [
            "activity": "Enjoyed water play at the outdoor tray.",
            "sleep": "Settled quickly after lunch — slept 50 minutes.",
            "nappy": "Wet, cream applied.",
            "meal": "Ate most of pasta — refused vegetables.",
            "wellbeing": "Bright, sociable, engaged in singing.",
            "milestone": "Stacked four blocks unaided!"
        ]
        for child in createdChildren {
            let n = Int.random(in: 2...5)
            for _ in 0..<n {
                let type = entryTypes.randomElement() ?? "activity"
                let entry = DiaryEntry(
                    childId: child.id,
                    childName: child.preferredName,
                    entryType: type,
                    description: notes[type] ?? "Lovely moment with friends.",
                    keyworkerName: keyworker
                )
                entry.timestamp = cal.date(byAdding: .hour, value: -Int.random(in: 0...10), to: today) ?? today
                entry.eyfsArea = ["Communication & Language", "Physical Development", "PSED", "Literacy"].randomElement() ?? ""
                context.insert(entry)
            }
        }

        // Attendance records for today
        for child in createdChildren {
            let rec = AttendanceRecord(childId: child.id, childName: child.preferredName)
            rec.date = today
            if child.isCheckedIn {
                rec.checkInTime = child.checkInTime
                rec.droppedOffBy = child.checkInBy
            }
            context.insert(rec)
        }

        // Meal records (lunch today)
        for child in createdChildren.prefix(5) {
            let meal = MealRecord(childId: child.id, childName: child.preferredName, mealType: "lunch")
            meal.foodOffered = "Chicken pasta, broccoli, milk"
            meal.foodConsumed = ["all", "most", "half", "little"].randomElement() ?? "most"
            meal.fluidType = "water"
            meal.fluidAmount = Int.random(in: 80...200)
            meal.keyworkerName = keyworker
            context.insert(meal)
        }

        // One open incident
        let inc = IncidentReport(
            childId: createdChildren[1].id,
            childName: createdChildren[1].preferredName,
            reportedBy: keyworker,
            category: "minor_accident",
            description: "Tripped on the soft mat during free-play. No mark visible, child resumed play after a cuddle."
        )
        inc.location = "Daisy Room — soft area"
        inc.immediateAction = "Cold compress applied for 2 minutes. Monitored for 15 minutes."
        context.insert(inc)

        // Weekly meal plan (Mon-Fri)
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let menu: [(Int, String, String, String)] = [
            (0, "breakfast",       "Porridge with banana",        ""),
            (0, "morning_snack",   "Apple slices, oat crackers",  ""),
            (0, "lunch",           "Chicken pasta, broccoli",     "wheat,egg"),
            (0, "afternoon_snack", "Yoghurt, raisins",            "milk"),
            (1, "breakfast",       "Cereal with milk",            "milk,gluten"),
            (1, "lunch",           "Cottage pie, peas",           ""),
            (1, "afternoon_snack", "Rice cakes, hummus",          "sesame"),
            (2, "breakfast",       "Toast with butter",           "wheat,milk"),
            (2, "lunch",           "Fish fingers, mash, carrots", "fish,wheat"),
            (2, "afternoon_snack", "Banana, milk",                "milk"),
            (3, "breakfast",       "Weetabix, milk",              "milk,gluten"),
            (3, "lunch",           "Vegetable curry, rice",       ""),
            (3, "afternoon_snack", "Cheese cubes, crackers",      "milk,wheat"),
            (4, "breakfast",       "Pancakes, berries",           "wheat,egg,milk"),
            (4, "lunch",           "Pasta bake, salad",           "wheat,milk"),
            (4, "afternoon_snack", "Fruit kebabs, yoghurt dip",   "milk")
        ]
        for (day, type, food, allergens) in menu {
            let item = MealPlanItem(weekStartDate: weekStart, dayOfWeek: day, mealType: type, foodItem: food, allergens: allergens)
            context.insert(item)
        }

        // Guaranteed milestone entries (one per child) so Development tracker has data
        for child in createdChildren {
            let m = DiaryEntry(
                childId: child.id,
                childName: child.preferredName,
                entryType: "milestone",
                description: "Achieved a new developmental milestone — \(["stacked 4 blocks","said full sentence","fed self with spoon","walked unaided","sang nursery rhyme"].randomElement() ?? "great progress")!",
                keyworkerName: keyworker
            )
            m.timestamp = cal.date(byAdding: .day, value: -Int.random(in: 0...14), to: today) ?? today
            m.eyfsArea = ["Communication & Language", "Physical Development", "PSED"].randomElement() ?? ""
            context.insert(m)
        }

        // A couple of parent messages
        for child in createdChildren.prefix(2) {
            let msg = Message(
                senderName: child.parentOneName,
                senderRole: "Parent",
                recipientName: keyworker,
                recipientRole: "Keyworker",
                content: "Hi! \(child.preferredName) had a restless night — please keep an eye on naps today.",
                childName: child.preferredName
            )
            msg.timestamp = cal.date(byAdding: .hour, value: -Int.random(in: 1...5), to: today) ?? today
            context.insert(msg)
        }

        try? context.save()
    }
}
