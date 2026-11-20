---
name: create-playwright-framework
description: >-
  Build or extend a service's TypeScript Playwright E2E framework using
  playwright-bdd, Gherkin, typed pages fixtures, Page Object Model,
  shared helpers, data-driven journey switches, accessibility checks and verified
  reporting. Use when asked to adopt, scaffold or implement E2E tests in a service.
---

# Create a Playwright E2E framework

Implement a working, service-specific E2E journey and validation scenario. Preserve the target service's application behaviour, build scripts and existing tests.

After creating or updating the framework, do not execute any tests. This includes the new E2E and validation scenarios, existing unit or integration tests, and test commands invoked through scripts or other tools. You may run non-test checks such as BDD generation/listing, lint, or type-checking when they do not execute tests. Report that tests were not run; do not claim execution or passing results.

Use the [portable starter patterns](references/starter-patterns.md) for configuration, step bindings and scripts. For page objects, fixture registration and feature files, use only the mandatory templates below. Starter patterns are illustrative code for a hypothetical service, not selectors or routes to copy blindly. This folder is self-contained.

## Mandatory templates

These templates are required, not optional examples. Follow their structure, naming and method set exactly, substituting only the `<placeholders>`:

- [Page templates](references/page-templates.md): create exactly three page files: `e2e-tests/pages/base-page.ts` (`BasePage`), `<service>-landing-page.ts` and `<service>-<second-page>-page.ts`. Both service-prefixed classes extend `BasePage`, inherit its constructor and define `expectedPageTitle()` and the page-specific completion method shown in the templates. Register the base page and both service pages in the fixture.
- [Feature templates](references/feature-templates.md): create one `<service>.feature` with one E2E `Scenario Outline` and one Examples row, plus one `<service>-validation.feature` with one validation `Scenario`. Follow the templates' tags, step wording and scenario layout.

Where a template and the starter patterns differ, the templates win. Do not add more page objects or scenarios, or substitute your own page layout, class naming or feature structure. Do not add constructors, locators or action methods beyond the templated completion methods to the two service pages. If the requested journey cannot fit this boundary, ask before expanding it.

Implement all Given, When and Then bindings needed by both features in the step file, following the starter's switch-based example and shared continue and error bindings. Reuse a single binding for identical step text, including the shared Given. Implement validation navigation and field entry using verified service behaviour; do not create empty callbacks. Include both features in discovery once their bindings are implemented, and report any execution blockers explicitly.

## 1. Inspect before implementing

Read the target repository's instructions and inspect:

- Worktree status, package manifest, runtime requirements, package-manager lockfile and install/build lifecycle.
- Existing E2E tests, Playwright configuration, TS configuration and lint rules.
- Application routes, form definitions, templates, accessible labels, validation and page transitions.
- CI provider, test environment provisioning, reporting, artifact storage and secret injection.
- The target pull-request template, if present, to understand expected evidence.

Do not read, print, copy or embed secret values merely to understand environment setup. Variable names and placeholder-only examples are sufficient.

## 2. Establish the implementation boundary

Determine the target service, initial journey, page order, input variants and observable outcome from source or approved browser evidence.

Before potentially consequential actions, resolve:

- Which non-production target is approved?
- Is authentication required, and how is test-owned authentication supplied?
- Do submission/retry actions create records, send email, charge, notify or otherwise affect external systems?
- Should execution target an existing deployment or start a local service?
- Should reporting stay with the existing provider, use Playwright HTML, or explicitly adopt Allure?
- Is CI publishing requested, and what destinations and permissions are approved?

Ask for missing decisions when they materially affect design or safety. Never invent routes, credentials, labels, expected messages or submission permissions. Implement inspectable portions while clearly reporting any remaining blockers; do not claim a blocked browser journey passed.

For an existing framework, integrate with it instead of creating competing fixtures/configs or replacing unrelated scripts. Do not silently migrate package managers, raise runtime requirements, or turn off install/build hooks.

## 3. Preserve the architecture

Use this structure unless the target repository already has an equivalent established layout:

```text
e2e-tests/
  features/                 # <service>.feature and <service>-validation.feature (feature templates)
  steps/                    # E2E and validation bindings and journey orchestration
  fixture/
    fixtures.ts             # Typed pages fixture and exported test/expect
  pages/
    base-page.ts            # Shared BasePage from the page templates
    <service>-landing-page.ts # Service-prefixed landing page from the page templates
    <service>-<second-page>-page.ts # Second service page, named from the actual journey
  utility-helper/           # Synthetic data and reusable, justified helpers
  README.md                 # Setup, run, debug and reporting commands
playwright.config.ts        # BDD discovery and execution
.features-gen/              # Generated, ignored, never manually maintained
```

Required dependency flow:

**Feature example -> bddgen -> Playwright test -> typed fixture -> BDD step -> page object -> browser -> assertion -> report.**

Implementation rules:

1. Use `playwright-bdd`'s base test for `base.extend<{ pages: Pages }>`.
2. Construct each page object with the supplied test-scoped `page` inside the fixture and pass the registry to `await use(...)`.
3. Keep the registry type and constructed properties consistent. Let Playwright manage the page/context lifecycle.
4. Bind steps with `createBdd(test)`, importing the extended test from the fixture.
5. Include the step module and the fixture module in BDD discovery, together with the E2E and validation features. When integrating with an existing framework, retain discovery of its existing features and avoid duplicate bindings.
6. Reuse shared base-page helpers for interactions; keep service-specific step bindings and journey sequencing in steps and use the templated completion methods where appropriate.
7. Prefer a small shared base over a generic automation abstraction. Extract a component only when there is real repeated behaviour.
8. Class naming follows the page templates: `BasePage` and PascalCase service-prefixed page classes. Follow the target repository's formatting otherwise.

Do not add a Cucumber World or separate Cucumber runner to this Playwright-fixture architecture unless a specific requirement warrants a different design.

## 4. Implement one real vertical slice

Add compatible dependencies with the existing package manager only as needed. Resolve versions against the target runtime, manifest and lockfile.

Implement in coherent batches:

1. BDD discovery and runner settings.
2. Exactly three page files: the shared base page and the two service-prefixed pages from the [page templates](references/page-templates.md).
3. Typed fixture registration.
4. One E2E journey feature and one validation feature from the [feature templates](references/feature-templates.md), with all matching bindings and synthetic data.
5. Expected outcome assertions, including meaningful data differences where relevant.
6. Run/debug/report scripts, environment documentation and ignore rules.

Keep the first executable slice small enough to validate end to end. Do not leave a demonstration contact form in a service whose real journey differs.

### Page objects and assertions

Keep both service pages limited to `expectedPageTitle()` and their templated completion method, and inherit the base constructor. Fill required fields before completing a page and verify its continue button against the application. The following interaction rules apply to the shared base page and step bindings, not additional service-page members.
- Inject `Page`; use typed, readonly `Locator` properties for page-owned controls.
- Prefer accessible role/name or label locators; otherwise use stable, intentional IDs/test IDs verified against the actual application.
- Await every relevant UI action. Do not parallelize a sequential journey on the same tab.
- Clearly distinguish fill-only actions from actions that also continue or submit.
- Use retrying locator assertions for readiness, errors, headings, values and links.
- Do not use fixed sleeps, positional selectors or CSS tied to class ordering as shortcuts.
- Do not wrap actions in catches that turn failures into success.
- Preserve intentional invalid input for application-validation tests. Validate missing test configuration separately from intentionally invalid form data.
- Derive exact expected titles from the service, including the `Error: ` prefix and title separators. Use the template's `title.startsWith('Error')` conditional in both service pages. Document accessibility/title checks performed by completion methods or steps.

## 5. Implement BDD variants and the journey switch

Follow the outline-to-step pattern in the starter:

1. Define one readable journey label in the single Examples row.
2. Capture the quoted value with `{string}` as a typed callback argument.
3. Use `switch (scenario.toLowerCase())` with lowercase case labels for a small number of variants.
4. Await the page calls with variant-specific data; terminate each supported case with `break`.
5. Keep genuinely shared completion after the switch only when every variant should execute it.
6. Throw a descriptive error in `default`, including the original supplied label.

Explain in the service README that lowercasing does not trim whitespace or repair punctuation/spelling. A switch is not a tag filter: outline rows become independent generated tests.

For a larger data-only matrix, consider a typed data set rather than duplicating orchestration. Do not introduce that abstraction pre-emptively.

For validation steps, navigate through the actual service and enter and submit the specified values, preserving intentionally invalid data. Verify each expected message against the application. Implement a data-table binding only if the feature actually uses one.

## 6. Environment, configuration and isolation

- Load local configuration with the existing mechanism, such as dotenv; use an ignored local file and placeholder-only documentation.
- Validate required variables explicitly. Do not evaluate unrelated required integration data during discovery unless necessary.
- Document that existing process variables take precedence when dotenv override is not enabled.
- Set a verified base URL. Start a managed server only when its command, port/readiness and dependencies are known.
- Do not default tests to production. Keep authentication state ignored and test-owned.
- Match runner/browser/CI image versions and document local versus CI headless, worker and retry behaviour.
- Make effective screenshot/video/trace settings clear, including project overrides.
- Use test-scoped fixtures; shared back-end resources still need uniqueness or cleanup.
- Review retry side effects before enabling retries or parallel workers.
- Document that `CI=false` is truthy in configurations using `!!process.env.CI`.

Merge scripts without removing `build`, `postinstall`, existing unit tests or application startup. Add `bddgen` before E2E execution. Keep generated output and private artifacts out of Git.

## 7. Accessibility, lint and types

For agreed visited states, establish page readiness, scan with explicit axe rule tags, and report actionable violations. If using soft assertions, explain that the test still fails overall.

Do not present automated axe scans as full accessibility certification. Identify relevant manual keyboard/screen-reader checks and error/dynamic states.

Keep the generated `tsconfig.json` limited to this configuration; do not add other keys or compiler options:

```json
{
  "compilerOptions": {
    "types": ["node", "@playwright/test"]
  }
}
```

Ensure TypeScript-aware linting and an explicit type-check command actually include the E2E files. Playwright's TS transformation is not type-checking. Avoid `any`, unsafe casts and unused step parameters.

Do not run `yarn test:e2e:lint` or `yarn test:e2e:types`. Report these checks as not run.

If framework setup creates a root `.eslintrc.cjs`, remove that generated file after setup and verification are complete. Do not delete a `.eslintrc.cjs` that existed before the task, and ensure no added scripts or configuration depend on the generated file.

Add focused coverage for the introduced behaviour, not a large unrelated test suite.

## 8. Reporting and optional CI publishing

By default, preserve existing reporting or use Playwright HTML/list. Distinguish:

- Generated executable tests.
- Raw execution results and attachments.
- A rendered HTML report.
- A published release/artifact and its link.

Only add Allure when requested or agreed. It needs a compatible reporter, raw results, a generation step, ignored output and a publisher pointed to the generated directory. For Allure 2 CLI, verify a compatible Java runtime. Account for CLI reporter overrides in scheduled runs.

For requested CI integration:

1. Use the target CI provider and deployment readiness; do not copy environment-specific domains, secret names or repository identity.
2. Generate reports on passing and failing tests without discarding the test exit status.
3. Reject missing/stale results rather than publishing an empty or previous report.
4. Publish only to an approved destination with appropriate access/retention.
5. Use existing short-lived authentication where available. Never hardcode tokens or private keys.
6. Preserve deliberate rerun behaviour for asset replacement and marked PR comments.
7. Validate locally with mocks where practical; do not upload artifacts or create PR comments merely to test a script without approval.

Do not create a CI publishing integration if the user requested only local framework setup.

## 9. Verify the actual requirement

Run the smallest non-test checks that demonstrate the framework is configured correctly. Do not execute tests after creating or updating the framework:

1. If dependencies changed, install them only if the install lifecycle does not execute tests.
2. Run BDD generation and test listing only; confirm both scenarios have matching bindings and existing feature discovery is preserved. These checks must not execute tests.
3. Check ignored output, absence of secrets and preservation of existing application scripts/tests.
4. Confirm exactly three page files, only `expectedPageTitle()` and the templated completion method declared in each service page, and registrations for the base page and both service pages in the fixture. Do not run browser scenarios to verify title branches.

Generation, listing, lint and type-check success are not evidence that tests passed or that the actual service's labels/routes work. State explicitly that tests were not run and that browser behaviour remains unverified; provide safe commands for the team to run tests separately if appropriate.

Do not weaken assertions, disable accessibility, skip meaningful tests or raise timeouts merely to obtain a green result.

## 10. Deliver the implementation and handover

Provide:

- Working source/configuration changes limited to the requested service scope.
- A service E2E README with folder map, commands, environment names/placeholders, fixture/POM explanation, journey labels, tags, accessibility scope and report instructions.
- A concise implementation summary and any intentional deviations from these templates.
- Exact non-test checks run and outcomes; explicitly state that the E2E and validation scenarios were not run and identify their unverified behaviour.
- CI/PR evidence matching the target template when requested; do not create a PR or commit automatically.

Stop when the requested slice is implemented and verified to the available approval/environment boundary. Do not claim production readiness, full accessibility compliance or passing E2E execution without supporting evidence.
