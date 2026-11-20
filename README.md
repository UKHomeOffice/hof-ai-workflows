# HOF AI Workflows

This directory contains ai workflows and skills being used by the HOF team.

## Current SKILLS

### CTF Test to Playwright Migration

A [SKILL](./skills/ctf-test-to-playwright/SKILL.md) targeted at migrating existing tests from `hof-e2e-auto-tests` (original source is located in Bitbucket) into Playwright BDD tests.

### Add Playwright CI/CD Infrastructure

A [SKILL](./skills/add-playwright-ci-cd/SKILL.md) targeted at adding or updating Drone CI/CD infrastructure for Playwright BDD test runs and reporting.

### Update Playwright Tests

A [SKILL](./skills/update-playwright-tests/SKILL.md) and [reusable workflow](./.github/workflows/update-playwright-tests.yml) targeted at updating existing Playwright tests after changes are merged to a target repository's main branch.

### Create Playwright E2E Framework

The [Create Playwright framework skill](./skills/create-playwright-framework/README.md) implements service-specific Playwright E2E tests using the LMR pattern. It creates E2E and validation features from the templates and service-prefixed page objects. When using it from a different service in this workspace, copy the skill into that service's `.github/skills` folder, open the service repository in the Copilot agent surface, and request: `Use the create-playwright-framework skill to create e2e-tests for <service name>.`
