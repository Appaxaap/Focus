## Focus v2.2.0

### New Features

**Drag and drop tasks** between quadrants on mobile. Long-press any task to drag it into a different quadrant.

**Quadrant renaming** on mobile. Long-press any quadrant header in card view or list view to rename it. Names persist across app restarts.

**Search** across all quadrants in real time. Tap the search icon in the header to find any task by title or notes.

**Undo delete** when swiping left on a task. A 4-second snackbar appears with an undo option before the task is permanently deleted.

**AMOLED theme** with pure black surfaces for OLED screens. Selectable from the settings bottom sheet alongside Light and Dark.

**App icon badge** showing the count of tasks due today, synced with the settings toggle.

### Improvements

Consistent dialog UI across the entire app with a smooth scale-in animation and rounded corners.

Info button moved to the greeting header row in the settings bottom sheet for a cleaner layout.

UNDO on task completion now properly persists the restored task to local storage.

Timer in task tiles only runs when the task has a due date, reducing unnecessary battery usage.

Search results show a quadrant color indicator and label badge for quick identification.

### Bug Fixes

Fixed quadrant rename dialog losing typed text when the keyboard opens.

Fixed drag and drop gesture conflicting with swipe-to-complete and swipe-to-delete.

Fixed backup import crashing when reading the exported JSON format.

Fixed silent exception swallowing in notification scheduling.

Fixed Platform.isWindows crash risk on non-desktop platforms.

### Downloads

**Focus-v2.2.0-universal.apk** — works on all Android devices

**Focus-v2.2.0-arm64-v8a.apk** — optimised for modern 64-bit devices (recommended)

**Focus-v2.2.0-armeabi-v7a.apk** — for older 32-bit devices
