---
title: MongoDB
index: 250
icon: page
---

## Recomendaciones

Como se destaca en el documento acerca de [arquitectura
de especificaciones técnicas](setup/specs), se recomienda
que MongoDB sea instalado en una
máquina separada de la del servidor de Clarive, eso ayuda a mejorar el rendimiento general y compartir mejor los recursos disponibles entre las máquinas

## Instalación

Los pasos necesarios para la instalación de MongoDB son:

- Descargar el fichero para su Sistema Operativo.
- Descomprimir los ficheros y dejarlos en la ubicación definitiva.
- Edite los ficheros de configuración.
- Arranque la base de datos

### Descarga

Primero, descargue los binarios de la instalación de MongoDB para su sistema operativo desde los siguientes enlaces:

#### Windows

- [Windows 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-3.2.4-signed.msi)

#### Mac OS X

- [Mac OS X <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-3.2.4.tgz)

#### Linux

- [RHEL 5 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel55-3.2.4.tgz)
- [RHEL 6 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.2.4.tgz)
- [RHEL 7 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.4.tgz)
- [SUSE 11 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-suse11-3.2.4.tgz)
- [SUSE 12 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-suse12-3.2.4.tgz)
- [Debian 7 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian71-3.2.4.tgz)
- [Ubuntu 12.04 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1204-3.2.4.tgz)
- [Ubuntu 14.04 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1404-3.2.4.tgz)
- [Ubuntu 14.04 Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1404-3.2.4.tgz)
- [Ubuntu 14.10 Clang 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1410-clang-3.2.4.tgz)
- [Legacy Linux 64-bit <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.2.4.tgz)

## Configuración del servidor Mongo

Para configurar MongoDB, es necesario editar el fichero `mongod.conf` ubicado en su directorio `CLARIVE_BASE/config`.


Este archivo contiene la configuración estándar del producto,
por favor no cambiar ningún parámetro que no se mencionan en este
documentación, que puede anular su contrato de servicio / mantenimiento
o menos que sea solicitado por su representante de asistencia Clarive.


Este fichero contiene la configuración estándar del producto. Por favor, no cambie ningún parámetro no mencionado en esta documentación, puede anular su contrato de servicio/mantenimiento a menos que sea solicitado por su representante de asistencia Clarive.

Contenido del fichero `mongod.conf`:

```yaml
dbpath=/opt/clarive/data/mongo
logpath=/opt/clarive/logs/mongod.log
pidfilepath=/opt/clarive/logs/mongod.pid
fork=true
bindIp=127.0.0.1
port=27017
logappend=true
setParameter=failIndexKeyTooLong=false
storageEngine=wiredTiger
```

### `bindIp`

Esta es la dirección IP del demonio de la base de datos MongoDB
desde el que escucha las conexiones entrantes. Si esto es una instancia de MongoDB
que, por ejemplo, se ha instalado para uso exclusivo con Clarive, entonces:

- **No  vincule** a direcciones IP que son accesibles por su red corporativa o por Internet! Si es posible, elija una dirección IP que solo esté disponible a nivel de cluster.
- Configure un firewall que limite el acceso al servidor Mongo


### `port`

El puerto es el puerto de red del demonio de la base de datos Mongo donde escucha las conexiones del servidor Clarive.

Recuerde que si cambia aquí el puerto, necesita modificar el puerto en el fichero de configuración del servidor de Clarive.


### `dbpath`

Esta es la ruta de acceso al directorio donde se ubicarán
los archivos de base de datos Mongo.

Los archivos de este directorio requerirán mucho espacio en disco a medida que Clarive crezca en uso. El uso de disco y el tamaño de los archivos, dependerá en gran medida del uso del sistema, el número de *jobs*, artefactos
generados y otros factores, pero es posible que llegue a muchos GB rápidamente.

Por favor, planifique en consecuencia, la falta de espacio en el disco de base de datos puede **interrumpir el servicio Servidor Clarive y podría causar graves
pérdida de datos**.

Por defecto, este valor se establece en `CLARIVE_BASE/data/mongo`.

### `logpath`

Esta es la ruta de acceso al directorio donde se almacenan los logs de Mongo.

Planifique las necesidades de espacio, por lo general, alrededor de 1 GB.


### `pidfilepath`

Ruta al archivo que indica si la base de datos está inicializada o no.

Puede cambiar esta ruta a cualquier ubicación en el servidor para adecuarse a las necesidades de instalación, pero se recomienda establecerla en los directorios `DECLARATIVE_BASE/logs/` o `CLARIVE_HOME/data/`.

## Configuración de Clarive y Mongo

Aquí se describe el fichero `[env] archivo .yaml` de Clarive donde se controla la conexión de Clarive con MongoDB

```yaml
mongo:
    dbname: acmebank
    retry_frequency: 5
    max_retries: 60
    client:
        host: 'localhost:27017'
        username: myuser
        password: mypassword
        auto_reconnect: 1
        query_timeout: -1
        #auto_connect: 1
        #host: 'mongodb://localhost:27017,localhost2:27018'
        #w
        #wtimeout
        #j
        #timeout: 20000
        #db_name
        #max_bson_size
        #find_master: 1
        #ssl
        #sasl
        #sasl_mechanism
        #dt_type
        #inflate_dbrefs: 1
```

Opciones:

#### `dbname`

El nombre de la base de datos

#### `host`

Especifica un único servidor para conectarse (bien como <nombre de host>
o <nombre de host: puerto>), o bien una cadena de conexión URI con una lista de nodos de uno o mas servidores más las opciones de conexión.

Por defecto, la conexión URI es mongodb://localhost: 27017.

#### `auth_mechanism`

Este atributo determina como los clientes se autentifican con el servidor. Los valores válidos son:

    NONE
    DEFAULT
    MONGODB-CR
    MONGODB-X509
    GSSAPI
    PLAIN
    SCRAM-SHA-1



Si no se especifica, no se proporciona ningún nombre de usuario se vuelve por defecto a NONE. Si se proporciona un nombre de usuario, se configurará como DEFAULT, que elige SCRAM-SHA-1 si está disponible o MONGODB-CR en caso contrario.

Esto se puede establecer en la cadena de conexión con la opción AuthMechanism.


#### `auth_mechanism_properties`

Esta es una referencia hash opcional sobre las propiedades de un mecanismo de identificación específico. Consulte "Autenticación" para más detalles.


Se puede establecer en una cadena de conexión con la opción authMechanismProperties.
Si se les da, el valor debe ser pares clave/valor unidas con un ":". Los pares múltiples
deben estar separados por una coma. Si ": o "," aparece en una clave o valor, deben
URL codificadas.


#### `connect_timeout_ms`

Especifica, en milisegundos, el tiempo máximo de espera para una nueva conexión al servidor

Por defecto es 10.000 ms.

Si se establece un valor negativo, las operaciones de conexión se bloquearán de manera indefinida hasta que el servidor responda o hasta que el sistema TCP/IP se dé por vencido (por ejemplo si no se puede resolver el nombre o si no hay un proceso de escucha
host/puerto).

Un valor cero sondea el socket durante la conexión y por lo tanto es probable que falle,
excepto cuando se trate de un proceso local (y aún así).

Esto se puede establecer en una cadena de conexión con la opción connectTimeoutMS.

#### `db_name`

Opcional. Si *auth_mechanism* requiere una base de datos para la autenticación, este atributo será utilizado se utilizará atributo. De lo contrario, se ignorará. Por defecto es "admin".

Este se puede proporcionar en la cadena de conexión URI como una ruta entre el
autorizado y opción de parámetros. Por ejemplo, para la autenticación en
la base de datos "admin" (se muestra una opción de configuración de ejemplo):

    mongodb://localhost/admin?readPreference=primary

#### `heartbeat_frequency_ms`

El timpo en milisegundos (no negativos) entre e

El tiempo en milisegundos (no negativos) entre llamadas a todos los servidores para comprobar si están activos y actualizar su latencia. El valor predeterminado es 60.000 ms.


Esto se puede establecer la cadena de conexión con la opción *heartbeatFrequencyMS*.

#### `j`

Si está a *true*, el cliente se bloqueará hasta que las operaciones de escritura se hayan realizado y publicados en el log del servidor. Antes de MongoDB 2.6, esta opción se ignoraba si el servidor se estaba ejecutando sin registrar la actividad. A partir de Mongo 2.6, las operaciones de escritura fallarán si se usa esta opción cuando el servidor se está ejecutando sin registrar la actividad.

Esto se puede establecer en la cadena de conexión con la opción de avisos como strings
'true' o 'false'.


#### `local_threshold_ms`

La anchura de la 'ventana de latencia': a la hora de elegir entre múltiples servidores para una operación, el valor aceptable en milisegundos (no negativos)
entre el mínimo y el máximo promedio de los tiempos de ida y vuelta. Los servidores de la
ventana de latencia son seleccionados al azar.


Se establece a "0" para seleccionar siempre el servidor con el tiempo medio mas corto de respuesta. Ajuste este parámetro en un valor muy alto para elegir siempre al azar cualquier servidor conocido.

Por defecto se establece a 15 ms.

Esto se puede establecer en la cadena de conexión con la opción 'localThresholdMS'.


#### `max_time_ms`

Especifica en milisegundos el tiempo máximo que el servidor podrá ser  usado para tareas de comandos de la base da datos. El valor predeterminado es 0, lo cual
desactiva esta función. Asegúrese de que este valor es más corto que *socket_timeout_ms*

Nota: Esto sólo será utilizado para las versiones de servidores 2.6 o superior, ya que era cuando se introdujo el meta-operador *$maxTimeMS*.

Se recomienda configurar esta variable si conoce si su entorno tiene MongoDB 2.6 o superior, para evitar una respuesta de error desde el
servidor se recomienda que sea superior al timeout del socket de la red.

Esto se puede establecer desde la cadena de conexión con la opción 'maxTimeMS'.


#### `password`

Si un "auth_mechanism" requiere una contraseña, se utilizará este atributo.
De lo contrario, se ignorará.

Esto puede ser proporcionado por la cadena de conexión URI como un par nombre de usuario:contraseña en la sección delantera con un carácter @.
Por ejemplo, para autenticarse como usuario "mulder" con la contraseña "trustno1":

    mongodb://mulder:trustno1@localhost Si el nombre de usuario o contraseña contiene un ":" o "@", debe ser codificado en URL. Una contraseña vacia tambien requiero del carácter ":".

#### `port`

Si el puerto de red no se especifica como parte del atributo del host, este
parámetro especifica el puerto a utilizar. Su valor predeterminado es 27107.

#### `read_pref_mode`

El '`read_pref_mode' determina qué tipos de servidores son candidatos para una
operación de lectura. Los valores válidos son:

    primary
    primaryPreferred
    secondary
    secondaryPreferred
    nearest

Para más información acerca de esta propiedad, ver:
[http://docs.mongodb.org/manual/core/read-preference/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://docs.mongodb.org/manual/core/read-preference/)

Esto se puede establecer desde la cadena de conexión con la opción 'readPreference'.


#### `read_pref_tag_sets`

El parámetro *read_pref_tag_sets* es una lista ordenada de conjuntos de etiquetas que se usa para restringir la elección de servidores así como para el conocimiento del centro de datos. Debe ser una referencia a un array de referencias hash.

La aplicación de *read_pref_tag_sets* varía dependiendo de la propiedad *read_pref_mode*. Si el *read_pref_mode* es 'primary', entonces *read_pref_tag_sets* no se debe definir.

Para más información acerca de esta propiedad, ver:
[http://docs.mongodb.org/manual/core/read-preference/ <img class='ext-link' src='static/images/icons/new_window_link.svg' />](http://docs.mongodb.org/manual/core/read-preference/)

Esto se puede establecer en la cadena de conexión con la opción 'readPreferenceTags'. Si
viene dado, el valor debe ser pares clave/valor unidas con un ":". Para pares múltiples deben, éstos deben de estar separados por una coma.
Si ": o ",", aparecen en una clave o valor, deben estar
URL codificada. La opción 'readPreferenceTags' puede aparecer más de una vez, en este caso, cada documento se añadirá a la lista de etiquetas.

#### `replica_set_name`

Especifica el nombre del conjunto de réplicas para conectarse. Si esta cadena no está vacía, entonces
la topología es tratada como un conjunto de réplicas y todos los nombres del conjunto de réplicas del servidor debe
coincidir con este o sino serán retirados de la topología.

Esto se puede establecer en la cadena de conexión con la opción 'replicaSet'.

#### `server_selection_timeout_ms`

Este atributo especifica el tiempo, en milisegundos, de esperar a un
servidor adecuado disponible para una operación de lectura o escritura. Si no hay un servidor disponible dentro de este período de tiempo, se produce una excepción.

Por defecto este valor es 30,000 ms.

Esto se puede establecer en la cadena de conexión con la opción  'serverSelectionTimeoutMS'.

#### `server_selection_try_once`

Este atributo controla si el cliente hará un solo intento de
encontrar un servidor adecuado para una operación de lectura o escritura. El valor por defecto es *true*.

Cuando es *true*, el cliente no utilizará el 'server_selection_timeout_ms'. En cambio, si
la información de topología es incompleta y necesita ser comprobada, o si el
servidor adecuado no está disponible, el cliente deberá hacer una sola exploración de todos los servidores conocidos tratar de encontrar uno adecuado.

Cuando el valor es *false*, el cliente va escanea continuamente los servidores conocidos hasta que se encuentra un servidor adecuado o se alcanza el tiempo de espera definido en 'serverSelectionTimeoutMS'.

Esto se puede establecer en la cadena de conexión con la opción 'serverSelectionTryOnce'.

#### `socket_check_interval_ms`

Si el socket de un servidor no se ha utilizado en este número de milisegundos, el comando
*IsMaster* será lanzado para comprobar el estado del servidor antes de
emitir cualquier acción de lectura o escritura. No debe ser negativo.

Por defecto este valor es 5,000 ms.

Esto se puede establecer en la cadena de conexión con la opción 'socketCheckIntervalMS'.

#### `socket_timeout_ms`

Este atributo especifica la cantidad de tiempo en milisegundos para esperar una respuesta
desde el servidor antes de emitir una excepción a la red.

Por defecto este valor es 30,000 ms.

Si se establece en un valor negativo, las operaciones con sockets se bloquearán indefinidamente hasta que el servidor responda o hasta que la pila TCP/IP se de por vencido.

Un valor cero sondea el socket durante la conexión y por lo tanto es probable que falle,
excepto cuando se trate de un proceso local (y aún así).

Esto se puede establecer en la cadena de conexión con la opción 'socketTimeoutMS'.

#### `ssl`

Esto le indica al driver que se está conectando a una instancia MongoDB SSL.

Si no se proporciona el fichero *SSL_ca_file*, los certificados del servidor se verifican contra una
lista predeterminada de entidades de certificación, por ejemplo, el fichero CA que viene por defecto en los sistemas operativos. Para desactivar la verificación, se puede utilizar *SSL_verify_mode* => 0x00.

Se recomienda encarecidamente utilizar su propio archivo de CA para mayor seguridad.

Los nombres de host de servidor también se validan contra el nombre CN en el servido utilizando SSL_verifycn_scheme => 'http'. Es posible utilizar el esquema 'none' para deshabilitar esta comprobación.

Deshabilitar el certificado o la verificación es un riesgo de seguridad y no está recomendado.

Es posible establecer esta propiedad a *true* o *false* en la cadena de conexión con la opción 'ssl', que habilitará SSL con la configuración por defecto. (Una versión futura
del driver puede soportar la personalización de SSL a través de la cadena de conexión.)

#### `username`

El nombre de usuario es opcional para esta conexión de cliente. Si este campo se establece, el cliente se
intentará autenticar al conectarse a servidores. Dependiendo de
*auth_mechanism*, será necesario establecer el campo 'contraseña' u otros atributos
para que la autenticación se realice de manera correcta.

Esto puede ser establecerse en la cadena de conexión URI como par de nombre de usuario: contraseña en la parte delantera de la URI antes de un carácter @. por
ejemplo, para autenticarse como usuario "Mulder" con la contraseña "trustno1":

    mongodb://mulder:trustno1@localhost If the username or password have a ":"
    or "@" in it, they must be URL encoded. An empty password still requires a
    ":" character.

#### `w`

Describe la garantia con la que MongoDB ha realizado una escritura

- 0 *Unacknowledged*. El cliente Mongo NO esperará al mensaje de confirmación que ha recibido el servidor y procesa la petición. La documentación antigua se puede referir a esto como el modo "fire-and-forget". Esta opción no es recomendable.
- 1 *Acknowledged*. Opción por defecto. El cliente Mongo confirma que ha recibido la orden de escritura y que ha aplicado el cambio.
- 2 *Replica Acknowledged*. El cliente Mongo esperará hasta, al menos, que dos replicas (la principal y una secundaria) confirmen la escritura. Es posible establecer un número mayor para mayor replicación. En MongoDB v2.0+, es posible 'etiquetar' los miembros de la replica. Con este 'etiquetado' se puede especificar un asunto de escritura propio. Para más información visite *Data center awareness*

Esto se puede establecer en la cadena de conexión con la opción 'w'.


#### `wtimeout`

El número de milisegundos que una operación debe esperar a que los servidores 'w' confirmen la operación.

Por defecto, se establece en 1000 (1 segundo).

Consulte 'w' en el apartado anterior para más información.

Esto se puede establecer en la cadena de conexión con la opción 'wTimeoutMS'.

#### `read_concern_level`

El nivel de garantía determina el nivel de consistencia requerida

El nivel predeterminado es *undef*, lo que significa que el servidor utilizará su configuración por defecto.

Si el nivel se establece en 'local', las lecturas devuelven los últimos datos a un servidor local.

Los niveles adicionales son específicos del motor de almacenamiento.

Lea *Read concern* en la documentación de MongoDB para más detalles.

Esto se puede establecer en la cadena de conexión con la opción 'readConcernLevel'.


#### `query_timeout (EN DESUSO)`

Se establece en milisegundos y por defecto es 30000.

#### `timeout (EN DESUSO Y SOLO-LECTURA)`

Esta opción se ha renombrado a 'connect_timeout_ms'. Si la opción se establece, y la otra no, entonces será utilizada.

Valor en milisegundos. Por defecto se establece en 10000.

## Aviso de Soporte y Mantenimiento

MongoDB es soportado como parte del contrato de software Clarive. Los parches y cualquier otro servicio de asesoramiento de Mongo se distribuyen como cualquier otros parches al núcleo del servidor Clarive y de productos relacionados (como el agente ClaX) incluido en su acuerdo de servicio.

No realizados soporte para MongoDB que tengan acceso a la red exterior, como tener otros usuarios conectándose a la base de datos desde clientes de cualquier tipo.

El acceso a MongoDB debe restringirse bien para las direcciones controladas por la red local de clusters, por reglas de cortafuegos o combinación de las dos. Al realizar esto, solo la IP del servidor de Clarive y sus procesos podrán acceder al puerto de la base de datos. La configuración recomendad está descrita en nuestra guía de instalación y configuración para MongoDB. Esto está realizado no solo por una recomendación de buenas prácticas, sino como una cláusula del servicio: Si usted utiliza MongoDB fuera de Clarive de cualquier otra manera, nuestra capacidad para apoyar la instalación estaría limitada y podría anular las garantías de servicio.