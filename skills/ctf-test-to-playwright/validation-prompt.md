# Validation Prompt For Playwright Migration

Run this after migration implementation is complete.

## Objective

Validate migrated Playwright BDD scenarios one by one, diagnose failures, and provide actionable recommendations for the next iteration pass.

## Inputs

- Target service repository root.
- Migrated Playwright feature files and step files.
- Source Java Selenium feature and behavior references.
- Migration output from SKILL run, including SOURCE_TO_TARGET_SCENARIO_MAPPING_TABLE.

## Required Validation Sequence

1. Preflight
- Confirm test runtime prerequisites and base URL strategy.
- Confirm generated artifacts are excluded by .gitignore.
- Confirm bdd generation step is available.

2. One By One Execution
- Execute each migrated scenario in isolation.
- Use deterministic commands and single worker execution.
- If a run hangs, stop it and retry once with equivalent command.
- Record pass or fail for each scenario.

3. Failure Diagnostics
- For each failure, capture:
  - scenario name
  - command used
  - failing step phrase
  - route or page at failure
  - error summary
  - root cause category: selector, wait, branching, data mapping, assertion, environment, or unknown
  - recommended code change
  - confidence: high, medium, or low

4. Iteration Recommendations
- Group recommendations by file and change type.
- Prioritize smallest safe fix that preserves source behavior semantics.
- Mark each recommendation as:
  - apply now
  - defer with rationale

5. Full Run Verification
- After one-by-one checks and recommended fixes, run full migrated feature.
- Report final status and any residual failures.

6. Skill Improvement Capture
- For repeated or systemic failure patterns, propose reusable SKILL.md rule updates.
- Distinguish between service-specific fixes and reusable migration guidance.

## Required Output Format

1. VALIDATION_SUMMARY
2. SCENARIO_RESULTS_TABLE
3. FAILURE_DIAGNOSTICS_REPORT
4. RECOMMENDED_CHANGES_BY_FILE
5. ITERATION_PLAN
6. FULL_RUN_VERIFICATION
7. SKILL_IMPROVEMENT_RECOMMENDATIONS
8. MANUAL_ACTIONS

## Scenario Results Table Schema

- scenario_name
- isolated_command
- isolated_result
- retry_used
- duration
- notes

## Failure Diagnostics Schema

- scenario_name
- failing_step_phrase
- failure_location
- root_cause_category
- evidence
- recommended_change
- confidence

## Quality Bar

- Do not stop after first failure.
- Continue one-by-one execution for all scenarios unless blocked by environment outage.
- Recommendations must be specific enough to implement directly.
- Final output must state whether validation loop can proceed to iteration or is blocked.
