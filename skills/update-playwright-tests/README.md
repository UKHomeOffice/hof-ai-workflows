# Update Playwright Tests

This skill and workflow automate Playwright test maintenance after changes are merged to a repository's main branch.

The target repository keeps a small caller workflow. The caller invokes the reusable workflow from `UKHomeOffice/hof-ai-workflows`, which pulls this skill, computes the merge diff, and starts a Copilot cloud agent task in the target repository.

## Flow

1. A change is merged to `main` in a repository that already has Playwright tests.
2. The target repository's GitHub Actions workflow runs on the `push` to `main`.
3. The caller invokes `.github/workflows/update-playwright-tests.yml` from this repository.
4. The reusable workflow checks out the target repository and this repository.
5. The reusable workflow loads `skills/update-playwright-tests/SKILL.md`, computes the changed range, and starts a Copilot cloud agent task for the target repository.
6. The skill decides whether coverage needs to be added, amended, or left unchanged.
7. If test changes are needed, Copilot commits them and opens a pull request for human developer or QAT review.

## Target Repository Caller Workflow

Add this workflow to each target repository that should run the automation:

```yaml
name: Update Playwright tests

on:
  push:
    branches:
      - main

permissions:
  contents: read
  actions: read

jobs:
  update-playwright-tests:
    if: ${{ github.actor != 'copilot-swe-agent[bot]' }}
    uses: UKHomeOffice/hof-ai-workflows/.github/workflows/update-playwright-tests.yml@main
    with:
      base-ref: main
      skill-ref: main
      target-sha: ${{ github.sha }}
      diff-base-sha: ${{ github.event.before }}
      create-pull-request: true
    secrets:
      COPILOT_AGENT_TOKEN: ${{ secrets.COPILOT_AGENT_TOKEN }}
      HOF_AI_WORKFLOWS_APP_ID: ${{ secrets.HOF_AI_WORKFLOWS_APP_ID }}
      HOF_AI_WORKFLOWS_APP_PRIVATE_KEY: ${{ secrets.HOF_AI_WORKFLOWS_APP_PRIVATE_KEY }}
```

For production use, pin both `uses` and `skill-ref` to a reviewed tag or commit SHA rather than `main`.

## Required Secrets

### `COPILOT_AGENT_TOKEN`

Required. A user-to-server token that can call the Copilot agent tasks API for the target repository.

`GITHUB_TOKEN` is not supported by the Copilot agent tasks API. Use a token for a user or GitHub App user-to-server flow with access to:

- the target repository,
- Copilot cloud agent,
- repository contents, pull requests, actions, and issues as required by the agent task API.

### `HOF_AI_WORKFLOWS_TOKEN`

Optional fallback token with read access to `UKHomeOffice/hof-ai-workflows`.

Prefer the GitHub App credentials below so the workflow generates a short-lived installation token instead of relying on a long-lived stored checkout token.

### `HOF_AI_WORKFLOWS_APP_ID`

Optional GitHub App ID or client ID for an app installed on `UKHomeOffice/hof-ai-workflows`.

When supplied with `HOF_AI_WORKFLOWS_APP_PRIVATE_KEY`, the reusable workflow generates a short-lived installation token using `actions/create-github-app-token` and uses that token to checkout this repository.

### `HOF_AI_WORKFLOWS_APP_PRIVATE_KEY`

Optional private key for the GitHub App identified by `HOF_AI_WORKFLOWS_APP_ID`.

The app only needs:

- repository access to `UKHomeOffice/hof-ai-workflows`,
- `Contents: Read-only`,
- `Metadata: Read-only`.

The installation ID used in Drone is not required by `actions/create-github-app-token`; the action resolves the installation from `owner: UKHomeOffice` and `repositories: hof-ai-workflows`.

## Reusable Workflow Inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `base-ref` | `main` | Base branch for the Copilot agent task. |
| `skill-ref` | `main` | Ref in `UKHomeOffice/hof-ai-workflows` to load the skill from. Pin this in production. |
| `target-sha` | workflow event SHA | Commit SHA to analyse. |
| `diff-base-sha` | push event `before`, then target parent | Base SHA for the changed range. |
| `create-pull-request` | `true` | Tells Copilot cloud agent to open a PR if test changes are required. |
| `copilot-model` | empty | Optional Copilot model override. |
| `diff-max-bytes` | `180000` | Maximum diff size embedded directly in the prompt. Larger diffs are summarised and recomputed by the agent. |

## Behaviour

The reusable workflow skips before starting Copilot when it cannot find a Playwright configuration or Playwright dependency marker in the target repository.

When it does start Copilot, the generated prompt includes:

- the full skill instructions,
- target repository and commit metadata,
- changed file names,
- diff stat,
- the full diff when below `diff-max-bytes`,
- instructions to recompute the authoritative diff in the agent environment.

The agent is instructed to make no changes and open no PR when there is no user-facing Playwright coverage gap. When changes are needed, it must create the smallest conventional Playwright test update, validate it where feasible, commit with `test: <summary>`, and leave the PR for human review.

## Human Review

The workflow does not merge agent-created pull requests. A developer or QAT must review the PR, check the validation output, request changes if needed, and merge only when satisfied.
