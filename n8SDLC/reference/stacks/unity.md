# Stack: Unity

## Detect
`Assets/`, `ProjectSettings/`, `Packages/manifest.json`.

## Scaffold
Unity projects are created from the Unity Hub/editor, not the CLI — if no project exists, ask the user to create one in Unity Hub (ask which editor version and render pipeline) and pause until it exists. Then add the agent-manageable parts:

- `.gitignore` from GitHub's Unity template; verify `Library/`, `Temp/`, `Logs/` are ignored
- Git LFS for binary assets: `git lfs install` + a Unity `.gitattributes` (textures, audio, models, `*.unity` optionally)
- Confirm serialization is Force Text and Visible Meta Files (ProjectSettings) so diffs/merges work

## Tests / quality
- Unity Test Framework (EditMode + PlayMode): `com.unity.test-framework` in `Packages/manifest.json`
- CLI run: `Unity -batchmode -runTests -projectPath . -testPlatform EditMode -testResults results.xml` (requires the editor installed and licensed)
- C# quality: same analyzers as the .NET stack where applicable

## CI (GitHub Actions)
Use GameCI (`game-ci/unity-test-runner`, `game-ci/unity-builder`). Requires a `UNITY_LICENSE` secret — walk the user through GameCI activation; CI is not fully autonomous for Unity until that secret exists. Cache `Library/`.

## Audit tooling
- Dependencies: review `Packages/manifest.json` pins; Dependabot has no Unity support — note this honestly in audits
- Static analysis: Semgrep (`p/csharp`) on `Assets/**/*.cs`; CodeQL C# works only with a full build, which is often impractical in CI — say so rather than pretending coverage
- Performance: Unity Profiler guidance; frame-budget checks in PlayMode tests where feasible
