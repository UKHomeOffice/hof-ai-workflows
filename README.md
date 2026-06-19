# CTF Feature Migration Prompt Framework

This directory contains a portable, parameter-driven prompt system for migrating cucumber features into Playwright BDD with Drone wiring.

## Files
- `ctf-feature-migration-master-prompt.md`: machine-agnostic master execution prompt.
- `steering/lmr-blueprint.md`: canonical migration blueprint (LMR).
- `steering/source-e2e-conventions.md`: source cucumber conventions from shared e2e repo.
- `manifests/migration-manifest.template.yaml`: template for new migration units.
- `manifests/modern-slavery-nrm.yaml`: concrete example manifest.

## How to run
1. Copy `manifests/migration-manifest.template.yaml` to a service/feature specific file.
2. Fill placeholders (`{{WORKSPACE_ROOT}}`, service folder names, branch policy, etc.).
3. In your agent run, provide:
- the full master prompt from `ctf-feature-migration-master-prompt.md`
- the chosen manifest content as `RUN_MANIFEST`
- steering references from `steering/` as `STEERING_CONTEXT`
4. Execute in real mode for implementation, or dry-run for planning.

## Auth policy
All migrations must enforce GitHub App based auth for Drone clone flows. PAT-based clone credentials are forbidden and must be removed where touched.
