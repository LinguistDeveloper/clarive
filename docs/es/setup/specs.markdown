---
title: Arquitectura y requerimientos
index: 200
icon: page
---

# Componentes

La arquitectura de Clarive consiste en los siguientes elementos generales:

- Servidores de automatización.
- Servidor Web.
- Cliente Web.
- Servidores Staging-Build.
- Agentes de comunicación.

<img src="/static/images/docs/arch1.png" class="img_help" />

## Servidor automatizado

Clarive requiere de al menos un servidor de automatización. Este servidor será el responsable de las siguientes tareas:

- Planificación y ejecución de jobs e integración con los planificadores.
- Gestión de construcción y despliegue. Comunicación con los agentes.
- Procesos batch, como las purgas o backups.
- Integración con herramientas externas: Gestión de código fuente, gestión de incidencias, cmdb, etc.
- Exportación e importación de datos.
- Planificación y ejecución de jobs y su integración mediante planificadores.
- Gestión de la construcción y despligue. Comunicación a través de agentes.
- Procesos batch como la purgas o copias de seguridad.
- Integración con herramientas externas: Gestión de código fuente, gestión de incidencias, cmdb, etc...
- Exportación e importación de datos.

## Servidor Web

La interfaz de usuario principal de Clarive está basado en la Web.


Clarive cuenta con un servidor de aplicaciones que proporciona la interfaz web de Clarive así como los servicios web SOAP y REST. El servidor web está basado en el *framework* Catalyst y se ejecuta de manera independiente o bajo servidores compatibles como Apache, Nginx o Lighttpd.

## Cliente Web

Clarive cliente Web utiliza la última tecnología de la Web 2.0 para ofrecer una experiencia de usuario dinámica y natural, similar a la de una aplicación cliente, pero desde cualquier sistema de la red.

## Agentes

Realizar el proceso de construir y desplegar aplicaciones, Clarive necesita comunicarse con los servidores de la red: con agentes de propiedad o a través de SSH.

<img class="img_help" src="/static/images/docs/arch2.png" />

Los agentes de Clarive son compatibles con cualquier tecnología UNIX, Linux o Windows.

## Interfaces

El producto incluye las siguientes interfaces para la personalización e integración dentro de la empresa.

* Servicios web SOAP y REST
* Linea de comandos
* DSL JavaScript DSL y API para la implementación de *plugins* y lógica automática.

### Autentificación y autorización

El usuario se podrá autenticar en Clarive utilizando los estándares más comunes de la compañía.

* LDAP, Directorio activo.
* Autenticación de propietarios.
* Integración con sistemas de autenticación y autorización externos *SSO (Single Sign-On)*, como BMC Atrium, CAS, SAML,  mediante el uso de generadores de clave.

A través de las herramientas de la API de la carga de los usuarios
y la concesión de permisos a los roles, los grupos y las aplicaciones pueden ser manipulados.

# Requerimientos del sistema

Clarive requiere un servidor de arquitectura de 64-bits. Esta máquina puede ser virtualizada o no. Otros requisitos dependen de los requisitos de uso de la máquina, teniendo en cuenta las siguientes variables

* Número de usuarios
* Tamaño de la aplicación
* Frecuencia de la versión de la aplicación
* Número de despliegues diarios

## Sistemas operativos compatibles (Servidor)

### Linux 2.6 or higher, 64 bits

* SUSE, OpenSUSE
* CentOS 5.x, 6.x, 7.x
* RedHat Linux 5.x, 6.x, 7x
* Oracle Linux 6.x
* Debian 5 o superior (o Ubuntu)

### Unix o BSD 64 bits

* OSX 10.6 o superior
* Solaris 11 / OpenSolaris (SmartOS) 64-bit

### Microsoft Windows

* Microsoft Windows 7 (edición 64-bit).
* Microsoft Windows Vista (edición 64-bit).
* Microsoft Windows Server 2008 R2 (edición 64-bit)

## Bases de datos compatibles

* MongoDB 2.6 o superior.

## Navegadores web compatibles

* Microsoft Internet Explorer 11
* Google Chrome 13 o superior.
* Mozilla Firefox 3.x o superior.
* Safari 5 o superior.

### Mainframe (Agentes y Clarive ZSCM)

* z/OS zLinux (Solo agente)
* z/OS 1.7 o superior (Agente, Clarive ZSCM)

## Requisitos del sistema recomendados

### Servidor Clarive

Hay 2 procesos de servidor necesarios para ejecutar procesos Clarive: el servidor web y el *dispatcher*.

* Sistema operativo: Linux 64 bits
* Núcleos: 8
* RAM: 32 GB
* Disco:
    - $CLARIVE_BASE (software): 5 GB
    - $CLARIVE_BASE/tmp: 50 GB (depende del número de jobs y el tamaño de las aplicaciones. Se recomienda compartirlo entre dos máquinas (NFS, SAN, etc)
    - $CLARIVE_BASE/logs: 20 GB
    - $GIT_BASE/repo: 500 GB (depende del tamaño de los repositorios de la aplicación)  Se recomienda compartirlo entre dos máquinas (NFS, SAN, etc?)

### Servidor de la base de datos

2 servidores que ejecutan los procesos del servidor de base de datos MongoDB. Los servidores se pueden configurar como un conjunto de replicación.

* Sistema operativo: Linux 64 bits
* Núcleos: 8
* RAM: 16 GB
* Disco:
    - $MONGO_BASE/data: 200 GB
    - $MONGO_BASE/logs: 20 GB

## Agentes de apoyo

### Sistemas operativos

* Linux 2.4 o superior: Red Hat, Centos, Debian, OpenSUSE
* IBM AIX 4 o superior
* HP-UX
* Oracle Sun Solaris / SunOS
* IBM ZOS (OS-390) / IBM USS (OMVS)
* Windows Server 2000 o superior
* OSX, BSD o compatible
