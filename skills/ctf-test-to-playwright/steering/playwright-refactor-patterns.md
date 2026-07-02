# Playwright Refactor Patterns

Use these patterns during Java Selenium to Playwright migration when preserving behavior parity.

## Intent

- Preserve source user-facing behavior and validation intent.
- Prefer Playwright-native design and reliability over Selenium-style implementation details.
- Keep page objects and step definitions cohesive, maintainable, and DRY.

## Page Object Patterns

- Prefer mostly one web page per page object class/module.
- Keep each page object focused on page-level responsibilities only.
- Move shared utilities into reusable helpers instead of duplicating across page objects.
- Avoid cross-page orchestration inside a single page object; orchestration belongs in step-level workflow helpers.

## Step Definition Patterns

- Split step definition files by journey or bounded feature area.
- Keep step definitions thin: delegate UI behavior to page objects and helper utilities.
- Reuse common selectors, waits, and assertions through shared modules.
- Do not duplicate the same wait logic across many steps; centralize and call shared helpers.

## Selector And Wait Patterns

- Prefer role-based or accessible selectors before brittle CSS/XPath selectors.
- Use explicit waits tied to user-observable readiness, such as heading visibility or URL transitions.
- Avoid arbitrary sleep-based waits.
- Use selector fallback only when needed for markup variance and only if behavior semantics stay equivalent.

## Input And Interaction Patterns

- For typeahead or autocomplete fields, model selection behavior explicitly: type, wait for options, select option.
- Use keyboard interactions when source behavior depends on focus and key events.
- Use `fill` for plain text fields where keyboard semantics are not behaviorally significant.
- Keep branching logic route-aware; interact only with controls present on the current page.

## Assertion Patterns

- Assert using specific visible outcomes (page heading, panel title, landmark text).
- Avoid weak assertions against hidden or generic text.
- Keep final submission assertions aligned to service-specific success content.

## Test Data Patterns

- Keep test data under a `test-data` folder in the target test structure.
- Translate source CSV behavior into explicit in-code data modules when needed, while retaining scenario variation intent.
- Keep scenario keys and labels traceable to source scenarios.

## Naming Patterns

- Use explicit names that communicate purpose and scope.
- Avoid single-character abbreviations for variables, helper names, and parameters.
- Prefer names such as `selectedScenario`, `reportReference`, `currentRoute`, and `supportContactDetails`.

## Selenium To Playwright Refactor Guidance

- Replace Selenium-style deep page chaining with Playwright route-aware helpers.
- Replace brittle element polling with Playwright locator assertions.
- Replace duplicated interaction code with composable helper methods.
- Preserve source behavior; refactor structure, not outcomes.
