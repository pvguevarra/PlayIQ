
# PlayIQ

PlayIQ is a Flutter application designed to help flag football coaches and players streamline team management, communication, and training. It supports role-based access for coaches and players, allowing teams to create rosters, generate practice plans, share game strategies, and more.

## Tech Stack

- **Flutter + Dart**: Cross-platform mobile development.
- **Firebase Auth**: Secure user authentication.
- **Firestore**: Real-time NoSQL database for storing user and team data.
- **YouTube Player**: Embedded instructional videos in practice plans.
- **Material 3 + Iconsax**: Modern and consistent UI design.
- **Weather API**: Displays local weather conditions on the home screen.
- **Geolocator + Geocoding**: Fetches user location and city name.

## Architecture

PlayIQ is modularly structured with components handling authentication, team creation, dashboard views, and feature-specific UI.

### Authentication & Team Management
- Handles sign-up, login, and role assignment (coach or player).
- Users can create or join teams via a unique code.
- Coaches are auto-assigned as admins of their team.

### Dashboard & Navigation
- Bottom navigation bar provides access to Home, Community, Roster, and Settings.
- Home screen shows events, announcements, and weather updates.

### Practice & Game Planning
- Coaches can generate practice plans based on selected category and duration.
- Drills include embedded YouTube videos, equipment needs, and descriptions.
- Game plan page allows strategy input for upcoming games.

### Community & Roster
- Community board includes team discussion posts, comment threads, and vote counts.
- Roster is dynamically populated and auto-synced with user/team data.
- Coaches appear at the top with badge styling.

### Settings & Profile
- Users can edit username, change password, view team code, logout, or delete their account.

## Features

- Role-based access control (coach/player)
- Team creation and invite system via unique codes
- Drill-based practice plan generation
- Embedded training videos with categories and descriptions
- Event and announcement posting (coach-only)
- Community forum with upvotes, downvotes, and commenting
- Roster management with role badges
- Local weather forecast integration
- Modern Material 3 UI theme and intuitive navigation
- Secure Firebase authentication and Firestore data management

## Getting Started

To run PlayIQ on your own device using Flutter:

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- Android Studio or Visual Studio Code with Flutter/Dart plugins
- Firebase CLI (for re-generating config, if needed)
- A connected Android device or emulator

### Installation Steps

1. **Clone the repository**

```bash
git clone https://github.com/your-username/playiq.git
cd playiq
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Connect Firebase**

Make sure `firebase_options.dart` is already included (it is). If reconfiguration is needed:

```bash
flutterfire configure
```

> You’ll need Firebase CLI installed and authenticated to your Google account.

4. **Run the app**

Make sure your emulator or physical device is running:

```bash
flutter run
```

### Alternative: Using the APK

You can download and install the latest demo APK of **PlayIQ** directly from GitHub:

**[Download PlayIQ APK](https://github.com/pvguevarra/PlayIQ/releases/tag/v.1.0.0)**

> If the link doesn’t work, check the [Releases page] for the latest version.

---

### How to Install on Android Emulator

1. **Download** the APK using the link above
2. **Open your Android Emulator**
3. **Drag and drop** the `.apk` file onto the emulator window
4. The app will auto-install and launch

---

This version includes:
- Team creation and login
- Practice plan generator
- Playbook management
- Community forum and more


## Contributors

| Name             | GitHub Username     |
|------------------|---------------------|
| Patrick Guevarra | @pvguevarra         |

