#!/bin/bash
set -e

KEYCLOAK_URL="http://localhost:8080"  # Using port-forward
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
until curl -s "$KEYCLOAK_URL/realms/master" > /dev/null; do
  sleep 5
done

# Get admin token
echo "Getting admin token..."
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r .access_token)

# Create client
echo "Creating client for the application..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/master/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "sample-app",
    "enabled": true,
    "protocol": "openid-connect",
    "redirectUris": ["http://app.example.com/*"],
    "webOrigins": ["http://app.example.com"],
    "publicClient": true,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true
  }'

echo "Keycloak setup complete!"
