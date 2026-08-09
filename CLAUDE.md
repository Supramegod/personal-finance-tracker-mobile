# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`personaltracker` — Flutter mobile client for a Personal Finance Tracker (Indonesian UI, group/family shared finances). It is a pure API client: all data lives in a backend at `https://jalu-finance.shelterdev.online/api/v1`. There is no local database.

Stack: Flutter 3.44 / Dart SDK ^3.10.1, **Riverpod** (`StateNotifierProvider` + `Provider`, no code generation), **go_router**, **Dio**, `flutter_secure_storage`, `fl_chart`.

## Commands

```bash
flutter pub get
flutter analyze                 # lint gate (flutter_lints 4.0)
flutter test                    # all tests
flutter test test/widget_test.dart --plain-name 'nama test'   # single test by name
flutter run                     # debug run
flutter build apk --debug
```

`riverpod_generator` / `build_runner` are declared in `pubspec.yaml` but **no `.g.dart` files exist and no source uses `@riverpod`** — providers are written by hand. Do not introduce codegen without a deliberate decision; if you do, `flutter pub run build_runner build --delete-conflicting-outputs`.

`ARCHITECTURE.md` in the repo root is **stale** — it documents a different app (`shelia`, GetIt + BLoC + auto_route + fvm). Only its *layer-rule* spirit carries over; ignore its concrete tooling instructions. This file supersedes it.

## Architecture

```
lib/
  main.dart                  # bootstrap: ProviderScope + overrides only
  app/
    app.dart                 # MaterialApp.router root
    router/app_router.dart   # GoRouter + auth redirect
    di/dependency_injection.dart   # composition root, aggregates feature registrars
    main_navigation/         # MainScaffold (bottom-nav shell)
  core/                      # api (dio_client, api_exception), constants, storage, theme, utils
  shared/widgets/            # cross-feature widgets
  features/<feature>/
    <feature>_di.dart        # usecase providers + List<Override> register<Feature>Dependencies()
    data/{models,repositories}
    domain/{entities,repositories,usecases}
    presentation/{pages,providers,widgets}
```

Features: `auth`, `dashboard`, `transactions`, `calendar`, `reports` (incl. AI insights), `installments`, `groups`, `settings`, `more`.

### Layer rules

- `core/` and `shared/` never import from `features/`.
- A feature may import another feature's `domain/`; never another feature's `data/`.
- Cross-feature `presentation/` imports only from shell surfaces (`app/`, `main_navigation`, `more`).
- All imports inside `lib/` are **relative**; `test/` imports `lib/` via `package:personaltracker/...`.

### Repository / provider pattern (follow this exactly)

Each repository implements a `domain/repositories/*_contract.dart` interface, takes `Dio` in its constructor, wraps every call in `try/on DioException catch (e) { throw ApiException.fromDio(e); }`, and exposes a provider typed to the **contract**, e.g.:

```dart
final transactionRepositoryProvider = Provider<TransactionRepositoryContract>(
  (ref) => TransactionRepository(ref.watch(dioProvider)),
);
```

Typing the provider to the contract is what lets tests override it with a fake. Usecases (`domain/usecases/`) are thin pass-throughs kept as a mocking seam; they live behind providers in `<feature>_di.dart`.

Presentation state is a `StateNotifier` with an immutable state class exposing `copyWith(..., bool clearX = false)` for nullable fields, plus `isLoading` / `errorMessage` flags. Errors are surfaced as `e.toString()` (which yields `ApiException.message`, already user-facing Indonesian text).

### DI seam

`buildDependencyOverrides()` in `app/di/dependency_injection.dart` concatenates each feature's `register<Feature>Dependencies()`. These currently return `const []` — Riverpod providers are lazy — but the seam exists so tests and alternate environments can inject overrides in one place. Keep new features consistent: add a `<feature>_di.dart` with a registrar and wire it into the central list.

### Auth and networking

- Tokens go in `flutter_secure_storage` via `TokenStorage` — **never** SharedPreferences (SharedPreferences is only for the theme preference).
- `dio_client.dart` attaches `Bearer` headers and does silent refresh on 401 for non-`/auth/` paths, single-flight-guarded by a `Completer` because the backend rotates refresh tokens single-use. Both new tokens must be persisted.
- On refresh failure it calls `onSessionExpiredProvider`, which `main.dart` overrides to hit `authProvider.notifier.onExpired()`. That flips `AuthStatus`, which `_AuthRefresh` bridges into `GoRouter.refreshListenable`, which triggers the redirect to `/login`. Breaking any link in that chain silently strands the user on a dead screen.
- `ApiEndpoints.baseUrl` uses `String.fromEnvironment` with the *URL* as the variable name, so `--dart-define=API_BASE_URL=...` has no effect today; change the name if you need per-environment builds (Android emulator → `http://10.0.2.2:8080`).

### Backend response shapes

Lists come back as a flat envelope `{data, total, page, limit}` (no `meta`); `total_pages` is computed client-side. `Transaction.fromJson` tolerates both flat (`category_id`, `category_name`) and nested (`category: {...}`) forms. Dates are sent as `YYYY-MM-DD` substrings.

## Conventions

- UI strings and doc comments are **Bahasa Indonesia**; code identifiers are English.
- Never hard-code colors, spacing, or text styles in widgets — use `AppColors`, `AppSpacing`, `AppTextStyles` from `core/constants/`. Currency and dates go through `core/utils/formatters.dart` (`formatIdr`, `formatDate`, …).
- Dark theme is the default (`ThemeNotifier` defaults to `AppThemeMode.dark`); check every screen in both themes.
- Optimistic mutations restore previous state on failure and **rethrow** — see `TransactionListNotifier.delete`, whose remove-before-await ordering is required to avoid Flutter's "A dismissed Dismissible widget is still part of the tree" crash. Do not "simplify" it to await-then-remove.

## Tests

All tests live in `test/widget_test.dart` (unit + widget mixed). Widget tests wrap the subject in `ProviderScope(overrides: [...])`; notifiers that fetch on construction expose a `@visibleForTesting` no-repo constructor (`GroupNotifier.test()`) so a widget can be pumped without network. Prefer that pattern over mocking Dio.
