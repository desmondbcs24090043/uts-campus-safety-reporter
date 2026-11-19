# Campus Safety Reporter — Web Admin integration (2026-11-19)

## Purpose
Bring Member 4's standalone Flutter Web Admin into the team's latest Student UI feature branch without replacing student screens or shared Supabase data contracts.

- Team source: `desmondbcs24090043/uts-campus-safety-reporter`, branch `feature/m2-auth-dashboard-integration`, commit `f33e3167005af0e62850ca79d025027c1159ac3a`.
- Admin source: `bcs24090035-creator/uts-campus-safety`, branch `main`, commit `b109ba62e5a96c4c10f340c87f647645d3fcdde0`.
- 7 shared Supabase model/repository/config files were checked to have **identical Git object hashes**.
- The integration creates a new local branch and adds 15 files. It never replaces `pubspec.yaml`, `lib/main.dart`, preview files, or the current Vercel Student Preview.

## Running the integration
1. Install Git for Windows, and ensure it can clone both GitHub repositories.
2. Extract this ZIP to a folder on your Windows computer.
3. Open PowerShell in that folder.
4. Run `powershell -ExecutionPolicy Bypass -File .\Integrate-WebAdmin.ps1` (or `./Integrate-WebAdmin.ps1` if your local execution policy permits).
5. A fresh local clone and commit are created under `campus-safety-integration/team-repo`. The script **does not push** and therefore does not trigger GitHub Actions by itself.
6. Inspect the changed files and run Flutter tests/build before pushing. If authorized to publish the branch, run with `-Push` after review; otherwise ask the repository owner to push it.

## How to run the standalone Web Admin
From the generated `team-repo` directory on a machine with Flutter:

```powershell
flutter pub get
Copy-Item env.example.json env.json
# Edit env.json to add actual SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.
flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env.json
```

The Web Admin requires the real Supabase project, applied migrations, and a test admin account with the appropriate `profiles.role`. **Do not put secret/service_role keys in a client app or this package.**

For a web build:

```powershell
flutter build web --release -t lib/main_admin.dart --dart-define-from-file=env.json
```

Publish the generated `build/web` to a **separate** Vercel site for Admin, not the existing student preview at `https://campus-safety-reporter-preview.vercel.app/`.

## Validation checklist (required before PR merge)
- [ ] `flutter analyze`, `flutter test`, and Web Admin build pass.
- [ ] Admin website requires staff login; a student account is denied access.
- [ ] Admin reads real Supabase reports and can save a new status.
- [ ] The status survives refresh, and the Student Android App observes the changed status.
- [ ] RLS rules prevent students reading other students' private reports or changing status.
- [ ] Student App uses real auth and report repositories, not MockAuthRepository/DemoReportsRepository.
- [ ] Test with a real Android device and update the user manual with real screenshots.
- [ ] No sensitive credentials, `env.json`, or personal reports are committed.

## Existing blockers
The latest Team Student Preview is **still mock authenticated**, its report form still uses sample photos and does not submit to Supabase, and its admin placeholder is not the real Admin Portal. This package only integrates Member 4's existing Admin UI and schema handoff; it does not claim the end-to-end live system is already functioning. Media is currently single-photo `photo_path`, so video / multi-photo requires a separately agreed migration.

Member 4's original setup guide and API contract are included as new source files by the integration script. Coordinate with the owner before applying migrations to a database that already contains live data.
