# Add Playwright CI/CD 

High-level CI/CD skill for wiring Playwright BDD into existing Drone pipelines after test migration is complete.

This skill focuses on deterministic `.drone.yml` updates, GitHub App token auth flows, and reliable PR/nightly Playwright execution.

## What This SKILL Does

- Adds or updates Drone steps to run Playwright e2e in pull requests.
- Wires PR report publication for Playwright HTML results.
- Adds nightly Playwright execution and summary notification flow.
- Modernizes modified auth flows to use GitHub App installation tokens.
- Enforces idempotent updates so reruns do not duplicate anchors, steps, or ignore entries.

## What It Does Not Do

- Migrate feature tests (handled by `ctf-test-to-playwright`).
- Refactor unrelated CI pipeline areas.
- Change service runtime behavior outside CI/CD wiring needs.

## Run Order

Run this skill after `ctf-test-to-playwright`.

Typical chained sequence:

1. Run migration skill (`ctf-test-to-playwright`) and confirm Playwright tests are present.
2. Run CI/CD skill (`add-playwright-ci-cd`) to wire pipeline execution/reporting.
3. Validate pipeline wiring and rerun idempotency checks.

## Required Inputs

Provide these before execution:

1. Target repository root.
2. Target `.drone.yml` path.
3. Branch policy (default and feature branch globs).
4. PR deployment step name (usually `deploy_to_branch`).
5. Image publish dependency step name.
6. GitHub App secret variant in use (`ukho` and/or `hof`).

## Core Wiring Expectations

The skill expects to produce or align the following patterns:

1. Required anchors in `.drone.yml`:
- `github_app_token_step`
- `github_app_token_secrets_ukho`
- `github_app_token_secrets_hof`
- `clone_repos_step`

2. Mandatory two-step clone flow:
- Generate GitHub App token to file.
- Clone using `x-access-token` URL and remove token file.

3. PR e2e flow:
- `deploy_to_branch` and `e2e_tests` mount `dockersock` at `/root/.dockersock`.
- `e2e_tests` reads deployed URL from `/root/.dockersock/branch_url.txt`.
- `PLAYWRIGHT_BASE_URL` is set from that file, not reconstructed inline.

4. PR report publishing:
- Generate report token via GitHub App.
- Publish report using `bin/publish_e2e_test_report.sh`.

5. Nightly flow:
- Nightly Playwright run step.
- Slack/summary notification step using `bin/summarise_playwright_report.js`.

## Supporting Steering Files

The skill uses these canonical references in `steering/`:

- `example-drone.yml`
- `generate_github_app_token.sh`
- `publish_e2e_test_report.sh`
- `summarise_playwright_report.js`

When target scripts already exist, updates should be minimal and behavior-aligned rather than wholesale replacement.

## Mandatory Ignore Updates

1. `.eslintignore` must include:
- `e2e-tests`
- `playwright-report`
- `test-results`

2. `.gitignore` must include:
- `.features-gen`
- `playwright-report`
- `test-results`

No duplicate entries on rerun.

## How To Use It

Recommended prompt pattern:

```text
Run add-playwright-ci-cd SKILL for <service>.
Target drone file is <path-to-.drone.yml>.
Wire PR e2e, PR report publishing, and nightly e2e summary using GitHub App auth.
Keep updates idempotent and preserve existing branch/event policy.
```

Chained prompt example (after migration):

```text
Run ctf-test-to-playwright for service modern-slavery (source folder nrm),
then run add-playwright-ci-cd to wire .drone.yml and Playwright CI flows.
Use one-by-one validation for migrated scenarios first, then finalize CI wiring.
```

## Validation Guidance

After edits, validate:

1. Required anchor presence.
2. No PAT usage in modified auth flows.
3. Correct PR e2e dependency chain and branch URL artifact usage.
4. Nightly step and summary notification presence.
5. Ignore file compliance.
6. Idempotent rerun behavior.

## Expected Output Sections

- `PATCH_SUMMARY`
- `CI_WIRING_SUMMARY`
- `AUTH_COMPLIANCE_REPORT`
- `DRONE_DOCKERSOCK_VOLUME_COMPLIANCE`
- `ESLINT_IGNORE_COMPLIANCE`
- `GITIGNORE_COMPLIANCE`
- `WARNINGS`
- `ASSUMPTIONS`
- `MANUAL_ACTIONS`
- `ROLLBACK_HINTS`

## Quick Checklist

- Playwright test scripts exist in target repo.
- `.drone.yml` anchors and steps are present and deduplicated.
- PR e2e runs against deployed branch URL artifact.
- PR Playwright report publish works via GitHub App token.
- Nightly e2e and summary notification are wired.
- Ignore files include required entries without duplicates.

## Common Pitfalls

1. Missing branch URL artifact for PR e2e
- Symptom: `e2e_tests` fails before tests with missing `/root/.dockersock/branch_url.txt`.
- Check: `deploy_to_branch` mounts `dockersock` and writes branch host artifact.
- Fix: ensure both `deploy_to_branch` and `e2e_tests` mount `/root/.dockersock` and deploy step writes `branch_url.txt`.

2. GitHub App secrets not available at runtime
- Symptom: token generation step fails fast on missing secret vars.
- Check: selected secret variant (`ukho` or `hof`) matches repo/environment.
- Fix: update secret anchor usage and verify secret names in Drone.

3. Report publish step fails despite successful e2e run
- Symptom: `publish_e2e_report_to_pr` fails with missing token file or API auth errors.
- Check: report token generation step ran and token file path matches publish step expectation.
- Fix: align `OUTPUT_TOKEN_FILE` and publish-step read path under `/root/.dockersock`.

4. Nightly summary step runs but output is unusable
- Symptom: empty/invalid summary or parse errors.
- Check: nightly step persists raw Playwright output and summary script input path is correct.
- Fix: ensure `bin/summarise_playwright_report.js` receives expected input text file.

5. Rerun introduces duplicate anchors or steps
- Symptom: Drone YAML has repeated anchors, duplicate step names, or duplicated cron entries.
- Check: skill logic is doing append-only edits without existing-key checks.
- Fix: update edits to be idempotent by matching existing names before insert.

6. Inline branch-host URL logic drifts from deployment artifact
- Symptom: tests run against wrong environment URL.
- Check: `PLAYWRIGHT_BASE_URL` is sourced from `branch_url.txt` and not reassembled inline.
- Fix: enforce artifact-based URL contract in `e2e_tests` commands.
