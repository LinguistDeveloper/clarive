---
title: LDAP Authentication
index: 5000
icon: users
---

LDAP authentication is the mechanism that allows
users to authenticate into Clarive by checking their
passwords against an LDAP database.

The advantage of using LDAP authentication is that
passwords do not need to be stored in Clarive, but are rather
centrally in an LDAP server.

## Setup

Access to Clarive environment configuration files is necessary
in order to setup the LDAP authentication mechanism

Under the key `baseliner: authentication: ldap:`
we configure the LDAP binding credentials and server information:

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

Some of the fields that are required:

- `binddn` - Cointains the userid and its domain namespace.
- `bindpw` - The password
- `ldap-server` - The IP of the LDAP server
- `user_basedn` - The domain namespace where the user names are found.
- `user_field` - The LDAP field that cointains the user
- `user_filter` - Used to parse the uid from the LDAP information
