---
title: Autentificación LDAP
index: 5000
icon: users
---

La autenticación LDAP es el mecanismo que permite
los usuarios autentificarse en Clarive, al comprobar su
contraseñas contra una base de datos LDAP.

La ventaja de utilizar la autenticación LDAP es que
contraseñas no necesitan ser almacenadas en Clarive, 
puesto que están centralizadas en un servidor LDAP.

## Configuración
Para el acceso a los archivos de configuración del entorno 
Clarive es necesario configurar el mecanismo de autenticación LDAP

Bajo la variable `baseliner: authentication: ldap:` se configuran las credenciales LDAP y la información del servidor:

```yaml
    baseliner:
    authentication:
        ldap:
            credential:
              class: Password
              password_field: password
              password_type: self_check
            store:
              binddn: uid=<ldap-user-id>,ou=XXXXX,o=XXXXXX
              bindpw: <bind-password>
              ldap_server: <server-ip>
              ldap_server_options:
                port: 1389
                timeout: 30
              use_roles: 0
              user_basedn: ou=XXXXXXXXXX,ou=XXXXXXXXXX,o=XXXXXXX,o=XXXXXXX
              user_field: uid
              user_filter: (&(objectclass=person)(uid=%s))
```

Algunos de los campos necesarios son:

- `binddn` - Contiene el *userid* y el *namespace* del dominio.
- `bindpw` - La contraseña.
- `ldap-server` - La IP del servidor LDAP.
- `user_basedn` - El *namespace* del dominio cuando el usuario ha sido encontrado.
- `user_field` - El campo LDAP que contiene el nombre de usuario
- `user_filter` - Se utiliza para parsear el uid.
