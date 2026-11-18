# Blueprint Compliance Checklist

Use this checklist in Phase 6, gate G7, of [SKILL.md](./SKILL.md). Rule definitions are in [playwright-blueprint.md](./playwright-blueprint.md).

Mark every item `PASS`, `FAIL`, `N/A` (with a reason) or `REPORTED` (a pre-existing deviation outside touched code, listed under `DEVIATIONS_NOT_FIXED`). The work is not complete while any MUST item in **new or touched** code is `FAIL`.

Verification method key:

- **scan**: [blueprint-static-scan.sh](./blueprint-static-scan.sh) reports it (the finding ID is shown).
- **gate**: proved by a verification gate (G1–G6).
- **review**: inspect the diff manually and quote the file and line as evidence.

| ID | Check | Severity | Verify by |
|---|---|---|---|
| ARCH-01 | Feature, step, page, fixture and constants concerns sit in their own layers | MUST | review |
| ARCH-02 | Nothing under `.features-gen/`, `playwright-report/` or `test-results/` is edited or staged | MUST | scan `ARCH-02` |
| ARCH-03 | New files are in the blueprint folders (or the repository's existing equivalents); no parallel tree | MUST | review |
| ARCH-04 | No second test style (plain `*.spec.ts`) was added for the feature | MUST | scan `ARCH-04` + review |
| CFG-01 | `defineBddConfig` covers the feature, steps and fixture globs | MUST | review + gate G1 |
| CFG-02 | `bddgen` and `test:e2e` (`bddgen && playwright test`) scripts exist | MUST | review |
| CFG-03 | `.features-gen/`, `playwright-report/`, `test-results/` and `.env` are git-ignored | MUST | review (`git check-ignore`) |
| CFG-04 | Runner defaults follow the blueprint or an agreed repository variant | SHOULD | review |
| CFG-05 | No copied LMR URLs, ports, start commands or secrets | MUST | review |
| FEAT-01 | The feature file is byte-identical to the input, or the user explicitly approved changes | MUST | review (`git diff` on the feature) |
| FEAT-02 | Recommendations recorded for any non-business-readable wording | SHOULD | review |
| FEAT-03 | Recommendation recorded for long multi-page validation walks | SHOULD | review |
| FEAT-04 | Two-column tables read with `rowsHash()`; missing keys throw | MUST | review + gate G6 |
| FEAT-05 | `¬`-separated messages are split and asserted in order | MUST | review |
| FEAT-06 | Tags used deliberately; tag-script semantics noted | SHOULD | review |
| STEP-01 | `createBdd(test)` uses the extended fixture `test`; no `@playwright/test` `test` import in steps | MUST | scan `STEP-01` |
| STEP-02 | Steps destructure `{ pages }` and await every call | MUST | review + lint (`no-floating-promises` if configured) |
| STEP-03 | Expressions and parameter order exactly match the feature | MUST | gate G1 (no missing steps) |
| STEP-04 | Every step parameter is used | MUST | review + type-check/lint (`no-unused-vars`) |
| STEP-05 | Unsupported values, missing fields and unknown journeys throw descriptive errors | MUST | gate G6 |
| STEP-06 | Every `Then` asserts an observable outcome with a retrying assertion | MUST | review + gate G5 |
| STEP-07 | No selectors or raw `page` interaction in step files | MUST | scan `STEP-07` |
| STEP-08 | No duplicate or near-duplicate step expressions | MUST | gate G1 (no ambiguous steps) + review |
| STEP-09 | Constants are imported in the repository's agreed form | SHOULD | review |
| STEP-10a–d | Journey switch: exact lowercased labels, `break` per case, throwing `default`, distinct outcomes modelled explicitly | MUST | review + gate G6 |
| FIX-01 | Fixture extends playwright-bdd `test` and exports `test` and `expect` | MUST | review |
| FIX-02 | Each new page is in both the `Pages` type and the `use({...})` object | MUST | review + type-check (G3) |
| FIX-03 | Page objects are built from the test-scoped `page`; no shared state | MUST | review |
| POM-01 | Pages extend the base page and call `super(page)` | MUST | review |
| POM-02 | Locators are `readonly` and defined once | MUST | review |
| POM-03 | Method names express user intent | MUST | review |
| POM-04 | Page objects never instantiate or import other page objects | MUST | scan `POM-04` + review |
| POM-05 | Side-effecting methods (navigate, submit, a11y/title checks) have JSDoc | MUST | review |
| POM-06 | No swallowed failures (`.catch(() => {})`, empty `catch`) | MUST | scan `POM-06` |
| POM-07 | Form pages follow the complete…Page pattern and accept invalid input | SHOULD | review |
| POM-08 | No service-specific workflow in the base page | MUST | review |
| POM-09 | Base helpers are reused only where they fit the control | MUST | review |
| LOC-01 | Role/label locators with `exact: true` where names could be ambiguous | MUST | review |
| LOC-02 | IDs or test IDs only when semantics are insufficient | MUST | review |
| LOC-03 | No XPath, position, class-chain or incidental-text CSS selectors | MUST | scan `LOC-03` (error) / `LOC-03W` (warning; justify or scope) |
| LOC-04 | Repeated names are scoped to a component | MUST | review |
| LOC-05 | Changed accessible names are flagged | SHOULD | review |
| ASSERT-01 | Retrying web-first assertions for UI state | MUST | review + gate G5 |
| ASSERT-02 | No `expect(await …isVisible()/textContent()/innerText())` snapshots | MUST | scan `ASSERT-02` |
| ASSERT-03 | No `waitForTimeout` or sleep promises | MUST | scan `ASSERT-03` |
| ASSERT-04 | Validation checks both the heading and the ordered summary messages | MUST | review |
| ASSERT-05 | No `.only`; any `.skip`/`.fixme` has a reported reason | MUST | scan `ASSERT-05` |
| A11Y-01 | `assertAccessibility()` contract kept (load, h1, axe wcag2a/wcag2aa, `expect.soft`) | MUST | review |
| A11Y-02 | Each new page and the final page are scanned | MUST | review |
| A11Y-03 | Report states that automated a11y coverage is partial | MUST | review (report) |
| DATA-01 | Synthetic data only; no real PII or credentials | MUST | scan `DATA-01` (warning) + review |
| DATA-02 | Reusable values live in the constants library; existing constants reused | MUST | review |
| DATA-03 | Required config read through `requiredEnv` with a clear error | MUST | review |
| DATA-04 | No `.env` or real values committed | MUST | scan `DATA-04` |
| DATA-05 | Relative dates use the date helper; timezone/leap-day risk considered | MUST | review |
| DATA-06 | Scenarios are isolated and retry-safe | MUST | review |
| SAFE-01 | Submitting scenarios run only against local or approved non-prod targets | MUST | gate G4 |
| SAFE-02 | Retries × side effects considered | MUST | gate G4 |
| SAFE-03 | No secrets in logs, traces, video or reports | MUST | review |
| SAFE-04 | No CI/CD, application source or unrelated test changes | MUST | review (`git diff --stat`) |
| CODE-01 | TypeScript, kebab-case files, `*.step.ts`, named exports | MUST | scan `CODE-01` + review |
| CODE-02 | Class naming matches the repository convention consistently | MUST | review |
| CODE-03 | Lint and type-check cover the E2E folder (gap reported if not) | MUST | gate G3 |

## Gate summary

| Gate | Proves | Pass condition |
|---|---|---|
| G1 | Generation | `bddgen` exits 0; no missing or ambiguous step warnings for the feature |
| G2 | Static rules | `blueprint-static-scan.sh` exits 0 on new or touched files; every warning is justified |
| G3 | Types and lint | The repository's type-check and lint commands for E2E exit 0, or the gap is reported |
| G4 | Safe execution | Safety decision recorded; focused run against an approved target passes, or it was not run, with the reason |
| G5 | Assertions can fail | A temporarily broken expected value in a `Then` makes the focused run fail; restored; `git diff` shows no residue |
| G6 | Explicit failure | A temporarily unknown journey or missing table key throws the descriptive error; restored; no residue |
| G7 | Checklist | Every row above is marked with evidence |
