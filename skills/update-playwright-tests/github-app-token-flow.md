# GitHub App Token Flow For Playwright Automation

This document explains the GitHub App authentication model used by the Playwright automation workflows, why each token is required, and where each token is configured.

It is intended for repository owners and administrators who need to approve, configure, or support this flow.

## Purpose

The Playwright automation runs after changes are merged to a target repository's `main` branch. For example:

```text
UKHomeOffice/visa-web-messenger
```

The target repository calls the reusable workflow in:

```text
UKHomeOffice/hof-ai-workflows
```

The reusable workflow loads the `update-playwright-tests` skill, computes the merge diff, and starts a GitHub Copilot cloud agent task. The agent decides whether Playwright tests need to be added or updated. If test changes are required, the agent creates a branch and pull request for human developer or QAT review.

This requires two distinct authentication paths:

1. read access to `UKHomeOffice/hof-ai-workflows`, and
2. user-to-server access to start a Copilot cloud agent task in the target repository.

These are different GitHub security models and cannot be handled by the same installation token.

## Relevant GitHub Documentation

- Copilot cloud agent tasks API: <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-via-the-api>
- GitHub App user-to-server authentication: <https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-with-a-github-app-on-behalf-of-a-user>
- Generating a GitHub App user access token: <https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app>
- Refreshing GitHub App user access tokens: <https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens>

## GitHub App Details

The current app intended for this flow is:

```text
App name: hof-gh-app-user-access
Owner: UKHomeOffice
App ID: 4559464
Client ID: Iv23li1s8P9i2385ZLac
Installation ID: 152950386
```

Required repository permissions:

```text
Agent tasks: Read & write
Contents: Read & write
Pull requests: Read & write
Issues: Read & write
Actions: Read & write
Metadata: Read-only
```

`Agent tasks: Read & write` is required by GitHub's `POST /agents/repos/<owner>/<repo>/tasks` endpoint. The remaining permissions allow the Copilot cloud agent to inspect repository contents, create a branch, commit Playwright test changes, open a pull request, and interact with the repository workflow context.

GitHub App user access is limited by both:

1. the app's permissions and installation scope, and
2. the authorising user's own repository access.

The token cannot grant access that either the app or the user does not already have.

## Token Types Used By The Workflow

| Purpose | Token type | Generated how | Secret name |
| --- | --- | --- | --- |
| Checkout `UKHomeOffice/hof-ai-workflows` | GitHub App installation token | Generated automatically by the reusable workflow from app credentials and installation ID | `HOF_AI_WORKFLOWS_APP_*` |
| Start Copilot cloud agent task in the target repo | GitHub App user access token | Generated once through GitHub App user authorisation/device flow | `COPILOT_AGENT_TOKEN` |

## Why `COPILOT_AGENT_TOKEN` Must Be User-To-Server

The Copilot cloud agent task is started through:

```text
POST /agents/repos/<owner>/<repo>/tasks
```

GitHub documents that the Copilot agent tasks API supports user-to-server tokens. It does not support server-to-server tokens such as GitHub App installation tokens.

This means the workflow cannot start a Copilot cloud agent task using only:

```text
GitHub App ID
GitHub App private key
GitHub App installation ID
```

Those values can only create an installation token. They cannot silently impersonate a user.

For the Copilot task API, a user must authorise the GitHub App and produce a GitHub App user access token. This token starts with:

```text
ghu_
```

That token is then stored as:

```text
COPILOT_AGENT_TOKEN
```

## Required App Installation Scope

The app must be installed on every target repository that will use the Playwright automation, for example:

```text
UKHomeOffice/visa-web-messenger
```

If the same app is also used to checkout the reusable workflow and skill, the installation must also include:

```text
UKHomeOffice/hof-ai-workflows
```

If the app is installed only on selected repositories, add every approved target repository and `hof-ai-workflows` to that installation.

## Required App Settings

Enable:

```text
Device Flow
```

This is needed to generate the initial GitHub App user access token through:

```text
https://github.com/login/device
```

If the token will be generated once and stored as a long-lived Actions secret, disable:

```text
User-to-server token expiration
```

If expiration remains enabled, GitHub App user access tokens expire after 8 hours and require refresh-token rotation. That rotation is not currently managed by this workflow.

## Generate `COPILOT_AGENT_TOKEN`

Run these steps as the user or service account that should own the automation. The user must have access to the target repositories.

### 1. Request a device code

```sh
CLIENT_ID="Iv23li1s8P9i2385ZLac"

curl -sS \
  -X POST \
  -H "Accept: application/json" \
  https://github.com/login/device/code \
  -d "client_id=${CLIENT_ID}"
```

The response includes:

```text
device_code
user_code
verification_uri
interval
```

If the response is:

```json
{"error":"device_flow_disabled"}
```

enable Device Flow on the GitHub App and retry.

### 2. Authorise the app

Open the returned verification URI, usually:

```text
https://github.com/login/device
```

Enter the returned `user_code`, then authorise `hof-gh-app-user-access` as the automation user or service account.

If the organisation uses SAML SSO, ensure the user has an active SSO session and authorisation for `UKHomeOffice`.

### 3. Exchange the device code for a user access token

```sh
CLIENT_ID="Iv23li1s8P9i2385ZLac"
DEVICE_CODE="PASTE_DEVICE_CODE_FROM_STEP_1"

curl -sS \
  -X POST \
  -H "Accept: application/json" \
  https://github.com/login/oauth/access_token \
  -d "client_id=${CLIENT_ID}" \
  -d "device_code=${DEVICE_CODE}" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:device_code"
```

Copy the returned:

```text
access_token
```

The value should start with:

```text
ghu_
```

If user-to-server token expiration was disabled before generating the token, the response should not include:

```text
expires_in
refresh_token
refresh_token_expires_in
```

## Store `COPILOT_AGENT_TOKEN`

Store the `ghu_...` token in each target repository that calls the reusable workflow, or as an organisation-level Actions secret restricted to approved target repositories.

For a target repository such as `UKHomeOffice/visa-web-messenger`:

```text
Settings
→ Secrets and variables
→ Actions
→ New repository secret
```

Use:

```text
Name: COPILOT_AGENT_TOKEN
Value: ghu_...
```

Do not commit the token, print it in logs, or store it in Markdown documentation.

## Configure The Target Repository Workflow

The target repository workflow passes the user access token and app installation credentials to the reusable workflow:

```yaml
secrets:
  COPILOT_AGENT_TOKEN: ${{ secrets.COPILOT_AGENT_TOKEN }}
  HOF_AI_WORKFLOWS_APP_ID: ${{ secrets.HOF_AI_WORKFLOWS_APP_ID }}
  HOF_AI_WORKFLOWS_APP_PRIVATE_KEY: ${{ secrets.HOF_AI_WORKFLOWS_APP_PRIVATE_KEY }}
  HOF_AI_WORKFLOWS_APP_INSTALLATION_ID: ${{ secrets.HOF_AI_WORKFLOWS_APP_INSTALLATION_ID }}
```

The reusable workflow uses:

```yaml
env:
  GH_TOKEN: ${{ secrets.COPILOT_AGENT_TOKEN }}
```

to start the Copilot cloud agent task.

The reusable workflow uses the `HOF_AI_WORKFLOWS_APP_*` values to create a short-lived installation token for checking out `UKHomeOffice/hof-ai-workflows`.

## Troubleshooting

### `device_flow_disabled`

Device Flow has not been enabled on the GitHub App.

Enable it in:

```text
UKHomeOffice
→ Settings
→ Developer settings
→ GitHub Apps
→ hof-gh-app-user-access
```

### `gh: forbidden (HTTP 403)` when starting the Copilot agent task

The workflow reached GitHub, but `COPILOT_AGENT_TOKEN` is not authorised to call the Copilot agent tasks API.

Check that:

- `COPILOT_AGENT_TOKEN` is the `ghu_...` GitHub App user access token,
- `COPILOT_AGENT_TOKEN` is not `GITHUB_TOKEN`,
- `COPILOT_AGENT_TOKEN` is not a GitHub App installation token,
- the app has `Agent tasks: Read & write` repository permission,
- the authorising user can access the target repository,
- the authorising user has a Copilot Business or Enterprise subscription,
- the app is installed on the target repository,
- Copilot cloud agent is enabled for the target repository and organisation,
- any app permission changes have been approved on the installation and the user access token was regenerated afterwards,
- organisation SSO or token approval requirements have been completed.

### 404 when generating the `hof-ai-workflows` checkout token

The GitHub App installation cannot see `UKHomeOffice/hof-ai-workflows`.

Check that:

- `HOF_AI_WORKFLOWS_APP_INSTALLATION_ID` is the `UKHomeOffice` installation ID,
- the app installation includes `UKHomeOffice/hof-ai-workflows`,
- the app has `Contents: Read-only` permission or higher for that repository.

## Summary For Repository Owners

The app is required because the Playwright automation needs to start Copilot cloud agent work in target repositories. GitHub requires that API call to use user-to-server authentication.

A GitHub App installation token can read repositories and is used for checking out `hof-ai-workflows`, but it cannot start Copilot cloud agent tasks.

The `COPILOT_AGENT_TOKEN` secret must therefore contain a GitHub App user access token produced once by authorising `hof-gh-app-user-access` as an approved automation user.
