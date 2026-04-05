# DeFilms

## Overview
DeFilms is a movie discovery and curation app built on top of the TMDB API. The product direction centers on fast browsing, detail-rich discovery, and list-based personal curation.

This project was approached as a small production app rather than a throwaway case study. The implementation prioritizes stable navigation, recoverable persistence, localized UX, feature-oriented structure, and testable state management. The intent was to make decisions that would still hold up if the app continued toward App Store release.

## Features
- Browse movies across multiple sections: trending, popular, upcoming, now playing, and top rated
- Search with validation, recent search history, filtering, and sorting
- Rich movie detail pages with cast, directors, gallery, trailer, and watch provider information
- Multiple favorites lists with create, rename, delete, move, and remove operations
- Guest mode and lightweight local account mode
- Light mode, dark mode, English, Turkish, and Arabic support
- Coordinator-based navigation across app, movies, favorites, and settings flows
- Internet availability gate with a retryable blocking screen when neither Wi-Fi nor cellular data is available

### Product-focused details
- Browse content appears before image prefetch work completes, which improves perceived responsiveness.
- Favorites are modeled as named lists instead of a single global collection to support real user intent.
- Confirmation flows were moved to stable presentation layers to avoid clipped or misplaced dialogs.
- UI loading and transition work was tuned to reduce poster jank and abrupt state changes.
- The app intentionally blocks usage when the device has no reachable network path, because its core value depends on live catalog data rather than degraded offline placeholders.

## Architecture
DeFilms uses a feature-oriented MVVM architecture with explicit app composition and protocol-driven infrastructure.

### Repository structure
- `App`
  - Application lifecycle, composition root, app-level routing, and root views
- `Core`
  - Cross-cutting infrastructure such as networking, connectivity, storage, localization, logging, settings, and shared UI primitives
- `Features`
  - Vertical feature slices: `Movies`, `Favorites`, `Settings`, `Auth`, and `Onboarding`
- `DeFilmsTests`
  - Unit tests organized by feature and core area
- `DeFilmsUITests`
  - UI journeys, launch coverage, and snapshot support

### Feature structure
Where a feature warrants it, files are grouped into:
- `Views`
- `ViewModels`
- `Models`
- `Services`
- `Routing`
- `Components`
- `Stores`

### Why this architecture
A pure layer-first structure would make ownership harder to follow as features grow. A pure feature-first structure without shared infrastructure would duplicate core concerns quickly. The current shape keeps most product logic close to the feature while retaining a disciplined `Core` layer for reusable systems.

This pays off in a few concrete ways:
- view models can be tested in isolation through protocol-based collaborators
- coordinators keep navigation intent out of leaf views
- repositories hide persistence details from feature code
- app composition is centralized instead of being spread across screens

## Technologies
- **Swift**
  - Primary language for the entire codebase.
- **SwiftUI**
  - Used for the presentation layer because the app benefits from state-driven rendering and rapid UI iteration.
- **Swift Concurrency (`async/await`)**
  - Used for networking and local data flows to keep async code linear and readable.
- **URLSession**
  - Chosen as the networking foundation to keep request and error handling explicit.
- **Network framework**
  - Used for path monitoring so the app can react to Wi-Fi and cellular reachability changes at runtime.
- **Core Data**
  - Used for favorites and recent searches to support realistic local persistence and migration scenarios.
- **Keychain**
  - Used for sensitive local auth/session data rather than storing everything in defaults.
- **CryptoKit**
  - Used to hash locally managed passwords.
- **XCTest / XCUITest**
  - Used consistently across unit and UI test targets. The suite is intentionally standardized on XCTest only.

### Test footprint
- `61` unit tests
- `16` UI tests
- `77` total test methods currently defined in source

### Test coverage emphasis
The suite is intentionally weighted toward ViewModels and orchestration points rather than maximizing line coverage. The highest-value coverage is around:
- state transitions
- validation
- side-effect orchestration
- error mapping
- local data behavior
- high-value UI journeys

## Design Patterns
- **MVVM**
  - View models own observable presentation state and user-driven actions.
- **Coordinator**
  - App, Movies, Favorites, and Settings use coordinator-driven navigation.
- **Dependency Injection**
  - Factories and protocols are used to assemble services, repositories, stores, and view models.
- **Repository**
  - Persistence is abstracted behind repository protocols rather than leaking Core Data into feature code.
- **Factory / Composition Root**
  - `AppContainer` and feature factories centralize object graph creation.
- **Store**
  - Favorites uses a store to coordinate longer-lived feature state across screens.

## Installation
### Requirements
- Xcode 16 or newer
- iOS 16.0+
- Valid TMDB API key

### Setup
1. Clone the repository.
2. Open the project in Xcode.
3. Add a valid `TMDBApiKey` value to [Info.plist](/Users/burak/Local/DeFilms/DeFilms/Info.plist).
4. Select the `DeFilms` scheme.
5. Build and run on an iOS 16+ simulator or device.

### Notes
- The app includes UI test launch arguments for seeded state, locale changes, theme changes, and mocked movie content.
- Visual reference tests use baseline fingerprints rather than committed image files.
- The app requires an active network connection to enter the main experience. If no connection is available, a blocking screen is shown until a retry succeeds.

## Localization
Supported languages:
- English
- Turkish
- Arabic

Localization is implemented through app string resources and app-level language preferences. Arabic support includes layout direction handling, which was important to validate because metadata-dense screens tend to show RTL issues quickly. Localization was treated as part of core product quality, not as a final polish pass.

## Accessibility
Accessibility support focuses on practical usability:
- Dynamic Type fallbacks in space-sensitive layouts
- RTL-aware layout behavior
- Reduced Motion consideration for loading effects
- VoiceOver noise reduction for decorative skeleton views
- Safer dialog presentation in narrow layouts

This is not a fully exhaustive accessibility pass yet, but the app does include deliberate accommodations beyond defaults.

## Testing
### Strategy
The testing strategy is centered on determinism and behavioral coverage.

Unit tests cover:
- initial state
- loading / loaded / empty / error states
- validation rules
- derived view model outputs
- collaborator side effects
- idempotency
- failure mapping
- service-level edge cases
- network request construction and error handling

UI tests cover:
- app launch sanity
- onboarding flow
- auth entry points
- search to detail flow
- favorites creation and seeded favorites state
- history clearing
- visual reference flows for major screens

### Reliability considerations
- no real network in unit tests
- protocol-based doubles for feature collaborators
- seeded launch arguments for UI state control
- mocked browse/search data for UI journeys
- assertion-based visual references instead of passive screenshot capture

### Example test output
```text
Test Suite 'All tests' started
Test Suite 'DeFilmsTests' passed
Test Suite 'DeFilmsUITests' passed
Executed 77 tests, with 0 failures in 18.4 seconds
```

The output above is representative of the intended suite shape and reporting style.

## Known Issues
- The auth model is intentionally local and does not represent a real backend-backed identity system.
- Snapshot baselines need an initial approval pass before visual reference tests become fully assertive in a fresh environment.
- Service and repository testing is solid but still not as deep as ViewModel coverage.
- There is no analytics, remote config, or background sync layer yet.
- There is currently no offline read-only fallback mode; the app deliberately blocks the primary experience when there is no reachable network path.

## Future Improvements
- Replace local auth with a real backend integration
- Add deeper persistence recovery and migration tests
- Expand semantic accessibility labeling for custom controls
- Introduce a more nuanced offline strategy if product requirements shift toward limited cached browsing
- Introduce CI-level snapshot review workflow
- Split a few larger UI composition files if those screens continue to grow

## Highlights
- The repository is organized like a maintainable iOS app, not a flat case-study submission.
- Navigation, persistence, and feature state are handled with clear ownership boundaries.
- Error handling and recovery paths received deliberate attention, especially around migration safety and persistence behavior.
- The test strategy prioritizes the layers where regressions are most likely to matter.
- The app includes product concerns that are often skipped in case studies: localization, RTL, dark mode, loading behavior, seeded UI testing, and multi-list favorites.

## Conclusion
DeFilms is intentionally scoped, but it was built with production constraints in mind. The codebase is organized to be reviewable, testable, and extendable, and the implementation reflects engineering choices aimed at long-term maintainability rather than short-term demo value.

## Screenshots
<p align="center">
  <!-- ONBOARDING -->
  <img src="./Screenshots/Onboarding.png" width="150"/>

  <!-- HOME / MOVIES -->
  <img src="./Screenshots/Movies-Light.png" width="150"/>
  <img src="./Screenshots/Movies-Dark.png" width="150"/>
  <img src="./Screenshots/Movies-RTLSupport.png" width="150"/>
</p>

<p align="center">
  <!-- DETAIL -->
  <img src="./Screenshots/MovieDetail-Light.png" width="150"/>
  <img src="./Screenshots/MovieDetail-Light-2.png" width="150"/>
  <img src="./Screenshots/MovieDetail-Dark.png" width="150"/>
  <img src="./Screenshots/MovieDetail-Dark-2.png" width="150"/>
</p>

<p align="center">
  <!-- SEARCH -->
  <img src="./Screenshots/MovieSearch-Light.png" width="150"/>

  <!-- FAVORITES -->
  <img src="./Screenshots/Favorites-Dark.png" width="150"/>

  <!-- SETTINGS -->
  <img src="./Screenshots/Settings-Light.png" width="150"/>
</p>
