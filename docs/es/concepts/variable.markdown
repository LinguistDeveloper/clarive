---
title: Variable
---

Una variable en Clarive se define de manera global usando la clase de CI Variable.

Cada variable puede contener valores como cadenas de texto, número, listas, hashes (diccionarios) y CIs.

Las varibles pueden ser referenciadas en las reglas usando la notación `${nombre-variable}`.

Cuando se ejecuta una regla, su [stash](Conceptos/stash) se carga con los valores por defecto de las variables globales. Entonces, al continuar con la ejecución, cada valor de las variables cambia o se introducen nuevas variables en el stash.

## Variables Obligatorias

Cada variable puede ser marcada como obligatoria. Esto afecta a las variables de proyecto (ver [Proyecto](Conceptos/project) para más información).

## Copiar variables

Cuando copias variables entre entornos (ver [Proyecto](Conceptos/project) para más información), si está marcada con el flag copiar hace que el valor sea copiado también.
