---
title: Login
index: 30
icon: user.gif
---
* Antes de poder acceder a la herramienta, el Administrador de Clarive debe de registrar al usuario desde la [Administración de usuarios](Administracion/user)
* El administrador tiene que suministrar al usuario la siguiente información: <br />

&nbsp; &nbsp;• **Usuario** – El usuario creado dentro de la herramienta y con el que tendrá acceso a Clarive. <br />

&nbsp; &nbsp;• **Contraseña** – Contraseña generada por el administrador. Sensible a mayúsculas/minúsculas. <br />

&nbsp;* *El usuario podrá modificar la contraseña desde las preferencias de usuario.* <br />

**Nota**: Por lo general, los administradores deshabilitan los privilegios de poder cambiar la contraseña cuando se trata de un inicio único de sesión o la autenticación LDAP / SAML está habilitada.


<br />
### Login externo
* Si se quiere realizar el login a Clarive directamente desde otra ubicación (portal web por ejemplo), se puede utilizar este código HTML como plantilla para crear el formulario:

<br />
<textarea style="height: 250px; width: 90%">
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
