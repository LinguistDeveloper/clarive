---
title: Gestión de artefactos
index: 2000
---


Un repositorio almacena dos tipos de artefactos: releases e instantáneas. Los
repositorios de releases son para artefactos de lanzamientos estables y
estáticos y los repositorios de instantáneas son repositorios frecuentemente
actualizados que almacenan los artefactos binarios de software de proyectos que
están en constante desarrollo. Aunque es posible crear un repositorio que sirva
tanto artefactos de releases como instantáneas, los repositorios suelen
segmentarse en repositorios de instantáneas o de releases que sirven a
diferentes consumidores y mantienen diferentes normas y procedimientos para
desplegar artefactos.

Al igual que la diferencia entre una red de producción y una red de *stagging*,
un repositorio de releases se considera una red de producción y un repositorio
de instantáneas es más bien una red de desarrollo o de pruebas. Aunque existe
un nivel más alto de procedimiento asociado con el despliegue en un repositorio
de releases, los artefactos de instantáneas se pueden desplegar y cambiar con
frecuencia sin tener en cuenta las preocupaciones de estabilidad y
repetibilidad.

### Artifactos de Release

Un artefacto de release es un artefacto que fue creado por una versión
específicamente versionada. Por ejemplo, considere la versión 1.2.0 de la
librería *commons-lang* almacenada en el repositorio central de Clarive. Este
artefacto de release, *commons-lang-1.2.0.jar* y el POM asociado,
*commons-lang-1.2.0.pom*, son objetos estáticos que nunca cambiarán en el
repositorio central de Clarive.

Los artefactos de release se consideran sólidos, estables y perpetuos para
garantizar que las construcciones que dependen de ellos sean sólidas y
repetibles en el tiempo. El artefacto JAR liberado está asociado con una firma
PGP, un MD5 y un SHA que puede usarse para verificar tanto la autenticidad como
la integridad del artefacto de software binario.

### Artefactos *Snapshot*

Los artefactos *Snapshot* son artefactos generados durante el desarrollo de un
proyecto de software. Un artefacto *Snapshot* un número de versión como "1.3.0"
o "1.3" y una marca de tiempo en su nombre. Por ejemplo, un artefacto
*Snapshot* para *commons-lang 1.3.0* podría tener el nombre
*commons-lang-1.3.0-20090314.182342-1.jar*. Los hash POM, MD5 y SHA asociados
también tendrían un nombre similar.

Para facilitar la colaboración durante el desarrollo de componentes software,
Clarive y otros clientes que saben como funcionan este tipo de artefactos,
saben cómo consultar los metadatos asociados al artefacto y siempre recuperan
la última versión de una dependencia de instantánea de un repositorio.

### Grupos

Los grupos pueden agrupar diferentes repositorios en uno solo.

De esta forma, para el usuario, se puede utilizar una sola URL para acceder a
los artefactos. Automáticamente, Clarive buscará a través de los repositorios
de artefactos que componen el grupo e intentará encontrar un artefacto, *en el
orden en que los repositorios de artefactos estén en un grupo*.

### Repositorios Remotos y Proxy

Clarive puede tener repositorios locales y remotos. Los repositorios remotos
son URLs que se probarán cuando el usuario requiera de Clarive para un
artefacto.

    USUARIO ===> REPOSITORIO LOCAL CLARIVE ===> REPOSITORIO REMOTO

Los repositorios remotos se pueden usar para sustituir y almacenar en caché
artefactos remotos.

#### Almacenamiento en caché de artefactos remotos

Una vez que se solicita un artefacto, Clarive recupera el artefacto y lo
almacena localmente.

Cada vez que un usuario solicita el artefacto, si Clarive ya tiene archivado en
caché localmente, solo comprobará si el artefacto remoto tiene la misma marca
de tiempo y tamaño. Si coinciden, Clarive servirá el archivo local, reduciendo
así la sobrecarga de extracción remota.


### Publicación de artefactos

Para incluir nuevos artefactos en el repositorio de Clarive, utilice la regla
`Publicar artefacto`.

Esto publicará *e indexará* el artefacto.

Si no utiliza la operación y decide copiar el archivo directamente a la ruta
del repositorio, no se indexará para las búsquedas.

### Búsquedas

Los artefactos añadidos al repositorio utilizando la operación `Publicar
artefacto` forzarán una actualización de índice, lo que se traduce en búsquedas
más rápidas a través de la interfaz de `Artefactos`.


### Repositorio como proveedor de cambios

Los repositorios de artefactos pueden utilizarse como proveedores de cambios.

Simplemente agregue cualquier repositorio de artefactos a la lista de
repositorios del proyecto (en el CI del proyecto) para que funcione.

### Identificadores

Los artefactos pueden identificarse mediante una combinación de 3 puntos de
datos:

#### Identificador de grupo (groupId)

Un identificador de grupo agrupa un conjunto de artefactos en un grupo lógico.
Los grupos se diseñan a menudo para reflejar la organización bajo la cual se
está produciendo un componente de software particular. Por ejemplo, los
componentes de software que están siendo producidos por el proyecto Maven en
Apache Software Foundation están disponibles bajo el groupId org.apache.maven.

#### Identificador de artefacto (artefactId)

Un artefacto es un identificador para un componente de software. Un artefacto
puede representar una aplicación o una librería. Por ejemplo, si está creando
una aplicación web sencilla, su proyecto podría tener un artefactId como
"simple-webapp", y si está creando una librería simple, su artefacto podría ser
"libreria-simple". La combinación de groupId y artifactId debe ser única para
un proyecto.

#### Versión (version)

La versión de un proyecto sigue el convenio establecido de Mayor, Menor y Fase.
Por ejemplo, si su artefacto de librería simple tiene una versión de
lanzamiento mayor de 1, una versión de lanzamiento menor de 2 y una versión de
lanzamiento fase de 3, su versión sería 1.2.3. Las versiones también pueden
tener calificadores alfanuméricas que a menudo se usan para indicar el estado
de la release. Un ejemplo sería una versión como "1.2.3-BETA" donde BETA señala
una etapa de pruebas significativa para los consumidores de un componente de
software.

### Origen

Un repositorio de artefactos de Clarive es completamente ajeno en lo que
respecta al tipo de artefacto que se está manejando. Los paquetes puede ser
cualquier cosa que describa cualquier formato de software binario, incluyendo
ZIP, SWC, SWF, NAR, WAR, EAR, SAR.
