#!/usr/bin/env bash
#
# One Vault JWT role for ALL GitHub Actions workflows in repo GITHUB_REPO_FULL.
#
# Workaround: Some Vault CLI builds treat `bound_claims=@claims.json` as a raw string
# and return: expected a map, got 'string'. Writing the WHOLE role as one JSON file
# avoids that (same nested object as the HTTP API).
#
# Prerequisites:
#   export VAULT_ADDR=https://vault.naidu72.info
#   vault login
#
# Optional env:
#   ROLE_NAME=github-actions
#   POLICY_NAME=github-actions
#   GITHUB_REPO_FULL=naidu72/study_terraform
#   BOUND_AUDIENCES=https://github.com/naidu72

set -euo pipefail

ROLE_NAME="${ROLE_NAME:-github-actions}"
POLICY_NAME="${POLICY_NAME:-github-actions}"
GITHUB_REPO_FULL="${GITHUB_REPO_FULL:-naidu72/study_terraform}"
BOUND_AUDIENCES="${BOUND_AUDIENCES:-https://github.com/naidu72}"

ROLE_JSON="$(mktemp)"
trap 'rm -f "$ROLE_JSON"' EXIT

export ROLE_NAME POLICY_NAME GITHUB_REPO_FULL BOUND_AUDIENCES

python3 <<'PY' > "$ROLE_JSON"
import json, os

data = {
    "role_type": "jwt",
    "bound_audiences": [os.environ["BOUND_AUDIENCES"]],
    "user_claim": "sub",
    "bound_claims_type": "string",
    "bound_claims": {"repository": os.environ["GITHUB_REPO_FULL"]},
    "policies": [os.environ["POLICY_NAME"]],
    "ttl": "1h",
    "token_ttl": "1h",
}
print(json.dumps(data))
PY

echo "========================================================================"
echo "  VAULT_ADDR     = ${VAULT_ADDR:-<set export VAULT_ADDR>}"
echo "  role           = ${ROLE_NAME}"
echo "  policy         = ${POLICY_NAME}"
echo "  bound_claims   = repository:${GITHUB_REPO_FULL}"
echo "  bound_audiences= ${BOUND_AUDIENCES}"
echo "========================================================================"
echo ""

echo ">>> Payload (bound_claims must be a JSON object):"
cat "$ROLE_JSON" | python3 -m json.tool
echo ""

echo ">>> Removing old role (clears bound_subject / branch-only limits)..."
vault delete "auth/jwt/role/${ROLE_NAME}" 2>/dev/null || true

echo ">>> Creating role via: vault write auth/jwt/role/${ROLE_NAME} @${ROLE_JSON}"
vault write "auth/jwt/role/${ROLE_NAME}" @"$ROLE_JSON"

echo ""
echo ">>> vault read auth/jwt/role/${ROLE_NAME}"
vault read "auth/jwt/role/${ROLE_NAME}"

echo ""
echo "Done. Workflows use role: ${ROLE_NAME}"
