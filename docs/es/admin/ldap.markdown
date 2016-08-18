---
title: Autentificacion LDAP
---

## Configuración
* Para configurar el mecanismo que permita acceder al entorno de Clarive a través de un sistema LDAP, es necesario modificar algunos ficheros de configuración.

Bajo la variable `baseliner: authentication: ldap:` se configuran las credenciales LDAP y la información del servidor:

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



* Algunos de los campos necesarios son:
    `binddn` - Contiene el userid y el namespace del dominio.
    `bindpw` - La contraseña.
    `ldap-server` - La IP del servidor LDAP.
    `user_basedn` - El namespace del dominio cuando el usuario ha sido encontrado.
    `user_field` - El campo LDAP que contiene el nombre de usuario
    `user_filter` - Se utiliza para parsear el uid.