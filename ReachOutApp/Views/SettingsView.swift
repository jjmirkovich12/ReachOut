import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Birthday reminders", isOn: $appState.settings.birthdayRemindersEnabled)
            }
            .navigationTitle("Settings")
        }
    }
}
