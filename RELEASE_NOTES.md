## What's New in v2.2.0

### New Features
- **Drag and drop tasks** between quadrants on mobile — long-press a task to drag it to another quadrant
- **Quadrant renaming** — long-press any quadrant header to rename it, synced across card and list view
- **Search** — tap the search icon to find tasks across all quadrants in real time
- **Undo delete** — swipe left to delete now shows a 4-second undo snackbar before permanently deleting
- **AMOLED theme** — pure black theme for OLED screens, selectable from the settings bottom sheet
- **App icon badge** — shows pending task count on the app icon

### Improvements
- Consistent dialog UI across the entire app with scale-in animation
- Fixed UNDO on task completion now properly persists to local storage
- Timer in task tiles only runs when task has a due date
- Search results show quadrant color indicator and label badge
- Info button moved to greeting header row in settings bottom sheet

### Bug Fixes
- Fixed quadrant rename dialog losing typed text on keyboard open
- Fixed drag and drop gesture conflict with swipe-to-complete
- Fixed backup import/export JSON format mismatch
- Fixed silent exception swallowing in notification scheduling
- Fixed Platform.isWindows crash risk on non-desktop platforms

### Downloads
- **Focus-v2.2.0-universal.apk** — works on all Android devices
- **Focus-v2.2.0-arm64.apk** — optimised for modern 64-bit devices (recommended)
- **Focus-v2.2.0-arm32.apk** — for older 32-bit devices
