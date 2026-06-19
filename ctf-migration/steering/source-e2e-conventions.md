# Source E2E Conventions Steering

Purpose: normalize how source cucumber assets are consumed from the shared e2e repository.

## Source repository convention
- Repository root contains source features under:
  - `Function/src/main/resources/features/ui`
- Source page objects are under:
  - `Function/src/main/java/domain/component/ui/pages/<service-folder>`
- Source step libraries are under:
  - `Function/src/main/java/domain/component/ui/stepLib`
- Source applicant data is under:
  - `Function/src/main/resources/test-data/applicant-data/<service>.csv`
- Each service usually maps to a folder under `ui` (for example `ui/nrm`, `ui/lmr`, `ui/eta`).

## Migration unit
- A migration unit is typically one service feature folder.
- The agent should support globs that include nested feature files:
  - `${source_repo_root}/Function/src/main/resources/features/ui/${service_folder}/**/*.feature`

## Source parsing requirements
- Preserve tags, background blocks, scenario outlines, examples tables, and scenario titles.
- Treat commented-out examples or scenarios as non-active test input unless explicitly requested.
- Treat source Java page objects and step libraries as behavior-reference inputs for migration.
- Treat source applicant CSV as behavior/data-reference input only.

## Test data migration requirements
- Do not copy applicant CSV files into the Playwright target repo as runtime fixtures.
- Convert CSV-driven paths into switchable in-code test data, selectable by scenario key/tag/example.
- Follow blueprint style used by LMR (`e2e-tests/utility-helper/constants-lib.ts`) or an equivalent constants/data module.
- Ensure migrated step flows consume the switchable data module rather than external CSV files.

## Naming requirements for migrated artifacts
- Use kebab-case for migrated Playwright page-object filenames.
- Use kebab-case for migrated Playwright step-definition filenames.
- Do not carry over Java CamelCase filenames into migrated Playwright artifacts.

## Mapping requirements
- Output a source-to-target scenario mapping table.
- Include statuses: `migrated`, `partial`, `deferred`.
- Record rationale for all non-migrated scenarios.

## Completion requirements
- For strict parity runs, process source StepLib and page-object mappings in deterministic batches until no unmapped items remain.
- Do not stop after an initial partial migration pass unless blocked by a hard dependency that cannot be resolved in-repo.
- If blocked, report the exact blocker, impacted source methods/pages, and a concrete remediation path.
