---
title: Login
index: 100
icon: user.gif
---

Before you can log in to Clarive, your Clarive Administrator must add you as a User of Clarive.
Your Clarive Administrator will then notify you of your login information consisting of:

- **Username**

The username is not case-sensitive.

- **Password**

The password is always case-sensitive.

You can easily change your password from your user preferences page.

**Note**: Typically, Administrators will disable your password changing privileges
when single sign on or LDAP/SAML authentication is enabled.

### External Login

If you wish to log into Clarive directly from your company portal,
or from another web page that is external to Clarive, you may use this
HTML code as a template to create your login form:

<textarea style="height: 250px; width: 90%">
    &lt;form action="https://clariveserver:port/login" method="POST"&gt;
    &lt;table border="0" cellspacing="5" cellpadding="5"&gt;
    &lt;tr&gt;
    &lt;td&gt;User Name:&lt;/td&gt;
    &lt;td&gt;&lt;input type="text" name="username"/&gt;&lt;/td&gt;
    &lt;/tr&gt;
    &lt;tr&gt;
    &lt;td&gt;Password:&lt;/td&gt;
    &lt;td&gt;&lt;input type="password" name="password"/&gt;&lt;/td&gt;
    &lt;/tr&gt;
    &lt;tr&gt;
    &lt;td colspan="2"&gt;&lt;input type="submit"/&gt;&lt;/td&gt;
    &lt;/tr&gt;
    &lt;/table&gt;
    &lt;/form&gt;
</textarea>
