#!/bin/bash

# Check parameter value and set defaults
if [ -z "$KEYCLOAK_USER" ]; then
    export KEYCLOAK_USER=admin
fi
if [ -z "$KEYCLOAK_PASSWORD" ]; then
    export KEYCLOAK_PASSWORD=admin
fi
if [ -z "$KEYCLOAK_PORT" ]; then
    export KEYCLOAK_PORT=8080
fi
if [ -z "$KEYCLOAK_HOST" ]; then
    export KEYCLOAK_HOST=host.docker.internal
fi

# Wait for KeyCloak
until [ "$(curl -sL -w "%{http_code}\\n" http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/realms/master/.well-known/openid-configuration -o /dev/null)" == "200" ]
do
    echo "$(date) - still trying to connect to KeyCloak at http://$KEYCLOAK_HOST:$KEYCLOAK_PORT"
    sleep 5
done

# Get JWT token
echo "Getting JWT for $KEYCLOAK_USER user";
export TOKEN=$(curl -ss -d "username=$KEYCLOAK_USER&password=$KEYCLOAK_PASSWORD&grant_type=password&client_id=admin-cli&client_secret=7f2fc8e5-f01c-471b-b981-ef7534041790" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/realms/master/protocol/openid-connect/token | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Create users
input="users.csv"
while IFS=',' read -r f1 f2 f3 f4 f5
do
 var=$(curl -d "{ \"username\": \"$f1\", \"enabled\": true, \"emailVerified\": false, \"firstName\": \"$f4\", \"lastName\": \"$f3\", \"credentials\": [{ \"type\": \"password\", \"value\": \"$f2\", \"temporary\": false }] }" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST  http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/admin/realms/master/users)
 if [ "$var" == "201" ]; then
    echo "User $f1 created";
 else
  if [ "${var: -3}" == "409" ]; then
    echo "User $f1 exists";
  else
    echo "An error occurred during user creation";
  fi
 fi
done < "$input"

# Create clientA
var=$(curl -d @clientA.json -H "Expect:" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/admin/realms/master/clients)
if [ "$var" == "201" ]; then
    echo "ClientA created";
else
    if [ "${var: -3}" == "409" ]; then
        echo "ClientA exists";
    else
        echo "An error occurred during client creation";
    fi
fi

# Create clientB
var=$(curl -d @clientB.json -H "Expect:" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/admin/realms/master/clients)
if [ "$var" == "201" ]; then
    echo "ClientB created";
else
    if [ "${var: -3}" == "409" ]; then
        echo "ClientB exists";
    else
        echo "An error occurred during client creation";
    fi
fi