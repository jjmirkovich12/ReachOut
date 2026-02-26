import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Birthday reminders", isOn: $appState.settings.birthdayRemindersEnabled)
                    Toggle("Overdue reminders", isOn: $appState.settings.overdueRemindersEnabled)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
