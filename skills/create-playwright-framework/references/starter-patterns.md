# Portable Playwright starter patterns

Read this when implementing the skill. This is a connected, hypothetical contact/review journey demonstrating the architecture, **not an implementation to install unchanged**. Inspect the target service and substitute actual page names, routes, controls and expected outcomes.

Preserve target conventions and existing scripts/configuration when integrating.

## Framework invariants

| Layer          | Responsibility                                                     |
| -------------- | ------------------------------------------------------------------ |
| Gherkin        | Business behaviour and example values                              |
| BDD generation | Convert features/bindings into Playwright tests                    |
| Fixture        | Construct typed page objects on the test-scoped Playwright page    |
| Step           | Select data, orchestrate pages, assert outcomes                    |
| Page object    | Encapsulate selectors and page-level actions                       |
| Shared helper  | Small reusable UI/accessibility/data capabilities                  |
| Runner         | Browser lifecycle, isolation, retries and evidence                 |
| Reporting/CI   | Render results, preserve failures and publish only when configured |

Use `playwright-bdd` with Playwright, not a separate Cucumber World. HTML/list reporting is sufficient for a basic setup; Allure is optional.

## 1. Configuration

Use compatible `@playwright/test`, `playwright-bdd`, `@cucumber/cucumber`, `@axe-core/playwright`, `dotenv`, TypeScript and Node types, according to the target manifest/runtime. Install only missing/changed dependencies with the selected package manager.

The config below demonstrates discovery of both E2E and validation features; substitute the actual service feature filenames. Preserve discovery of existing features when integrating. `PLAYWRIGHT_BASE_URL` (from the git-ignored `.env`) selects the target; when it is unset, the config starts the service locally with the `webServer` command on `PLAYWRIGHT_PORT` (default 8080). Replace the `yarn start:dev` command, port and readiness settings with the target service's own, or remove `webServer` if the service is always tested on a deployed environment.

**Target file:** root `playwright.config.ts`.

```ts
import { defineConfig, devices } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';
import dotenv from 'dotenv';

dotenv.config({ quiet: true });

// baseURL is PLAYWRIGHT_BASE_URL from the .env file if set, otherwise http://localhost:${port}.
const port = Number(process.env.PLAYWRIGHT_PORT || 8080);
const baseURL = process.env.PLAYWRIGHT_BASE_URL || `http://localhost:${port}`;

const testDir = defineBddConfig({
  features: ['e2e-tests/features/contact.feature', 'e2e-tests/features/contact-validation.feature'],
  steps: [
    'e2e-tests/steps/**/*.step.ts',
    'e2e-tests/fixture/fixtures.ts',
  ],
  outputDir: '.features-gen',
});

export default defineConfig({
  testDir,
  timeout: 60000,
  expect: {
    timeout: 6000,
  },
  fullyParallel: true,
  workers: process.env.CI ? 2 : 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  reporter: [['html', { open: 'never' }], ['list']],
  use: {
    baseURL,
    viewport: null,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
    headless: !!process.env.CI,
  },

  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
      command: 'yarn start:dev',
      port,
      reuseExistingServer: !process.env.CI,
      timeout: 120_000
    },

  projects: [
    {
      name: 'chromium',
      use: {
        browserName: 'chromium',
        launchOptions: {
          args: ['--start-maximized'],
        },
        video: 'on-first-retry', // 'on', 'off', 'retain-on-failure' or 'on-first-retry'
        screenshot: 'only-on-failure', // 'on', 'off', 'only-on-failure' or 'on-first-retry'
      },
    }
  ],
});
```

The project-level `video` and `screenshot` values override the top-level `use` values for the chromium project. A missing `PLAYWRIGHT_BASE_URL` falls back to localhost, so make sure it is never left unset when you intend to test a deployed environment. Retries/workers above are examples: review side effects and capacity before enabling them.

## 2. Base page

Use the base page in [page-templates.md](page-templates.md) (section 0). Do not write a different base page.

## 3. Page objects

Use the service-prefixed page templates in [page-templates.md](page-templates.md): exactly three page files, comprising `BasePage`, the service landing page and one other verified journey page. Both service pages inherit the base constructor and declare `expectedPageTitle()` with the normal/error title conditional and their templated completion method. Do not generate additional pages or service-page members.

## 4. Typed fixture

Register the base page and the two service pages in the fixture exactly as shown in [page-templates.md](page-templates.md) (section 3). Add imports, type entries and instances together. The same test-scoped page is supplied to all page objects. Do not create a second browser or maintain a cross-test singleton.

## 5. Synthetic data

**Target file:** `e2e-tests/utility-helper/constants-lib.ts`.

```ts
export class ConstantsLib {
  static readonly FULL_NAME = 'Example Test Applicant';
  static readonly COMPANY_NAME = 'Example Test Company';
}
```

These are synthetic values. If an integration requires an environment value, validate it explicitly where needed, do not hardcode it, and avoid requiring unrelated integration configuration just to list scenarios.

## 6. Feature and switch-based steps

The feature below is a minimal illustration of the outline-to-step pattern. Real feature files must follow [feature-templates.md](feature-templates.md). The step example calls `contactPage.open()`/`complete()` and `reviewPage` for illustration only; do not generate those page members or additional page objects. Implement the actual E2E Given, When and Then bindings using the two service-prefixed pages, their templated completion methods, inherited base-page helpers and the supplied Playwright page. Also implement every validation step, reusing a single Given binding for the identical start step in both features. Do not create empty callbacks.

**Target file:** `e2e-tests/features/contact.feature`.

```gherkin
@contact
Feature: Contact details
  Scenario Outline: Review contact details
    Given I open the contact form
    When I complete the contact journey "<journey>"
    Then I see the contact review
    Examples:
      | journey              |
      | All fields completed |
      | Optional omitted     |
```

**Target file:** `e2e-tests/steps/contact.step.ts`.

```ts
import { createBdd } from 'playwright-bdd';
import { test, expect } from '../fixture/fixtures';
import { ConstantsLib as c } from '../utility-helper/constants-lib';

const { Given, When, Then } = createBdd(test);

Given('I open the contact form', async ({ pages }) => {
  await pages.contactPage.open();
});

When('I complete the contact journey {string}',
  async ({ pages }, scenario: string) => {
    switch (scenario.toLowerCase()) {
      case 'all fields completed':
        await pages.contactPage.complete(c.FULL_NAME, c.COMPANY_NAME);
        break;
      case 'optional omitted':
        await pages.contactPage.complete(c.FULL_NAME, '');
        break;
      default:
        throw new Error(`Unsupported contact journey: ${scenario}`);
    }

    await pages.reviewPage.assertAccessibility();
  });

Then('I see the contact review', async ({ pages }) => {
  await expect(pages.reviewPage.heading).toBeVisible();
});

When('I select continue', async ({ pages }) => {
  await pages.basePage.clickContinueButton();
});

Then('I should see {string} error message displayed', async ({ pages }, expectedErrorMessage: string) => {
  await expect(pages.basePage.thereIsAProblemText).toBeVisible();
  const actualErrorMessageLocator = await pages.basePage.getThereIsAProblemTextErrorText();
  if (actualErrorMessageLocator === null) {
    throw new Error('Error summary heading has no text content');
  }
  expect(expectedErrorMessage).toEqual(actualErrorMessageLocator);
});

Then('I should see {string} error summary', async ({ pages }, expectedErrorMessage: string) => {
  const expectedErrorArray = expectedErrorMessage.trim().split('¬');

  await expect(pages.basePage.errorSummaryList).toBeVisible();
  const actualText = await pages.basePage.getErrorSummaryListText();
  if (actualText === null) {
    throw new Error('Error summary list has no text content');
  }
  const actualErrorArray = actualText
    .replaceAll('\t', '')
    .trim()
    .split(/\r?\n/);

  expect(actualErrorArray).toEqual(expectedErrorArray);
});
```

The common post-switch scan checks the converged page state for both branches; the Then asserts the specific business heading. In a multi-page service, sequence actual common page actions there instead of inventing a submission step.

The three shared validation bindings above use `pages.basePage` from the fixture. They check the heading and ordered summary text as supplied, using `¬` between expected errors and removing tabs from actual list text. They wait for the relevant locator and report null text explicitly. Verify that the service's rendered text and whitespace match this convention; adapt selectors to the service, not expected messages to a fabricated result.

In the same step file, implement `When I choose to navigate to {string} page for <service>` and `When I enter {string} into {string} field and page for <service>` from the validation template. Use verified page names, controls and transitions, and submit after entering the value so invalid input displays errors and valid input advances. Reject unsupported page or field names with a descriptive error. Match the actual feature text and avoid registering a second binding for the shared Given.

`toLowerCase()` returns a new string. Case labels match exactly after lowercasing; whitespace and punctuation still matter. `break` reaches the common code; `return` would skip it. The default throws before common completion. Outline Examples generate separate tests; tags select tests, not switch branches.

## 7. Scripts, environment and ignore rules

Merge these scripts into the target manifest using its package manager. Preserve all unrelated commands, especially application `build` and `postinstall`.

```json
{
  "bddgen": "bddgen",
  "test:e2e": "bddgen && playwright test",
  "test:e2e:headed": "bddgen && playwright test --headed",
  "test:e2e:debug": "bddgen && playwright test --debug",
  "test:e2e:report": "playwright show-report"
}
```

Document local values with placeholders:

```dotenv
PLAYWRIGHT_BASE_URL=https://<approved-test-environment>
```

Ignore generated/private files:

```gitignore
.env
node_modules/
/.features-gen/
/test-results/
/playwright-report/
/blob-report/
/playwright/.auth/
/playwright/.cache/
```

Add a dedicated E2E type-check command and TS-aware lint inclusion using the target tooling. Select TS module/module-resolution settings compatible with the repository rather than copying an unrelated compiler setup.

## 8. Validation sequence

Example Yarn commands; translate to the selected package manager:

```powershell
yarn bddgen
yarn playwright test --list
yarn playwright test --grep @contact
yarn test:e2e:report
```

Listing does not execute browser interactions. Run only against an approved target. With zero local retries, request a retry explicitly when verifying first-retry traces. Verify supported E2E branch outcomes, validation errors and accessibility states.

For missing environment values or an unmatched journey, preserve useful errors rather than normalizing/falling back silently.

## 9. Optional Allure/CI extension

Do not add unless requested or agreed. Use compatible Allure reporter/CLI versions and the runtime the chosen CLI needs.

```ts
reporter: [
  ['list'],
  ['allure-playwright', { resultsDir: 'allure-results' }],
],
```

For Allure 2 CLI, merge:

```json
{
  "allure:generate": "allure generate allure-results --clean -o allure-report",
  "allure:open": "allure open allure-report"
}
```

Also ignore `/allure-results/` and `/allure-report/`. Raw results are not the rendered report. Generation must run after failing tests and preserve their failure status.

Illustrative shell block for CI, not a complete provider-specific configuration:

```sh
if [ -e allure-results ] || [ -e allure-report ]; then
  echo "A clean CI workspace is required for Allure output" >&2
  exit 1
fi

test_status=0
yarn test:e2e || test_status=$?
if [ ! -d allure-results ] ||
   [ -z "$(find allure-results -type f -name '*-result.json' -print -quit)" ]; then
  echo "No Allure test results were generated" >&2
  exit 1
fi
yarn allure:generate || exit $?
if [ ! -f allure-report/index.html ]; then
  echo "Missing generated Allure report" >&2
  exit 1
fi
exit "$test_status"
```

Adapt environment setup, shell/provider quoting and application readiness. For Drone, preserve its needed dollar escaping. If publishing is in another step, let that step run on both pass/fail without masking the original failure. Publisher inputs must reference `allure-report`, not a previous Playwright directory.

Before real publishing, check pass, fail, no-results, stale-results and generation-failure paths with synthetic results/mocks as appropriate. Do not contact a real artifact API or post comments just to verify local code without approval.
