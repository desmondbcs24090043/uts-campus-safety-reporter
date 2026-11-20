# Student App Integration Handoff

Audit date 20 November 2026. Prepared from the actual local working tree, including modified and untracked files.

Project root is `D:\IT_MAD\campus_safety_admin_integration_kit\campus-safety-integration\team-repo`. Source paths below are relative to this root.

Branch is `feature/m2-student-media-ui`. HEAD is `89182cd97427e12d73d9a3b0e9c33a336024e399`. The local enhancements include uncommitted and untracked files. HEAD alone cannot reproduce this working tree.

Student Preview is available at [the fixed Vercel URL](https://campus-safety-reporter-preview.vercel.app/). The previous deployment used `lib/preview_auth_dashboard_main.dart` with `REAL_MEDIA=true`.

## Evidence and status

**Confirmed source facts** describe code inspected in this audit. **Proposed integration** describes work for group agreement. Production Supabase configuration, applied migrations, policies and authenticated end-to-end behavior were not queried during this documentation audit. Supabase-backed code is present, with live acceptance still pending.

The earlier verification session recorded Analyze success, 51 passing Flutter tests, six focused tests with Real Media enabled, successful Web release and Android debug APK builds, and Chrome checks at 320, 360, 390 and 430 px in both themes. Those results establish preview behavior. This audit ran read-only source/Git checks and document validation only. Android camera permissions and device capture still require runtime testing.

### Entry points

| File | Confirmed composition |
|---|---|
| `lib/preview_auth_dashboard_main.dart` | `MockAuthRepository` → `AuthCubit` → `AuthDashboardPreview` → `ReportsBloc(DemoReportsRepository())` → Student UI. Admin access reaches a placeholder. |
| `lib/live_student_main.dart` | Opt-in `SupabaseAuthRepository`, startup session restoration and student-role check → `ReportsBloc(SupabaseReportsAdapter(IncidentReportRepository()))` → the same Student UI. The form, Feed and other preview-only features stay local. |
| `lib/main_admin.dart` | Supabase initialization → `AdminApp` → `AdminAuthGate` with auth-state subscription and admin-role verification. |
| `lib/main.dart` | Flutter counter template. The team must explicitly agree on the final Android launch entry point. |
| Other `preview*_main.dart` and `report_issue_ui_main.dart` | Earlier/isolated preview entry points. Use the agreed entry point when reproducing integration results. |

### Feature inventory

| Feature | Confirmed implementation and gap | Integration responsibility |
|---|---|---|
| Register/login/sign-out | Supabase-backed methods exist in `lib/features/auth/data/supabase_auth_repository.dart`. The deployed preview uses `mock_auth_repository.dart`. Live acceptance pending. | Member 1, with Member 2 UI wiring |
| Session and roles | Live Student startup checks `auth.currentUser` and `ProfileRepository.fetchMyRole()`. Its gate lacks the Admin gate's auth-state subscription. `AuthCubit.signOut()` has no error recovery. | Member 1 |
| Dashboard/My Reports | Shared UI and BLoC work with demo or Supabase repository injection. Live adapter fetches own reports. Search and status filtering operate on loaded records. | Member 2, Member 4 data contract |
| Student Report Details | Live Dashboard/My Reports now open an injected read-only loader that fetches the selected report afresh. Demo routes retain fixtures. Existing private-photo paths use a safe unavailable placeholder pending Storage confirmation. | Member 2 with Members 3/4 |
| Campus Feed | `lib/preview/campus_feed_ui.dart` uses `demo_data.dart`. Category filtering and View details work locally. | Member 2 UI, Member 4 backend |
| Comments and staff labels | Fictional author/time/staff fixtures. Own comments use `You (demo)`, device time and in-memory add/delete. Backend support missing. | Members 2/4, Member 1 identity dependency |
| Helpful / I also noticed | In-memory sets. Helpful is a personal binary toggle with a 0/1 display. Own comments have no Helpful control. Noticed is also a local 0/1 toggle. Shared totals and backend permissions are missing. | Members 2/4 |
| Form and review | `ReportIssuePreviewPage` validates category, description and Campus Area. Finish navigates to preview completion and states that no report was submitted. Repository submission is unwired. | Member 3 with Member 2 |
| GPS / map | Sample coordinates and a simulated location sheet. No real device location or map selection is wired here. | Member 3 |
| Photo/video selection | `NativeMediaPickerCard` uses `image_picker` when `REAL_MEDIA=true`. Selection and removal are local. Photo thumbnails and video preview work. Backend upload is unwired. | Member 3 |
| Web/Android video preview | `video_preview.dart` conditionally selects Web URL/blob playback or native file playback using `video_player`. | Member 3, Member 5 platform QA |
| Shared report/Storage layer | `IncidentReportRepository` implements report reads, create, admin status updates, one-photo upload and signed URLs. Models and migrations contain one nullable `photo_path`. Live acceptance pending. | Member 4 |
| Web Admin | Real Supabase auth, role gate, report list, selected report fetch, signed photo URL and status update calls exist under `lib/admin/`. Live acceptance pending. | Member 4 |
| Profile | Student account/profile text is a placeholder. The shared profile repository fetches role only. | Member 1 with Member 2 |
| Notifications | `NotificationsV2Page` shows sample records and keeps read changes in page memory. Settings notification toggle is local state. Delivery and persisted read/preferences are missing. | Member 5 with Member 4 |
| Offline support | Report serialization exists through `IncidentReport.toJson/fromJson`. No report cache, attachment draft store or submission queue is connected. | Member 5 with Members 3/4 |
| Light/Dark appearance | Implemented locally using `AppAppearance` and `shared_preferences` key `student.dark_mode`. First-launch default is Light. | Member 2, Member 5 regression QA |

## Existing contracts to preserve

Evidence is in [the API contract](../backend/API_CONTRACT.md), `lib/data/models/`, `lib/data/repositories/` and the three existing files under `supabase/migrations/`. The API document is labeled DRAFT v1. The following reflects the checked-in implementation.

- `profiles` contains identity, role and creation time. It currently provides no display-name field for comment authors.
- `incident_reports` contains category, description, required latitude/longitude, one nullable `photo_path`, status and timestamps. It has no Campus Area, Specific Location, video attachment, public-feed publication flag, comment or reaction contract.
- Valid categories are `safety_hazard`, `facility_damage`, `suspicious_activity`, `lighting` and `other`. Description is trimmed and must contain 5–1,000 characters.
- The client omits `reporter_id` and initial status on insertion. Database defaults and RLS control ownership and initial `pending` status.
- Student report reads are owner-only. Admin reads cover all reports. Admin updates are limited to status. Report deletion is unavailable under current grants.
- The private `report-photos` bucket accepts JPEG, PNG and WEBP up to 5 MB. Student access is scoped to their own folder, and Admin can read images. `photoUrl()` supplies short-lived signed URLs.
- Existing SQL security tests are in `supabase/tests/rls_security_tests.sql`. Their presence does not establish the currently deployed database state. Execute and record them against the approved test environment during integration.

## Authentication handoff

**Confirmed facts.** Login and Register use `AuthCubit` and the existing `AuthRepository` interface in `lib/features/auth/data/auth_repository.dart`. Its methods use named `email` and `password` arguments, and sign-in returns a role string. A reusable Supabase implementation already exists as an untracked local file.

`SupabaseAuthRepository` calls Supabase sign-up and password login. After sign-up it signs out any returned session so the user returns to login. Student sign-in validates the profile role and signs out rejected roles. `ProfileRepository` currently treats a missing profile row as student.

**Proposed integration.** Member 1 should review and adopt or reconcile this implementation with the official Authentication work through the same interface. Member 2 should keep the existing forms and inject the agreed repository at the composition root. Agree on one Student auth gate and one role source.

**Acceptance criteria.**

- Confirm registration with email confirmation enabled and disabled. UI messages match the project's actual confirmation requirement.
- Valid login, invalid credentials, startup session restoration, refresh/expiry, external sign-out and sign-out failure behave consistently.
- Admin accounts use the Admin portal. Missing/malformed roles and failed role reads have an agreed behavior.
- Profile identity shown in the Student UI comes from the authenticated account.
- Student A cannot read Student B's private reports or attachments. Test with real student sessions and verify database enforcement.
- Keep privileged keys out of Flutter and browser builds. Use the existing local configuration mechanism and approved publishable key.

## Reports, Details and submission handoff

**Confirmed facts.** `SupabaseReportsAdapter.fetchMyReports()` maps shared `IncidentReport` rows to UI `ReportRecord` values. It drops `photoPath`, `reporterId` and `updatedAt`. It uses the category label as title and coordinates as location text. Student Details receives this UI record and never resolves a real signed attachment URL.

`fetchMyReports()` defaults to 50 rows. Dashboard tiles derive from loaded records. The adapter does not currently use `countByStatus()` or expose paging. The timeline illustrates current status, without a status-history source.

**Proposed integration.**

- Member 2 and Member 4 agree on a presentation boundary that preserves the selected report identity and access to attachment/status information. Member 2 wires authenticated detail fetching and authorized image loading.
- Member 3 connects confirmed submission to the shared repository. The current single-photo flow is upload → obtain path → `createReport(NewIncidentReport(...))` → receive saved row → refresh Student reports.
- Members 3/4 agree how Campus Area and Specific Location map to production data. The demo accepts manual area selection without GPS, while the current insert contract requires coordinates.
- Agree on dashboard totals, paging and freshness after Admin status updates. Current source has no report Realtime subscription.
- Agree on retry/idempotency and recovery when an upload succeeds but report creation fails. The current Storage migration provides no client cleanup policy for abandoned uploads.

**Acceptance criteria.** Successful submission is shown only after the required uploads and saved report row are confirmed. Upload or row failure keeps an actionable draft and displays an error. Reload shows the saved report and correct media. Admin status changes appear after the agreed refresh mechanism. Zero attachments, loading errors and expired/unauthorized signed URLs have distinct states.

## Media handoff

**Confirmed facts.**

- `REAL_MEDIA=false` uses bundled photo samples. `REAL_MEDIA=true` selects `NativeMediaPickerCard` in the existing form and uses `NativeMediaSelection` for page-lifetime state.
- Selection allows three photos and one video. Photos have filename-extension checks and a 5 MB size limit. Video has a temporary 25 MB client limit. The picker passes a 30-second maximum-duration request, with no separate returned-file duration validation.
- Web playback uses `VideoPlayerController.networkUrl` with the selected file URL. Android uses `VideoPlayerController.file`. Browser URLs and temporary picker files require an agreed retention strategy for later drafts/uploads.
- The form reviews selected media counts. It makes no `uploadPhoto`, video-upload or `createReport` call. Newly selected media is independent of the fixture photos shown in demo Details.
- The shared repository and image-only Storage contract provide no multi-photo/video persistence API.

**Proposed integration.** Member 3 owns device permissions, picker cancellation/errors, attachment validation, upload orchestration and submission UX. Member 4 owns the agreed attachment representation, Storage MIME/size rules, ownership, authorized reads and cleanup mechanism. Member 2 wires saved attachments into Details and preserves the approved photo UI. Member 5 coordinates offline retention and platform failure tests.

**Acceptance criteria.** Agree on MIME types, duration, byte limits, ordering and replacement/removal rules. Validate actual file content and server limits. Verify canceled picks, permission denial, unsupported codecs, oversize files, interrupted uploads and duplicate retries. Confirm Web selection/playback and Android camera/gallery/playback separately. Preserve old reports with null or single `photo_path` through any agreed contract evolution. Multi-attachment changes require an approved new migration and compatible repository/model changes.

## Campus Feed, comments and reactions handoff

**Confirmed facts.** Feed entries use fictional `DemoReport` records and `CSR-...` IDs. View details maps these fixtures into the existing Student detail page. Comments, Helpful and Noticed have no Supabase queries. Their UI state is local and temporary. Comment author/staff identity is fixture data and new comment timestamps use the device clock.

**Proposed integration.** Member 4 defines an authenticated/public Feed access contract with the group, including publication/moderation criteria and safe fields. The current report statuses do not define publication approval. Preserve the private owner-only report boundary and explicitly design cross-student access to any published media.

Members 1/4 agree on author display identity and server-derived staff roles. Members 2/4 agree on comment create/list/delete, pagination, timestamps, Helpful totals and Noticed totals. Candidate uniqueness rules are one reaction per user/comment and one Noticed reaction per user/report. These are proposals requiring team approval.

**Acceptance criteria.**

- Only authorized, publishable reports and permitted fields appear. Private reports, precise locations and private files remain protected according to the agreed policy.
- Use production report UUIDs for live detail routes. Fixture identifiers stay confined to demo routes.
- Author name, staff identification and server timestamps are accurate. Ordinary users cannot supply a trusted Staff flag.
- Users can delete their own comments and cannot delete another user's comments through direct API calls.
- Toggle/retry/concurrent actions preserve correct aggregate counts without duplicate reactions.
- Account changes, refresh, loading errors and offline operation follow the agreed persistence behavior.

## Offline and notifications handoff

Member 5 coordinates both areas with Member 4 contracts and Member 3 draft/submission behavior.

**Proposed integration.** Agree on per-user report caches, draft schema, local attachment lifetime, offline queue policy and explicit queued/sending/failed/submitted states. Browser blob URLs are ephemeral. Decide how attachment bytes survive reloads or app restarts. Clear or isolate private data on account changes.

Agree on notification source, delivery channel, recipients, read state, preferences, permissions and report links. A status update does not currently generate a live notification in this code. The Settings switch does not currently control delivery.

**Acceptance criteria.** Test offline launch/read, stale cache indication, interrupted transfer and reconnection, duplicate prevention, sign-out cleanup and account switching. Notification read/preference changes persist as agreed. A notification opens an authorized report. Test permission denial and supported Web/Android delivery behavior separately.

## Action checklist by member

### Member 1 — Authentication

- [ ] Reconcile the existing Supabase auth repository with the official implementation and retain the shared interface.
- [ ] Agree on the final Student auth gate, session events, role handling and registration confirmation.
- [ ] Connect real profile identity with Member 2 and author identity with Member 4.
- [ ] Pass student/admin isolation, expiry, restoration and sign-out acceptance tests.

### Member 2 — Student Dashboard and UI Integration

- [ ] Keep Home / My Reports / Campus / Profile navigation and the approved Light/Dark system.
- [ ] Wire the agreed live report/detail presentation boundary, signed media loading, refresh and totals.
- [ ] Replace Feed/comment/reaction fixtures through agreed contracts and preserve failure/empty states.
- [ ] Keep photo thumbnails in one row with full-screen viewing, and preserve media form/review behavior.
- [ ] Coordinate a single production composition root with Member 1.

### Member 3 — Report Submission and Media

- [ ] Implement real GPS/map selection and agree on manual-location mapping with Member 4.
- [ ] Validate selected media and complete upload/submission orchestration using agreed repositories.
- [ ] Agree with Members 4/5 on retry, orphan cleanup, durable drafts and queue semantics.
- [ ] Show saved success only after confirmed persistence and refresh Member 2's report list.
- [ ] Verify Android permissions, cancellation, camera/gallery and video playback on a running device/emulator.

### Member 4 — Backend and Web Admin

- [ ] Review the checked-in API draft against the actual test database and run/record RLS tests.
- [ ] Agree on multi-attachment representation, compatible migration, MIME/size rules and Storage access.
- [ ] Define Feed publication, redacted fields, comment ownership and reaction aggregate contracts.
- [ ] Coordinate author/staff identity, notification events and offline retry support.
- [ ] Verify Admin report reads, photo access and status updates against real accounts.

### Member 5 — Offline, Notifications and Testing

- [ ] Agree on caches, drafts, attachment retention and any submission queue with Members 3/4.
- [ ] Connect notification delivery, persisted read state and Settings preferences.
- [ ] Test multi-user privacy, offline/reconnection, expired URLs and partial upload failures.
- [ ] Re-run responsive/theme regressions, real Web media tests and Android runtime tests.
- [ ] Record the exact entry point, build defines, source revision/local patch and test environment.

## Recommended integration order

| Step | Lead and dependencies | Exit condition |
|---|---|---|
| 1. Capture the local handoff | All members coordinate local modified/untracked files. | Shared, reviewable snapshot includes every required file. No teammate changes are lost. |
| 2. Reconcile Authentication | Member 1 with Member 2, using Member 4's profile contract. | One agreed Student gate passes live auth/role/session criteria. |
| 3. Complete own-report reads | Member 2 with Member 4. | Own reports, live Details and existing single-photo signed reads pass privacy tests. |
| 4. Agree location/media and publication contracts | Member 4 with Members 1/2/3/5. | Written interfaces, compatibility and permissions approved before schema work. |
| 5. Complete submission/media | Member 3 with Members 2/4. | Persisted report and required files appear in Student Details and Admin. Partial failure recovery works. |
| 6. Complete Feed/comments/reactions | Member 2 UI with Member 4 backend and Member 1 identity. | Publication, ownership and aggregate-count acceptance criteria pass. |
| 7. Integrate offline/notifications | Member 5 with Members 2/3/4. Draft/queue contract design starts at step 4. | Persistence, reconnect, account isolation and delivery criteria pass. |
| 8. Run shared acceptance | All members, coordinated by Member 5. | Approved live environment passes Web and Android end-to-end tests with recorded evidence. |

Steps 4–6 can proceed in parallel after their shared contracts are agreed.

## Verification commands for the team

Run from the project root. Live commands require an approved local configuration. Keep `env.json`, session tokens and private credentials out of shared logs and commits.

```powershell
# Interactive Student preview with actual local media selection
flutter run -d chrome -t lib/preview_auth_dashboard_main.dart --dart-define=REAL_MEDIA=true

# Opt-in live Authentication and own-report reads
flutter run -d chrome -t lib/live_student_main.dart --dart-define-from-file=env.json --dart-define=REAL_MEDIA=true

# Separate Web Admin
flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env.json

flutter analyze
flutter test
flutter test --dart-define=REAL_MEDIA=true test/campus_feed_ui_test.dart test/auth_dashboard_integration_test.dart
flutter build web --release -t lib/preview_auth_dashboard_main.dart --dart-define=REAL_MEDIA=true
flutter build apk --debug -t lib/preview_auth_dashboard_main.dart --dart-define=REAL_MEDIA=true

# Replace DEVICE_ID with a running Android device/emulator ID
flutter devices
flutter run -d DEVICE_ID -t lib/preview_auth_dashboard_main.dart --dart-define=REAL_MEDIA=true
```

The tests named `supabase_reports_adapter_test.dart` and `supabase_dashboard_integration_test.dart` use fake repositories. Real Supabase acceptance requires separate authenticated environment tests. Build commands above describe team verification work after handoff. This audit did not execute them.

## Risks and likely code conflicts

- **Untracked dependencies.** The live Student entry point, Supabase auth repository, Feed, native-media/video files, Admin theme/settings files and Feed tests are currently untracked. A branch checkout or commit-only ZIP can omit essential work.
- **Shared editing hotspots.** Coordinate changes to `preview_app_integrated.dart` among Members 1/2/3, `report_issue_ui.dart` among Members 2/3/5, and repositories/models/contracts among Members 3/4/5. Keep Admin changes with Member 4.
- **Divergent boot paths.** Preview, live Student, Admin and the template main have different gates/data sources. Record the selected entry point and defines with every test/release. The Student Vercel URL is reserved for the Student preview.
- **Identity and model mapping.** UI and database report/status types are separate. Preserve explicit mappings, UUID ownership, old nullable photo paths and fixture isolation.
- **Live refresh and partial failure.** Student session events, report freshness, upload cleanup and notification delivery need explicit coordination. Existing green UI tests do not cover these live outcomes.
- **Privacy.** Public Feed access requires an approved design around owner-only report and private-file policies. Staff labels and comment ownership need server enforcement.
- **Offline media.** Picker files and Web blob URLs need durable retention decisions before a retry queue can promise successful submission.

This handoff preserves the technical limitations documented in `UI_HANDOFF.md`. When integrations are accepted, update that guide and this status inventory together.

## Member 2 read-only Details implementation follow-up

Implemented locally on 20 November 2026. This section supersedes the earlier Details loading gap in this handoff. The Authentication audit remains a point-in-time record of the pre-implementation state.

- `lib/features/reports/presentation/report_details_loader.dart` injects `IncidentReportRepository`, a current-user ID reader and an identity-event stream. Each opening fetches through `fetchReport(id)`. Reload generations prevent older successes or errors from replacing newer data.
- `LiveStudentReportDetailsPage` in `lib/preview_integrated/preview_app_integrated.dart` reuses the approved Details cards, theme, navigation and status rendering. It has loading, unavailable/denied, generic error and Retry states. Missing/denied reports share a privacy-preserving UI message.
- `lib/live_student_main.dart` supplies the route builder for Dashboard/My Reports and passes read-only identity observations from the existing Supabase SDK. Member 1's cubit, authentication repository, sign-in/out flow and role policy are untouched.
- A changed identity or logout clears the current Details payload and invalidates its outstanding requests. The old route stays invalid even if the previous user signs back in. Return to My Reports and reopen it. The loader also rejects a returned record with a different ID or owner. These checks supplement the existing server policy and do not establish RLS acceptance.
- The list and Details now reuse `SupabaseReportsAdapter.toRecord()`. Shared database/UI report models and Member 4's repository contract are unchanged.
- Campus Feed fixture navigation explicitly bypasses the live loader. Bundled sample IDs and photos stay confined to the demo route.
- Private attachments require the existing `photoUrl()` signed URL flow. The API contract is still marked DRAFT and deployed Storage authorization is unverified. This implementation deliberately defers image resolution. A null/empty path shows No photo attached, while an existing path shows Photo preview unavailable. It creates no public URL and performs no uploads or Storage policy changes.
- Member 4 must confirm authorized signed-photo access and expiry/error behavior before that remaining rendering integration. Multiple photos/videos still require the separate agreed contract described above.
- Member 1 still owns the global auth-event/session gate, role handling and identity contract. Details-local invalidation does not replace the pending whole-app account-switch and private-route cleanup acceptance.
- `test/student_report_details_test.dart` adds 22 fake-repository tests for state rendering, denial/errors, Retry, reopening after a status change, stale responses, identity invalidation and fixture-route separation. No live Supabase accounts or RLS tests were used.

## Integration branch publication snapshot

The 20 November 2026 publication branch is `feature/m2-student-integration-20261120`. It includes the existing local Student integration, read-only live Details loader, media selection and Web video support, tests and these handoff documents. Earlier branch/HEAD references above and in the audit identify the inspected baseline.

The branch also carries the existing Member 4 Web Admin import commit and its local presentation integration. Admin themes, settings, search, responsive layout and error handling use the shared repository. Member 4 retains ownership of backend contracts, Supabase migrations, RLS and Storage decisions. Publishing these files does not apply SQL or establish live acceptance.

The Android Gradle change disables Kotlin incremental compilation for the previously verified local Android build. The Flutter dependency lockfile is included explicitly to reproduce the verified package resolution. Local credentials, deployment links, build output and backups are excluded.

Teammates should review this snapshot on its new branch and coordinate ownership before merging into their own work. Authentication and the two-student/RLS acceptance plan remain pending as described in the audits.
