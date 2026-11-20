# Create Playwright framework skill

Use this skill to ask an AI assistant to implement LMR-style E2E testing in another service. It supplies a repeatable workflow, not an automatic installer or a promise that copied selectors will work.

## Contents

- [SKILL.md](SKILL.md): discoverable skill instructions and verification gates.
- [Starter patterns](references/starter-patterns.md): portable configuration, journey switch, steps, scripts and optional reporting examples.
- [Page templates](references/page-templates.md): exactly three page files (`BasePage`, a service-prefixed landing page and one other service page) and a fixture registering the base page and both service pages. Each service page declares `expectedPageTitle()` with normal/error title branches and a completion method.
- [Feature templates](references/feature-templates.md): mandatory E2E and validation feature file templates.

The whole folder is self-contained. Keep both instructions and references when copying it.

## Install in another service
Recommended prompt pattern:

```text
 Use the create-playwright-framework skill to create e2e-tests for `<service name>`.
 Create both an E2E feature and a validation feature using the feature templates and the service-prefixed page templates.
```

## Example request for modern-slavery service

```text
 Use the create-playwright-framework skill to create e2e-tests for `modern-slavery`.
 Create both an E2E feature and a validation feature using the feature templates and the service-prefixed page templates.
```

## Expected outcome

- A real service-specific E2E journey, not copied example page names or a demonstration contact form.
- Feature -> generated test -> fixture -> step -> page object -> assertion -> report.
- Exactly three page files: the shared base and two service pages inheriting its constructor, each declaring `expectedPageTitle()` and a completion method.
- Explicit supported journey cases and useful failures for unknown labels.
- Implemented E2E and validation step bindings, including shared continue and error-summary checks; both features are included in discovery.
- Stable selectors, awaited actions, isolated fixtures and safe synthetic data.
- Accessibility checks with a documented scope and explicit type/lint coverage.
- Any root `.eslintrc.cjs` created during setup is removed after verification; existing files are preserved.
- Ignored generated output and placeholder-only environment documentation.
- Optional CI/report publishing only when requested, preserving test failures.
- A handover stating files changed, checks run, intentional deviations and blockers.

## What this skill does not do

- It does not configure a target service until invoked and allowed to make changes.
- It does not bypass approvals or authorize production testing, live submissions or publishing.
- It does not assume Allure is already installed.
- It does not reproduce known limitations such as excluded E2E lint files, brittle class selectors or unused step parameters as recommended standards.

For skill storage and supported Copilot surfaces, see the [official agent skills documentation](https://docs.github.com/en/copilot/concepts/customizations/agent-skills).
