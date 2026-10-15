#!/usr/bin/env bash
# Deploys Gitea in the namespace "gitea" and creates user1 .. userN with the same
# password they use for OpenShift and AAP. Safe to re-run: existing users get their
# password reset to PASSWORD_OF_USERS.
#
# Optional: MANAGER_PASSWORD=<password> ./deploy_gitea.sh also creates "manager" as a
# Gitea administrator (use the same password as the OpenShift login "manager").
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NS="gitea"
EMAIL_DOMAIN="example.com"

# Take PASSWORD_OF_USERS and NUM_USERS from lab/create_users.sh, so OpenShift, AAP and
# Gitea always get the same users and password. Environment variables override them.
eval "$(grep -E '^(PASSWORD_OF_USERS|NUM_USERS)=' "${REPO_DIR}/lab/create_users.sh" | sed 's/#.*//')"
PASSWORD_OF_USERS="${GITEA_USERS_PASSWORD:-${PASSWORD_OF_USERS}}"
NUM_USERS="${GITEA_NUM_USERS:-${NUM_USERS}}"

oc apply -f "${SCRIPT_DIR}/gitea.yaml"

host=$(oc get route gitea -n "${NS}" -o jsonpath='{.spec.host}')
# Gitea builds clone URLs and webhook links from ROOT_URL. No change, no new rollout.
oc set env deployment/gitea -n "${NS}" GITEA__server__ROOT_URL="https://${host}/"
oc rollout status deployment/gitea -n "${NS}" --timeout=300s

gitea() { oc exec -n "${NS}" deployment/gitea -- gitea "$@"; }

# Rows start with the numeric user ID; this skips the header and any log lines.
existing=$(gitea admin user list | awk '$1 ~ /^[0-9]+$/ {print $2}')

# create_or_update <username> <password> [extra flags for "user create"]
create_or_update() {
  local name=$1 password=$2
  shift 2
  if grep -qx "${name}" <<< "${existing}"; then
    gitea admin user change-password --username "${name}" --password "${password}" \
      --must-change-password=false > /dev/null
    echo "Updated Gitea user '${name}'"
  else
    gitea admin user create --username "${name}" --password "${password}" \
      --email "${name}@${EMAIL_DOMAIN}" --must-change-password=false "$@" > /dev/null
    echo "Created Gitea user '${name}'"
  fi
}

if [ -n "${MANAGER_PASSWORD:-}" ]; then
  create_or_update manager "${MANAGER_PASSWORD}" --admin
fi

for i in $(seq 1 "${NUM_USERS}"); do
  create_or_update "user${i}" "${PASSWORD_OF_USERS}"
done

echo "Gitea is available at https://${host}/"
