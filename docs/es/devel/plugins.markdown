---
title: Plugins
index: 5000
icon: page
---

El sistema de plugins Clarive es la forma oficial de extender las funcionalidades del producto. Cada punto de entrada oficial
en el producto debe estar a disposición de los plugins.

## Ubicaciones de los plugin

Hay 2 directorios en los plugins pueden ser guardados:

- Bajo el directorio `CLARIVE_BASE/plugins`, destinado para los plugins creados por el usuario, específicos para una instalación o plugins públicos listos para descargar.
- Bajo el directorio `CLARIVE_HOME/plugins`, donde se almacenan **solo los plugins que pertenecen al producto unicamente**.

## Sobreescribir plugins

Los plugins públicos pueden sobrescribir a los plugins de productos en cualquier momento puesto que los plugins públicos tienen prioridad sobre los del producto.

Para sobrescribir un plugin de producto tan solo en necesario crear un plugin con el mismo nombre que el de producto.

**NOTA** - Sobrescribir plugins del producto puede ocasionar un funcionamiento inestable de Clarive. En muchos casos, es mejor utilizar un nombre de módulo/librería distinto.

## Estructura de directorios de los plugins


El sistema de plugins carga los archivos desde una estructura de carpetas predefinida.

La estructura de las carpetas determina **cuando y donde** los ficheros del plugin serán cargados, pero no determina que contenido exacto tendrá el archivo cargado.

Esta es la estructura de directorios:

- `plugin/modules` - módulos que pueden ser requeridos por el DSL Clarive JS con la función `require()`.
- `plugin/init` - código ejecutado en el inicio, que puede cargar clases de CI o registrar nuevos menús, acciones y otros código de estructuras.
- `plugin/forms` - Formularios Web en JS que pueden ser usados en la interfaz de Clarive
- `plugin/rules` - DSL de reglas que pueden ser usadas de manera independiente o como parte del programa.

## ¿Que pasa con las features de Clarive?

Las Features continuarán ahí. Permanecen como un laboratorio de extensiones al producto

El sistema de features no está destinado al público general y tampoco a la 
personalización de las mismas, y cualquier feature añadida al producto que no esté oficialmente soportada a menos de que se acuerde previamente.

El sistema de features es un sistema completamente separado del sistema de plugins, con una estructura de directorios diferentes y lenguaje.