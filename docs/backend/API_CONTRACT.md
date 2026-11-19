# UTS Campus Safety Reporter — Database & REST API Contract

**Owner:** Member 4 (Supabase + REST API + Web Admin)  
**Status:** DRAFT v1 — for team review before integration  
**Rule:** Nobody changes these tables, columns, values or permissions without group agreement. Any change goes in a **new** migration file. Never edit an old one.

---

## 1. Tables

### `profiles`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | = `auth.users.id` |
| `role` | text | `student` or `admin`. Default `student` |
| `created_at` | timestamptz | auto |

- A row is created **automatically** when someone registers (trigger `handle_new_user`). The app never inserts profiles.
- Every new account is `student`, even if the app sends `role: admin` in sign-up metadata.
- To make an admin, run `supabase/seed/make_admin.sql` in the SQL Editor.

### `incident_reports`
| Column | Type | Who sets it | Rules |
|---|---|---|---|
| `id` | uuid, PK | database | auto |
| `reporter_id` | uuid → profiles.id | database | = logged-in user (`auth.uid()`). **Don't send it** |
| `category` | text | app | one of the values in section 2 |
| `description` | text | app | 5 – 1000 characters (trimmed) |
| `latitude` | double | app | -90 … 90 |
| `longitude` | double | app | -180 … 180 |
| `photo_path` | text, nullable | app | path in bucket `report-photos`, must start with `<your user id>/` |
| `status` | text | database / admin | `pending` → `in_progress` → `resolved`. Default `pending` |
| `created_at` | timestamptz | database | auto |
| `updated_at` | timestamptz | database | auto-updated by trigger |

## 2. Allowed values

| `status` (DB) | UI label |
|---|---|
| `pending` | Pending |
| `in_progress` | In Progress |
| `resolved` | Resolved |

| `category` (DB) | UI label |
|---|---|
| `safety_hazard` | Safety Hazard |
| `facility_damage` | Facility Damage |
| `suspicious_activity` | Suspicious Activity |
| `lighting` | Lighting |
| `other` | Other |

Dart enums: `lib/data/models/report_status.dart`, `lib/data/models/report_category.dart`.

## 3. Permissions (enforced by RLS in the database)

| Action | Logged out | Student | Admin |
|---|---|---|---|
| Read own profile | ✗ | ✓ | ✓ (all) |
| Change a role | ✗ | ✗ | ✗ (SQL Editor only) |
| Create report | ✗ | ✓ own, always `pending` | ✓ (not used) |
| Read reports | ✗ | **own only** | **all** |
| Change `status` | ✗ | ✗ | ✓ |
| Edit other columns | ✗ | ✗ | ✗ |
| Delete report | ✗ | ✗ | ✗ |
| Upload photo | ✗ | own folder only | — |
| View photo | ✗ | own only | all |

Proven by `supabase/tests/rls_security_tests.sql` (19 tests).

## 4. How to call it — use the shared repository

**Please don't write your own Supabase queries for these tables.** Use:

```dart
final repo = IncidentReportRepository();      // lib/data/repositories/
final profiles = ProfileRepository();
```

| Who | Method | REST call it makes |
|---|---|---|
| Member 1 (role navigation) | `profiles.fetchMyRole()` → `UserRole.student / admin / null` | `GET /rest/v1/profiles?select=role&id=eq.<uid>` |
| Member 2 (Dashboard) | `repo.fetchMyReports()` | `GET /rest/v1/incident_reports?reporter_id=eq.<uid>&order=created_at.desc` |
| Member 2 (Dashboard cards) | `repo.countByStatus()` → `{pending: n, ...}` | `GET /rest/v1/incident_reports?select=status` |
| Member 2 (Details) | `repo.fetchReport(id)` | `GET /rest/v1/incident_reports?id=eq.<id>` |
| Member 2/4 (photo) | `repo.photoUrl(report.photoPath)` → signed URL, valid 1 h | `POST /storage/v1/object/sign/report-photos/<path>` |
| Member 3 (Submit) | `repo.uploadPhoto(bytes, extension: 'jpg')` → `photoPath` | `POST /storage/v1/object/report-photos/<uid>/<file>` |
| Member 3 (Submit) | `repo.createReport(NewIncidentReport(...))` → saved `IncidentReport` | `POST /rest/v1/incident_reports` |
| Member 4 (Admin) | `repo.fetchReports(status: ...)` | `GET /rest/v1/incident_reports?status=eq.<s>&order=created_at.desc` |
| Member 4 (Admin) | `repo.updateStatus(id, ReportStatus.resolved)` | `PATCH /rest/v1/incident_reports?id=eq.<id>` body `{"status":"resolved"}` |
| Member 5 (offline) | `report.toJson()` / `IncidentReport.fromJson()` for SQLite cache | — |

All methods throw **`RepositoryException`** with a `message` you can show the user directly.

### Example: Member 3 submit flow
```dart
String? path;
if (photoBytes != null) {
  path = await repo.uploadPhoto(photoBytes, extension: 'jpg');   // 1. photo first
}
final draft = NewIncidentReport(
  category: ReportCategory.safetyHazard,
  description: descriptionController.text,
  latitude: pos.latitude,
  longitude: pos.longitude,
  photoPath: path,
);
final error = draft.validate();             // show in the form before calling the API
if (error != null) { /* show error */ return; }
final saved = await repo.createReport(draft); // 2. then the row
```

### Raw REST (for the Technical Report / Postman testing)
```
Base URL : https://<project-ref>.supabase.co/rest/v1
Headers  : apikey: <publishable key>
           Authorization: Bearer <user access token from login>
           Content-Type: application/json
           Prefer: return=representation     (to get the saved row back)
```

## 5. Storage
- Bucket: **`report-photos`** — **private**, max 5 MB, `image/jpeg`, `image/png`, `image/webp`.
- Path format: `<auth user id>/<timestamp>_<random>.<ext>` (the repository does this for you).
- Never store a public URL in the table, only the path. Show photos via `repo.photoUrl()`.

## 6. Secrets
- The app only uses the **publishable (anon) key**. It's safe in the app *because* of RLS.
- The **service_role / secret key** is never used in Flutter, never committed, never shared in chat.
- Keys are passed with `--dart-define-from-file=env.json`. `env.json` is in `.gitignore`. Copy `env.example.json`.
