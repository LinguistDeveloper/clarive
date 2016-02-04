---
title: Mensajes del sistema
icon: sms
---

* Los mensajes del sistema son notificaciones globales que se publican a todos los usuarios registrados en Clarive.
* Son útiles para notificar a los usuarios eventos como puedan ser una inoperatividad del sistema a causa de mantenimiento, un cambio de comportamiento o un aviso de mejora en el ciclo de vida.
* Se puede acceder a los mensajes del sistema a través del menú de Administración → <img src="/static/images/icons/sms.gif" /> Mensajes de sistema.


<br />
## Columnas

<br />
#### ID
* Muestra el identificador único del mensaje creado.

<br />
#### Mensaje
* Muestra el mensaje que se ha emitido.

<br />
#### Fecha de caducidad
* Aparece la fecha en la que el mensaje desaparecerá. Se configura dentro del mensaje.

<br />
#### Leído
* Una vez el mensaje se ha publicado, los mensajes pueden ser leídos por parte de los usuarios. 
* Los mensajes leídos por parte de un único usuario se contabilizarán en esta columna, es decir, si un usuario lee el mensaje dos o más veces, se contabilizará unicamente una. 
* Pulsando en el valor de la columna, se abre la lista de usuarios que han leído y descartado el mensaje. Al ser un mensaje intrusivo, que limita el acceso al menú superior se espera que los usuarios, una vez leído el mensaje, lo cierre. <br />

<br />
## Opciones

<br />
### <img src="/static/images/icons/edit.gif" /> Componer
* Para crear una nueva alerta, hay que componer el mensaje que se emitirá. Para ello, hay que completar los siguientes campos: <br />

&nbsp; &nbsp;• **Título**: El título del mensaje aparecerá en la barra superior. es recomendable que sea breve como 'Nueva release 5.X.X' o 'Mantenimiento planificado'.  <br />

&nbsp; &nbsp;• **Texto**: Permite especificar más el mensaje a emitir. También aparecerá en la parte superior de la ventana. <br />

&nbsp; &nbsp;• **Caducidad**: Establece la duración del mensaje. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `H` - Indica la duración en horas que durará la difusión del aviso: *2H*. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `m` - Indica la duración en minutos: *20m*. <br />

&nbsp; &nbsp;&nbsp; &nbsp;• `D` - Indica el número de días que durará el aviso del sistema: *1D*. <br />

&nbsp; &nbsp;• **Usuario**: Permite enviar el aviso a un único usuario. Puede ser usado para enviar un mensaje rápido a un usuario que está dentro de la herramienta. <br />

&nbsp; &nbsp;• **Más Información**: *Campo Opcional*. Campo válido para escribir un texto mas concreto en relación con el aviso. Este campo acepta imágenes, enlaces, etc..para poder explicar mas detalladamente el aviso lanzado. <br />
<br />

* Para publicarlo, pulsar `Publicar` en la parte superior derecha de la ventana. El aviso se emitirá de inmediato.

<br />
#### <img src="/static/images/icons/copy.gif" /> Clonar
* Permite clonar el mensaje seleccionado haciendo más rápida la difusión de un nuevo aviso. 

<br />
#### <img src="/static/images/icons/delete_.png" /> Borrar
* Elimina el mensaje. La difusión del mismo también pararía.

<br />
#### <img src="/static/images/icons/close.png" /> Cancelar
* Cierra la ventana de mensajes del sistema.

<br />
## Probar un mensaje
* Para probar un mensaje antes de hacerlo publico, se recomienda poner al propio usuario como único destinario del aviso. De esta manera, en caso de que se quiera hacer algún cambio se podrá realizar sin que afecte al resto de usuarios. 
* Una vez que esté listo, pulsar en `Clonar` y cambiar los receptores del aviso.