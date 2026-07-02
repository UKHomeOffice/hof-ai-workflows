# ctf-test-to-playwright

High-level migration skill for converting Java Selenium Cucumber tests from `hof-e2e-auto-tests` into Playwright BDD tests in a target service repository.

This skill is designed for strict behavior parity, not partial rewrites. It guides migration, parity auditing, and validation iteration until scenarios pass.

## What This SKILL Does

- Migrates one service at a time from source Cucumber/Selenium to target Playwright BDD.
- Preserves source behavior semantics, scenario intent, and active scenario inventory.
- Maps source artifacts end-to-end: feature files, step definitions, StepLib methods, page objects, and test data behavior.
- Enforces parity gates so migrated coverage does not silently drift.
- Runs a validation-driven iteration loop where failing scenarios are diagnosed and fixed.

## What It Does Not Do

- CI/CD or pipeline wiring.
- Infrastructure/secrets/auth provisioning.
- Deployment or environment provisioning changes.

## Core Principles

- Like-for-like migration is the default mode.
- Fail on parity gaps (scenario/title/examples drift and unmapped source behavior).
- Keep migration test-focused and infrastructure-agnostic.
- Prefer Playwright-idiomatic implementation while preserving source semantics.

## Required Inputs

Provide these before running the skill:

1. Source feature files for a single service.
2. Source step definition and StepLib implementations used by those features.
3. Source page objects used by those flows.
4. Source test-data references (for behavior mapping).
5. Target service repository root.

## End-to-End Workflow

1. Recon
- Inventory source features, steps, StepLib methods, page objects, and test-data dependencies.

2. Pre-req check
- Confirm target repository has Playwright BDD harness (or bootstrap it first).

3. Migration
- Apply this skill to produce migrated feature files, step definitions, page objects, and test-data modules.

4. Parity audit
- Verify no drift in feature title, scenario titles, and active Examples rows.

5. Validation
- Run migrated scenarios one-by-one first.
- Diagnose failures and apply fixes.
- Repeat until all individual scenarios pass.

6. Full-run confirmation
- Run full migrated feature only after all single-scenario validations are green.

## Output You Should Expect

The skill is expected to produce a structured report including:

- Patch summary
- Source-to-target scenario mapping
- Feature parity audit
- Implementation mapping table
- Coverage and parity compliance block (PASS/FAIL)
- Validation run manifest
- Warnings, assumptions, and manual actions

## How To Use It

Use this skill when you want complete migration for one service, not ad-hoc test fixes.

Recommended prompt pattern:

```text
Run SKILL.md for service <target-service>.
Source e2e folder is <source-folder> in hof-e2e-auto-tests.
Migrate with strict source parity, then validate one scenario at a time before full-run.
```

Example:

```text
Run SKILL.md for service modern-slavery.
Source e2e folder is nrm.
Apply strict parity gates and perform one-by-one validation before full feature run.
```

## Validation Guidance

- Always run one scenario at a time before running full feature suites.
- Treat each failure as a route-level diagnostic task (selector, wait, branching, data, assertion, or environment).
- After each fix, rerun only the failing scenario first.
- Move to full feature execution only after all isolated scenarios pass.

## Companion Files

- `SKILL.md`: core migration contract and compliance rules.
- `validation-prompt.md`: required one-by-one validation workflow.
- `steering/playwright-refactor-patterns.md`: Playwright refactor and architecture patterns.

## Quick Checklist

- Source inventory complete.
- Target harness ready.
- Feature/scenario/examples parity verified.
- Source mappings complete (no silent gaps).
- Individual scenario runs all passing.
- Full migrated feature run passing.

