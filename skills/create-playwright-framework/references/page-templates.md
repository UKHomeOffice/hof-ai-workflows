# Page object templates

Create exactly three page files: a shared base page, a service landing page and one other page from the actual journey. The base class is `BasePage`; both service page classes are PascalCase with the service prefix (for example, `PermitLandingPage`). Imports use `'./base-page'` with no `.ts` extension. Prefix both service page files, classes and fixture properties with the service name, for example service `permit` gives `permit-landing-page.ts`, class `PermitLandingPage` and fixture property `permitLandingPage`. The base page is shared and is not prefixed. Replace each `<placeholder>` with values verified from the target application; `<SecondPage>` is the PascalCase name corresponding to `<second-page>`.

## 0. Base page (shared)

**Target file:** `e2e-tests/pages/base-page.ts`

The locators below suit a GOV.UK Design System service; verify each against the target application and adjust. Keep the variables and methods that the service uses.

```ts
import { Page, Locator, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

export class BasePage {
  readonly page: Page;

  // Common locators
  readonly headerText: Locator;
  readonly continueButton: Locator;
  readonly thereIsAProblemText: Locator;
  readonly errorSummaryList: Locator;

  constructor(page: Page) {
    this.page = page;
    this.headerText = page.locator('h1');
    this.continueButton = page.locator("input[value='Continue']");
    this.thereIsAProblemText = page.locator('#error-summary-title');
    this.errorSummaryList = page.locator("[class='govuk-list govuk-error-summary__list']");
  }

  async assertPageTitle(page: Page, title: string) {
    await expect(page).toHaveTitle(title);
  }

  async assertAccessibility() {
    const results = await this.scanForAccessibilityIssues();
    // Soft assertion records violations without stopping the test; it still fails in the final report.
    expect.soft(results.violations, JSON.stringify(results.violations, null, 2)).toEqual([]);
  }

  async scanForAccessibilityIssues() {
    await this.page.waitForLoadState('load');
    await expect(this.headerText).toBeVisible();

    return new AxeBuilder({ page: this.page })
      // Scan the current page context, without opening a new page
      .setLegacyMode()
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();
  }

  async click(locator: Locator) {
    await locator.click();
  }

  // Fills then presses Tab; reuse only where the control needs it
  async type(locator: Locator, text: string) {
    await locator.fill(text);
    await this.page.keyboard.press('Tab');
  }

  async clickContinueButton() {
    await this.click(this.continueButton);
  }

  async isVisible(locator: Locator) {
    return await locator.isVisible();
  }

  async selectCheckboxOptionWithText(optionText: string) {
    if (!optionText || optionText.trim() === '') {
      throw new Error('Checkbox option text value cannot be null or blank.');
    }
    await this.page.getByRole('checkbox', { name: optionText }).check();
  }

  // Converts readable labels such as "Today's date" to dd/mm/yyyy; other values pass through unchanged
  convertTextToDate(dateValue: string | null): string | null {
    if (dateValue == null) return null;

    const date = dateValue.trim().toLowerCase();
    if (!date) return dateValue;

    const now = new Date();
    const formatDate = (d: Date): string => {
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      return `${day}/${month}/${d.getFullYear()}`;
    };
    const addDays = (d: Date, days: number) => {
      const newDate = new Date(d);
      newDate.setDate(newDate.getDate() + days);
      return newDate;
    };
    const addYears = (d: Date, years: number) => {
      const newDate = new Date(d);
      newDate.setFullYear(newDate.getFullYear() + years);
      return newDate;
    };

    // Keep only the labels the service's features use
    const dateMappings: Record<string, () => Date> = {
      "yesterday's date": () => addDays(now, -1),
      "today's date": () => now,
      "tomorrow's date": () => addDays(now, 1),
      'less than 18 years ago': () => addDays(addYears(now, -18), 1),
      '19 years ago': () => addYears(now, -19),
      'more than 100 years ago': () => addDays(addYears(now, -100), -1),
    };

    const dateFn = dateMappings[date];
    return dateFn ? formatDate(dateFn()) : dateValue;
  }

  async enterDateOrDob(inputDate: string | null) {
    if (!inputDate?.trim()) return;

    const formattedDate = this.convertTextToDate(inputDate);
    if (!formattedDate) return;

    const dateParts = formattedDate.split('/');
    if (dateParts.length !== 3) {
      throw new Error('Invalid date format. Expected format: dd/mm/yyyy');
    }

    const [dayVal, monthVal, yearVal] = dateParts;
    await this.type(this.page.getByLabel('Day'), dayVal);
    await this.type(this.page.getByLabel('Month'), monthVal);
    await this.type(this.page.getByLabel('Year'), yearVal);
  }

  async linkTextIsDisplayed(page: Page, linkText: string): Promise<boolean> {
    return await page.getByRole('link', { name: linkText }).isVisible();
  }

  async getUrlForLinkText(page: Page, linkText: string): Promise<string | null> {
    return await page.getByRole('link', { name: linkText }).getAttribute('href');
  }

  async getThereIsAProblemTextErrorText(): Promise<string | null> {
    return await this.thereIsAProblemText.textContent();
  }

  async getErrorSummaryListText(): Promise<string | null> {
    return await this.errorSummaryList.textContent();
  }
}
```

## 1. Landing page

**Target file:** `e2e-tests/pages/<service>-landing-page.ts`

`continueButton`, `click()`, `assertAccessibility()` and `assertPageTitle()` come from the base page. Both service pages inherit its constructor and declare `expectedPageTitle()` and a page-specific completion method. Do not add constructors, locators or other action methods. Verify that the inherited continue button matches each page before using it.

```ts
import { BasePage } from './base-page';

export class <Service>LandingPage extends BasePage {
  async expectedPageTitle(): Promise<string> {
    const title = await this.page.title();

    return title.startsWith('Error')
      ? "Error: Landing <service name> – <service name> – GOV.UK"
      : "Landing <service name> – <service name> – GOV.UK";
  }

  async completeLandingPage() {
    await this.assertAccessibility();
    await this.assertPageTitle(this.page, await this.expectedPageTitle());
    await this.click(this.continueButton);
  }
}
```

## 2. Second service page

**Target file:** `e2e-tests/pages/<service>-<second-page>-page.ts`

Choose the second page from the verified journey, not a fictional example. Use the same method format as the landing page, substituting the second page's exact title text. Verify the full titles and separators against the application; do not infer them from the current title beyond choosing the error branch. Fill any required fields before calling the completion method.

```ts
import { BasePage } from './base-page';

export class <Service><SecondPage>Page extends BasePage {
  async expectedPageTitle(): Promise<string> {
    const title = await this.page.title();

    return title.startsWith('Error')
      ? "Error: <second page title> – <service name> – GOV.UK"
      : "<second page title> – <service name> – GOV.UK";
  }

  async complete<SecondPage>Page() {
    await this.assertAccessibility();
    await this.assertPageTitle(this.page, await this.expectedPageTitle());
    await this.click(this.continueButton);
  }
}
```

## 3. Fixture registration

**Target file:** `e2e-tests/fixture/fixtures.ts`

```ts
import { test as base } from 'playwright-bdd';
import { BasePage } from '../pages/base-page';
import { <Service>LandingPage } from '../pages/<service>-landing-page';
import { <Service><SecondPage>Page } from '../pages/<service>-<second-page>-page';

type Pages = {
  basePage: BasePage;
  <service>LandingPage: <Service>LandingPage;
  <service><SecondPage>Page: <Service><SecondPage>Page;
};

export const test = base.extend<{ pages: Pages }>({
  pages: async ({ page }, use) => {
    await use({
      basePage: new BasePage(page),
      <service>LandingPage: new <Service>LandingPage(page),
      <service><SecondPage>Page: new <Service><SecondPage>Page(page),
    });
  },
});

export const expect = test.expect;
```

Notes:
- Use the target repo's naming style if it differs, but keep the service prefix consistent across file, class and fixture property.
- Create exactly these three page files; register `basePage` and both service pages on the same test-scoped page.
- Selectors must be verified against the real application; prefer role/label locators.
