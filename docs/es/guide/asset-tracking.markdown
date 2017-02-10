---
title: Seguimiento de recursos y despliegues de elementos
index: 2000
---

El seguimiento de recursos es una característica de envío de archivos de Clarive 
que comprueba si el archivo que se aloja actualmente en el servidor es el mismo 
archivo que es enviado por Clarive.

Existen 3 diferentes casos de uso en Clarive donde se puede activar esta auditoría.

### Sobrescribir el sistema de seguridad

Antes de desplegar un elemento que sobrescribirá a otro elemento, compruebe 
si la versión del elemento que vamos a sobrescribir es la versión 
actual que Clarive ha podido desplegar en un pase anterior.

La razón de esto es asegurarse de que no hay elementos no intencionados 
(modificados externamente debido a posibles razones legítimas excepcionales) se 
sobrescriben de manera silenciosa por un despliegue de una aplicación iniciado 
por Clarive.

### Auditando los recursos

Se trata de una auditoría programada (cada noche, cada X horas, etc.) o 
activada manualmente a través un trigger y ejecutada por Clarive para determinados 
entornos o aplicaciones.

Cualquier conflicto o caso dudoso detectado por esta auditoria puede desencadenar 
diversos eventos como enviar un e-mail o cualquier otra operación disponibles 
en Clarive.


### Auditoria manual

Para la gestión de seguimiento de recursos es necesaria la petición de un 
usuario. Esto puede hacerse a través del menú de acciones de los CIs y 
seleccionar la acción `Verificar recurso` en el elemento seleccionado.


## Activar el seguimiento de recursos

### Método de verificación de archivos

Los archivos se verifican en el *nodo destino* utilizando uno de los dos 
métodos, si la conexión es a través de un agente (o sin agente).

- Checksum (MD5) de archivos.
- Fecha y tamaño del archivo

El primer método requiere que el agente o el *nodo destino* soporte operaciones 
de *checksum*. Esto no está disponible para nodos basados en SSH (sin agentes).

En cualquier caso, la combinación tamaño del fichero con la fecha del fichero 
será utilizada para identificar el elemento desplegado. El método de verificación 
posterior no es tan seguro y puedo crear falsos positivos (por ejemplo, Clarive 
piensa que el elemento está bien pero en realidad no tiene porque ser así), aunque 
la probabilidad es alta (99,9%) para casi todos los tipos de elementos, el tamaño 
del fichero y la fecha es un buen indicador de que el elemento es el correcto.
