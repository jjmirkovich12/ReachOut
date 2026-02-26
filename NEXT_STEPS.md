# ReachOut — Final setup and release steps

The application logic and UI are implemented in `ReachOutApp/`, but you still need to wire it into an Xcode iOS project for running on device and App Store distribution.

## 1) Create the Xcode project and attach source files
1. Open Xcode → **File → New Project → iOS App**.
2. Use SwiftUI + Swift.
3. Add all files from:
   - `ReachOutApp/` to app target
   - `ReachOutAppTests/` to test target
4. Ensure module name used by tests matches your app target name.

## 2) Configure iOS permissions
In `Info.plist`, add:
- `NSContactsUsageDescription`: explain why contacts are needed.

In app capabilities/settings:
- Notifications enabled in app signing profile/device settings.

## 3) Real-device QA checklist
Run this full pass on iPhone:
1. Add a person from contacts.
2. Try adding same person again → duplicate alert should appear.
3. Tap a person row → edit cadence/date and save.
4. Swipe delete a person → confirmation alert appears.
5. Deny contacts permission → "Open Settings" path works.
6. Toggle birthday + overdue reminders in Settings and verify pending notifications update.

## 4) App Store readiness
1. Add icons, launch screen, and branding assets.
2. Add Privacy Policy URL + App Store privacy metadata.
3. Capture final screenshots (People, Add/Edit flow, Settings).
4. Run TestFlight beta and verify lock-screen reminders.
