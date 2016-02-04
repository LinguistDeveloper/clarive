---
title: cla migra - Migraciones
icon: console
---
* `cla migra`: Ejecuta las migraciones de bases de datos, necesarias para evitar incompatibilidades entre la versión de la base de datos y la versión de Clarive tras instalar parches.

<br />
## Subcomandos
<br />

#### migra-init
Inicializa la migración

#### migra-start
Actualiza o desactualiza las migraciones. Las opciones son:
            
        --init Inicia la ejecución antes de migrar
        --path Indica la ruta de las migraciones en caso de no usar la de defecto

<br />
#### migra-set
Establece manualmente la versión más reciente de las migraciones.
            
        --version La versión que se quiere establecer

<br />
#### migra-fix
Elimina el error de la última migración. Use *SOLO* cuando el tema es realmente
fijo.


#### migra-specific
Actualiza o desactualiza las migraciones de manera manual pasandole como argumente el nombre de la migración. Las opciones son:
            
        --name Nombre de la migración
        --downgrade Ejecutar un downgrade en vez de la actualización



     
