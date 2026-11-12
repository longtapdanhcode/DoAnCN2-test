# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Fieldline — a Flutter field-inventory app (course capstone). The field app (iOS/Android/macOS) scans QR/barcodes, runs a YOLOv8s TFLite model on-device, records audits offline in Isar, captures signatures and evidence photos, and syncs to Supabase. The **web build is a management console** that reads/writes Supabase directly (no Isar, no camera, no AI). README.md (Vietnamese) is the authoritative feature/setup doc; code comments, docs and commit messages are in Vietnamese.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate *.g.dart after changing @riverpod / Isar models
flutter analyze
flutter test                                               # all tests
flutter test test/features/offline_audit/auto_sync_test.dart       # one file
flutter test --plain-name "substring of test name"                 # one test
flutter run                  # field mode (mobile/macOS)
flutter run -d chrome        # web console mode
flutter build apk --release
```

- Generated `*.g.dart` files **are committed**; rerun build_runner and commit them when annotated code changes.
- `lib/core/network/supabase_config.dart` is gitignored — copy from `supabase_config.dart.example`. App boots with empty values but login is mandatory.
- iOS: Impeller is disabled in `Info.plist` (camera black-screen workaround); camera/AI need a physical device.

## Architecture

Feature-first Clean Architecture under `lib/features/<feature>/{domain,data,presentation}`; shared infra in `lib/core/` (router, theme, Isar init, Supabase provider, connectivity, PDF generator, `FieldlineShell` navigation).

### Two app modes from one codebase
This is the key cross-cutting design — read these together:
- `lib/main.dart`: web → `ProviderScope(overrides: consoleOverrides())`, no Isar; mobile → opens Isar and overrides `isarInstanceProvider`.
- `lib/core/platform/app_mode.dart`: `AppMode.field` / `AppMode.console` (`appModeProvider`, overridable in tests) and `fieldOnlyPaths` (`/scanner`, `/audit-form`, `/signature`, `/sync`).
- `lib/core/router/app_router.dart`: GoRouter with auth redirect, redirects field-only paths to `/` in console mode, `ShellRoute` for the main shell.
- `lib/features/cloud_console/console_overrides.dart`: swaps `auditRecordsProvider` (polls Supabase every minute), `evidencePhotoStoreProvider` (URL-based) and `assetCatalogRepositoryProvider` (cloud repo) so dashboard/assets/reports/locations/settings screens are reused unchanged on web.
- `edge_vision/data/repositories/vision_ai_providers.dart` uses a conditional export (`dart.library.js_interop`) to replace the TFLite repository with an unsupported stub on web (no `dart:ffi`).

When adding a screen or provider used on both platforms, make its data source a provider that `consoleOverrides()` can replace rather than branching on `kIsWeb` inside widgets.

### Offline-first audit + sync (`features/offline_audit`)
- Every audit is written to Isar (`AuditRecordModel`) first. Unsigned records are **drafts**: never synced, excluded from reports.
- `SyncController` pushes signed, unsynced records to Supabase (`audit_records` table, `signatures` / `evidence` storage buckets). `AutoSyncController` triggers on connectivity changes with a 3s debounce and exponential retry 30s → 5min; settings persisted via `SyncSettingsStore` (shared_preferences).
- Asset catalog (`features/asset_catalog`) keeps `baseJson` / `conflictJson` on `AssetModel` for three-way merge (`domain/asset_merge.dart`); conflicts surface on `/sync/conflicts`.

### Edge AI pipeline (`features/edge_vision`, `core/ai_pipeline/ai_config.dart`)
- Model `assets/models/object_detection.tflite`, input 1×3×640×640 NCHW, output 1×13×8400 (cx,cy,w,h + 9 class scores; labels in `labels.txt`).
- Only the centre square (`AiConfig.cropFraction` = 70% of short side, matching the green scan frame) is fed to the model. Thresholds: 0.5 equipment, 0.7 damage classes (0,1,2,5). New frames are dropped while inference is running.
- iOS uses the Metal GPU delegate with CPU fallback.
- `mobile_scanner` is a **locally patched copy** in `third_party/mobile_scanner` (wired via `dependency_overrides` in pubspec). The iOS/macOS patch emits frames without barcodes (~2 fps) and an `aiInput` key with the pre-cropped 640×640 RGB buffer. Android is **not** patched (AI only runs when a code is visible). See `third_party/mobile_scanner/PATCH_NOTES.md` before touching it.

### State management
Riverpod 3 — mix of generated providers (`@riverpod` + `*.g.dart`) and hand-written `Provider`/`AsyncNotifier`. Tests inject fakes via `ProviderScope`/`ProviderContainer` overrides (e.g. `isarAuditRepositoryProvider`, `syncRepositoryProvider`, `authRepositoryProvider`); shared fakes live in `test/helpers/`.

### Supabase
Schema changes go in `supabase/migrations/` (timestamp-prefixed, applied in name order); sample data in `supabase/seed/`. RLS: authenticated users only; audit records editable only by `created_by`.

## Git workflow

Branches: `main` ← `develop` ← `feature/sprint<S>-card<N>-tv<K>`; changes reach `develop` via PR. Conventional Commits with Vietnamese descriptions, e.g. `feat(card26): ...`, `fix(ai): ...`. `HUONG_DAN_GIT_NHOM.md` asks to stage specific files rather than `git add .`.
