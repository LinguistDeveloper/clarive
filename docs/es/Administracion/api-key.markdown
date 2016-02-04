---
title: Claves API 
icon: lock_small
---
* Las clave API permite al usuario a acceder a sus datos de la cuenta de Clarive sin necesidad de utilizar el nombre y la contraseña. Sin embargo, cualquier aplicación que use la clave API se tendrá acceso a la misma información que habiendo accedido utilizando el usuario/contraseña.
* Las claves API no requieren una licencia de Clarive adicional porque es una extension de la licencia que posee el usuario.
* Las claves son strings que autentifican al usuario cuando accede a los servicios web de Clarive. Sin embargo, a diferencia de una sesion normal, la clave API no caduca. 
* Las claves son válidas siempre y cuando el usuario lo desee, pudiendo ser borradas o reestablecidas.
* Los administradores pueden ver, eliminar y resetar todas las claves desde la página de Claves API.


<br />
<p class="help-note">
<b>Nota</b> Si las claves están deshabilitadas en la instalación, a un usuario que esté intentando configurar una nueva clave o editar la existente se le notificará con un mensaje de error indicando que están deshabilitadas y que contacte con el administrador para habilitar dicha funcionalidad.
</p>

<br />
### Crear nueva clave
* Para crear una nueva clave, el usuario tiene que acceder a sus [preferencias](Primeros_pasos/prefs) o, en caso de ser administrador a través de las preferencias del usuario, opción situada en Administración → <img src="/static/images/icons/user.gif" /> Usuarios.
* Una vez en la pestaña `API` hay que pulsar el botón `Generar clave API` o insertar una en el cuadro superior. Por último, es necesario guardar la clave.

