---
description: Migrate existing Java Selenium Cucumber tests for one service from hof-e2e-auto-tests into equivalent Playwright BDD tests using lmr conventions, excluding CI and infrastructure.
name: ctf-test-to-playwright
---
# CTF Test To Playwright

Migrate Java Selenium Cucumber tests for a single service from hof-e2e-auto-tests into equivalent Playwright BDD tests, following lmr test conventions.

## Migration Mode

- Default mode is strict like-for-like migration.
- Migrate all in-use source functionality from selected feature files through associated step definitions, StepLib methods, page objects, and test data behavior.
- Do not stop at partial parity unless a hard blocker is documented with evidence.

## Scope

In scope:
- Test migration only: features, step behavior, page behavior, and test data modeling.
- Source inputs from hof-e2e-auto-tests.
- Target outputs under the service Playwright BDD test structure.
- Updating target project .gitignore to exclude the following;
  - .features-gen/
  - playwright-report/
  - test-results/

Out of scope:
- CI or CD wiring.
- Drone pipeline edits.
- Secrets, auth, token scripts, or repository infrastructure.
- Deployment scripts and environment provisioning.

## End To End Workflow

1. Recon step
- Run `recon-prompt.md` to inventory source features, step definitions, StepLib methods, page objects, and test data.
- Produce a migration plan with explicit source-to-target traceability.

2. Pre-requisite check
- Confirm target service repository is ready for migration.
- Check if target service repository already has Playwright BDD setup, if not then setup Playwright BDD test harness using lmr conventions before migration.
  - Required dependencies: Playwright, dotenv.
    - Use `dotenv.config({ quiet: true });`
  - playwright.config.ts;
    - baseURL, testDir, and testMatch configured.
    - screenshots always on
    - video always on

2. Migration step
- Run this `SKILL.md` to implement the migration plan and produce Playwright BDD tests with strict parity intent.

3. Validation step
- Confirm with user that the migration is complete and ready for validation. Ask for permission to run validation on the target service repository.
- Run `validation-prompt.md` to execute newly migrated Playwright scenarios one by one, record failures, diagnose root causes, and produce recommended changes.

4. Iteration step
- Apply recommended changes from validation diagnostics.
- Re-run validation one by one.
- Continue until all scenarios pass in full-run verification.

## Required Inputs

1. Source feature files for one service, for example Function/src/main/resources/features/ui/<service>/**/*.feature.
2. Source StepLib files that back those scenarios, for example Function/src/main/java/uk/gov/ho/domain/component/ui/stepLib/*.java.
3. Source page object files for that service, for example Function/src/main/java/uk/gov/ho/domain/component/ui/pages/<service>/*.java.
4. Source test data references, for example Function/src/main/resources/test-data/applicant-data/<service>.csv.
5. Target service repository root.

## Non-Negotiable Rules

- Preserve source behavior semantics and scenario intent.
- Maintain functional parity for all in-use source steps and page interactions in migration scope.
- Map all in-scope StepLib methods and page objects used by selected scenarios.
- Preserve source feature inventory exactly for active coverage: feature title, scenario titles, scenario outline names, active Examples rows, and source scenario identifiers/descriptions.
- Do not silently drop, merge, rename, or reword source scenarios or active Examples rows.
- If target-only tags are needed for execution convenience, keep all source tags and only add extra tags additively.
- Duplication may be refactored only when behavior parity is preserved.
- Any refactor-based consolidation must list exact source methods/pages merged and why behavior remains equivalent.
- Unmapped source items are allowed only when explicitly deferred with rationale and remediation.

## Parity Policy

- parity_coverage: FAIL-ON-GAP
- max_unmapped_source_pages: 0
- max_unmapped_steplib_methods: 0
- max_unmapped_step_phrases: 0
- max_unmapped_scenarios: 0
- max_feature_title_drift: 0
- max_scenario_title_drift: 0
- max_active_example_row_drift: 0

## Migration Hardening Rules

- Preserve source interaction semantics for tricky fields: if the source test used focus plus keyboard typing, mirror that instead of using fill.
- Treat autocomplete and lookup inputs as selection workflows, not plain text entry. After typing, explicitly select the matching option before continuing.
- Prefer role-based button clicks for primary actions when page markup varies between input and button implementations.
- Do not assert on broad or hidden confirmation text. Use a specific visible heading, dialog title, or page landmark that matches the source success state.
- When a migrated step fails to advance, check for unmet required fields before changing selectors. Fill the same required inputs the source flow depended on.
- When the target app splits a source step across different routes, split the Playwright helper at the real page boundary and only interact with fields that exist on the current branch.
- In child referral paths, preserve post-home-office-reference forks exactly. If the route goes directly to first responder contact details, do not force adult-only who-contact or victim-contact pages.
- In end-of-journey submission flows, handle intermediate optional pages explicitly (for example upload evidence pages with Save and continue) before asserting final confirmation.
- Assert final submission on the real success panel or heading text used by the target service (for example referral sent), not a generic confirmation keyword.
- Keep selector fallbacks only when they preserve source behavior. If a page changed from input to button markup, support both without changing the scenario intent.
- For local Playwright runs, ensure the test harness and app process target the same base URL and port before treating a 503 as a product failure.

## Mandatory Architecture And Naming Rules

- Use page objects with mostly one web page per page object. Preserve single responsibility and separation of concerns.
- Keep step definitions split by coherent user behavior boundaries. Do not create monolithic step files that mix unrelated journeys.
- Keep migration implementations DRY by reusing shared selector helpers, wait helpers, navigation helpers, and common assertions across step files and page objects.
- Do not copy Java/Selenium implementation patterns blindly. When a source pattern is not appropriate for Playwright, refactor to an idiomatic Playwright design while preserving source behavior semantics.
- Store migrated test data under a `test-data` folder in the target Playwright test area.
- Use explicit, self-describing variable names. Do not introduce single-character abbreviations except for standard short loop indexes where unavoidable.

## Autonomous Completion Loop

- After each migration pass, recompute SOURCE_IMPLEMENTATION_PARITY_COMPLIANCE.
- If parity decision is FAIL and no hard blocker exists, continue migrating the next unmapped StepLib/page-object group in the same run.
- Do not stop with "awaiting continue" when unmapped items remain.

## Validation Driven Iteration Loop

- Validation must execute migrated Playwright scenarios one by one before any full-suite run.
- For each failing scenario, produce diagnostics with:
  - failing step and route
  - observed versus expected behavior
  - likely root cause category (selector, wait, branching, data mapping, assertion, environment)
  - exact recommended code change
  - confidence level and rationale
- Apply recommended changes in a dedicated iteration pass, then repeat one-by-one validation.
- Exit loop only when:
  - all individual migrated scenarios pass, and
  - full migrated feature run passes.

## Skill Improvement Feedback Loop

- Any repeated or high-confidence validation recommendation must be captured as an improvement to this `SKILL.md`.
- Improvement updates must target reusable migration guidance, not one-off service specifics.
- When a new rule is added, include a short rationale tied to the failure pattern it prevents.

## Process

1. Preflight inventory
- Enumerate all source feature files in scope.
- Inventory referenced step definition classes and participating methods.
- Inventory referenced StepLib classes and participating methods.
- Inventory service page objects and relevant methods, including shared/common pages referenced by in-scope StepLib methods.
- Inventory source test data files used by migrated scenarios.

2. Scenario mapping
- Map each source scenario to a target Playwright BDD scenario.
- Preserve tags, Background, Scenario Outline, Examples, titles, and intent.
- Mark each scenario as migrated, partial, or deferred.

3. Feature parity gate
- Compare source and target feature files and verify there is no drift in:
  - feature title
  - scenario and scenario outline titles
  - active Examples rows (row count and values)
  - source scenario ID and description values used for test data selection
- If drift exists, parity decision is FAIL until corrected or explicitly deferred with rationale.

4. Implementation mapping
- Build a SOURCE_IMPLEMENTATION_MAPPING_TABLE from source step definitions, StepLib, and page object behavior to target Playwright steps and pages.
- Migrate behavior intent, not Java class structure.
- Record explicit rationale for any partial or deferred mappings.

5. Playwright BDD implementation
- Create or update target feature files, step definitions, and page objects.
- Use kebab-case filenames for migrated Playwright page and step files.
- Keep naming and style aligned to lmr test conventions.

6. Test data translation
- Do not copy source CSV files into target runtime fixtures.
- Convert CSV-driven variations to switchable in-code data modules.
- Ensure migrated step flows select data variants by scenario key, tags, or examples.
- Ensure target test-data includes every source scenario ID/description used by active source scenarios and active Examples rows.

7. Validation and reporting
- Recheck mapping completeness for scenarios, step phrases, step definition methods, StepLib methods, and page objects.
- Produce required output sections in the order below.

8. Validation handoff
- Produce a per-scenario execution manifest for one-by-one Playwright validation.
- Include the exact commands to run each scenario in isolation and one full feature command.
- Include known environment preconditions needed for stable execution.

## Output Format

1. PATCH_SUMMARY
2. SOURCE_TO_TARGET_SCENARIO_MAPPING_TABLE
3. FEATURE_FILE_PARITY_AUDIT
4. SOURCE_IMPLEMENTATION_MAPPING_TABLE
5. STEP_DEFINITION_COVERAGE
6. SOURCE_IMPLEMENTATION_PARITY_COMPLIANCE
7. VALIDATION_RUN_MANIFEST
8. WARNINGS
9. ASSUMPTIONS
10. MANUAL_ACTIONS

## Mandatory Compliance Block

SOURCE_IMPLEMENTATION_PARITY_COMPLIANCE must include:
- source_scenarios_inventory_count
- source_active_example_row_count
- source_step_phrases_inventory_count
- source_step_definition_methods_inventory_count
- source_steplib_methods_inventory_count
- source_page_objects_inventory_count
- mapped_scenarios_count
- mapped_active_example_row_count
- mapped_step_phrases_count
- mapped_step_definition_methods_count
- mapped_steplib_methods_count
- mapped_source_pages_count
- unmapped_scenarios
- feature_title_drift
- scenario_title_drift
- active_example_row_drift
- unmapped_step_phrases
- unmapped_step_definition_methods
- unmapped_steplib_methods
- unmapped_source_pages
- refactored_duplicates_with_equivalence_rationale
- decision: PASS or FAIL
- remediation_actions

## Conventions

- Use lmr test patterns as blueprint for Playwright BDD test structure and behavior.
- Follow source-e2e conventions for source discovery and parsing.
- Read and apply the companion steering patterns in `steering/playwright-refactor-patterns.md` for Playwright-idiomatic refactors and DRY implementation patterns.
- Use `validation-prompt.md` as the required post-migration validation stage.
- Keep this skill strictly test-focused and infrastructure-agnostic.
