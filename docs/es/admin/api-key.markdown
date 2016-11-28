---
title: Claves API
index: 5000
icon: lock
---

Las clave API permite al usuario a acceder a sus datos de la cuenta de Clarive sin necesidad de utilizar el nombre y la contraseña. Sin embargo, cualquier aplicación que use la clave API tendrá acceso a la misma información que accediendo a la herramienta utilizando el usuario y contraseña.

Las claves API no requieren una licencia adicional porque es una extensión de la licencia de Clarive que posee el usuario.

Las claves son *strings* que acreditan al usuario cuando accede a los servicios web de Clarive. Sin embargo, a diferencia de una sesión normal, la clave API no caduca.

Las claves son válidas siempre y cuando el usuario lo desee, pueden ser borradas o reseteadas.

Los administradores pueden ver, eliminar y resetar las claves de cualquier usuario desde la página de Claves API.

<p class="help-note">
<b>Nota</b> Si las claves están deshabilitadas en la instalación, a un usuario que esté intentando configurar una nueva clave o editando la existente se le notificará con un mensaje de error indicando que están deshabilitadas y que contacte con el administrador para habilitar dicha funcionalidad.
</p>

### Crear nueva clave
Para crear una nueva clave, el usuario tiene que acceder a sus [preferencias](getting-started/prefs) o, en caso de ser administrador a través de las preferencias del usuario, opción situada en Administración - <img src="/static/images/icons/user.svg" /> Usuarios.

Una vez en la pestaña `API` hay que pulsar el botón `Generar clave API` o insertar una en el cuadro superior. La clave se guarda de manera automática.