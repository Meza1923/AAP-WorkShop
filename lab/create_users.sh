#!/usr/bin/env bash
set -euo pipefail

AAP_URL="https://aap-aap.apps.cluster-vc4zx.vc4zx.sandbox2372.opentlc.com/"
TOKEN="a"
PASSWORD_OF_USERS="a"
NUM_USERS=10   # creates user1 .. user<NUM_USERS>
ORG_FULL_ACCESS="true"   # "true": each user is Organization Admin of their own organization

API="${AAP_URL%/}/api/gateway/v1"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v htpasswd > /dev/null || { echo "htpasswd not found (install httpd-tools)" >&2; exit 1; }

# OpenShift logins: one htpasswd file for all users, applied as a Secret after the loop.
htpasswd_file=$(mktemp)
trap 'rm -f "${htpasswd_file}"' EXIT
# Keep users that this script does not create (e.g. manager) from the current Secret.
kubectl get secret htpass-secret -n openshift-config -o jsonpath='{.data.htpasswd}' 2> /dev/null \
  | base64 -d | grep -vE '^user[0-9]+:' >> "${htpasswd_file}" || true

auth=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

member_role_id=$(curl -sk -G "${auth[@]}" "${API}/role_definitions/" --data-urlencode "name=Organization Member" | jq -r '.results[0].id')
admin_role_id=$(curl -sk -G "${auth[@]}" "${API}/role_definitions/" --data-urlencode "name=Organization Admin" | jq -r '.results[0].id')

# Returns the id of the object with this name, creating it first if needed (safe to re-run).
get_or_create() {
  local kind=$1 name=$2 body=$3 id
  id=$(curl -sk -G "${auth[@]}" "${API}/${kind}/" --data-urlencode "${4:-name}=${name}" | jq -r '.results[0].id // empty')
  [ -n "${id}" ] || id=$(curl -sk "${auth[@]}" -X POST "${API}/${kind}/" -d "${body}" | jq -r '.id')
  echo "${id}"
}

for i in $(seq 1 "${NUM_USERS}"); do
  name="user${i}"

  org_id=$(get_or_create organizations "${name}" "{\"name\": \"${name}\"}")
  user_id=$(get_or_create users "${name}" \
    "{\"username\": \"${name}\", \"password\": \"${PASSWORD_OF_USERS}\"}" username)

  # Member makes the organization the user's home; Admin gives full access inside it.
  org_roles=("${member_role_id}")
  [ "${ORG_FULL_ACCESS}" = "true" ] && org_roles+=("${admin_role_id}")
  for role_id in "${org_roles[@]}"; do
    curl -sk "${auth[@]}" -X POST "${API}/role_user_assignments/" \
      -d "{\"user\": ${user_id}, \"role_definition\": ${role_id}, \"object_id\": ${org_id}}" > /dev/null
  done

  htpasswd -B -b "${htpasswd_file}" "${name}" "${PASSWORD_OF_USERS}" 2> /dev/null

  ns="${i}user-aap"
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null

  kubectl create serviceaccount "${name}" -n "${ns}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null
  kubectl create rolebinding "${name}-admin" -n "${ns}" --clusterrole=admin \
    --serviceaccount="${ns}:${name}" --user="${name}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null

  # admin does not cover monitoring objects: the PrometheusRule (Activity 1 Part B)
  # and the AlertmanagerConfig (Activity 3) need these two roles.
  for role in monitoring-rules-edit alert-routing-edit; do
    kubectl create rolebinding "${name}-${role}" -n "${ns}" --clusterrole="${role}" \
      --serviceaccount="${ns}:${name}" --user="${name}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null
  done

  echo "Created user '${name}' with organization '${name}', namespace '${ns}', service account and OpenShift login '${name}' (admin, monitoring-rules-edit, alert-routing-edit)"
done

# Writes htpass-secret (users above plus kept users), then enables the htpasswd login.
kubectl create secret generic htpass-secret -n openshift-config \
  --from-file=htpasswd="${htpasswd_file}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl apply -f "${REPO_DIR}/openshift/htpasswd/oauth.yaml" > /dev/null
echo "OpenShift htpasswd login configured for user1 .. user${NUM_USERS} (takes a few minutes to roll out)"
