# Campus Safety Reporter — Student UI Handoff

- [GitHub repository](https://github.com/desmondbcs24090043/uts-campus-safety-reporter)
- Branch: `feature/m2-auth-dashboard-integration`
- UI baseline: `f1f2d35d258a56d6020bd2482c3444e86fbb57d8`
- [Vercel Flutter Web demo](https://campus-safety-reporter-preview.vercel.app/)

The student preview starts at `lib/preview_auth_dashboard_main.dart`. Its layouts and navigation are ready to reuse. The preview uses mock authentication, demo report data, and sample notifications. Dark Mode is a working local preference.

## Get the right branch and run it

From a clone of the repository, with a clean worktree:

```sh
git fetch origin
git switch feature/m2-auth-dashboard-integration
git merge --ff-only origin/feature/m2-auth-dashboard-integration
git rev-parse HEAD

flutter pub get
flutter run -d chrome -t lib/preview_auth_dashboard_main.dart
flutter analyze
flutter test
flutter build web --release -t lib/preview_auth_dashboard_main.dart
```

If the branch does not exist locally, use `git switch --track origin/feature/m2-auth-dashboard-integration`. If your local branch has diverged or has uncommitted work, save your work and check with the team before integrating. Start your integration work on your own branch from the reviewed UI baseline. Apply targeted diffs and have another teammate review shared-widget and theme changes. Keep `lib/main.dart` untouched during preview integration. `lib/report_issue_ui_main.dart` is available for isolated report-form work.

## Screens and navigation

| Screen | Widget and source | Navigation and current behavior |
|---|---|---|
| Login | `LoginPage` in `lib/features/auth/presentation/login_page.dart` | First screen. Create an account opens Register. Mock student sign-in opens Dashboard. |
| Register | `RegisterPage` in `lib/features/auth/presentation/register_page.dart` | Back or successful mock registration returns to Login. |
| Dashboard | `_HomeScreen` in `lib/preview_integrated/preview_app_integrated.dart` | Home tab. View all selects My Reports, a report opens Report Details, the report button opens Report an Issue, and the bell opens Notifications. Counts and recent items use demo records. |
| My Reports | `_MyReportsScreen` in `lib/preview_integrated/preview_app_integrated.dart` | Bottom tab. Search, status filters, reload, loading, failure, and empty states work through `ReportsBloc`. Tap a record to open Report Details. |
| Report Details | `_ReportDetailsScreen` in `lib/preview_integrated/preview_app_integrated.dart` | Pushed from Dashboard or My Reports. Shows the report summary, description, Attached Photo card, and status timeline. The fictional corridor report has a labeled demo image that opens an enlarged viewer. Other reports show No photo attached. Back returns to the source tab. |
| Report an Issue | `ReportIssuePreviewPage` and `_ReportPreviewCompletePage` in `lib/preview/report_issue_ui.dart` | Dashboard → form → review sheet → edit or finish preview → completion → Home. Campus Area requires a labeled demo choice. Specific Location is optional. GPS and Map are optional demo aids. Camera and Gallery show demo notices. |
| Notifications | `NotificationsV2Page` in `lib/preview/notifications_ui.dart` | Dashboard bell → sample list → detail sheet. All/Unread and read actions work for the lifetime of the page. |
| Profile | `ProfileV2Page` in `lib/preview/profile_settings_ui.dart` | Bottom tab. Opens Settings and Help & Support. Sign out calls the injected callback and returns the mock flow to Login. Student account details are placeholders. |
| Settings | `SettingsV2Page` in `lib/preview/profile_settings_ui.dart` | Profile → Settings → About App. Dark Mode persists locally. Notifications is a local demo switch. |
| About App | `_AboutPage` in `lib/preview/profile_settings_ui.dart` | Static app description and version. Back returns to Settings. |
| Help & Support | `_HelpPage` in `lib/preview/profile_settings_ui.dart` | Static guidance. Back returns to Profile. |

`AuthDashboardPreview` gates entry to the student shell. The shell uses an `IndexedStack` with Home, My Reports, and Profile, keeping tab state while opening detail pages with `MaterialPageRoute`. The preview has an admin placeholder. Keep demo notices until each matching live flow is connected and verified.

## Member 1 — Authentication and Profile

- Keep the forms and shared `auth_visuals.dart` widgets. In the real app's composition root, supply an implementation of `AuthRepository` to `AuthCubit` in place of `MockAuthRepository`. The contract is `signUp(email, password)`, `signIn(email, password) → String role`, and `signOut()`.
- Initialize Supabase with `lib/core/supabase_config.dart` in the real entry point. Configuration uses `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from local Dart defines. Use a publishable key and keep local config and privileged credentials out of source control.
- Resolve the authenticated user's role through `ProfileRepository.fetchMyRole()` in `lib/data/repositories/profile_repository.dart`. It reads `profiles.role` for the current user, returns `null` with no session, and currently falls back to student when the profile row is missing. Map `UserRole.dbValue` to the existing `student` / `admin` routing values. Agree on missing-profile behavior, registration confirmation, session restoration and expiry, and sign-out error handling before release. The current cubit starts unauthenticated and its sign-out method has no error handler.
- Supply approved session/profile data to Profile in place of the placeholders. The existing Profile widget only takes `onSignOut`, and the repository currently fetches the role only. Keep Profile navigation and wire the callback to real session sign-out.

## Member 3 — GPS, photos, and submission

- Keep `ReportIssuePreviewPage` and its form, review sheet, and completion layout. Wire Use GPS to the platform location service and Choose on map to a real picker returning latitude and longitude. Replace the sample coordinates. Handle permission denied, disabled services, cancellation, and retry. The demo can review a report with Campus Area alone and no coordinates. Agree on the production area list and stable identifiers, how the optional Specific Location maps to the contract, and how manually located reports will supply the coordinates required by the current API.
- Wire Camera and Gallery to native pickers and keep the optional photo preview. Validate JPG/JPEG, PNG, or WEBP and the repository's 5 MB limit. Keep `ReportCategory` and the trimmed 5–1,000 character description rule.
- On confirmed submission, validate the `NewIncidentReport` fields. If a photo is selected, use `IncidentReportRepository.uploadPhoto(bytes, extension: ...)` and pass its private storage path as `photoPath`. Then call `createReport(...)` and show success after it returns the saved `IncidentReport`. The database supplies `reporter_id` and initial `pending` status. Use the saved result to refresh My Reports. Agree on retries, duplicate prevention and cleanup if upload succeeds but row creation fails.

## Member 4 — Supabase reports and Dashboard

- `lib/data/models/incident_report.dart` defines the shared `IncidentReport` row and `NewIncidentReport` insert contract. Keep `ReportCategory.dbValue` and the status values `pending`, `in_progress` and `resolved`. `lib/data/repositories/incident_report_repository.dart` owns reads, writes, uploads, and short-lived signed photo URLs from the private `report-photos` bucket.
- In the authenticated student entry point, supply `ReportsBloc(SupabaseReportsAdapter(IncidentReportRepository()))` and dispatch `ReportsRequested`, as the demo root does with `DemoReportsRepository`. The adapter in `lib/features/reports/data/supabase_reports_adapter.dart` calls `fetchMyReports`, maps database statuses to UI statuses, and converts each `IncidentReport` into a `ReportRecord` with category title and coordinate text. The student read filters on the current user's `reporter_id`. Verify RLS with real student sessions.
- Dashboard totals and recent reports currently derive from the fetched list. The repository defaults to 50 rows, and search/filter run on the loaded records. Agree on paging and full-history counts before treating the tiles as lifetime totals. Report Details gets the selected `ReportRecord`. Use `fetchReport(id)` and `photoUrl(photoPath)` at the authenticated data boundary for live details and photos. Keep the labeled demo asset scoped to the fictional report. In the live flow, display an attachment only when the real record has a photo path. Resolve the signed image URL from that path, and account for missing, expired, or inaccessible images. The current adapter drops photo paths and update timestamps, and the visual timeline reflects the current status. A real status history needs an agreed data source.

## Interfaces still to agree on

- **Notifications.** `NotificationsV2Page(notifications: ..., previewMode: ...)` accepts `CampusNotificationRecord` values with ID, report ID, title, message, date label, kind, and read state. Confirm delivery (push, local, or in-app), permissions, preference storage, server-side read actions, and report links. Keep the Dashboard bell as the list entry and Settings as the toggle entry. The page currently keeps read changes in memory.
- **Offline caching.** Use `IncidentReport.toJson()` / `fromJson()` as the shared serialization boundary. Confirm per-user cache isolation, refresh and stale-data behavior, sign-out cleanup, and whether offline submissions need a queue. Protect locations and private photo references. Agree on how to retain Campus Area, optional Specific Location, coordinates, and local attachments when saving drafts or queuing reports offline. Cache authorized attachment data or references per user. Renew expired signed URLs when online and keep the no-photo state distinct from an unavailable attachment. `shared_preferences` currently stores only the student theme for this UI. No report cache or submission queue is connected.

## Preserve the design and verify on Android

- Reuse `buildPreviewTheme` and `AdaptivePalette` in `lib/preview/preview_theme.dart` and the shared auth widgets. Preserve the approved Light/Dark tokens, including the Dark Pending background `#5B4529`. Keep `AppAppearance.restore()` before the first frame and the existing `student.dark_mode` preference. Light is the first-launch default.
- Keep Home / My Reports / Profile, the Dashboard bell, existing copy, stable widget keys, flexible rows and filter wrapping, scrollable sheets, and safe areas around pinned controls. Recheck 320, 360, 390, and 430 logical pixels in both themes. `test/student_responsive_test.dart` and `test/dark_mode_persistence_test.dart` cover the preview flows. The baseline passed Analyze, 43 tests, Web release build, and a browser smoke test on the Vercel alias.
- Vercel hosts the Flutter Web demo. For an Android UI smoke test, run `flutter devices` and then `flutter run -d <device-id> -t lib/preview_auth_dashboard_main.dart`. For the final Android release, build and install the APK from the agreed authenticated entry point. Complete cold-launch theme restoration, session handling, permissions, GPS/camera/gallery, actual report submission, and online/offline checks on Android. Web verification does not cover these Android behaviors.
