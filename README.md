# DeFilms — Movie Discovery for iOS

<p align="center">
  <img src="./DeFilms/App/Assets.xcassets/AppLogo.imageset/logoDark@3x.png#gh-dark-mode-only" width="140" alt="DeFilms">
  <img src="./DeFilms/App/Assets.xcassets/AppLogo.imageset/logo@3x.png#gh-light-mode-only" width="140" alt="DeFilms">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16%2B-blue?style=flat-square&logo=apple" alt="iOS 16+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Architecture-MVVM%20%2B%20Coordinator-blue?style=flat-square" alt="Architecture">
  <img src="https://img.shields.io/badge/API-TMDB-01d277?style=flat-square&logo=themoviedatabase" alt="TMDB API">
  <img src="https://img.shields.io/badge/Localization-EN%20%2F%20TR%20%2F%20AR-red?style=flat-square" alt="Localization">
  <img src="https://img.shields.io/badge/Tests-88%20tests-success?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/Apple%20Intelligence-Yes-purple?style=flat-square" alt="Apple Intelligence">
</p>

DeFilms is a SwiftUI movie discovery app built with the TMDB API. Designed as a small product rather than a one-off demo — stable navigation, testable state, careful persistence, polished localization, and a user flow that holds together across edge cases.

---

## Architecture

```
DeFilms/
├── App/                  # Composition root, lifecycle, routing, root views
├── Core/                 # Shared infrastructure
│   ├── Foundation/       # Extensions, validation, utilities
│   ├── Localization/     # L10n manager (EN/TR/AR)
│   ├── Logging/          # Structured logging
│   ├── Navigation/       # Coordinator + router
│   ├── Network/          # Endpoints, network manager, monitoring
│   ├── Security/         # Keychain, biometric auth
│   ├── Settings/         # App settings
│   ├── Storage/          # Core Data models + stack
│   └── UI/               # Theme, reusable components
├── Features/             # Vertical slices
│   ├── Auth/             # Local sign up/sign in, account management
│   ├── Lists/            # Custom movie lists
│   ├── Movies/           # Browse, search, detail, AI picks
│   ├── Onboarding/       # First-run flow
│   └── Settings/         # Preferences, privacy, account
├── DeFilmsTests/         # Unit tests (72 tests)
└── DeFilmsUITests/       # UI tests (16 tests)
```

### Key Design Decisions

| Principle | Implementation |
|-----------|---------------|
| **MVVM + Coordinator** | ViewModels own screen state, coordinators own navigation — views stay lean |
| **Protocol-driven Networking** | Repository abstractions with mockable protocols |
| **Feature-oriented Slices** | Each feature is a vertical slice: models, services, view models, views |
| **Apple Intelligence** | On-device AI picks via Foundation Models — graceful fallback when unavailable |
| **RTL-aware Localization** | Full Arabic support with layout-direction handling, not just translated strings |
| **Deterministic UI Tests** | Seeded launch arguments for consistent test flows |
| **Stale Response Protection** | Search and pagination guard against out-of-order async responses |

---

## Features

### Movies
- Search with validation and recent search history
- Filter/sort controls for year, rating, genre, ordering
- Rich detail pages: trailer, cast, watch providers, gallery, similar titles
- Browse sections: trending, now playing, popular, top rated, hidden gems, family night, upcoming, and more
- Section-scoped horizontal pagination

### AI Picks
- On-device movie recommendations powered by Apple Foundation Models
- Mood-based prompts (e.g. "tense but not too heavy")
- Context-aware: lists, watchlist, ratings, platform preferences, TMDB candidates
- Graceful fallback when Apple Intelligence unavailable or model not ready

### Lists
- Multiple custom lists instead of a single flat "saved" collection
- Full CRUD: create, rename, delete, move, remove movies
- Confirmation steps for destructive actions

### Settings
- Light / dark / system theme
- EN / TR / AR localization with RTL layout for Arabic
- Streaming platform preferences
- Local auth: sign up, sign in, sign out, password change, account deletion
- TMDB attribution, privacy notes, App Store review readiness

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI** | SwiftUI |
| **Concurrency** | Swift async/await |
| **Networking** | URLSession + custom network layer |
| **Persistence** | Core Data + Keychain + CryptoKit |
| **AI** | Apple Foundation Models |
| **Auth** | Local (Biometric + Keychain) |
| **Testing** | XCTest / XCUITest |

---

## Testing

```
Test Suite 'DeFilmsTests' passed
Test Suite 'DeFilmsUITests' passed
Executed 88 tests, with 0 failures
```

Coverage weighted toward regressions: view model state transitions, validation rules, persistence behavior, navigation-critical flows, async loading and error handling.

---

## Installation

### Requirements
- Xcode 16+
- iOS 16.0+
- TMDB API key

### Setup

```bash
git clone https://github.com/burak-bilgen/DeFilms.git
cd DeFilms
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Set TMDB_API_KEY in Config/Secrets.xcconfig
open DeFilms.xcodeproj
```

Select the **DeFilms** scheme, build and run on iOS 16+ simulator or device.

> `Config/Secrets.xcconfig` is git-ignored. Rotate any TMDB key that was ever committed before public use.

---

## Project Statistics

| Metric | Value |
|--------|-------|
| Swift files | ~96 (production) |
| Unit tests | 72 |
| UI tests | 16 |
| Localized languages | 3 (EN, TR, AR) |
| Minimum deployment | iOS 16.0 |
| External dependencies | TMDB API only |

---

## Localization

| Language | Layout |
|----------|--------|
| English | LTR |
| Turkish | LTR |
| Arabic | RTL |

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built with SwiftUI + TMDB API by <a href="https://github.com/burak-bilgen">Bilgen Works</a></sub>
</p>
