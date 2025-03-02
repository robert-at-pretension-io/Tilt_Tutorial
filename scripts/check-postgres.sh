#!/bin/bash
set -e

echo "Checking PostgreSQL connection..."
kubectl exec -it -n keycloak keycloak-postgresql-0 -- bash -c "PGPASSWORD=bn_keycloak psql -U bn_keycloak -d bitnami_keycloak -c 'SELECT 1;'"

if [ $? -eq 0 ]; then
  echo "PostgreSQL connection successful!"
else
  echo "PostgreSQL connection failed!"
fi
