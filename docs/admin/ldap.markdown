---
title: LDAP Authentication
---

## Setup

* To setup the LDAP authentication mechanism access to Clarive environment
configuration files is necessary. 

* Under the key `baseliner: authentication: ldap:` we configure the LDAP binding credentials and server information:
            
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


<br />

* Some of the fields that are required: <br />

&nbsp; &nbsp;• `binddn` - Cointains the userid and its domain namespace.  <br />
&nbsp; &nbsp;• `bindpw` - The password <br />
&nbsp; &nbsp;• `ldap-server` - The IP of the LDAP server <br />
&nbsp; &nbsp;• `user_basedn` - The domain namespace where the user names are found. <br />
&nbsp; &nbsp;• `user_field` - The LDAP field that cointains the user <br />
&nbsp; &nbsp;• `user_filter` - Used to parse the uid from the LDAP information
