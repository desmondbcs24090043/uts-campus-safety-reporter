# Authentication and Student Reports Integration Audit

Audit date 20 November 2026. Scope is the actual local working tree, including modified and untracked files. Read [INTEGRATION_HANDOFF.md](INTEGRATION_HANDOFF.md) first.

Project root is `D:\IT_MAD\campus_safety_admin_integration_kit\campus-safety-integration\team-repo`. Branch is `feature/m2-student-media-ui`, at HEAD `89182cd97427e12d73d9a3b0e9c33a336024e399`. Paths below are relative to the project root.

## Recommendation and evidence boundary

**Recommended official Student entry-point candidate is `lib/live_student_main.dart`.** It already composes the existing real auth repository, role check, shared Student UI and Supabase reports adapter. Member 1 should review and accept this composition before the group promotes it to the official Android/Student launch path.

The real login, logout, session restoration, role enforcement and deployed RLS acceptance results remain **unverified** in this audit. No controlled account credentials or authorized report fixtures were supplied. There were no live authentication attempts or database/Storage calls. An empty report list provides no RLS evidence.

Safe local tests were run using the existing mock/fake repositories. Six tests passed. This establishes the checked code's mapping, filtering and mock UI flow, with the limitations described below.

## Existing implementations and entry points

| Implementation | Confirmed behavior | Decision |
|---|---|---|
| `lib/live_student_main.dart` | Restores theme, initializes Supabase from local defines, constructs `_LiveStudentAuthCubit`, attempts startup session restoration, and injects the shared report repository/adapter after student authentication. | Reuse as the production candidate after Member 1 acceptance and live tests. |
| `lib/preview_auth_dashboard_main.dart` | Injects `AuthCubit(MockAuthRepository())` and `DemoReportsRepository`. Admin reaches a placeholder. | Retain for the existing Student demonstration. |
| `lib/main.dart` | Flutter counter template. | Team must agree on launch packaging explicitly. |
| `lib/main_admin.dart` and `lib/admin/admin_app.dart` | Separate real Admin entry point. `AdminAuthGate` listens to `auth.onAuthStateChange` and checks the profile role. | Preserve Member 4's portal and coordinate common auth behavior with Member 1. |

No additional official Member 1 implementation was identified in the inspected local auth files. The real and mock repositories have distinct purposes. The shared `AuthRepository` interface and forms provide an existing integration boundary.

### Interfaces and coordinated files

| Files | Interface or responsibility |
|---|---|
| `lib/features/auth/data/auth_repository.dart` | Named-argument `signUp(email:, password:)`, `signIn(email:, password:) → Future<String>` role, and `signOut()`. |
| `lib/features/auth/data/supabase_auth_repository.dart` | Supabase password login, sign-up, profile role check and SDK sign-out. Currently untracked. |
| `lib/features/auth/data/mock_auth_repository.dart` | Demo delays/errors and email-based demo role selection. |
| `lib/features/auth/presentation/auth_cubit.dart`, `auth_state.dart` | Shared loading/authenticated/unauthenticated/error transitions. |
| `lib/features/auth/presentation/login_page.dart`, `register_page.dart` | Existing forms, validation and navigation, driven by the shared cubit. |
| `lib/live_student_main.dart` | Untracked live composition root, startup restoration and Student auth gate. |
| `lib/data/repositories/profile_repository.dart` | `fetchMyRole()` selects the current user's profile role. |
| `lib/features/reports/data/supabase_reports_adapter.dart` | `fetchMyReports()` maps shared database records into UI `ReportRecord` values. |
| `lib/features/reports/presentation/reports_bloc.dart`, `reports_state.dart` | Fetch, loaded records, search/status filters and failure state. |
| `lib/data/repositories/incident_report_repository.dart` | Existing shared report reads, status updates, single-photo upload and signed URLs. Member 4 owns the contract. |
| `lib/preview_integrated/preview_app_integrated.dart` | Shared Student shell, Dashboard, My Reports, Details routes and display. |
| `lib/admin/pages/report_detail_page.dart` | Admin fetch, signed photo reads and confirmed `updateStatus()` calls. |

Member 1 owns auth behavior and the session/identity boundary. Member 2 owns report presentation, loading and navigation. Agree on the composition root and identity reset behavior before both members edit shared files.

## Confirmed working local features

Command executed from the project root:

```powershell
flutter test --no-pub test/supabase_reports_adapter_test.dart test/supabase_dashboard_integration_test.dart test/auth_dashboard_integration_test.dart --reporter expanded
```

**Result was six tests passed.**

| Existing tests | What passed | Evidence limit |
|---|---|---|
| `test/supabase_reports_adapter_test.dart` | Database-record-to-UI mapping and an empty fake dataset. | Uses `FakeIncidentRepository`. It bypasses real REST queries, JWTs and RLS. |
| `test/supabase_dashboard_integration_test.dart` | Fake adapted records appear in My Reports, status filtering and search. | Uses a fake shared repository. It does not demonstrate account ownership or live status updates. |
| `test/auth_dashboard_integration_test.dart` | Mock student login → Dashboard → sign-out and Register navigation. | Uses `MockAuthRepository`. It does not exercise the real Supabase repository or live gate. |

No test files or application source were changed.

## Findings for the six verification areas

### 1. Real login and logout

**Confirmed code.** `SupabaseAuthRepository.signIn()` calls `auth.signInWithPassword()`, checks the returned user and obtains the profile role. A role other than student is rejected and the SDK session is signed out. Sign-out delegates to `auth.signOut()`.

**Missing acceptance.** Valid/invalid credentials, confirmed/unconfirmed email, network failures and real logout were not exercised. `AuthCubit.signOut()` emits loading and awaits the repository without a catch branch. A failure can leave the UI in loading and propagate an unhandled error.

**Coordination.** Member 1 should define error recovery and messages. Member 2 should preserve the existing login/profile callback contract and clear report presentation when the accepted auth gate signs the user out.

### 2. Session restoration and account switching

**Confirmed code.** `_LiveStudentAuthCubit.restoreSession()` checks `auth.currentUser`, then checks the role. It runs during startup. The Student live gate observes cubit state, with no Supabase auth-state subscription visible in this path.

**Gaps and risks.**

- SDK session refresh may occur independently, but Student navigation is not explicitly reconciled with SDK expiry, remote/external sign-out or user changes.
- The startup role-check catch emits unauthenticated without explicitly clearing an existing SDK session. Member 1 must decide the intended recovery.
- `AuthAuthenticated` contains only `role`, and its Equatable properties omit user ID. Repeated authenticated states for different students cannot represent their identity difference through this state.
- `ReportsBloc` is created inside the authenticated gate, without a user-ID key. Session changes, in-flight loads and route disposal need acceptance tests.
- A pushed Details route contains an existing record. Verify that logout/expiry removes private routes and that browser/device Back cannot recover previous-user details.

These are source-based lifecycle risks. Cross-account leakage was not reproduced.

### 3. Student role validation

**Confirmed code.** Both real sign-in and startup restoration call `ProfileRepository.fetchMyRole()`. Existing Student sign-in rejects Admin. `UserRole.fromDb()` rejects unknown roles.

**Decision required.** A missing profile row currently returns `UserRole.student`. Member 1 and Member 4 must agree on this fallback, trigger timing and role-query failure behavior. Client routing complements the backend policies. Deployed role policies remain unverified.

### 4. My Reports ownership filtering

**Confirmed code.** `IncidentReportRepository.fetchMyReports()` requires a current user ID and sends `reporter_id = current user ID`, newest first, with a default 50-row limit. `SupabaseReportsAdapter` uses this method and `ReportsRequested` loads it into the BLoC.

The checked-in migration `supabase/migrations/20261113000002_rls_policies.sql` enables RLS. Its Student SELECT policy requires `reporter_id = auth.uid()`, with a separate Admin policy. Logged-out visitors have no table grants.

**Unverified.** Applied policy state and real cross-student protection. The explicit client ownership filter can hide a permissive database policy. Verify an unfiltered authenticated read and an explicit foreign-report request with controlled fixtures.

Dashboard counts are calculated from loaded records. They may cover only the first 50 reports. `countByStatus()` exists in the repository but is not used by the Student adapter/BLoC.

### 5. Report Details ownership protection

**Confirmed code.** `_PreviewShellState._openDetails(ReportRecord)` pushes `_ReportDetailsScreen` with the selected object. Dashboard and My Reports use this navigation. Details reads the object and performs no fresh repository request.

The shared `fetchReport(id)` queries by ID only and relies on RLS. For an unauthorized/nonexistent row its `.single()` result is wrapped in `RepositoryException`. This method is currently used by Admin Details, and is available for Student integration.

**Missing integration.**

- No fresh owner-authorized fetch when opening Student Details.
- No Student detail-loader loading/error/retry handling for deleted, inaccessible or stale records.
- The adapter drops `photoPath`, `reporterId` and `updatedAt`. Details only supplies bundled demo photos for `CSR-2026-001`, and otherwise shows the no-photo state.
- The role-only auth state provides no presentation identity for checking cached or in-flight detail work.

Campus Feed opens the same Details UI by mapping fictional `DemoReport` records. Keep fixture routes explicit when introducing a live loader. Owner-only private reports and a future published Feed have different access requirements. Fixture `CSR-...` IDs must stay out of live UUID queries.

### 6. Admin status changes reflected in Student UI

**Confirmed code.** Admin Details calls `IncidentReportRepository.updateStatus()` after confirmation. The shared repository updates only status, and the checked-in RLS/grants restrict updates to Admin. Student adapter maps the three database statuses into UI statuses.

Student My Reports exposes `reload-reports`, which dispatches `ReportsRequested`. After an actual successful fetch, Dashboard/My Reports consume the newly loaded records. An already-open Details screen holds its old object and does not subscribe to the refreshed BLoC.

**Unverified.** A real Admin save followed by an authenticated Student refresh. There is no Student report Realtime subscription or automatic status-history source in the inspected path. A minimal initial acceptance target is manual reload plus reopening Details. In-place live Details refresh requires a separate agreed implementation.

## Two-student acceptance test plan

### Required fixtures and authority

Use an approved isolated test environment or approved existing test records. Member 4 verifies the fixture inventory and policies. Member 1 supplies access through the normal login mechanism. Keep credentials, JWTs and private report contents out of the document and shared logs.

Required inventory:

| Fixture | Required known state |
|---|---|
| Student A and Student B | Two separate approved accounts, confirmed email as required, known profile role `student`. |
| A1 and A2 | Two existing reports owned by A with known UUIDs, harmless recognizable markers and different statuses. |
| B1 and B2 | Two existing reports owned by B with known UUIDs and recognizable markers. |
| Optional private photo | Existing approved image path owned by one account, with permitted read expectations. |
| Admin C | Existing approved admin account for role-denial checks and the separately authorized status-update step. |

This audit created none of these fixtures. If they are unavailable, mark affected cases blocked and request authorization for Member 4 to prepare them. Confirm each known UUID exists under its owner or an authorized Admin before using it as a negative-access target.

The existing `supabase/tests/rls_security_tests.sql` creates and deletes temporary users/reports and cleans leftovers. Its comments describe a security test setup, but execution mutates data. It was not run. Obtain authorization and use a suitable test environment before running it.

### Read and session cases

Use separate browser profiles/contexts for A, B and Admin. Also include a same-context A → logout → B cycle to test stale UI/session cleanup.

| Case | Procedure | Pass criterion |
|---|---|---|
| Login/logout | Log in as A through the live Student entry, then log out normally. | Student UI loads only after accepted role validation. Logout clears private UI and Back cannot restore Details. |
| Invalid login | Use an approved invalid-password attempt without repeated lockout attempts. | Useful error, no authenticated report access and retry remains available. |
| Restoration | With A's valid session, refresh Web and cold-launch the agreed Android build. | A's role is revalidated and only A's reports return. Record current SDK/configuration behavior. |
| Expiry/sign-out event | Member 1 coordinates a test-session expiry/sign-out event or controlled SDK event simulation. | Private routes disappear and pending data loads cannot repopulate prior-user content. No other users' sessions are revoked. |
| Role check | Try Admin C in Student login, then verify Admin through its separate portal. | Student rejects the admin role, while the approved Admin gate behaves correctly. |
| Own-report positive controls | As A, load A1/A2. As B, load B1/B2. | Correct ownership markers and UUIDs appear for each account. |
| RLS without client filter | Using each student's own authenticated client and normal publishable key, invoke `fetchReports()` or equivalent read with the reporter filter omitted. | Results expose only authorized own reports. An empty list is insufficient without the positive controls. |
| Explicit foreign access | As A, request known B1 through `fetchReport(B1)` and an explicit foreign `reporter_id` query. Repeat B → A1. | No foreign row data returned. Record zero-row/permission error behavior without logging tokens. Verify the same UUID is accessible to its owner. |
| Logged-out access | With no user session, try report reads and direct Details data loading. | No private report content returned or left visible. Use no privileged key. |
| Same-context account switch | Open A1, log out, sign in as B and use tabs/Back. Repeat with a slow in-flight A load. | Fresh B report state and routes, no A detail or delayed A payload. |
| Photo authorization | Where a controlled photo fixture exists, test the authorized signed URL flow and foreign signing attempts. | Owner can obtain permitted access and another student cannot mint a new signed URL. Treat already-issued URL expiry according to the agreed Storage behavior. |
| Missing profile / role failure | Use fake profile repository responses or an approved disposable fixture. | Agreed loading/error/fallback behavior. No audit-time profile deletion or role modification. |

Run the live entry explicitly:

```powershell
flutter run -d chrome -t lib/live_student_main.dart --dart-define-from-file=env.json
```

Use the SDK current user's ID when recording ownership evidence locally, with redaction for group sharing. Avoid privileged SQL contexts and service-role clients when testing Student authorization.

### Separately authorized status propagation case

Updating a report changes data. This case requires explicit approval for the designated test record and Admin action. It remains unexecuted in this audit.

1. Record A1's initial status through A's own read and an authorized Admin read.
2. Keep A1 open in Student Details. In Admin, change only A1 to an agreed target status.
3. Confirm the save response through the shared repository and Admin reload.
4. Return to Student My Reports, press Reload, and inspect A1 plus Dashboard counts.
5. Reopen A1 Details and compare status with the saved value. Record whether the already-open screen stays stale.
6. Check that B's unrelated reports remain unchanged. Restore the test status only if separately authorized.

Acceptance requires consistent persisted status after the agreed refresh flow. UI-only status changes, mock updates and automatic Realtime behavior do not satisfy this manual integration case.

### Evidence record

For each case record build entry point/defines, source revision plus local-file snapshot, approved test environment, redacted account/fixture references, action, expected result, actual result and pass/fail/blocked status. Record authorization for any future fixture or status mutation.

## Recommended minimal changes and ownership

All changes below are proposals. This audit implemented none.

| Priority | Owner and coordinated files | Minimal proposal and acceptance |
|---|---|---|
| P1 | Member 1 with Member 2, `live_student_main.dart`, `auth_cubit.dart`, `auth_state.dart`, `supabase_auth_repository.dart` | Accept one official Student composition, reconcile SDK events, logout failure and role fallback. Agree on a stable user/session identity boundary. Pass live login, role and restoration cases. |
| P1 | Member 2 consuming Member 1's agreed identity boundary, `preview_app_integrated.dart`, report BLoC | Reset/dispose private report state and routes on account changes. Prevent stale requests from publishing prior-user data. Pass same-context and delayed-load cases. |
| P2 | Member 2 with Member 4, Student Details and an injectable presentation loader | Fetch the selected live report through existing `fetchReport(id)`, then resolve existing single-photo paths via `photoUrl()`. Preserve UI layout and model contracts. Show loading, denied/unavailable and retry states. Keep fixture Details separate. |
| P2 | Member 2 with Member 4, report adapter/BLoC | Agree on manual refresh, paging and totals. After Admin save, reload and reopen Details display the new status. |
| P2 | Member 1 with Member 4, ProfileRepository and registration messages | Confirm missing-profile behavior and confirmation requirements. Use fake cases first and approved live fixtures later. |
| P3 | Member 5 with Members 1/2/4 | Execute and record two-student, account-switch and Android runtime acceptance. Expand regression coverage for auth events and delayed/stale data. |

Member 4 retains ownership of Supabase policies, the shared repository and schema. Member 3 retains submission/media upload orchestration. These responsibilities remain outside the proposed read-only Student detail loader.

## Conflicts and coordination risks

- `live_student_main.dart` and `supabase_auth_repository.dart` are untracked locally. Branch HEAD alone omits the real Student composition.
- Both Student entry points use the same forms and cubit. Restrict preview changes through explicit composition/configuration, and coordinate modifications to shared auth states with Member 1.
- Student and Admin auth gates currently handle session events differently. Reconcile requirements while retaining their separate role-specific routing.
- `AuthAuthenticated(role)` carries no user identity. Member 2 should consume Member 1's agreed identity contract and avoid introducing another auth repository or role source.
- Student report/detail work shares `preview_app_integrated.dart` with Dashboard, Feed and media enhancements. Preserve current local edits and explicit demo routing.
- UI `ReportRecord` and database `IncidentReport` have different fields/status enums. Preserve mappings and obtain Member 4 agreement before changing shared data contracts.
- A filtered successful own-report read and green fake tests cannot establish deployed RLS security. Include positive controls and direct cross-user denial tests.

## Smallest safe next implementation task

**Member 2 can add a narrowly scoped, injectable read-only Student Details loader using the existing `fetchReport(id)` and `photoUrl()` interfaces, starting with fake-repository tests.**

First cover successful own-record loading, nullable photo paths, stale status, request failure/denial and retry through fake responses. Preserve the approved Detail cards, photo viewer and demo fixture route. Avoid changing AuthCubit, SupabaseAuthRepository, role rules or the shared schema in this task.

Member 1 reviews the official entry point and session identity boundary in parallel. Live release acceptance of the loader depends on that boundary and the controlled two-student tests. This gives Member 2 a concrete integration task without taking ownership of Authentication.
