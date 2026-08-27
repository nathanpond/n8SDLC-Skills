# Stack: Dart / Flutter

## Detect
`pubspec.yaml` (with `flutter:` section for Flutter vs plain Dart).

## Scaffold
```bash
flutter create <name> --org <reverse.domain> --platforms <ios,android,web,...>
# plain Dart: dart create -t console|package <name>
```

Ask which platforms matter (affects CI matrix and audit scope). Ask state-management preference (Riverpod/Bloc/provider/vanilla) during planning, not here.

## Tests / quality
- Test: `flutter test` (unit + widget), `flutter test integration_test` or Patrol for integration
- Lint/format: `dart analyze` and `dart format --set-exit-if-changed .`; `flutter_lints`/`very_good_analysis` in `analysis_options.yaml`

## CI (GitHub Actions)
`subosito/flutter-action` → `flutter pub get` → `dart analyze` → format check → `flutter test` → platform builds (`flutter build apk|ios|web`). iOS builds need macOS runners and signing secrets — ask before assuming. Deploy per roadmap answers (stores via fastlane, web hosting, etc.).

## Audit tooling
- Dependencies: `flutter pub outdated`, `dart pub audit` (advisories), Dependabot (pub support)
- Static analysis: Semgrep (`p/dart` where available), custom lint rules via `analysis_options.yaml`
- 508/accessibility: Flutter's Semantics; widget tests with `meetsGuideline` (`textContrastGuideline`, `androidTapTargetGuideline`, `labeledTapTargetGuideline`)
