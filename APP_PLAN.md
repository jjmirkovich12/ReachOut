# ReachOut – Product + Build Plan

## 1) Product Summary
ReachOut helps people maintain important relationships by reminding them when it is time to check in.

Core behavior:
- User grants Contacts permission.
- User taps **+** in the top-right to add someone from Contacts.
- For each person, user sets:
  - Check-in cadence (e.g., every 7/14/30 days)
  - Last check-in date
- Main list shows:
  - Person name
  - Last check-in date
  - **Check in** button (marks check-in as today)
- App sends local notifications when:
  - A person is overdue for a check-in.
  - A person has a birthday (optional in Settings).
- Bottom tab bar has:
  - **People** (main screen)
  - **Settings** (birthday reminder toggle)

---

## 2) MVP Scope (App Store v1)

### In scope
1. Contacts permission request and contact picker.
2. Add/remove tracked contacts.
3. Per-contact cadence and last check-in date.
4. Main list with one-tap “Check in”.
5. Overdue local notifications.
6. Birthday local notifications (global on/off toggle in Settings).

### Out of scope (v2+)
- Cloud sync across devices.
- Shared lists with partner/family.
- Widgets / Apple Watch.
- Smart suggestions from message/call history.

---

## 3) User Stories
1. As a user, I can import someone from my Contacts so I don’t type details manually.
2. As a user, I can choose how often I want to check in with each person.
3. As a user, I can quickly mark that I checked in today.
4. As a user, I receive reminders when I’m overdue.
5. As a user, I can enable/disable birthday reminders globally.

---

## 4) UX / Screen Design

## A. People Tab (Main)
Navigation title: `ReachOut`
Top-right: `+` button

List row content:
- Name (primary)
- `Last checked in: MMM d, yyyy`
- Optional badge when overdue: `Overdue`
- Button: `Check in`

Empty state:
- Illustration/icon
- Text: “No people yet”
- CTA: “Add your first person”

## B. Add Person Flow
1. Request contacts permission if not granted.
2. Present native contact picker (`CNContactPickerViewController`).
3. Show setup sheet/form:
   - Name (read-only from contact)
   - Cadence picker: [Every week, Every 2 weeks, Every month, Custom days]
   - Last check-in date picker (default today)
   - Save button

## C. Settings Tab
- Toggle: `Birthday reminders` (on/off)
- Optional future toggles:
  - “Overdue reminders”
  - Quiet hours

---

## 5) Data Model

```swift
struct TrackedPerson: Identifiable, Codable {
    var id: UUID
    var contactIdentifier: String   // CNContact.identifier
    var displayName: String
    var birthdayMonth: Int?         // from CNContact.birthday
    var birthdayDay: Int?
    var cadenceDays: Int
    var lastCheckInDate: Date
    var createdAt: Date
}

struct AppSettings: Codable {
    var birthdayRemindersEnabled: Bool
}
```

Derived values:
- `nextCheckInDate = lastCheckInDate + cadenceDays`
- `isOverdue = today > nextCheckInDate`

Storage:
- MVP: local persistence via `UserDefaults` or JSON file.
- Better: `SwiftData` (iOS 17+) or `CoreData`.

---

## 6) Notification Logic (Local Notifications)

Framework: `UserNotifications`

### Notification permissions
- Ask once in onboarding or first time user adds a person.
- Request `.alert`, `.sound`, `.badge`.

### Overdue reminders
For each tracked person, schedule a repeating daily check notification strategy:
- Option A (simple MVP): daily app refresh/scheduler updates pending notifications.
- Option B (better): schedule one notification at `nextCheckInDate`, then reschedule when check-in is recorded.

Recommended for MVP: **Option B**
- Identifier: `overdue_<person.id>`
- Trigger date: `lastCheckInDate + cadenceDays` at e.g. 9:00 AM local.
- On check-in:
  1. Update `lastCheckInDate = today`
  2. Remove old pending notification
  3. Schedule next overdue notification

### Birthday reminders
If enabled and contact has birthday:
- Identifier: `birthday_<person.id>`
- Trigger: yearly `UNCalendarNotificationTrigger` (month/day at 9:00 AM).
- If toggle turns off, remove all `birthday_*` requests.
- If toggle turns on, reschedule all birthday notifications.

---

## 7) Contacts Integration Notes

Framework: `Contacts` + `ContactsUI`

Permission flow:
- `CNContactStore.authorizationStatus(for: .contacts)`
- Request with `requestAccess(for: .contacts)`

Contact fields to fetch:
- `givenName`, `familyName`
- `birthday`
- `identifier`

Fallback behavior:
- If denied, show explainer + deep link to iOS Settings.

---

## 8) Suggested SwiftUI Architecture

- `ReachOutApp`
- `AppState` (ObservableObject)
  - people array
  - settings
  - add/remove/update/check-in methods
- `ContactsService`
- `NotificationService`
- `PersistenceService`

Views:
- `MainTabView`
- `PeopleListView`
- `AddPersonView`
- `SettingsView`
- `PersonRowView`

This keeps logic testable and separates system APIs from UI.

---

## 9) Edge Cases

1. Contact deleted from Contacts app:
   - Keep tracked entry with saved displayName.
   - Optionally show warning icon.
2. Birthday missing:
   - Skip birthday scheduling for that person.
3. Timezone changes:
   - Use local calendar triggers; re-evaluate schedule on app launch.
4. Cadence changed:
   - Recompute and reschedule overdue reminder.
5. Duplicate adds:
   - Prevent duplicate `contactIdentifier` entries.

---

## 10) App Store Readiness Checklist

- Clear permission copy for Contacts and Notifications.
- Privacy policy explaining local storage and contact usage.
- No collection of unnecessary contact data.
- App icon + screenshots (People tab, Add flow, Settings tab).
- Test on real device for notification timing/lock-screen behavior.

---

## 11) Build Order (Fastest Path)

1. Create tab scaffold (People + Settings).
2. Implement local model + persistence.
3. Add contacts picker and create tracked person flow.
4. Implement list rows + check-in action.
5. Add notification permission + overdue scheduling.
6. Add birthday toggle + yearly birthday scheduling.
7. QA pass + App Store metadata.

---

## 12) Future Enhancements

- Smart cadence suggestions (based on relationship category).
- Home Screen widget: “People to check in with today”.
- Siri shortcut: “I checked in with Alex”.
- Shared family/friend circles.
- Gentle streaks and insights dashboard.
