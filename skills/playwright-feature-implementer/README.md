# Playwright Feature Implementer

Implements a supplied Gherkin `.feature` file in the service repository represented by the current working directory. The skill discovers and follows local Playwright instructions, reuses the repository's existing test structure, and validates the focused test implementation.

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
