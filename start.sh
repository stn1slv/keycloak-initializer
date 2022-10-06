#!/bin/bash

# Check parameter value and set defaults
if [ -z "$KEYCLOAK_USER" ]; then
    export KEYCLOAK_USER=admin
fi
if [ -z "$KEYCLOAK_PASSWORD" ]; then
    export KEYCLOAK_PASSWORD=admin
fi
if [ -z "$KEYCLOAK_ENDPOINT" ]; then
    export KEYCLOAK_ENDPOINT=http://host.docker.internal:8080/auth
fi
if [ -z "$KEYCLOAK_REALM" ]; then
    export KEYCLOAK_REALM=master
fi
if [ -z "$KEYCLOAK_CLIENT_ID" ]; then
    export KEYCLOAK_CLIENT_ID=admin-cli
fi
if [ -z "$KEYCLOAK_CLIENT_SECRET" ]; then
    export KEYCLOAK_CLIENT_SECRET=7f2fc8e5-f01c-471b-b981-ef7534041790
fi

echo "KeyCloan endpoint is $KEYCLOAK_ENDPOINT"

# Wait for KeyCloak
until [ "$(curl -sL -w "%{http_code}\\n" $KEYCLOAK_ENDPOINT/realms/master/.well-known/openid-configuration -o /dev/null)" == "200" ]
do
    echo "$(date) - still trying to connect to KeyCloak at $KEYCLOAK_ENDPOINT"
    sleep 5
done

# Get JWT token
echo "Getting JWT for $KEYCLOAK_USER user";
export TOKEN=$(curl -ss -d "username=$KEYCLOAK_USER&password=$KEYCLOAK_PASSWORD&grant_type=password&client_id=$KEYCLOAK_CLIENT_ID&client_secret=$KEYCLOAK_CLIENT_SECRET" -H "Content-Type: application/x-www-form-urlencoded" -X POST $KEYCLOAK_ENDPOINT/realms/master/protocol/openid-connect/token | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Create realm
var=$(curl -d @realm.json -H "Expect:" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST $KEYCLOAK_ENDPOINT/admin/realms)
if [ "$var" == "201" ]; then
    echo "Realm created";
else
    if [ "${var: -3}" == "409" ]; then
        echo "Realm exists";
    else
        echo "An error occurred during realm creation";
    fi
fi

# Create users
input="users.csv"
while IFS=',' read -r f1 f2 f3 f4 f5
do
var=$(curl -d "{ \"username\": \"$f1\", \"enabled\": true, \"emailVerified\": false, \"firstName\": \"$f4\", \"lastName\": \"$f3\", \"credentials\": [{ \"type\": \"password\", \"value\": \"$f2\", \"temporary\": false }] }" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST  $KEYCLOAK_ENDPOINT/admin/realms/$KEYCLOAK_REALM/users)
if [ "$var" == "201" ]; then
    echo "User $f1 created in $KEYCLOAK_REALM realm";
else
if [ "${var: -3}" == "409" ]; then
    echo "User $f1 exists in $KEYCLOAK_REALM realm";
else
    echo "An error occurred during user creation";
fi
fi
done < "$input"

# Assign users to roles
users="user2role.csv"
while IFS=',' read -r f1 f2 f3
do
userId=$(curl -H "Authorization: Bearer $TOKEN" -sL -X GET  $KEYCLOAK_ENDPOINT/admin/realms/$KEYCLOAK_REALM/users?username=$f1 | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
status=$(curl -d "[{\"id\": \"$f3\", \"name\": \"$f2\"}]" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -sL -w "%{http_code}\\n" -X POST $KEYCLOAK_ENDPOINT/admin/realms/$KEYCLOAK_REALM/users/$userId/role-mappings/realm)
# echo "userId=$userId f1=$f1 f2=$f2 f3=$f3 status=$status"
if [ "$status" == "204" ]; then
    echo "Role $f2 assigned to user $f1 in $KEYCLOAK_REALM realm";
else
    echo "An error occurred during assignment role to user $status";
fi


done < "$users"

# Create clientA
var=$(curl -d @clientA.json -H "Expect:" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST $KEYCLOAK_ENDPOINT/admin/realms/$KEYCLOAK_REALM/clients)
if [ "$var" == "201" ]; then
    echo "ClientA created in $KEYCLOAK_REALM realm";
else
    if [ "${var: -3}" == "409" ]; then
        echo "ClientA exists in $KEYCLOAK_REALM realm";
    else
        echo "An error occurred during client creation";
    fi
fi

# Create clientB
var=$(curl -d @clientB.json -H "Expect:" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -sL -w "%{http_code}\\n" -X POST $KEYCLOAK_ENDPOINT/admin/realms/$KEYCLOAK_REALM/clients)
if [ "$var" == "201" ]; then
    echo "ClientB created in $KEYCLOAK_REALM realm";
else
    if [ "${var: -3}" == "409" ]; then
        echo "ClientB exists in $KEYCLOAK_REALM realm";
    else
        echo "An error occurred during client creation";
    fi
fi