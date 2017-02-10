---
title: Entrega de aplicaciones móviles
index: 4000
---

Clarive soporta despliegues tanto a la Apple App Store como a la tienda Google
Play Store utilizando sus APIs correspondientes y la herramienta de
librería/linea de comandos llamada **fastlane**, la cual se incluye dentro del
plugin de Clarive *mobile*.

### Publicar una app en la tienda

Publicar una app en una tienda móvil, como las de Apple o Google, implica unos
pasos los cuales han de ser muy bien planificados antes de implementarlos.

- Mantenimiento del perfil en la tienda.
- Firma del código de la aplicación con certificados.
- Mantenimiento de perfiles de notificación push.
- Crear capturas de pantalla de la aplicación.
- Compilar, probar e implementar la aplicación.

### Firma y mantenimiento de certificados

Tiene que planificar ejecutar el paso `PRE` que será donde se firma el código
utilizando los CIs de certificados correspondientes a través de una regla.


### Acceso a la tienda

Para cada tienda, desde Clarive recomendamos utilizar diferentes set de
librerias que se deben instalar por separado en el servidor Clarive.


#### Apple Store

La feature de Clarive App Store se basa en la biblioteca *spaceship*.

**spaceship** expone tanto el Centro de desarrolladores de Apple como el API de
iTunes Connect.

Esta potente y rápida API potencia partes de Clarive, y puede ser aprovechada
para caracteristicas de Clarive más avanzadas.

`https://idmsa.apple.com`

- Se utiliza para autenticarse y obtener una sesión válida.

`https://developerservices2.apple.com`

- Obtenga una lista detallada de todos los perfiles de aprovisionamiento
  disponibles.
- Esta API devuelve los dispositivos, certificados y aplicaciones para cada uno
  de los perfiles.
- Registrar nuevos dispositivos.

`https://developer.apple.com`

- Lista de todos los dispositivos, certificados, aplicaciones y grupos de
  aplicaciones.
- Crear nuevos certificados, perfiles de aprovisionamiento y aplicaciones
- Deshabilitar/habilitar servicios en aplicaciones y asignarlos a grupos de
  aplicaciones
- Eliminar certificados y aplicaciones
- Reparar perfiles de aprovisionamiento
- Descargar perfiles de aprovisionamiento
- Selección de equipos

`https://itunesconnect.apple.com`

- Administración de aplicaciones
- Gestión de probadores beta
- Enviar actualizaciones para revisar
- Gestión de metadatos de las aplicaciones

`https://du-itc.itunesconnect.apple.com`

- Cargar iconos, capturas de pantalla, trailers ...

#### Google Play Store

Clarive también admite los despliegues a Google Play Store.

El programa de instalación consiste en configurar su cuenta en el servicio de
Google Developers:

- Abrir la consola Google Play
- Seleccione la pestaña Configuración y a continuación la pestaña de acceso a
  la API.
- Click en el botón Crear cuenta de servicio y después siga el enlace Google
  Developers Console.
- Haga click en Crear Credenciales y seleccione cuenta de servicio.
- Seleccione JSON como tipo de clave y haga click en Crear.
- Anote el nombre del fichero JSON descargado y cierre el cuadro de diálogo.
- De vuelta a la consola del desarrollador de Google Play, haga click en Listo.
-  Haga click en *Grant access* para la nueva cuenta de servicio.
- Seleccione Manager de Release en el menú de Roles y haga click en Enviar
  invitación para cerrar el cuadro de diálogo.
