import SwiftUI
import SwiftData
import PencilKit

struct IncidentDraftView: View {
    var prefill: Child? = nil
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.fullName) private var children: [Child]
    @Query(sort: \IncidentReport.incidentDate, order: .reverse) private var incidents: [IncidentReport]

    @State private var selectedChildId: UUID?
    @State private var category: String = "minor_accident"
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var immediateAction: String = ""
    @State private var canvas = PKCanvasView()

    private let categories = ["minor_accident","first_aid","near_miss","safeguarding","allergic_reaction","medical"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    Picker("Child", selection: $selectedChildId) {
                        Text("Select child").tag(nil as UUID?)
                        ForEach(children) { Text($0.preferredName).tag($0.id as UUID?) }
                    }
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text(IncidentReport.categoryLabel($0)).tag($0)
                        }
                    }
                }
                Section("What happened?") {
                    TextField("Location", text: $location)
                    TextEditor(text: $description).frame(minHeight: 110)
                }
                Section("Immediate action taken") {
                    TextEditor(text: $immediateAction).frame(minHeight: 80)
                }
                Section("Keyworker signature") {
                    PencilCanvas(canvas: $canvas)
                        .frame(height: 140)
                        .background(AppPalette.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Clear") { canvas.drawing = PKDrawing() }
                        .font(.caption)
                }
                if !incidents.isEmpty {
                    Section("Earlier today") {
                        ForEach(incidents.prefix(5)) { inc in
                            VStack(alignment: .leading) {
                                Text("\(inc.childName) · \(inc.categoryDisplay)")
                                    .font(.subheadline.weight(.semibold))
                                Text(inc.incidentDescription).font(.caption)
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log Incident")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear {
                selectedChildId = prefill?.id ?? children.first?.id
            }
        }
    }

    private var canSave: Bool {
        selectedChildId != nil &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !canvas.drawing.bounds.isEmpty
    }

    private func save() {
        guard let id = selectedChildId, let child = children.first(where: { $0.id == id }) else { return }
        let inc = IncidentReport(
            childId: child.id,
            childName: child.preferredName,
            reportedBy: appState.keyworkerName,
            category: category,
            description: description
        )
        inc.location = location
        inc.immediateAction = immediateAction
        context.insert(inc)
        try? context.save()
        dismiss()
    }
}

struct PencilCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
