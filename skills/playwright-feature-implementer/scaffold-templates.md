# Scaffold Templates

Use these only in **scaffold mode**: Phase 2 of [SKILL.md](./SKILL.md), when discovery classifies the repository's Playwright framework as `absent`. When it is `partial`, add only the missing pieces and keep everything that already conforms.

Adapt every `<placeholder>` to the target service. Never copy LMR URLs, ports, start commands or secrets (CFG-05). Class names use PascalCase in a fresh scaffold (CODE-02).

## Folder layout

```text
<repo>/
  playwright.config.ts
  .env.example               # placeholders only (DATA-04)
  e2e-tests/
    features/<feature>.feature
    steps/<feature>.step.ts
    fixture/fixtures.ts
    pages/base-page.ts
    pages/<page-name>-page.ts
    utility-helper/constants-lib.ts
    tsconfig.json            # only if the root tsconfig does not cover e2e-tests (CODE-03)
```

## Dev dependencies (SCAF-02)

Install these with the repository's package manager and lockfile, in versions that work together. Then install Chromium (`npx playwright install chromium`).

`@playwright/test`, `playwright-bdd`, `@cucumber/cucumber`, `@axe-core/playwright`, `dotenv`, `@types/node`

## `playwright.config.ts` (CFG-01, CFG-04)

Use the full configuration below only when no Playwright configuration exists. When plain Playwright tests already exist, merge BDD through a separately scoped project while preserving existing projects and their effective discovery settings, so existing specs still run without duplication. Preserve existing runner commands when adapting the script examples below; if these constraints cannot be met, stop scaffolding and report the conflict under `BLOCKERS`.

```ts
import { defineConfig, devices } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';
import dotenv from 'dotenv';

dotenv.config({ quiet: true });

const port = process.env.PLAYWRIGHT_PORT || '<default-port>';
const externalBaseURL = process.env.PLAYWRIGHT_BASE_URL;
const baseURL = externalBaseURL || `http://localhost:${port}`;

const testDir = defineBddConfig({
  features: 'e2e-tests/features/**/*.feature',
  steps: ['e2e-tests/steps/**/*.ts', 'e2e-tests/fixture/fixtures.ts'],
});

export default defineConfig({
  testDir,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: process.env.CI ? 2 : 1,
  timeout: 30_000,
  expect: { timeout: 6_000 },
  reporter: [['html', { open: 'never' }], ['list']],
  use: {
    baseURL,
    headless: !!process.env.CI,
    viewport: null,
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
    video: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'], viewport: null, deviceScaleFactor: undefined } }],
  webServer: externalBaseURL
    ? undefined
    : {
        command: '<service dev start command>',
        url: baseURL,
        reuseExistingServer: !process.env.CI,
      },
});
```

## `package.json` scripts (CFG-02)

```json
{
  "scripts": {
    "bddgen": "bddgen",
    "test:e2e": "bddgen && playwright test",
    "test:e2e:headed": "bddgen && playwright test --headed",
    "test:e2e:debug": "bddgen && playwright test --debug",
    "test:e2e:report": "playwright show-report"
  }
}
```

Add tag-subset scripts (for example `--grep @<Service>RegressionTest`) only for tags that exist in the features (FEAT-06).

## `.gitignore` additions (CFG-03)

```text
.features-gen/
playwright-report/
test-results/
.env
```

## `e2e-tests/utility-helper/constants-lib.ts` (DATA-02, DATA-03)

```ts
export function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

// Synthetic, non-sensitive test data only (DATA-01).
export const FULL_NAME = 'Test User';
```

## `e2e-tests/pages/base-page.ts` (POM-01, A11Y-01)

```ts
import { expect, type Locator, type Page } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

export class BasePage {
  readonly page: Page;
  readonly continueButton: Locator;
  readonly heading: Locator;
  readonly errorSummary: Locator;

  constructor(page: Page) {
    this.page = page;
    this.continueButton = page.getByRole('button', { name: 'Continue', exact: true });
    this.heading = page.getByRole('heading', { level: 1 });
    this.errorSummary = page.getByRole('alert');
  }

  /** Navigates to a path relative to baseURL. */
  async goto(path: string): Promise<void> {
    await this.page.goto(path);
  }

  /** Clicks Continue, which navigates or submits the current form. */
  async continue(): Promise<void> {
    await this.continueButton.click();
  }

  /** Waits for load and a visible h1, then records WCAG 2 A/AA axe violations as soft failures. */
  async assertAccessibility(): Promise<void> {
    await this.page.waitForLoadState('load');
    await expect(this.heading).toBeVisible();
    const results = await new AxeBuilder({ page: this.page }).withTags(['wcag2a', 'wcag2aa']).analyze();
    expect.soft(results.violations, 'axe WCAG 2 A/AA violations').toEqual([]);
  }

  /** Asserts the page title, allowing for the "Error: " prefix after a failed submission. */
  async assertTitle(title: string, allowErrorPrefix = false): Promise<void> {
    const escaped = title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    await expect(this.page).toHaveTitle(new RegExp(`^${allowErrorPrefix ? '(Error: )?' : ''}${escaped}$`));
  }

  /** Asserts the error-summary heading and the ordered list of messages (ASSERT-04). */
  async assertErrorSummary(heading: string, messages: string[]): Promise<void> {
    await expect(this.errorSummary.getByRole('heading')).toHaveText(heading);
    await expect(this.errorSummary.getByRole('listitem')).toHaveText(messages);
  }
}
```

Adapt the error-summary locator to the service's real markup (for example the GOV.UK error summary role or ID) and keep it scoped (LOC-04).

## `e2e-tests/pages/<page-name>-page.ts` (POM-02 – POM-07)

```ts
import type { Locator, Page } from '@playwright/test';
import { BasePage } from './base-page';

export class StartPage extends BasePage {
  readonly fullNameInput: Locator;

  constructor(page: Page) {
    super(page);
    this.fullNameInput = page.getByLabel('<Full name label>', { exact: true });
  }

  /** Checks accessibility and title, fills the form, then continues to the next page. Accepts invalid input for validation scenarios. */
  async completeStartPage(fullName: string): Promise<void> {
    await this.assertAccessibility();
    await this.assertTitle('<Page title>', true);
    await this.fullNameInput.fill(fullName);
    await this.continue();
  }
}
```

## `e2e-tests/fixture/fixtures.ts` (FIX-01 – FIX-03)

```ts
import { test as base } from 'playwright-bdd';
import { StartPage } from '../pages/start-page';

type Pages = {
  startPage: StartPage;
};

export const test = base.extend<{ pages: Pages }>({
  pages: async ({ page }, use) => {
    await use({
      startPage: new StartPage(page),
    });
  },
});

export const expect = test.expect;
```

## `e2e-tests/steps/<feature>.step.ts` (STEP-01 – STEP-10)

```ts
import { createBdd, type DataTable } from 'playwright-bdd';
import { test, expect } from '../fixture/fixtures';
import * as c from '../utility-helper/constants-lib';

const { Given, When, Then } = createBdd(test);

Given('I am on the start page', async ({ pages }) => {
  await pages.startPage.goto('/<start-path>');
});

When('I enter the following details:', async ({ pages }, table: DataTable) => {
  const data = table.rowsHash();
  const fullName = data['Full name'];
  if (fullName === undefined) {
    throw new Error(`Missing "Full name" in data table: ${JSON.stringify(data)}`);
  }
  await pages.startPage.completeStartPage(fullName);
});

When('I continue with {string}', async ({ pages }, scenario: string) => {
  switch (scenario.toLowerCase()) {
    case 't1: all fields completed':
      await pages.startPage.completeStartPage(c.FULL_NAME);
      break;
    default:
      throw new Error(`Invalid scenario: ${scenario}`);
  }
});

Then('I should see the error {string} with messages {string}', async ({ pages }, heading: string, messages: string) => {
  await pages.startPage.assertErrorSummary(heading, messages.split('¬'));
});

Then('I should see the {string} page', async ({ pages }, heading: string) => {
  await expect(pages.startPage.heading).toHaveText(heading);
});
```

## `.env.example` (DATA-04)

```text
PLAYWRIGHT_BASE_URL=
PLAYWRIGHT_PORT=
# <SERVICE>_EMAIL=<approved-test-recipient>
```
