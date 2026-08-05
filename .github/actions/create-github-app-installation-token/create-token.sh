#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_APP_ID:?Missing GITHUB_APP_ID}"
: "${GITHUB_APP_PRIVATE_KEY:?Missing GITHUB_APP_PRIVATE_KEY}"
: "${GITHUB_APP_INSTALLATION_ID:?Missing GITHUB_APP_INSTALLATION_ID}"

TOKEN_REPOSITORIES="${TOKEN_REPOSITORIES:-}"
TOKEN_PERMISSIONS="${TOKEN_PERMISSIONS:-}"
if [[ -z "${TOKEN_PERMISSIONS}" ]]; then
  TOKEN_PERMISSIONS="{}"
fi

work_dir="${RUNNER_TEMP:-/tmp}/create-github-app-installation-token"
mkdir -p "${work_dir}"

key_file="${work_dir}/github-app-private-key.pem"
request_body_file="${work_dir}/request-body.json"
response_file="${work_dir}/response.json"

cleanup() {
  rm -f "${key_file}" "${request_body_file}" "${response_file}"
}
trap cleanup EXIT

printf '%b' "${GITHUB_APP_PRIVATE_KEY}" > "${key_file}"
chmod 600 "${key_file}"

b64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

app_id="$(printf '%s' "${GITHUB_APP_ID}" | tr -d '[:space:]')"
installation_id="$(printf '%s' "${GITHUB_APP_INSTALLATION_ID}" | tr -d '[:space:]')"

if ! [[ "${app_id}" =~ ^[0-9]+$ ]]; then
  echo "::error::app-id must be the numeric GitHub App ID."
  exit 1
fi

if ! [[ "${installation_id}" =~ ^[0-9]+$ ]]; then
  echo "::error::installation-id must be numeric."
  exit 1
fi

python3 - "${TOKEN_REPOSITORIES}" "${TOKEN_PERMISSIONS}" "${request_body_file}" <<'PY'
import json
import sys
from pathlib import Path

repositories_raw, permissions_raw, request_body_path = sys.argv[1:]

payload = {}

repositories = [
    repository.strip()
    for repository in repositories_raw.replace(",", "\n").splitlines()
    if repository.strip()
]

if repositories:
    payload["repositories"] = repositories

permissions_text = permissions_raw.strip()
if permissions_text:
    try:
        permissions = json.loads(permissions_text)
    except json.JSONDecodeError as error:
        print(f"::error::permissions must be a valid JSON object: {error}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(permissions, dict):
        print("::error::permissions must be a JSON object.", file=sys.stderr)
        sys.exit(1)

    if permissions:
        payload["permissions"] = permissions

Path(request_body_path).write_text(json.dumps(payload), encoding="utf-8")
PY

now="$(date +%s)"
iat="$((now - 60))"
exp="$((now + 540))"
header_b64="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)"
payload_b64="$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "${iat}" "${exp}" "${app_id}" | b64url)"
unsigned_token="${header_b64}.${payload_b64}"
signature_b64="$(printf '%s' "${unsigned_token}" | openssl dgst -binary -sha256 -sign "${key_file}" | b64url)"
jwt="${unsigned_token}.${signature_b64}"

http_status="$(curl -sS -o "${response_file}" -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${jwt}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${installation_id}/access_tokens" \
  --data-binary "@${request_body_file}")"

if [[ "${http_status}" != "200" && "${http_status}" != "201" ]]; then
  message="$(python3 - "${response_file}" <<'PY'
import json
import sys
from pathlib import Path

try:
    response = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except json.JSONDecodeError:
    print("Unable to parse GitHub API error response")
else:
    print(response.get("message", "Unknown GitHub API error"))
PY
)"
  echo "::error::Failed to create GitHub App installation token. HTTP ${http_status}: ${message}"
  exit 1
fi

token="$(python3 - "${response_file}" <<'PY'
import json
import sys
from pathlib import Path

response = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(response.get("token", ""))
PY
)"

if [[ -z "${token}" ]]; then
  echo "::error::GitHub App installation token response did not include a token."
  exit 1
fi

echo "::add-mask::${token}"
printf 'token=%s\n' "${token}" >> "${GITHUB_OUTPUT}"
