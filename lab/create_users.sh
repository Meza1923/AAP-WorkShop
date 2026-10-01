#!/usr/bin/env bash
set -euo pipefail

AAP_URL="https://aap-aap.apps.cluster-gvcw9.gvcw9.sandbox2320.opentlc.com/"
TOKEN="a"
PASSWORD_OF_USERS="aapworkshop77"
NUM_USERS=20   # creates user1 .. user<NUM_USERS>

API="${AAP_URL%/}/api/gateway/v1"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v htpasswd > /dev/null || { echo "htpasswd not found (install httpd-tools)" >&2; exit 1; }

# OpenShift logins: one htpasswd file for all users, applied as a Secret after the loop.
htpasswd_file=$(mktemp)
trap 'rm -f "${htpasswd_file}"' EXIT

auth=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

member_role_id=$(curl -sk -G "${auth[@]}" "${API}/role_definitions/" --data-urlencode "name=Organization Member" | jq -r '.results[0].id')

for i in $(seq 1 "${NUM_USERS}"); do
  name="user${i}"

  org_id=$(curl -sk "${auth[@]}" -X POST "${API}/organizations/" \
    -d "{\"name\": \"${name}\"}" | jq -r '.id')

  user_id=$(curl -sk "${auth[@]}" -X POST "${API}/users/" \
    -d "{\"username\": \"${name}\", \"password\": \"${PASSWORD_OF_USERS}\"}" | jq -r '.id')

  curl -sk "${auth[@]}" -X POST "${API}/role_user_assignments/" \
    -d "{\"user\": ${user_id}, \"role_definition\": ${member_role_id}, \"object_id\": ${org_id}}" > /dev/null

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

# Replaces htpass-secret with exactly the users above, then enables the htpasswd login.
kubectl create secret generic htpass-secret -n openshift-config \
  --from-file=htpasswd="${htpasswd_file}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl apply -f "${REPO_DIR}/openshift/htpasswd/oauth.yaml" > /dev/null
echo "OpenShift htpasswd login configured for user1 .. user${NUM_USERS} (takes a few minutes to roll out)"
