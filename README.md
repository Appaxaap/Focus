<h1 align="center">
  <img src="https://github.com/user-attachments/assets/0b26465a-9712-4286-b796-68aac70ef7d1" alt="Focus app icon offline task manager" width="128" height="128"/>
  <br>
  Focus
  <a href="https://github.com/Appaxaap/Focus/releases/latest">
    <img alt="GitHub Release" src="https://img.shields.io/github/v/release/Appaxaap/Focus?style=flat&color=D1BCFF&labelColor=202124"/>
  </a>
  <a href="https://buymeacoffee.com/bxmbshr">
    <img alt="Support development" src="https://img.shields.io/badge/Support-D1BCFF?style=flat&labelColor=202124"/>
  </a>
</h1>

<p align="center"><strong>Offline task manager built on the Eisenhower Matrix</strong></p>
<p align="center"><i>A privacy focused Android and Windows productivity app made with Flutter</i></p>

<div align="center">
  <img src="https://img.shields.io/badge/Platform-Android-D1BCFF?style=flat&logo=android&labelColor=202124">
  <img src="https://img.shields.io/badge/Platform-Windows-D1BCFF?style=flat&logo=windows&labelColor=202124">
  <img src="https://img.shields.io/badge/Platform-Linux-D1BCFF?style=flat&logo=linux&labelColor=202124">
  <img src="https://img.shields.io/badge/Framework-Flutter-D1BCFF?style=flat&logo=flutter&labelColor=202124">
  <img src="https://img.shields.io/badge/License-GPL_v3.0-D1BCFF?style=flat&labelColor=202124">
  <img src="https://img.shields.io/github/downloads/Appaxaap/Focus/total?style=flat&color=D1BCFF&label=Downloads&labelColor=202124">
</div>

---

![Focus offline Eisenhower Matrix task planner](https://github.com/user-attachments/assets/2ced335e-9bc7-45b2-8022-dd3079a7c77a)

---

## About Focus

Focus is an **offline task manager for Android** built around the **Eisenhower Matrix productivity method**.

Unlike most task and todo apps, Focus does not require accounts, cloud sync, subscriptions, or internet access. All data is stored locally on your device.

This makes Focus ideal for users who want a **simple, fast, and privacy respecting productivity app**.

### Key principles

- Fully offline task planning  
- Local only data storage  
- No analytics or tracking  
- No ads or subscriptions  
- Minimal and distraction free UI  

Focus is designed for intentional work and long term clarity.

---

## Eisenhower Matrix Task Management

The Eisenhower Matrix is a proven productivity framework that helps prioritize tasks based on urgency and importance.

|                    | Important       | Not Important |
|--------------------|-----------------|---------------|
| Urgent             | Do First        | Delegate      |
| Not Urgent         | Schedule        | Eliminate     |

Focus visualizes this matrix directly, allowing you to quickly decide what deserves attention and what does not.

This approach helps reduce cognitive overload and improve daily decision making.

---

## Features

- Eisenhower Matrix based task organization  
- Offline first Android task manager  
- Local NoSQL storage using Hive  
- Smart default due dates for each quadrant  
- Swipe gestures to complete or delete tasks  
- Haptic feedback for interactions  
- Light and dark theme support  
- List view and card view layouts  
- No account or onboarding required  

---

## Windows Features

- Native desktop layout optimized for keyboard and large screens  
- Light, dark, and AMOLED theme adaptation across desktop screens  
- Custom desktop settings flyout aligned with home screen styling  
- Draggable custom title area with custom window controls  
- Responsive desktop task edit UI for compact and wide window sizes  
- Unified custom dialog style across desktop actions and confirmations  

### Desktop Productivity

- Full Eisenhower Matrix workflow on desktop (`Do First`, `Schedule`, `Delegate`, `Eliminate`)  
- Focus Mode for distraction-free execution by active quadrant  
- Desktop insights panel (done/open/late counters + productivity progress)  
- Quick task creation and editing from home and command palette  
- Show/hide completed tasks and fast quadrant switching  

### Tray and Background Workflow

- System tray integration on Windows  
- Tray menu actions:
  - Show app
  - Quick add task
  - Open command palette
  - Quit
- Minimize/close to tray behavior for background workflow continuity  

### Keyboard-first Flow

- Global hotkey `Ctrl + K` opens command palette even when app is unfocused  
- In-app shortcut system for major desktop actions  
- Keyboard shortcut help dialog available in app  
- Command palette supports:
  - New task
  - Toggle focus mode
  - Toggle show completed
  - Open settings
  - Show shortcuts
  - Task search and open

### Notifications on Windows

- Native Windows reminder notifications for scheduled tasks  
- Notification action buttons:
  - **Mark done**
  - **Open task**
- Notification handling integrated with desktop task state updates  

### Windows Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl + K` | Open Command Palette |
| `Ctrl + N` | New task |
| `Ctrl + F` | Toggle Focus Mode |
| `Ctrl + H` | Toggle Show Completed |
| `Ctrl + ,` | Open Settings |
| `Ctrl + /` or `F1` | Show keyboard shortcuts |
| `1` `2` `3` `4` | Select Eisenhower quadrant |

### Current Windows Behavior

- Windows build runs in a single main window  
- Task editing opens in-app (multi-window editing is intentionally removed)  

---

## Comparison With Typical Task Apps

| Feature           | Focus                     | Typical Todo Apps |
|-------------------|---------------------------|-------------------|
| Offline usage     | Yes                       | Often limited     |
| Data storage      | Local only                | Cloud based       |
| Privacy           | No tracking               | Analytics common  |
| Cost              | Free                      | Freemium          |
| Complexity        | Minimal                   | Feature heavy     |

Focus prioritizes reliability and simplicity over feature bloat.

---

## Who This App Is For

- Developers and solo founders  
- Students and researchers  
- Deep work practitioners  
- Users who prefer offline productivity tools  
- Anyone looking for a private task manager  

If you believe productivity is about focus rather than constant activity, Focus is built for you.

---

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/3129b7de-d6ca-48e6-b454-bb8bad2c2fa0" width="220" />
  <img src="https://github.com/user-attachments/assets/f7f7dafe-1a88-409e-a995-7ed660792815" width="220" />
  <img src="https://github.com/user-attachments/assets/cc7aeac3-c5fa-408b-92fd-8090979237d8" width="220" />
</p>
<p align="center">
  <img src="https://github.com/user-attachments/assets/d1498880-d459-4cf6-ad9e-f2718bce4964" width="220" />
  <img src="https://github.com/user-attachments/assets/00189dab-eeec-453f-be9c-dd5b56640673" width="220" />
  <img src="https://github.com/user-attachments/assets/fb49fadb-2e0d-48f0-b325-707cfd49e97c" width="220" />
</p>

---

## Technology Stack

- Flutter for cross platform UI  
- Hive for offline local storage  
- Riverpod for state management  
- Material You for adaptive theming  

---

## Support Development

Focus is developed independently and will always remain offline first and privacy focused.

If you want to support continued development of ethical productivity tools, you can do so here:  
https://buymeacoffee.com/bxmbshr

---

## Community and Feedback

- Telegram community: https://t.me/+Cpyd0Us0sisxOWE1  
- Bug reports and feature requests: https://github.com/Appaxaap/Focus/issues  
- Product Hunt page: https://www.producthunt.com/posts/focus-10  

---

## License

Focus is open source software licensed under GPL v3.0.  
See the LICENSE file for details.

---

> What is important is seldom urgent, and what is urgent is seldom important.  
> Dwight D. Eisenhower
