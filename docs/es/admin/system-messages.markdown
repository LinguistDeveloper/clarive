---
title: Mensajes del sistema
index: 5000
icon: sms
---

Los mensajes del sistema son notificaciones globales
que se publican a todos los usuarios registrados en Clarive.

Son útiles para notificar a los usuarios eventos como puedan
ser una inoperatividad del sistema a causa de mantenimiento,
un cambio de comportamiento o un aviso de mejora en el ciclo de vida.

### Comportamiento de la mensajería

La campaña de mensajería comienza una vez que el mensaje es
publicado. Los mensajes que se van leyendo pueden ser vistos
por los administradores de los mensajes en la columna `Leídos,
que indica cuantos usuarios únicos han visto el mensaje

Haciendo clic en `Leido(s)` se abre la lista de usuarios
que han desestimado el mensaje. Como el mensaje es molesto
para los usuarios, ya que limita el acceso a la barra de menú
de la parte superior, búsqueda y otras funciones, se espera
que los usuarios desestimen los mensajes cerrándolos.

### <img src="/static/images/icons/edit.svg" /> Crear un mensaje nuevo

Entrar en la opción `Mensajes del sistema` del menú de administración.
Se abrirá una ventana con la lista de los mensajes actuales y los antiguos.

Seleccione `Componer` para crear un nuevo mensaje.

- **Título** - El título del mensaje se muestra en la barra superior. Déjelo corto, como "Nuevo consejo para la release" o "Mantenimiento Programado.
- **Texto** - El mensaje largo se muestra en la barra superior. El título, de hecho, el título puede ser largo, 130 caracteres es aceptable.
- **Expira** - Cuando el mensaje parará de mostrarse a los usuarios. Sigue el formato (1H - 1 hora, 1D - un día...).
- **Usuarios** - Mensaje dirigido a un usuario dado. Esto puede ser usado para mostrar un mensaje a un usuario que está logueado. El campo vacío significa que todos los usuarios recibirán el mensaje.
- **Más Información** - *Opcional*. Un cuerpo del mensaje largo, con el contenido detallado. Este área de texto acepta incluso imágenes, donde se puede explicar el nuevo comportamiento o números de teléfono a los que llamar, etc.

Pulsar en `Publicar` para distribuir el mensaje inmediatamente.

### Probar un nuevo mensajes

Para probar un mensaje antes de hacerlo publico,
se recomienda poner al propio usuario como
único destinatario del aviso

Si el mensaje está correcto, simplemente, clónalo
y re-publicalo a más usuarios

### Parar el envío de mensajes

Simplemente `Borra` un mensaje de la lista.

### Clonar un mensaje existente

Permite clonar un mensaje anterior, haciendo más
sencillo crear una nueva campaña de mensajería basada
en una anterior.