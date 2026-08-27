# Stack: TypeScript / Node (web)

## Detect
`package.json` (check for `typescript` in deps), `tsconfig.json`.

## Scaffold
Ask which shape: web app (default Vite + React unless the user prefers Next.js/other), Node service/API (Fastify or Express), CLI, or library. Then use the ecosystem generator rather than hand-rolling:

```bash
npm create vite@latest <name> -- --template react-ts     # web app
npx create-next-app@latest <name> --typescript           # Next.js
npm init -y && npm i -D typescript @types/node && npx tsc --init   # service/library base
```

Ask npm vs pnpm; default npm unless a lockfile says otherwise. Add Vitest for unit tests and Playwright for e2e when the app has a UI.

## Tests / quality
- Test: `npx vitest run` (unit), `npx playwright test` (e2e)
- Lint/format: ESLint + Prettier; typecheck with `npx tsc --noEmit`

## CI (GitHub Actions)
`actions/setup-node` (cache npm) → install → `tsc --noEmit` → lint → unit tests → build → e2e (Playwright container) if present. Deploy per roadmap answers (Vercel, Cloudflare, containers, etc.).

## Audit tooling
- Dependencies: `npm audit`, Dependabot
- Static analysis: CodeQL (javascript-typescript), Semgrep (`semgrep --config p/typescript --config p/react`)
- 508/accessibility: axe-core (`@axe-core/playwright`) wired into e2e tests; Lighthouse for page-level checks
- Fuzzing (where applicable): `@jazzer.js/core` for parsers/validators
