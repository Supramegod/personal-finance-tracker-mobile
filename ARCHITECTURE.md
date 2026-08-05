# Architecture Rules

## Target Structure

```
lib/
  main.dart                  # bootstrap only
  app/
    app.dart                 # root MaterialApp.router widget
    main_navigation/         # tab shell page (composes feature pages)
    router/                  # app_router_service + guards
    di/                      # central dependency_injection.dart + service_locator.dart
  core/                      # infra only: services, exceptions, constants, enums, utils
  shared/
    widgets/                 # cross-feature widgets (ex- presentation/widgets/shared)
    mixins/                  # paginated_scroll_mixin, attachment_handler_mixin
    bloc/                    # base_form_bloc
  features/
    <feature>/
      <feature>_di.dart      # void register<Feature>Dependencies(GetIt sl)
      data/{models,providers,repositories}
      domain/{entities,repositories,usecases}
      presentation/{bloc,pages,widgets}
  l10n/                      # untouched
```

## Layer Rules

1. `core` and `shared` **never** import from `features/`.
2. A feature **may** import another feature's `domain/` layer (entities, usecases,
   repository interfaces). This is how aggregator features work:
   - `home` → announcement, attendance, event, feature_flag, user domain
   - `profile` → user domain
   - `cleaning_execution` → master_cleaning_plan, cleaning_reliever domain
3. A feature must **never** import another feature's `data/` layer.
4. Cross-feature `presentation/` imports are allowed **only** from shell features:
   `home`, `profile`, `cleaning_execution`, and `lib/app/`.
5. Each feature owns exactly one `<feature>_di.dart`; the central initializer
   only registers core services and calls feature registrars.
6. All GetIt registrations use `registerLazySingleton` — registration-order-independent.
7. Usecase pass-throughs are **kept** — they are the mocking seam for unit tests.
8. Bloc field-initializer injection (`serviceLocator<UseCase>()`) is kept.
   Rule: blocs may inject core *services* via field initializers;
   domain operations must go through usecases.

## Per-Feature Move Recipe

For each feature migration (one commit: tests → move → DI registrar → importer fixes → regen):

1. **Write tests first** against the current paths — repo impl test + bloc test.
2. `git mv` each layer slice into `lib/features/<feature>/{domain,data,presentation}/`.
3. Fix relative imports via IDE analysis-server move; verify with `fvm flutter analyze`
   (exhaustive for `uri_does_not_exist` — clean analyze = all imports correct).
4. Create `lib/features/<feature>/<feature>_di.dart` with
   `void register<Feature>Dependencies(GetIt serviceLocator)`;
   cut the feature's registrations from the central DI file; central file calls the registrar.
5. Update external importers (central DI, router, aggregator features).
6. Run `fvm flutter pub run build_runner build --delete-conflicting-outputs`
   if any `@RoutePage()` page was moved; commit the regenerated `.gr.dart`.

**Done-gate per feature**: `fvm flutter analyze` zero new warnings →
`fvm flutter test` green → `fvm flutter build apk --debug` succeeds →
phase manual checklist.

## Import Convention

All imports within `lib/` use **relative paths** (lint: `prefer_relative_imports`).
Test files importing from `lib/` use `package:shelia/...` imports — Dart requires
`package:` imports across the `test/` → `lib/` boundary; relative paths are forbidden.
Zero `package:shelia/` imports inside `lib/` itself.

`directives_ordering` lint sorts relative imports alphabetically by their URI string.
The directory prefix ordering in this repo is: `core/` < `data/` < `domain/` < `features/`
< `presentation/`. New `features/` imports always land after the last `domain/` import
in any file that also imports `domain/` or `presentation/` paths.

## Test Conventions

Bloc tests that exercise `AnnouncementsError` (or any state that calls
`ErrorHandler.getErrorInfo`) must seed the localization ref in `setUp`:

```dart
import 'package:shelia/core/utils/app_localizations_ref.dart';
import 'package:shelia/l10n/generated/app_localizations_en.dart';

setUp(() {
  AppLocalizationsRef.instance = AppLocalizationsEn();
  ...
});
```

Bloc tests use a `StreamController` stub + two `Future.delayed(Duration(milliseconds: 50))`
yields (one to let the BLoC set up its subscription, one to let the internal event propagate)
rather than `expectLater(bloc.stream, emitsInOrder(...))`, which is timing-fragile for blocs
that dispatch internal events from stream callbacks.
