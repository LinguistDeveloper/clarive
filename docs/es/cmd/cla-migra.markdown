---
title: cla migra - Migraciones
index: 5000
icon: console
---

`cla migra`: Ejecuta las migraciones de bases de datos, necesarias para evitar incompatibilidades entre la versión de la base de datos y la versión de Clarive tras instalar parches.

## Subcomandos


### migra-init

Inicializa la migración


### migra-start

Actualiza o desactualiza las migraciones. Las opciones son:

        --init Inicia la ejecución antes de migrar
        --path Indica la ruta de las migraciones en caso de no usar la de defecto


#### migra-set

Establece manualmente la versión más reciente de las migraciones.

        --version <La versión que se quiere establecer>


#### migra-fix

Elimina el error de la última migración. Use *SOLO* cuando el problema esté completamente arreglado.

#### migra-specific

Actualiza o desactualiza las migraciones de manera manual pasándole como argumento el nombre de la migración. Las opciones son:

        --name Nombre de la migración
        --downgrade Ejecutar un downgrade en vez de la actualización




