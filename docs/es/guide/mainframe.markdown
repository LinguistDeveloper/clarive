---
title: Automatización de entrega en Mainframe
index: 4100
---

Clarive viene con integración nativa con el mainframe. Clarive es la
herramienta ideal para implementar un ciclo de entrega en toda la empresa que
no deja atrás los sistemas heredados.


### Lista de instalaciones de Mainframe disponibles

Aquí están los puntos clave de la integración de un mainframe con Clarive:

- Construcción y despliegue de artefactos Z/OS almacenados en un repositorio de
  código abierto (por ejemplo, Git o SVN).
- Creación y despliegue de artefactos Z/OS almacenados en el sistema de
  archivos Z/OS.
- Seguimiento de pases de despliegue.
- Encadenamiento de los resultados del despliegue.
- Análisis de los resultados del log para errores, etc.


Además, puede planificar su implementación para obtener el máximo provecho de
Clarive:

- El empaquetamiento, la construcción y el despliegue de programas Z/OS es
  realizado por Clarive
- Compilar y vincular programas utilizando plantillas preprocesadas de JCL.
  Despliegue elementos de DB2 directamente en la base de datos
- Controlar lo que hay en cada entorno: Desarrollo, QA, Producción, etc.
  Programar pases de releases individuales de acuerdo con la disponibilidad de
los calendarios.
- Solicitar aprobación para ventanas de implementación críticas o aplicaciones
  o elementos sensibles.
- Mantenga el ciclo de vida sincronizado con aplicaciones externas de gestión
  de problemas y proyectos.
- Ejecutar SQA en los cambios que se están desplegando. Bloquear el despliegue
  y realizar un rollback automático si los cambios no llegan al mínimo de
calidad exigida.


### Envío de archivos a particiones Z/OS

El agente de Clarive USS gestiona el envío de archivos directamente a
particiones Z/OS o USS (OMVS) en el mainframe.


Clarive utiliza los archivos *in-line* JCL para enviar archivos utilizando el
mecanismo FTP-JES.

### Identificar Relaciones - Análisis de Impacto

Clarive puede analizar el código fuente para determinar qué otros programas
necesitan ser compilados cuando hay un cambio en un artefacto.


### Enviar JCL a partir de plantillas

Defina las plantillas JCL en Clarive y, a continuación, envíelas como pases a
la instalación Z / OS JES.

Las plantillas JCL pueden tener variables que se definen para cada entorno,
agregando una gran capa de flexibilidad al procesamiento JCL para implementar
una lógica de compilación e implementación compleja.


### Compilar, enviar

Los JCL de Clarive pueden crear y desplegar prácticamente cualquier artefacto
que pueda ser automatizado por una tarjeta de pase en el mainframe.

El sistema de spool controla el anidamiento, de modo que si un JCL envía otro
JOB para su ejecución, Clarive lo rastreará.


### Recuperación de la salida de cola de pases

Todos los pases ejecutados por Clarive se controlan para visualizar los errores
y otros resultados.

Clarive gestiona el log de spool generado al ejecutar JCLs en el mainframe,
capturando y dividiendo su salida para que los resultados puedan leerse
fácilmente en cada una de sus secciones desde la interfaz web de Clarive.


### Mapas de traducción de caracteres

Clarive puede traducir los caracteres de ambas tarjetas de pases y el código
fuente que se envía desde el servidor Clarive.

Use la operación `Sed Parser` en la regla de Clarive para implementar
traducciones según sea necesario.

### REXX API

Puede configurar REXX en el mainframe para invocar a reglas Clarive usando
nuestra API de webservice.

Aquí está un ejemplo de cómo un REXX que llama a Clarive:

    /* REXX */ call claws '/rule/raw/is_release_ready', "api_key", "1234","release_id", "r.2.3.4"

## Requisitos Mainframe

Sólo hay 2 requisitos para la compatibilidad de mainframe con Clarive:

- Instalación de FTP-JES habilitada
- Opcionalmente, una partición USS/OMVS para el agente ClaX - no es necesario
  para enviar archivos, enviar pases, etc. sólo para integraciones especiales.
- REXX, para llamar a las reglas webservice de Clarive.

### Interfaz FTP-JES

Antes de comenzar, asegúrese de lo siguiente:

- Su máquina Z/OS tiene el servidor FTP en ejecución.
- Tiene un ID de usuario debidamente autorizado.
- Además, puede utilizar cualquiera de diferentes parámetros de configuración
  para controlar el comportamiento de la interfaz JES, incluyendo el parámetro
de configuración más importante: `JESINTERFACELEVEL`

#### Parámetros de configuración de la interfaz JES

- `JESINTERFACELEVEL` - Especifica el nivel de función que proporciona la
  interfaz JES. Ajuste a 2 para la función máxima.
- `JESENTRYLIMIT` - Limita cuántos pases se devolverán. El valor predeterminado
  es 200.
- `JESOWNER` - Limita los pases recuperados a los pases con este propietario.
  Si está en blanco, el valor predeterminado es el usuario actual.
- `JESJOBNAME` - Limita los pases recuperados a pases con el mismo nombre de
  pase. Si está en blanco, el valor predeterminado del usuario actual
concatenado con un \*. Utilice \* para recuperar todos los pases.
- `JESSTATUS` - Limita los pases recuperados a pases con el mismo estado. Si
  está en blanco, por defecto a todos los estados. Los estados válidos son
OUTPUT, ACTIVE y INPUT.
