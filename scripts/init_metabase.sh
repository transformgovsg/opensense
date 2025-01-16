#!/bin/sh

ADMIN_EMAIL=${MB_ADMIN_EMAIL:-admin@sense.local}
ADMIN_PASSWORD=${MB_ADMIN_PASSWORD:-Sense1!}

echo "${ADMIN_PASSWORD}"

METABASE_HOST=${MB_HOSTNAME:-localhost}
METABASE_PORT=${MB_PORT:-3000}

echo "⌚︎ Waiting for Metabase to start"
while (! curl -s -m 5 http://${METABASE_HOST}:${METABASE_PORT}/api/session/properties -o /dev/null); do sleep 5; done

echo "😎 Creating admin user"

SETUP_TOKEN=$(curl -s -m 5 -X GET \
    -H "Content-Type: application/json" \
    http://${METABASE_HOST}:${METABASE_PORT}/api/session/properties \
    | jq -r '.["setup-token"]'
)

MB_TOKEN=$(curl -s -X POST \
    -H "Content-type: application/json" \
    http://${METABASE_HOST}:${METABASE_PORT}/api/setup \
    -d '{
    "token": "'${SETUP_TOKEN}'",
    "user": {
        "email": "'${ADMIN_EMAIL}'",
        "first_name": "Metabase",
        "last_name": "Admin",
        "password": "'${ADMIN_PASSWORD}'"
    },
    "prefs": {
        "allow_tracking": false,
        "site_name": "Metawhat"
    }
}' | jq -r '.id')

echo -e "\n👥 Creating some basic users: "
curl -s "http://${METABASE_HOST}:${METABASE_PORT}/api/user" \
    -H 'Content-Type: application/json' \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    -d '{"first_name":"Basic","last_name":"User","email":"basic@sense.local","password":"'${ADMIN_PASSWORD}'"}'

curl -s "http://${METABASE_HOST}:${METABASE_PORT}/api/user" \
    -H 'Content-Type: application/json' \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    -d '{"first_name":"Basic 2","last_name":"User","email":"basic2@sense.local","password":"'${ADMIN_PASSWORD}'"}'

echo -e "\n👥 Basic users created!"

echo -e "\n🔑 Generating API key"

# First, get the admin group ID (typically group 1 is the administrators group)
ADMIN_GROUP_ID=$(curl -s \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    http://${METABASE_HOST}:${METABASE_PORT}/api/permissions/group | jq '.[] | select(.name=="Administrators") | .id')

# Generate new API key with a name and admin group
API_KEY=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    http://${METABASE_HOST}:${METABASE_PORT}/api/api-key \
    -d '{
        "name": "Sense Admin API Key",
        "group_id": '"${ADMIN_GROUP_ID}"'
    }' | jq -r '.unmasked_key')

if [ -z "$API_KEY" ] || [ "$API_KEY" == "null" ]; then
    echo "❌ Failed to generate API key"
    exit 1
fi

echo -e "\n✅ Successfully generated new Metabase API key:"
echo "API Key: $API_KEY"
