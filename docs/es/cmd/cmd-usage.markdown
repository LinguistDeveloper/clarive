---
title: Utilizando la línea de comandos
index: 4000
icon: console
---

Todos los de la interfaz de línea de comandos Clarive (CLI)
compartir algunos puntos en común.


## Obteniendo ayuda

Para obtener ayuda de un comando, solo hay que escribir:

    cla help [comando]

Para una lista de comandos disponibles, teclee:

    cla help

La lista de comandos puede variar en función a los plugins y features instaladas.

## Parámetros opcionales

La mayoría de las opciones se pueden transmitir usando argumentos en la línea de comandos
(a veces llamados *flags*) precedido por doble guión `--`.

Por ejemplo:

    --max_workers 20

En la línea de comandos, las opciones con guión bajó
pueden ser sustituidas por un guión `-`, por lo que también podría escribir:

    --max-workers 30

**NOTA**: Aunque esto es válido para las opciones de línea de comandos, 
no funciona igual para las opciones incluidas en  los archivos de configuración de entorno.

El valor que se quiere establecer a un parámetro desde línea de comandos tiene que estar definido con un signo de igual `=` o separado por un espacio, por lo que este formato también es válido:

    --max_workers=30

##  Sobreescritura de configuración


Los comandos disponibles desde la linea de comandos se pueden establecer en el fichero de configuración de entorno `2[env].yml`:

```yaml
max_workers: 30
```

## Datos anidados como opciones de línea de comandos

También es posible asignar valores en claves aninadas a través de la linea de comandos, mediante el uso de una notación atributo de estilo JSON:

    --cache_config.expire_seconds 3000

Cualquier punto `.` que se encuentre en un argumento será
traducido al valor anidado. En el caso anterior, el `[env].yml`
equivalente sería:

```yaml
cache_config:
  expire_seconds: 3000
```

Otra alternativa para hacer esto es cargar un objeto string en formato JSON,
en la línea de comandos con la opción `--json`:

    --json '{ cache_config: { expire_seconds: 3000 } }'

## Comprobación de la configuración cargada

El entorno final + las opciones dadas desde la linea de comandos pueden ser comprobadas para ver finalmente qué valores son los que Clarive carga ejecutando `config-cla show`

    cla config-show

Este comando devuelve los datos actuales en formato YAML.
