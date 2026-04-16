## Focus Android v2.2.4

### Fixes

- Fixed Android build failure in settings flow (`Platform` usage/import issue).
- Introduced Android-specific tag convention for releases: `android-x.y.z`.
- Standardized APK artifact naming for all Android releases:
  - `Focus-android-x.y.z-universal.apk`
  - `Focus-android-x.y.z-arm64-v8a.apk`
  - `Focus-android-x.y.z-armeabi-v7a.apk`

### Notes

- Windows and Android are now treated as separate release tracks.
- Android updater/discovery can safely match Android releases by tag pattern.

## Focus for Windows v3.0.0

### Release Title

Focus v3.0.0 - Desktop Experience Overhaul

### Summary

Focus v3 is a major Windows update focused on speed, clarity, and keyboard-first productivity.
This release strengthens desktop workflow, improves responsiveness, and adds deeper system integration.

### What's New

#### Keyboard-first workflow

- Full desktop shortcuts support (`Ctrl+K`, `Ctrl+N`, `Ctrl+F`, `Ctrl+H`, `Ctrl+,`, `Ctrl+/`, `F1`, `1-4`)
- In-app keyboard shortcuts help dialog
- Faster keyboard navigation across views and actions

#### Redesigned desktop experience

- Desktop home UI refined for keyboard-first use
- Settings flyout aligned with desktop visual style
- Better wide-screen layout behavior with structured side panels
- Unified desktop dialog styling

#### Faster interactions

- Reduced navigation overhead when opening task edit flow
- General desktop responsiveness improvements

#### Focus Mode

- Distraction-free mode for single-flow execution

#### System-level integrations

- Windows system tray integration with quick actions
- Global hotkey support for opening command palette
- Native Windows notifications with action buttons
- Notification actions integrated with in-app task updates

#### Smart reminders

- Due reminder fallback while app is active
- Improved notification routing behavior

#### Task interaction upgrades

- Drag and drop task movement across quadrants
- Task row quick actions (`Move`, `Complete`, `Delete`)

### Notes

- Windows and Android are versioned independently.
- This release applies to the Windows track only.

## Focus v2.2.2

### Fixes

Removed Google Fonts runtime usage and switched to system fonts to keep startup fully offline.

Removed `google_fonts` dependency from the app.

### Downloads

**Focus-v2.2.2-universal.apk** works on all Android devices

**Focus-v2.2.2-arm64-v8a.apk** optimised for modern 64-bit devices (recommended)

**Focus-v2.2.2-armeabi-v7a.apk** for older 32-bit devices
