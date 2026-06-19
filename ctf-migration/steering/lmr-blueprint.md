# LMR Blueprint Steering

Purpose: canonical implementation reference for cucumber-to-Playwright-BDD migrations.

## Required canonical references
- `lmr/.drone.yml`
- `lmr/playwright.config.ts`
- `lmr/package.json`
- `lmr/bin/deploy.sh`
- `lmr/e2e-tests/steps/lmr.step.ts`
- `lmr/e2e-tests/pages/*.ts`
- `lmr/e2e-tests/fixture/fixtures.ts`
- `lmr/e2e-tests/utility-helper/constants-lib.ts`
- `lmr/bin/generate_github_app_token.sh`
- `lmr/bin/publish_e2e_test_report.sh`
- `lmr/bin/summarise_playwright_report.js`

## Behavioral expectations
- PR flow includes deploy_to_branch, e2e execution against deployed branch URL, and report publication to PR.
- Nightly cron runs Playwright tests against a fixed environment, generates a summary artifact, and sends notification.
- BDD generation runs before Playwright execution (`bddgen` then `playwright test`).
- PR `e2e_tests` step consumes deployed branch URL only via dockersock artifact contract:
  - asserts `/root/.dockersock/branch_url.txt` exists and is non-empty before test run
  - exports `PLAYWRIGHT_BASE_URL` using the value from `branch_url.txt`
  - does not inline branch-host construction in the test command
- `bin/deploy.sh` must provide a branch URL artifact for PR e2e wiring:
  - branch slug normalization is applied before branch-host generation
  - branch host is computed per service convention
  - branch host is written to `/root/.dockersock/branch_url.txt` when available
- Test data modeling follows switchable in-code constants (for example `constants-lib.ts`) rather than source CSV fixtures.
- Migrated Playwright artifacts should follow kebab-case naming for page-object and step-definition files.

## Auth modernization standard
- Drone clone-related flows must use GitHub App token generation with token-file handoff.
- The following anchors are mandatory in migrated Drone config and must be created if missing:
  - `github_app_token_step`
  - `github_app_token_secrets_ukho`
  - `github_app_token_secrets_hof`
  - `clone_repos_step`
- Clone flows must always follow this two-step sequence:
  1. generate relevant GitHub App token using `github_app_token_step`
  2. clone repositories using `clone_repos_step` with token-file input
- This two-step clone sequence is mandatory for all clone paths:
  - push/pull_request clone flow
  - promote/prod clone flow
  - cron clone flow
- PAT patterns are forbidden in migrated Drone config:
  - `drone_git_token`
  - `drone_git_username`
  - any clone URL embedding static username:token credentials

## Acceptance criteria
- Migration is not complete unless PR e2e, PR report publish, nightly e2e, and auth modernization are all wired.
- Migration is not complete unless Drone `deploy_to_branch` and `e2e_tests` steps mount dockersock volume exactly for artifact sharing:
  - `volumes:`
  - `- name: dockersock`
  - `path: /root/.dockersock`
- Migration is not complete unless Drone `e2e_tests` command wiring follows branch-url artifact consumption contract:
  - includes pre-check: `test -s /root/.dockersock/branch_url.txt || (...)`
  - sets `PLAYWRIGHT_BASE_URL` from `https://$(cat /root/.dockersock/branch_url.txt)`
  - does not construct base URL directly from branch env vars in the e2e command
- Migration is not complete unless target `.eslintignore` contains all required entries:
  - `e2e-tests`
  - `playwright-report`
  - `bin/*`
- Migration is not complete unless `bin/deploy.sh` supports branch e2e artifact output:
  - includes branch slug max-length and sanitize exports for branch deployments
  - computes `BRANCH_HOST` for branch deployments
  - writes `BRANCH_HOST` to `/root/.dockersock/branch_url.txt` when directory exists
- Validation must emit `AUTH_COMPLIANCE_REPORT` and fail compliance if PAT references remain.
