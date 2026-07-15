#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <drone-server> <drone-token> <owner/repo> <secrets.env>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

export DRONE_SERVER="$1"
export DRONE_TOKEN="$2"
DRONE_REPO="$3"
SECRETS_ENV_FILE="$4"

if [[ ! "$DRONE_REPO" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]]; then
  echo "Repo must be in the form <org/repo>: $DRONE_REPO" >&2
  exit 1
fi

if [[ "$SECRETS_ENV_FILE" == */* ]]; then
  echo "Secrets file must be in the same directory as this script: $SECRETS_ENV_FILE" >&2
  exit 1
fi

HOF_UKHO_GH_APP_PK_FILE="$SCRIPT_DIR/ukho_gh_app.pem"
HOF_GH_APP_PK_FILE="$SCRIPT_DIR/hof_gh_app.pem"
SECRETS_ENV="$SCRIPT_DIR/$SECRETS_ENV_FILE"

if [ ! -f "$SECRETS_ENV" ]; then
  echo "Secrets file not found: $SECRETS_ENV" >&2
  exit 1
fi

create_secret() {
  local name="$1"
  local value="$2"

  echo "Creating Drone secret: $name"
  drone secret add \
    --name "$name" \
    --data "$value" \
    --allow-pull-request \
    "$DRONE_REPO"
}

while IFS='=' read -r name value || [ -n "$name" ]; do
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  value="${value%$'\r'}"

  if [ -z "$name" ] || [[ "$name" == \#* ]]; then
    continue
  fi

  if [ -z "${value+x}" ]; then
    echo "Skipping invalid line without '=' for secret: $name" >&2
    continue
  fi

  create_secret "$name" "$value"
done < "$SECRETS_ENV"

echo "Creating Drone secret: hof_ukho_gh_app_pk"
drone secret add \
  --name hof_ukho_gh_app_pk \
  --data @"$HOF_UKHO_GH_APP_PK_FILE" \
  --allow-pull-request \
  "$DRONE_REPO"

echo "Creating Drone secret: HOF_GH_APP_PK"
drone secret add \
  --name HOF_GH_APP_PK \
  --data @"$HOF_GH_APP_PK_FILE" \
  --allow-pull-request \
  "$DRONE_REPO"
