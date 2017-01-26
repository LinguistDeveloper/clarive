---
title: Configurar Máscara de Pase
index: 5000
icon: job
---

Por defecto, cuando abrimos el monitor, el nombre de los pases se crean siguiendo esta regla:

- **Prefijo.Entorno-Secuencia**

Esto se puede modificar editando la variable config.job.mask. Para editar esta variable, vamos a
Administración>Configuración y buscamos la variable.

Podemos editarla usando variables internas del pase. Por ejemplo, si queremos mostrar el id del pase,
seguido del entorno, debemos configurar la variable de la siguiente forma:

- **${mid}-${bl}**
