---
title: cla patch - parches para aplicar/rollback
index: 5000
icon: console
---

El mecanismo de parches es útil para actualizar a una nueva versión de Clarive sin tener que instalar todo el producto.

Todos los comandos soportan el modo `--dry-run` donde no se realizan cambios en los ficheros un un modo `--quiet` donde no se muestra ningún mensaje por pantalla.

## Aplicar parches

Para aplicar un parche recibido desde Clarive, hay que ejecutar:

    cla patch-apply --patch clarive_VERSION1-VERSION2.patch.tar.gz

Este comando actualizará su instalación de la VERSION1 a la VERSION2. El proceso fallará si la versión local es inválida o el código fuente no es parcheable.

## Marcha atrás en parches

Para realizar una marcha atrás y desaplicar el parche, ejecutar el siguiente comando:

    cla patch-rollback --patch clarive_VERSION1-VERSION2.patch.tar.gz

Revertirá todos los cambios que se han realizado con por la aplicación del parche.
