---
title: Login
index: 4000
icon: user
---

Before you can log in to Clarive, your [Clarive Administrator](admin/user) must
add you as a User of Clarive. Your Clarive Administrator will then notify you of
your login information consisting of:

- **Username**: The username is not case-sensitive.
- **Password**: The password is always case-sensitive.

You can easily change your password from your user preferences page.

**Note**: Typically, Administrators will disable your password changing privileges
when single sign on or LDAP/SAML authentication is enabled.

### External Login

If you wish to log into Clarive directly from your company portal,
or from another web page that is external to Clarive, you may use this
HTML code as a template to create your login form::

```html
<textarea style="height: 250px; width: 90%">
    <form action="https://clariveserver:port/login" method="POST">
        <table border="0" cellspacing="5" cellpadding="5">
            <tr>
                <td>User Name:</td>
                <td>
                    <input type="text" name="username" />
                </td>
            </tr>
            <tr>
                <td>Password:</td>
                <td>
                    <input type="password" name="password" />
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <input type="submit" />
                </td>
            </tr>
        </table>
    </form>
</textarea>
```
