---
title: Directorios de instalación
index: 600
icon: page
---

En este documento se describe la
estructura de directorios de una instalación Clarive.

## Los directorios bases de Clarive CLARIVE_BASE

El directorio base de Clarive, al que se refiere el
este manual como `CLARIVE_BASE`, es donde está instalado la estructura de Clarive.

El directorio de base contiene los ficheros binarios y bibliotecas comunes utilizados por Clarive, y de forma predeterminada, es donde se encuentran los directorios temporales y de datos. Esto puede
ser modificado por el usuario a través del fichero `[env].yml`.

#### CLARIVE_BASE en Linux, OS X y Unixes

Estos son los directorios por defecto de una instalación de Clarive:

- `jobs/` - Directorio temporal donde se escriben los jobs.
- `data/` - Los archivos de base de datos se mantienen aquí por defecto, normalmente bajo `data/mongo`.
- `logs/` - Para los logs del servidor y los ficheros de procesos `.pid` y `.lock`.
- `tmp/` - Para los archivos y directorios temporales utilizados, sobre todo por el servidor web.
- `config/` - Directorio para los archivos de configuración de usuario `[env].yml`. Este
directorio se encuentra en la ruta de búsqueda para la opción `--env` de la línea de comandos para el comando `cla`. Los archivos de configuración de MongoDB y Nginx se guardan aqui de forma predeterminada.
- `features/` - Aquí es donde se guardan las extensiones de producto instaladas por el usuario. Cada subdirectorio aquí es una extensión.
- `plugins/` - Aquí es donde los plugins de producto instalados por el usuario se almacenan. Cada subdirectorio es un plugin.
- `local/` - Se almacenan todas las bibliotecas externas y binarios tales como Git, OpenSSL, drivers de MongoDB o Perl. **No hay archivos servibles aqui**.
- `clarive/` - El directorio CLARIVE_HOME. Ver más abajo.


#### CLARIVE_BASE en Windows

El directorio CLARIVE_BASE en una instalación de Windows está contenido dentro de
más niveles que en una instalación en Linux / OS X. Esto es debido
a las especiales condiciones de estructura y base software que necesita Windows.

Para que la lectura sea más sencilla, suponemos que el directorio raíz de instalación en Windows es `C:\Clarive` en este manual.

- `C:\Clarive` - Ubicación raíz de la instalación, donde cada subdirectorio
es un producto Clarive, tales como "Servidor" o "Agente".
- `C:\Clarive\Server` - La instalación del servidor.
- `C:\Clarive\Server\app\` - El directorio de instalación de Cygwin, el cual emula una directorio raiz \*nix.
- `C:\Clarive\Server\app\opt\clarive` - El directorio de CLARIVE_BASE. Desde aqui hacia abajo, la estructura de carpetas coincide con la estructura de Clarive instalado en los sistemas operativos Linux/Unix/OSX, por lo que puede consultar el capitulo anterior para más información.
- `C:\Clarive\Server\bin` - Binarios especiales para Windows y otros accesos directos de la aplicación.

## Directorio inicial de Clarive CLARIVE_HOME


El directorio principal de Clarive es donde están instalados los ficheros del núcleo de Clarive, por lo general bajo el directorio `$CLARIVE_BASE`.

**No hay archivos servibles aquí**, así que no cambie los archivos de aquí, ya que pueden generar errores y la corrupción de datos.

## Cambiar el directorio de instalación por defecto

Para cambiar los directorios por defecto, establezca los nuevos valores en su
[entorno de configuración	](setup/config-file) file `[env].yml`.


