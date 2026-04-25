# DeFilms App Store Submission Checklist

## Before Archiving

- Rotate the TMDB API key that was previously committed.
- Keep the live key only in ignored `Config/Secrets.xcconfig`; new contributors should copy `Config/Secrets.xcconfig.example`.
- Confirm `TMDB_API_KEY` is populated for the archive build.
- Confirm the archived `.app` does not contain `Secrets.xcconfig` or any other local configuration file.
- Confirm the archived `.app` includes `PrivacyInfo.xcprivacy`.
- Keep the Release Swift inliner workaround until a newer Xcode no longer crashes optimized DeFilms builds.
- Confirm Settings > About > TMDB Attribution shows the TMDB logo and required disclaimer.
- Confirm Settings > About > Privacy & Data matches the current app behavior.
- Confirm Settings > Account > Delete Local Account removes the signed-in local profile data.
- Confirm the app is distributed as free and non-commercial unless a separate TMDB commercial agreement exists.
- Run the unit test suite before archiving and a full UI pass before TestFlight or App Review submission.

## App Store Connect Privacy

Use `PRIVACY.md` as the public Privacy Policy URL after it is hosted on a public page.

Suggested disclosure basis for the current build:

- DeFilms does not run ads, analytics, or tracking.
- Favorites, recent searches, local profile data, and preferences are stored on device.
- Movie search text and content requests are sent to TMDB to service the user's request.
- `PrivacyInfo.xcprivacy` declares the app's UserDefaults usage as a required-reason API.
- Re-check App Store Connect answers if analytics, crash reporting, ads, subscriptions, or a backend account system are added later.

## Review Notes

Suggested note:

```text
No server account is required. Reviewers can continue as guest or create a local-only account inside the app. Local account data stays on the device and can be deleted from Settings > Delete Local Account.

Movie data is provided by TMDB. TMDB attribution and disclaimer are available in Settings > About > TMDB Attribution.
```

## Metadata Disclaimer

Suggested App Store description footer:

```text
Movie metadata and images are provided by TMDB. This product uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB.
```
