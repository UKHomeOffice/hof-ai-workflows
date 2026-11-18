# Playwright Feature Implementer

Implements a supplied Gherkin `.feature` file in the service repository represented by the current working directory. The implementation strictly follows the QAT "Playwright Test Structure – LMR Playwright and POM framework blueprint": Playwright BDD (`playwright-bdd`), a typed `pages` fixture, and page objects that extend a shared base page. Verification gates prove it works.

## What The Skill Does

1. **Preflight and discovery.** Validates the input and reads local instructions. Classifies the repository's framework as `compliant`, `partial` or `absent` against the blueprint, and records a baseline static scan.
2. **Scaffold.** If the framework is `partial` or `absent`, adds the blueprint structure: config, scripts, `.gitignore`, base page, fixture and constants.
3. **Implement.** Builds constants and data, then page objects, then the fixture, then steps. It doesn't change the feature file.
4. **Touched-code remediation.** Fixes blueprint deviations in code it writes or reuses when the fix is safe. It reports the rest without changing them.
5. **Verification gates:**
   - G1: `bddgen`
   - G2: static scan
   - G3: lint and type-check
   - G4: safety check, then a focused run
   - G5: negative-assertion proof
   - G6: unknown-case proof
   - G7: compliance checklist
6. **Report.** Reports with a compliance checklist, gate evidence and deviations it didn't fix.

## Skill Files

| File | Purpose |
|---|---|
| [SKILL.md](./SKILL.md) | Workflow, guardrails, gates and output format |
| [playwright-blueprint.md](./playwright-blueprint.md) | Normative blueprint rules with stable IDs |
| [compliance-checklist.md](./compliance-checklist.md) | Checklist and gate pass conditions |
| [scaffold-templates.md](./scaffold-templates.md) | Templates used when a repository lacks the blueprint structure |
| [blueprint-static-scan.sh](./blueprint-static-scan.sh) | Dependency-free static scan for blueprint violations |

## Install Locally

For development, symlink the skill into your user-level Copilot skills directory from the root of this repository:

```bash
mkdir -p ~/.copilot/skills
ln -s "$PWD/skills/playwright-feature-implementer" \\
  ~/.copilot/skills/playwright-feature-implementer
```

To install a copy instead:

```bash
mkdir -p ~/.copilot/skills
cp -R skills/playwright-feature-implementer \\
  ~/.copilot/skills/playwright-feature-implementer
```

A symlink receives updates from this repository automatically. Reload VS Code or start a new Copilot Chat session after installing.

## Usage

Open the target service folder in VS Code, then invoke the skill with one feature-file path:

```text
/playwright-feature-implementer path/to/feature.feature
```

The skill assumes the current directory is the service repository and does not accept a separate service-folder argument.

Scenarios that submit forms, send email or call external integrations only run locally, or against a `PLAYWRIGHT_BASE_URL` you explicitly confirm is an approved non-production environment.

## Static Scan

You can run the scan on its own from a service repository root:

```bash
bash ~/.copilot/skills/playwright-feature-implementer/blueprint-static-scan.sh            # files changed vs HEAD
bash ~/.copilot/skills/playwright-feature-implementer/blueprint-static-scan.sh e2e-tests/steps/*.ts
bash ~/.copilot/skills/playwright-feature-implementer/blueprint-static-scan.sh --strict ... # warnings fail too
```

It prints `<SEVERITY> <file>:<line> <RULE-ID> <message>` for each finding. It exits with `1` when it finds errors, or warnings in `--strict` mode, and `0` otherwise. Rule IDs match [playwright-blueprint.md](./playwright-blueprint.md).
