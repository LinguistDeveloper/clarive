---
title: Clave API
icon: lock_small
---
* Una clave API es un código único que puede ser usado desde aplicaciones externas para identificar a un usuario existente en la herramienta y acceder a toda la funcionalidad de Clarive.
* Estas claves son una alternativa al uso de los credenciales de acceso a la herramienta. A diferencia de estas ultimas, la clave API sirve para identificarse en Clarive sin hacer uso de contraseña.
* Es importarte almacenar la clave en un sitio seguro. Si ésta es robada, tendrán acceso a todos los datos del usuario dentro de Clarive.

### Uso
* Las claves API pueden ser utilizadas de dos maneras:
    Puede ser usada como un parámetro que llama a una URL de Clarive.
    Como alternativa a la contraseña de un usuario.

### Configuración de acceso global a través de la clave API

* Inicialmente, las claves API no pueden ser usadas para acceder a la herramienta a través la pantalla principal de login. En caso contrario, existe un parámetro en la configuración del sistema que sí permite el acceso a Clarive a través de la clave API. Esta variable hay que ponerla a '1':

            
        api_key_authentication: 1


     

### Mensajes de error
* ***api-key authentication is not enabled for this url***

Este mensaje de error indica que la URL a la que se intenta acceder no permite el acceso a través de claves API. De manera alternativa es posible crear una regla de tipo [webservice](concepts/webservice) o habilitar el acceso global a través de claves API.

