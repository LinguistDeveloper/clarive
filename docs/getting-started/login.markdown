---
title: Login
---

Before you can log in to Clarive, your Clarive Administrator must add you as a User of Clarive. 
Your Clarive Administrator will then notify you of your login information consisting of:

- Username – The Username is in email address format, and is not case-sensitive.
- Password – The Password is case-sensitive.

You can easily change your password from your user preferences page.

**Note**: typically, Administrators will disable your password changing priviledges 
when single signon or LDAP/SAML authentication is enabled. 

## External Login 

If you wish to log into Clarive directly from your company portal, 
or from another web page that is external to Clarive, you may use this 
HTML code as a template to create your login form:

<textarea style="height: 250px; width: 100%">
    &lt;form action="https://clariveserver:port/login" method="POST"&gt;<br />
    &lt;table border="0" cellspacing="5" cellpadding="5"&gt;<br />
    &lt;tr&gt;<br />
    &lt;td&gt;User Name:&lt;/td&gt;<br />
    &lt;td&gt;&lt;input type="text" name="username"/&gt;&lt;/td&gt;<br />
    &lt;/tr&gt;<br />
    &lt;tr&gt;<br />
    &lt;td&gt;Password:&lt;/td&gt;<br />
    &lt;td&gt;&lt;input type="password" name="password"/&gt;&lt;/td&gt;<br />
    &lt;/tr&gt;<br />
    &lt;tr&gt;<br />
    &lt;td colspan="2"&gt;&lt;input type="submit"/&gt;&lt;/td&gt;<br />
    &lt;/tr&gt;<br />
    &lt;/table&gt;<br />
    &lt;/form&gt;
</textarea>
