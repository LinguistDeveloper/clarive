---
title: Inicializar directorio home
index: 5000
icon: job
---

Este servico es requerido para que arranque de manera correcta un job. 
Es necesario crear o limpiar el directorio de trabajos

El directorio de jobs se crea utilizando la ruta:

`$ENV{CLARIVE_JOBDIR}/`

o

`$CLARIVE_BASE/jobs/` - En caso de que la variable de entorno no esté definida.

y

`<N|B>.<bl>-<job_id>` - Donde los parámetros son:

- `<N|B>` - Dependiendo del tipo de trabajo, N para desplegar o trabajos estáticos o B para volver hacia atrás (rollback).
- `<bl>` -  Entorno.
- `<job_id>` - ID único dado por mongo.

