You are executing a single-feature migration run using the CTF prompt framework.

Resolve repository paths dynamically so this prompt can be run from either:
- the HOF monorepo root, or
- a service folder (for example `hff/`).

Before reading any files, derive:
- HOF_REPO_ROOT:
	- if `./ai/ctf-migration` exists, use `.`
	- else if `../ai/ctf-migration` exists, use `..`
	- else stop and report: `Unable to resolve HOF_REPO_ROOT from current working directory`
- SOURCE_E2E_REPO_ROOT: `${HOF_REPO_ROOT}/hof-e2e-auto-tests`
- TARGET_SERVICE_ROOT: `${HOF_REPO_ROOT}/${UI_SERVICE_FOLDER}`

Read and follow:
- ${HOF_REPO_ROOT}/ai/ctf-migration/ctf-feature-migration-master-prompt.md
- ${HOF_REPO_ROOT}/ai/ctf-migration/steering/lmr-blueprint.md
- ${HOF_REPO_ROOT}/ai/ctf-migration/steering/source-e2e-conventions.md

Use this manifest as base:
- ${HOF_REPO_ROOT}/ai/ctf-migration/manifests/migration-manifest.template.yaml

Set only these two values:
- UI_SERVICE_FOLDER=hff
- UI_FEATURE_FILE=hff.feature

Apply these derived overrides:
- source_repo_root: ${SOURCE_E2E_REPO_ROOT}
- source_feature_folder: Function/src/main/resources/features/ui/${UI_SERVICE_FOLDER}
- source_feature_glob: Function/src/main/resources/features/ui/${UI_SERVICE_FOLDER}/${UI_FEATURE_FILE}
- source_page_objects_root: Function/src/main/java/domain/component/ui/pages
- source_step_lib_root: Function/src/main/java/domain/component/ui/stepLib
- source_applicant_data_root: Function/src/main/resources/test-data/applicant-data
- target_repo_root: ${TARGET_SERVICE_ROOT}

Execution requirements:
- Real migration mode (not dry-run).
- Run Stage 1 then Stage 2 exactly as defined in the master prompt.
- Execute the autonomous completion loop from the master prompt and continue mapping in-run until SOURCE_IMPLEMENTATION_PARITY_COMPLIANCE is PASS (or a hard blocker is documented).
- Do not stop with partial parity and do not wait for a follow-up "continue" prompt.
- Enforce auth modernization: all Drone clone auth must use GitHub App token flow; PAT patterns must fail auth compliance.
- Enforce `.eslintignore` policy: target project must contain `e2e-tests`, `playwright-report`, and `bin/*` entries.
- Enforce `.gitignore` policy: target project must contain `.features-gen`, `playwright-report`, and `test-results` entries.
- Enforce `bin/deploy.sh` branch artifact policy: branch slug export lines, service-appropriate `BRANCH_HOST` computation, and write to `/root/.dockersock/branch_url.txt`.
- Enforce Drone dockersock volume policy: both `deploy_to_branch` and `e2e_tests` must mount `dockersock` at `/root/.dockersock`.
- Enforce `e2e_tests` branch URL artifact command policy:
	- include `test -s /root/.dockersock/branch_url.txt || (echo "Missing deployed branch URL at /root/.dockersock/branch_url.txt" && exit 1)` before running tests
	- run e2e with `CI=true PLAYWRIGHT_BASE_URL="https://$(cat /root/.dockersock/branch_url.txt)" yarn test:e2e`
	- do not inline branch-host construction in the e2e command
- Return output in the strict final section order from the master prompt.
- If required manifest keys are missing, stop and list missing keys before making changes.

Now execute with:
- UI_SERVICE_FOLDER=hff
- UI_FEATURE_FILE=hff.feature
