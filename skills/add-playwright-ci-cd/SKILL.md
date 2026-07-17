---
description: Add Drone CI/CD infrastructure to support Playwright BDD test runs and reporting.
name: add-playwright-ci-cd
---

# Add Playwright CI/CD Infrastructure

This SKILL adds or updates Drone CI/CD infrastructure so migrated Playwright BDD tests run reliably in PR and nightly pipelines.

This SKILL is intended to run after `ctf-test-to-playwright`, ideally as a chained agent handoff.

## Steering References

- [Example drone file](./steering/example-drone.yml) for assessing required steps and anchors.
- [Generate github app token script](./steering/generate_github_app_token.sh) for generating a github app token and setting it as a secret in the target service repository.
- [Publish e2e test report script](./steering/publish_e2e_test_report.sh) for publishing Playwright BDD test report to PR.
- [Summarise playwright test results script](./steering/summarise_playwright_report.js) for summarising Playwright BDD test results and notifying slack channel.

## Scope

In scope:
1. `.drone.yml` updates for PR e2e, PR report publishing, and nightly e2e flows.
2. GitHub App token-based auth modernization for clone and report actions.
3. Supporting script setup in target `bin/` from steering references where missing.
4. Mandatory `.eslintignore` and `.gitignore` updates for Playwright artifacts.
5. Mandatory `.eslintignore` for `bin/` artifacts and scripts.
5. Validation output proving CI/CD wiring completeness and idempotency.

Out of scope:
1. Test migration logic itself (handled by `ctf-test-to-playwright`).
2. Non-e2e unrelated pipeline refactors.
3. Service runtime code changes not required for pipeline wiring.

## Run Order And Handoff

Run this SKILL after `ctf-test-to-playwright` has completed core test migration.

Minimum handoff context expected from prior stage:
1. Target repository root and target `.drone.yml` path.
2. Confirmed Playwright scripts in `package.json` (`test:e2e` at minimum).
3. Playwright config path and expected base URL behavior.
4. Service branch-host/deploy conventions for branch environments.

## Required Inputs

1. Target repository root.
2. Target `.drone.yml` path.
3. Branch policy (default and feature branch globs).
4. Deployment step name for PR branch deployment (usually `deploy_to_branch`).
5. Existing image publish step name dependency for deploy.
6. Secrets naming variant for GitHub App auth (`ukho` and/or `hof`).

If required inputs are missing, stop and report missing fields explicitly.

## Non-Negotiable Rules

1. Idempotent updates only. Reruns must not duplicate anchors, steps, scripts, or ignore entries.
2. GitHub App tokens only for modified auth flows. PAT credential patterns are forbidden in migration scope.
3. Keep existing branch/event trigger policy unless explicitly instructed to change it.
4. Preserve existing non-e2e pipeline behavior.
5. Fail fast on missing required secrets/token files.
6. Minimum Playwright version is `1.60.0` for CI wiring produced by this SKILL.
7. Keep Playwright runtime and dependencies aligned:
            - Drone Playwright image tag (for example `mcr.microsoft.com/playwright:v1.60.0-*`),
            - `@playwright/test` version,
            - `playwright` version,
            - lockfile-resolved versions.
      Do not leave these on floating ranges that can drift independently.

## Mandatory Drone Updates

1. Add required anchors (if missing):
      - `github_app_token_step`
      - `github_app_token_secrets_ukho`
      - `github_app_token_secrets_hof`
      - `clone_repos_step`

2. Update clone flows to mandatory two-step pattern:
      - Step A: generate GitHub App token to a file.
      - Step B: clone repos using token file via `x-access-token` URL form.
      - Remove token file after clone.

3. PR e2e execution flow:
      - Ensure `deploy_to_branch` mounts `dockersock` at `/root/.dockersock`.
      - Add `e2e_tests` step (or update existing one) with same mount.
      - Ensure the `e2e_tests` Playwright container image is at least `v1.60.0`.
      - In `e2e_tests`, enforce commands:
        - `test -s /root/.dockersock/branch_url.txt || (echo "Missing deployed branch URL at /root/.dockersock/branch_url.txt" && exit 1)`
        - `echo "Running Playwright e2e against https://$(cat /root/.dockersock/branch_url.txt)"`
        - `CI=true PLAYWRIGHT_BASE_URL="https://$(cat /root/.dockersock/branch_url.txt)" yarn test:e2e`

4. PR report publishing flow:
      - Add token generation step for report publication.
      - Add `publish_e2e_report_to_pr` step using `bin/publish_e2e_test_report.sh`.
      - Ensure secure token handoff via file in `/root/.dockersock` and cleanup.

5. Nightly flow:
      - Add nightly `cron_nightly_e2e_tests` step.
      - Add `cron_notify_slack_nightly_e2e` summary/notification step.
      - Use `bin/summarise_playwright_report.js` for stable text summary generation.

6. Deploy artifact handoff requirement:
      - Ensure deploy script writes branch host artifact to `/root/.dockersock/branch_url.txt` when dockersock exists. Branch host must contain `internal` so the tests target the internally deployed service.

7. Update node image in use to `node:24.18.0-alpine3.24@sha256:4ba75f835bb8802193e4c114572113d4b26f95f6f094f4b5229d2a77773e0afc` if it hasn't already been done
      - Check the following files; 
            - Dockerfile
            - .drone.yml or .drone.yaml

8. Update node engine in package.json to `>=24.15.0 <25.0.0` if it hasn't already been done.

## Supporting Scripts

Use steering scripts as canonical references and copy/update into target `bin/` only when needed:
1. `generate_github_app_token.sh`
2. `publish_e2e_test_report.sh`
3. `summarise_playwright_report.js`

When scripts already exist, prefer minimal diffs to align behavior rather than full overwrite.

## Ignore File Updates (Mandatory)

1. `.eslintignore` must include exactly these entries:
      - `e2e-tests`
      - `playwright-report`
      - `test-results`

2. `.gitignore` must include exactly these entries:
      - `.features-gen`
      - `playwright-report`
      - `test-results`

Do not duplicate entries on rerun.

## Validation Requirements

After edits, validate and report:
1. Anchor presence and step wiring correctness.
2. Auth compliance (no PAT usage in modified scope).
3. Drone file is valid yaml with no indentation or syntax errors.
4. PR e2e dependency chain correctness.
5. Nightly e2e and summary flow presence.
6. Dockersock volume and branch URL artifact wiring.
7. Ignore file compliance.
8. Playwright version compliance:
      - Drone Playwright image is `>=1.60.0`.
      - `@playwright/test` and `playwright` are pinned and aligned with CI runtime.
      - lockfile reflects the pinned versions (no unresolved drift).

## Output Format

Return sections in this order:
1. `PATCH_SUMMARY`
2. `CI_WIRING_SUMMARY`
3. `AUTH_COMPLIANCE_REPORT`
4. `DRONE_DOCKERSOCK_VOLUME_COMPLIANCE`
5. `ESLINT_IGNORE_COMPLIANCE`
6. `GITIGNORE_COMPLIANCE`
7. `WARNINGS`
8. `ASSUMPTIONS`
9. `MANUAL_ACTIONS`
10. `ROLLBACK_HINTS`

## Success Criteria

1. PR pipeline can deploy branch and run Playwright tests against deployed URL artifact.
2. PR Playwright report is published using GitHub App token auth.
3. Nightly cron Playwright run and summary notification are wired.
4. Rerunning this SKILL is safe and does not duplicate config.
