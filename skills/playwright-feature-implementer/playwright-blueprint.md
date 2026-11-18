# Playwright Blueprint Rules

Normative rules taken from the QAT "Playwright Test Structure – LMR Playwright and POM framework blueprint". Every implementation the skill produces must follow them. Each rule has an ID that matches [compliance-checklist.md](./compliance-checklist.md).

- **MUST**: required. A violation in code the skill writes or touches must be fixed before the work is complete.
- **SHOULD**: recommended. If the skill doesn't follow it, the report must say why.
- Where a rule says "match the repository", the target repository's agreed convention wins. The blueprint itself says not to force LMR naming onto other services.

Precedence: blueprint rules beat repository conventions on **structure, safety and assertion quality**. Repository conventions win on **naming and style**.

---

## 1. Architecture and responsibilities (`ARCH`)

Execution flow: **Gherkin features → bddgen-generated tests → BDD step definitions → `pages` fixture (per test) → page objects + base page → Playwright page/service UI**. `playwright.config.ts` controls discovery, generation, server, browser and reporting.

| Layer | Responsibility | Canonical location |
|---|---|---|
| Features | Journeys, examples and validation outcomes in Gherkin | `e2e-tests/features/*.feature` |
| BDD generation | `defineBddConfig` discovers features and steps; `bddgen` writes tests to `.features-gen/` | `playwright.config.ts` |
| Steps | Bind Gherkin expressions to async functions; orchestrate page objects; assert outcomes | `e2e-tests/steps/*.step.ts` |
| Fixtures | Extend playwright-bdd `test` with a typed `pages` object built from the same test-scoped `page` | `e2e-tests/fixture/fixtures.ts` |
| Pages | Locators and page-level actions; extend the shared base page | `e2e-tests/pages/` |
| Shared helpers/data | Base page interactions, date conversion, error/a11y helpers; shared constants | `e2e-tests/pages/base-page.ts`, `e2e-tests/utility-helper/constants-lib.ts` |
| Runner/reports | Start or target the service, run Chromium, retry, report, keep failure evidence | `playwright.config.ts`, `package.json` |

- **ARCH-01 MUST** keep each concern in its layer: business language in features, journey orchestration and outcome assertions in steps, UI interaction and locators in page objects, shared values in constants.
- **ARCH-02 MUST NOT** create, edit or commit anything under `.features-gen/`, `playwright-report/` or `test-results/`. These are generated and git-ignored.
- **ARCH-03 MUST** place new files in the folder structure above. If the repository already uses equivalent blueprint-shaped folders under different names (for example `e2e/` instead of `e2e-tests/`), reuse them. Don't create a parallel tree.
- **ARCH-04 MUST NOT** add a second test style (for example plain `*.spec.ts` tests alongside BDD) for the supplied feature.

## 2. BDD generation and configuration (`CFG`)

- **CFG-01 MUST** generate tests with `defineBddConfig` in `playwright.config.ts`. Its `features` and `steps` globs must cover the feature and step folders, and the steps globs must include the fixture file.
- **CFG-02 MUST** have package scripts that run generation before Playwright: `bddgen`, and `test:e2e` = `bddgen && playwright test`. Report/debug/headed scripts SHOULD exist.
- **CFG-03 MUST** git-ignore `.features-gen/`, `playwright-report/`, `test-results/` and `.env`.
- **CFG-04 SHOULD** keep the blueprint runner defaults unless the repository has agreed different values:
  - Target: `PLAYWRIGHT_BASE_URL` when set (no managed server). Otherwise `http://localhost:<PLAYWRIGHT_PORT|8080>`, using the service's dev-start command as `webServer`, with `reuseExistingServer: !process.env.CI`.
  - Browser: one Chromium project (`viewport: null`). Headless when `CI` is set, headed locally.
  - Execution: `fullyParallel: true`; local 1 worker/1 retry; CI 2 workers/2 retries; `forbidOnly: !!process.env.CI`; test timeout 30s; expect timeout 6s.
  - Evidence: HTML and list reporters, `screenshot: 'only-on-failure'`, `trace: 'on-first-retry'`, video retained on first retry.
  - `dotenv.config({ quiet: true })` loads an optional, git-ignored `.env`. Process environment wins.
- **CFG-05 MUST NOT** copy LMR URLs, secrets, ports or start commands. Use the target service's own values.

## 3. Features and test data patterns (`FEAT`)

- **FEAT-01 MUST** keep the supplied feature's wording, step order, tags, Background, titles, Scenario Outline placeholders and Examples values exactly as written. The feature is the contract.
- **FEAT-02 SHOULD** write business-readable Given/When/Then. Use Scenario Outlines for variations and data tables for named fields. The skill doesn't rewrite a supplied feature to meet this. It records recommendations in the report.
- **FEAT-03 SHOULD** prefer independent, focused scenarios over one long multi-page validation walk. This reduces failure cascades and supports parallel runs. Report it as a recommendation when the supplied feature does otherwise.
- **FEAT-04 MUST** read two-column data tables with `DataTable.rowsHash()` and pass the values to page methods. Fail explicitly when a required key is missing (`STEP-05`).
- **FEAT-05 MUST** split multiple expected validation messages written in one cell with `¬` in the step (`value.split('¬')`), and assert them in order.
- **FEAT-06 SHOULD** apply tags deliberately (for example `@<Service>RegressionTest`, `@<Service>E2ETest`), with documented selection semantics. Don't rely on tag-based scripts (smoke/history) that select nothing.

## 4. Step definitions (`STEP`)

- **STEP-01 MUST** create steps with `createBdd(test)`, where `test` is imported from the repository's extended fixture (`../fixture/fixtures`). Never use `test` from `@playwright/test` or the bare `playwright-bdd` `test`.
- **STEP-02 MUST** destructure `{ pages }` (plus other fixtures only when needed) and `await` every page method and assertion.
- **STEP-03 MUST** make step expressions and parameter order match the feature text exactly (`{string}` receives the value without its quotes).
- **STEP-04 MUST** use every step parameter, or remove it from the expression. An unused parameter doesn't make a step generic.
- **STEP-05 MUST** fail explicitly with a descriptive `Error` that includes the original value for unsupported values, unknown journeys, missing table fields and malformed data. Never silently skip.
- **STEP-06 MUST** verify a meaningful, observable outcome in every `Then`, using a retrying locator assertion (`ASSERT-01`).
- **STEP-07 MUST NOT** contain selectors (`page.locator`, `getBy*`, CSS or ids) or raw `page` interactions. Steps call page-object methods and locators only.
- **STEP-08 MUST NOT** duplicate an existing step expression or create near-duplicates. Reuse existing steps and extend them only when the change is safe for every scenario that uses them.
- **STEP-09 SHOULD** import shared constants as a namespace (`import * as c from '../utility-helper/constants-lib'`) when the repository does so.

### Journey switch pattern (`STEP-10`)

Use this pattern only when an outline placeholder names a journey that selects different data or actions inside one generated test:

```ts
When('I fill out the answers to <form> pertaining to {string}', async ({ pages }, scenario: string) => {
  switch (scenario.toLowerCase()) {
    case 't1: all fields completed':
      await pages.startPage.completeStartPage(c.FULL_NAME);
      break;
    case 't2: optional field values not entered':
      await pages.startPage.completeStartPage('');
      break;
    default:
      throw new Error(`Invalid scenario: ${scenario}`);
  }
  // Genuinely shared completion goes after the switch.
});
```

- **STEP-10a MUST** write each `case` label as the exact lowercased Examples value. `toLowerCase()` doesn't trim, collapse whitespace or fix spelling or punctuation.
- **STEP-10b MUST** end every case with `break`. No fall-through.
- **STEP-10c MUST** have a `default` that throws `Invalid scenario: ${scenario}` using the original value.
- **STEP-10d MUST** model a journey with a different expected outcome explicitly in the feature and steps, not force it through the shared completion path.
- The switch selects data and actions within a generated test. It's not a tag filter.

## 5. Fixtures (`FIX`)

- **FIX-01 MUST** extend `test` from `playwright-bdd` (`base.extend<{ pages: Pages }>`) and export `test` and `expect = test.expect`.
- **FIX-02 MUST** define a typed `Pages` registry. Every page object must be added to **both** the `Pages` type and the object passed to `use(...)`.
- **FIX-03 MUST** construct each page object with the fixture's test-scoped `page`. The fixture is a per-test registry, not a global singleton. Don't share state across tests.

## 6. Page objects and base page (`POM`)

- **POM-01 MUST** extend the shared base page and call `super(page)` (once a base page exists). The base page stores the injected `Page`, common `readonly` locators and shared operations.
- **POM-02 MUST** declare page-specific locators as `readonly` properties, created in the constructor or as locator-returning methods. Each selector is defined once, not repeated in steps or other pages.
- **POM-03 MUST** name async methods for user intent (`completeExistingTenantsInformationPage`, `selectDeclarationAndSubmit`), not for DOM mechanics.
- **POM-04 MUST NOT** let page objects instantiate or import one another. Cross-page sequencing belongs in steps or a clearly named journey helper.
- **POM-05 MUST** document, in a short JSDoc, any side effect beyond filling fields: navigating, continuing, submitting, or running accessibility/title checks.
- **POM-06 MUST** treat only genuinely optional UI (for example a conditional cookie banner) as optional. Don't swallow failures with empty `catch` blocks or `.catch(() => {})`.
- **POM-07 SHOULD** follow the "complete…Page" pattern for form pages: accessibility scan, title check (allowing for the `Error: ` prefix where applicable), fill fields, continue. Completion methods must also work with invalid input so they can drive validation scenarios.
- **POM-08 MUST NOT** put service-specific workflows into the base page. Extract a component object only when a repeated component has enough behaviour to justify it.
- **POM-09 MUST** reuse base helpers only where their behaviour fits the control. LMR-style Tab-after-fill and blank-date handling aren't neutral for every control.

## 7. Selectors and locators (`LOC`)

Priority order:

1. **LOC-01** `getByRole(role, { name, exact: true })`, or `getByLabel(label, { exact: true })` for form inputs. Use `exact: true` wherever a name could be ambiguous.
2. **LOC-02** A stable, intentional id or agreed test id (`#tenant-full-name`, `getByTestId`) only when semantics are insufficient.
3. **LOC-03 MUST NOT** use XPath, layout or position selectors (`nth-child`, unscoped `.nth()`/`.first()`/`.last()`), exact class-attribute chains, or incidental-text CSS such as `a:has-text(...)`.
4. **LOC-04 MUST** scope locators to a component (`region.getByRole(...)`) when names repeat on the page.
5. **LOC-05** Treat a changed accessible name as both a UI and a test-contract change, and flag it in the report.

## 8. Assertions and waits (`ASSERT`)

- **ASSERT-01 MUST** use retrying web-first assertions for UI state: `await expect(locator).toBeVisible()`, `.toHaveText()`, `.toHaveTitle()`, `.toHaveURL()`, `.toHaveCount()`.
- **ASSERT-02 MUST NOT** assert on immediate snapshots such as `expect(await locator.isVisible())`, `expect(await locator.textContent())` or `expect(await locator.innerText())`. Don't copy existing helpers that do this. Fix them when touched.
- **ASSERT-03 MUST NOT** use fixed sleeps (`page.waitForTimeout`, `setTimeout` promises). Rely on actionability and retrying assertions. Use explicit, meaningful waits (`waitForURL`, `waitForResponse`, `waitForLoadState`) only for real external transitions.
- **ASSERT-04 MUST** compare validation outcomes against both the error heading and the ordered error-summary messages.
- **ASSERT-05 MUST NOT** leave `test.only`, `.skip` or `test.fixme` without a reported reason.

## 9. Accessibility (`A11Y`)

- **A11Y-01 MUST** keep the base-page `assertAccessibility()` contract: wait for load and a visible `h1`, run `@axe-core/playwright` with tags `wcag2a` and `wcag2aa`, and record violations with `expect.soft`.
- **A11Y-02 MUST** call `assertAccessibility()` (with title checks) in each new page's completion method and on the final/confirmation page. Raw continue clicks and link-only scenarios don't scan automatically, so add explicit scans where the feature covers new page states.
- **A11Y-03** Report that automated axe checks are partial coverage and don't replace manual accessibility testing.

## 10. Test data, environment and secrets (`DATA`)

- **DATA-01 MUST** use synthetic data only. No real personal data, credentials, tokens or production identifiers in code, features, constants or fixtures.
- **DATA-02 MUST** keep reusable values in `utility-helper/constants-lib.ts` and reuse existing constants before adding new ones.
- **DATA-03 MUST** read required configuration with a `requiredEnv(name)` helper that throws a clear error when the value is empty. Remember that module-level `requiredEnv` stops every scenario that imports the module, so resolve rarely used values lazily where practical.
- **DATA-04 MUST NOT** commit `.env` files or real values. A `.env` template may only contain placeholders such as `<approved-test-recipient>`.
- **DATA-05 MUST** produce relative dates (for example "yesterday") from a helper that formats `dd/mm/yyyy`. Consider timezone and leap-day boundaries, and remember that a segment-count check doesn't validate calendar dates.
- **DATA-06 MUST** keep scenarios isolated and safe to retry: no hidden cross-scenario state, unique resources where needed, and cleanup appropriate to the environment.

## 11. Safety and side effects (`SAFE`)

- **SAFE-01 MUST** run scenarios that submit, send email or call external integrations only against a local server or an explicitly approved non-production `PLAYWRIGHT_BASE_URL`. Never run them against production.
- **SAFE-02 MUST** remember that retries can repeat a submission. Confirm retries, worker count and side effects together.
- **SAFE-03 MUST** keep secrets in environment or CI secret stores and out of logs, screenshots, traces, videos and reports.
- **SAFE-04 MUST NOT** change CI/CD pipelines, application source or unrelated tests.

## 12. Coding conventions (`CODE`)

- **CODE-01 MUST** use TypeScript, kebab-case file names, `*.step.ts` step files, `async`/`await`, named exports, `readonly` locators and descriptive method names.
- **CODE-02 MUST** match the repository's agreed class-naming convention consistently. LMR uses lowerCamel (`basePage`, `lmr…Page`), and the blueprint's new-service example uses PascalCase. Follow whichever the repository uses, and use PascalCase in a fresh scaffold.
- **CODE-03 MUST** have TypeScript-aware lint and type-check commands that cover the E2E folder. Don't assume the service's lint config includes `e2e-tests` (LMR's `.eslintignore` excludes it). If no E2E type-check exists, run `npx tsc --noEmit -p <e2e tsconfig>` and report the gap.

## 13. Onboarding checklist for scaffold mode (`SCAF`)

Used only when the repository has no blueprint-compliant framework. See [scaffold-templates.md](./scaffold-templates.md).

1. **SCAF-01** Agree the test boundary: approved non-production environment, synthetic users/data, submission side effects, cleanup, accessibility scope and artifact retention. Record anything unknown as an assumption.
2. **SCAF-02** Add compatible `@playwright/test`, `playwright-bdd`, `@cucumber/cucumber`, `@axe-core/playwright`, `dotenv` and the required types as dev dependencies, using the repository's package manager and lockfile. Install Chromium.
3. **SCAF-03** Create the folders and adapt `playwright.config.ts` (CFG rules), scripts and `.gitignore`.
4. **SCAF-04** Create a minimal base page and one page object per feature page, using the service's real labels and routes.
5. **SCAF-05** Register the fixture (FIX rules).
6. **SCAF-06** Implement the feature as the first vertical slice, then run the verification gates (including the deliberate failing-assertion proof).
7. **SCAF-07** Afterwards: expand coverage, wire CI (`CI=true`, secrets, artifact upload) and review regularly. These are out of scope for this skill and must be reported as next steps.
