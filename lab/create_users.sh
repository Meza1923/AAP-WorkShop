#!/usr/bin/env bash
set -euo pipefail

AAP_URL="https://aap-aap.apps.cluster-gvcw9.gvcw9.sandbox2320.opentlc.com/"
TOKEN="a"
PASSWORD_OF_USERS="aapworkshop77"

API="${AAP_URL%/}/api/gateway/v1"

auth=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

member_role_id=$(curl -sk -G "${auth[@]}" "${API}/role_definitions/" --data-urlencode "name=Organization Member" | jq -r '.results[0].id')

for i in $(seq 1 20); do
  num=$(( RANDOM % 101 ))
  name="user${num}"

  org_id=$(curl -sk "${auth[@]}" -X POST "${API}/organizations/" \
    -d "{\"name\": \"${name}\"}" | jq -r '.id')

  user_id=$(curl -sk "${auth[@]}" -X POST "${API}/users/" \
    -d "{\"username\": \"${name}\", \"password\": \"${PASSWORD_OF_USERS}\"}" | jq -r '.id')

  curl -sk "${auth[@]}" -X POST "${API}/role_user_assignments/" \
    -d "{\"user\": ${user_id}, \"role_definition\": ${member_role_id}, \"object_id\": ${org_id}}" > /dev/null

  echo "Created user '${name}' with organization '${name}'"
done
