# Stack: .NET / C#

## Detect
`*.sln`, `*.slnx`, `*.csproj`, `global.json`, or an `.idea/` Rider project alongside C# sources.

## Scaffold
Ask which shape: console, class library, web API, Blazor, worker service. Then:

```bash
dotnet new sln -n <Name>
dotnet new <template> -n <Name> -o src/<Name>       # e.g. webapi, console, classlib
dotnet new xunit -n <Name>.Tests -o tests/<Name>.Tests
dotnet sln add src/<Name> tests/<Name>.Tests
dotnet new gitignore
```

Pin the SDK with `global.json` (`dotnet --version` to get the installed one). Ask xUnit vs NUnit if the user has a preference; default xUnit.

## Tests / quality
- Test: `dotnet test`
- Format/lint: `dotnet format --verify-no-changes`; enable `<TreatWarningsAsErrors>` and .NET analyzers in a `Directory.Build.props`.

## CI (GitHub Actions)
`actions/setup-dotnet` → `dotnet restore` → `dotnet build --no-restore -warnaserror` → `dotnet test --no-build`. Deploy jobs depend on the roadmap's deployment answers (Azure App Service, containers, etc.).

## Audit tooling
- Dependencies: `dotnet list package --vulnerable --include-transitive`
- Static analysis: CodeQL (csharp), Semgrep (`semgrep --config p/csharp`)
- Security analyzers: `SecurityCodeScan.VS2019` NuGet analyzer
- Fuzzing (where applicable, e.g. parsers): SharpFuzz
