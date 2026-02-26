import SwiftUI

struct AddPersonSheet: View {
    let selection: ContactSelection
    let onSave: (_ cadenceDays: Int, _ lastCheckInDate: Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cadenceDays = 14
    @State private var lastCheckInDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    Text(selection.displayName)
                }

                Section("Reminder cadence") {
                    Picker("How often", selection: $cadenceDays) {
                        Text("Every week").tag(7)
                        Text("Every 2 weeks").tag(14)
                        Text("Every month").tag(30)
                        Text("Every 6 weeks").tag(42)
                    }

                    DatePicker("Last check-in", selection: $lastCheckInDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(cadenceDays, lastCheckInDate)
                        dismiss()
                    }
                }
            }
        }
    }
}
