---
title: Login
index: 4000
icon: user
---

Antes de poder acceder a la herramienta, el Administrador de Clarive debe de
registrar al usuario desde la [Administración de usuarios](admin/user). El
administrador tiene que suministrar al usuario la siguiente información:

- **Usuario** - El usuario creado dentro de la herramienta y con el que tendrá acceso a Clarive.
- **Contraseña** - Contraseña generada por el administrador. Sensible a mayúsculas/minúsculas.

El usuario podrá modificar la contraseña desde las preferencias de usuario.

**Nota**: Por lo general, los administradores deshabilitan los privilegios de poder
cambiar la contraseña cuando se trata de un inicio único de sesión o la autenticación
 LDAP / SAML está habilitada.

### Login externo

Si se quiere realizar el login a Clarive directamente desde otra ubicación (portal web
por ejemplo), se puede utilizar este código HTML como plantilla para crear el formulario:

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
