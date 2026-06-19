# CTF Migration

** Work In Progress

Deterministic AI-assisted migration framework for moving cucumber features from hof-e2e-auto-tests into Playwright BDD suites in Home Office service repositories.

This project is designed to migrate:
- feature files
- associated StepLib behavior
- associated page-object behavior
- associated CSV-driven data behavior into switchable in-code data

It also enforces CI parity (Drone PR e2e, report publishing, nightly e2e) and strict validation.

## What this contains

- Master migration contract: `ctf-feature-migration-master-prompt.md`
- Generic run prompt (single feature): `per-service-basic-prompt.md`
- Manifest template: `manifests/migration-manifest.template.yaml`
- Source conventions steering: `steering/source-e2e-conventions.md`
- Canonical blueprint steering: `steering/lmr-blueprint.md`

## Key guarantees

- Two-stage execution: migration then independent validation.
- Strict parity mode by default: `parity_coverage: FAIL-ON-GAP`.
- Autonomous completion loop: the run continues until parity passes or a real hard blocker is reported.
- No PAT-based Drone auth in migrated scope; GitHub App token flow is mandatory.
- CSV files are not copied into target tests; behavior is migrated into switchable in-code data.

## Prerequisites

1. Monorepo layout includes both source and target repos, for example:
   - `<hof-root>/hof-e2e-auto-tests` (source)
   - `<hof-root>/<target-service>` (target)
2. You can open Copilot Chat in VS Code at either:
   - monorepo root, or
   - service folder
3. Target repo has normal write access for changes.

## Quick start

1. Duplicate the manifest template and create a service manifest:
   - Copy `manifests/migration-manifest.template.yaml`
   - Save as `manifests/<service>-migration.yaml`
2. Populate required fields for source/target paths and policy.
3. Open Copilot Chat.
4. Paste a run prompt (examples below).
5. Let it run Stage 1 + Stage 2 end-to-end.

## Required manifest fields

At minimum, set these correctly in your service manifest:

- `service_name`
- `source_repo_root`
- `source_feature_folder`
- `source_feature_glob`
- `source_features_root`
- `source_page_objects_root`
- `source_step_lib_root`
- `source_applicant_data_root`
- `target_repo_root`
- `target_drone_file`
- `target_playwright_config_path`
- `target_e2e_root`
- `validation_policy.parity_coverage` (must be `FAIL-ON-GAP` for strict runs)
- `steering_context.*`

## Run a single feature migration

Use this when you have one specific source feature file.

1. Start from `per-service-basic-prompt.md`.
2. Set only:
   - `UI_SERVICE_FOLDER=<source-ui-folder>`
   - `UI_FEATURE_FILE=<feature-file-name>.feature`
3. Keep the strict execution requirements in place.

Example values:

- `UI_SERVICE_FOLDER=hff`
- `UI_FEATURE_FILE=hff.feature`

## Run a folder migration

For full service migration, set the manifest glob to include nested features:

- `Function/src/main/resources/features/ui/<service-folder>/**/*.feature`

Then instruct Copilot Chat to execute the master prompt using your service manifest and steering context.

## What successful output looks like

The final response should include, in strict order:

1. `EXECUTIVE_DECISION`
2. `PATCH_SUMMARY`
3. `SOURCE_TO_TARGET_SCENARIO_MAPPING_TABLE`
4. `SOURCE_IMPLEMENTATION_MAPPING_TABLE`
5. `VALIDATION_SCORECARD`
6. `CI_CD_COMPLIANCE_CHECKLIST`
7. `WARNINGS_AND_REMEDIATIONS`
8. `MANUAL_ACTIONS`
9. `ASSUMPTIONS`
10. `NEXT_REPO_READINESS`

If parity has unmapped source pages/methods without approved exemptions, decision must be `NEEDS_REWORK`.

## How this handles steps, pages, and data

During migration, the agent must:

- inventory source page objects and StepLib methods in scope
- map source behavior into Playwright page objects and step definitions
- preserve scenario intent, tags, backgrounds, outlines, examples
- migrate CSV-driven permutations into switchable data in code
- produce explicit mapping tables for scenario and implementation coverage

This prevents feature-only migrations that miss behavior implemented in StepLib/page layers.

## CI requirements enforced

- PR e2e wired after branch deploy
- branch URL consumed from `/root/.dockersock/branch_url.txt`
- report publication step present
- nightly e2e + summary wiring present
- required dockersock volume mount in both `deploy_to_branch` and `e2e_tests`

## Common failure modes and fixes

- Missing required manifest key:
  - Fix: add the missing key and rerun.
- Parity still partial:
  - Fix: continue same run until unmapped method/page counts reach zero, unless hard-blocked.
- PAT auth detected in Drone:
  - Fix: replace with GitHub App token generation + clone anchor flow.
- CSV copied into target tests:
  - Fix: replace with in-code switchable data model and remap steps.
- CI wiring incomplete:
  - Fix: add missing e2e/report/nightly steps and branch URL artifact contract.

## Recommended operating pattern

1. Run one service/feature scope at a time.
2. Keep strict parity enabled (`FAIL-ON-GAP`).
3. Treat any unmapped source method as blocking unless explicitly exempted.
4. Rerun after changes to confirm idempotency and no duplicate Drone anchors/steps.

## Example run prompt skeleton

Use this in Copilot Chat after you have a completed manifest:

```text
Execute the migration using:
- master prompt: ai/ctf-migration/ctf-feature-migration-master-prompt.md
- manifest: ai/ctf-migration/manifests/<service>-migration.yaml
- steering:
  - ai/ctf-migration/steering/lmr-blueprint.md
  - ai/ctf-migration/steering/source-e2e-conventions.md

Requirements:
- Real migration mode
- Stage 1 then Stage 2
- Autonomous completion loop until SOURCE_IMPLEMENTATION_PARITY_COMPLIANCE = PASS or hard blocker with evidence
- Return final output in strict section order
```

## Notes

- This framework is migration orchestration and governance; it does not lock you to a single service.
- If your service needs service-specific steering, add a steering file under `steering/` and include it in manifest `canonical_blueprint_paths`.
