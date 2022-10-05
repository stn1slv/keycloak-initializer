# keycloak-initializer

This is a simple container which creates two clients and five users in KeyCloak.

## How to run

```
docker run --rm -it -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin -e KEYCLOAK_ENDPOINT=http://keycloak:8080/
        -e KEYCLOAK_REALM=registry stn1slv/keycloak-dev-data
```
