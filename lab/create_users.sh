#!/usr/bin/env bash
set -euo pipefail

AAP_URL="https://aap-aap.apps.cluster-gvcw9.gvcw9.sandbox2320.opentlc.com/"
TOKEN="a"
PASSWORD_OF_USERS="aapworkshop77"
NUM_USERS=20   # creates user1 .. user<NUM_USERS>

API="${AAP_URL%/}/api/gateway/v1"

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

  ns="${i}user-aap"
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null

  kubectl create serviceaccount "${name}" -n "${ns}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null
  kubectl create rolebinding "${name}-admin" -n "${ns}" --clusterrole=admin \
    --serviceaccount="${ns}:${name}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null

  echo "Created user '${name}' with organization '${name}', namespace '${ns}' and service account '${name}' (admin)"
done
