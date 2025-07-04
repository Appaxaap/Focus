<h1 align="center">🧭 Focus – Stay Productive, Not Just Busy</h1>

<p align="center">
  <img src="https://github.com/user-attachments/assets/0b26465a-9712-4286-b796-68aac70ef7d1" alt="Logo" width="150" />
</p><!-- Replace with your actual logo file path -->

![Android](https://img.shields.io/badge/platform-Android-green?style=flat-square&logo=android)  
![Flutter](https://img.shields.io/badge/flutter-3.10.5-blue?style=flat-square&logo=flutter)  
![Version](https://img.shields.io/github/v/release/Appaxaap/Focus?style=flat-square)  
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)

A fully offline Eisenhower Matrix planner built with Flutter.  
No distractions. No ads. No cloud. Just **you and your priorities**.


![feature_graphics](https://github.com/user-attachments/assets/2ced335e-9bc7-45b2-8022-dd3079a7c77a)


---

## 🧠 Why I Built This

I’ve tried dozens of productivity apps — most of them either lock features behind paywalls, require sign-ups, track your behavior, or worst of all… flood you with notifications.

**All I wanted was a simple, no-nonsense app** to organize my day using the Eisenhower Matrix — a method that actually works. So I built **Focus**:

- Offline-first by default
- No data collection
- Works out of the box
- Designed for clarity, not complexity

---

## 🚀 What is the Eisenhower Matrix?

The Eisenhower Matrix is a timeless productivity method that helps you **stop reacting and start planning**.

It splits your tasks into four clear quadrants:

| Urgent     | Not Urgent         |
|------------|--------------------|
| ✅ Important → Do now     | 🕒 Important → Plan it |
| ❗ Not Important → Delegate | 🚫 Not Important → Eliminate |

**Focus** brings this matrix to life in a calm, visual layout — right on your phone.

---

## ✨ What You Can Do with Focus

- 📋 Add, edit, and move tasks across 4 quadrants
- 🌗 Switch between light and dark mode (Material You)
- ✅ Mark tasks as complete
- 👁️ Show or hide completed tasks
- 📋 View all tasks in list mode
- 💾 Works entirely offline with local storage (Hive)
- 🔐 No login, no sync, no tracking

---

## 🧰 Built With

| Tech | Purpose |
|------|---------|
| [Flutter](https://flutter.dev/) | Cross-platform UI |
| [Hive](https://pub.dev/packages/hive) | Lightweight local database |
| Material You | Dynamic, adaptive theming |
| No Firebase | 100% local, zero dependencies |

---

## 📦 How to Run the App

### 📱 For Developers (Run from Source)
```bash
git clone https://github.com/Appaxaap/Focus.git
cd Focus
flutter pub get
flutter run
````

> Works on Android. iOS coming later.

---
## Screenshots 📱

<p align="center">
  <img src="https://github.com/user-attachments/assets/3129b7de-d6ca-48e6-b454-bb8bad2c2fa0" alt="Screenshot 1" width="300" />
  <img src="https://github.com/user-attachments/assets/f7f7dafe-1a88-409e-a995-7ed660792815" alt="Screenshot 2" width="300" />
  <img src="https://github.com/user-attachments/assets/cc7aeac3-c5fa-408b-92fd-8090979237d8" alt="Screenshot 3" width="300" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/d1498880-d459-4cf6-ad9e-f2718bce4964" alt="Screenshot 7" width="300" />
  <img src="https://github.com/user-attachments/assets/00189dab-eeec-453f-be9c-dd5b56640673" alt="Screenshot 8" width="300" />
  <img src="https://github.com/user-attachments/assets/fb49fadb-2e0d-48f0-b325-707cfd49e97c" alt="Screenshot 9" width="300" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/79c70e9d-8f7b-457b-bb4c-e076dc995c7b" alt="Screenshot 4" width="300" />
  <img src="https://github.com/user-attachments/assets/aeb6ef92-fedb-4c56-b45d-089e4f7459da" alt="Screenshot 5" width="300" />
  <img src="https://github.com/user-attachments/assets/eb7fed94-07d5-44a0-b5f8-61e83185aa61" alt="Screenshot 6" width="300" />
</p>

---
## 🤔 What Makes It Different?

* No signup or account needed
* No push notifications
* No backend, no Firebase
* No ads, ever
* No internet required
* No overthinking — just plan and go

It’s built around a simple idea:
**Your mind deserves clarity, not clutter.**

---

## 💡 Who Is It For?

* Indie makers and developers
* Students and self-learners
* Creatives who value deep work
* Anyone tired of noisy task apps

If you want something minimalist, private, and purposeful — this is for you.

---

## 🛠️ Project Structure (Simplified)

```
lib/
├── models/                # Data models for tasks and quadrants
│   ├── quadrant_enum.dart
│   ├── task_models.dart
│   └── *.g.dart           # Hive-generated adapter files
│
├── providers/             # State management using Riverpod/Provider
│   ├── filter_provider.dart
│   ├── task_provider.dart
│   ├── task_providers.dart
│   └── theme_provider.dart
│
├── screens/               # App screens
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   └── task_edit_screen.dart
│
├── services/              # Local services
│   ├── hive_service.dart
│   └── notification_service.dart
│
├── utils/                 # Utilities and constants
│   ├── constants.dart
│   ├── date_utils.dart
│   ├── enums.dart
│   └── theme_data.dart
│
├── widgets/               # Reusable UI components
│   ├── quadrant_card.dart
│   ├── settings_bottom_sheet.dart
│   └── task_tile.dart
│
├── hive_initializer.dart  # Initializes Hive boxes
└── main.dart              # Entry point

```

---

## 📄 License

This project is open-source under the **MIT License**.
That means it's free to use, change, and share — forever.
```
MIT License

Copyright (c) 2025 Basim Basheer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

---

## 🙋 Who Made This?

Hi, I’m **Basim Basheer** — Founder of [Codecx](https://codecx.ae), UX engineer, and Indie app builder.

I built **Focus** to solve a personal problem, and I hope it helps you too.

You can reach me at:
📧 [basim@codecx.ae](mailto:basim@codecx.ae)
🐦 [@Basim Basheer](https://x.com/Appaxaap)

---

## 🌍 Want to Help?

* Spot a bug? Open an issue.
* Have an idea? Let’s discuss it.
* Like the app? A ⭐ star means a lot.

Let’s keep this simple, human, and helpful — together.

---

## ✈️ Coming Soon

* F-Droid release
* Play Store version
* Optional task reminders
* Export to PDF/Markdown

---

> “What is important is seldom urgent and what is urgent is seldom important.”
> — Dwight D. Eisenhower
