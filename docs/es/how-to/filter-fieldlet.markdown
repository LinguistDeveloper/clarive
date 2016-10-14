---
title: Filtros en fieldlets
index: 1
icon: wrench
---

Este tipo de filtros están presentes en los siguientes fieldlets:

- **Topic Selector**.
- **Release Combo**.
- **CI List**.
- **CI Grid**.
- **CI Combo**.

En estos fieldlets, vamos a tener que configurar tres campos:

- `Campo filtrado` - Este campo es un combo en el que aparecen todos los fieldlets que tiene nuestro formulario.
	Es importante guardar el formulario antes de usar este combo, ya que en caso contrario, los fieldlets no aparecerán en él.
	En este campo, estamos seleccionando el fieldlet del cual se cogerán los valores para nuestro filtro.
- `Dato filtrado` - Este campo representa la clave de nuestro filtro..
- `Tipo de filtro` - Tenemos que seleccionar la lógica de nuestro filtro.

### Ejemplos

Queremos filtrar topicos a partir de usuarios. Para ello, creamos dos fieldlets. El primero es un combo de usuarios
con el id 'users' y el segundo es un selector de topicos con el id 'topics'.
El fieldlet 'users' tiene que estar en el formulario por encima del de tópicos.
La configuración de nuestro fieldlet de tópicos quedaría de la siguiente forma:

- Campo filtrado - users.
- Dato filtrado - owner.
- Tipo de filtro - OR.

Tendríamos como resultado un filtro como el que podemos ver a continuación:

		{'owner':$in['user-1, user-2..']}

Ahora queremos filtrar un ci combo en función del valor seleccionado en un fieldlet del tipo pills. Para ello, creamos en primer 
lugar un fieldlet tipo pills con el id 'pills' y después, creamos un fieldlet del tipo ci combo con el id 'ci combo'. La configuración
del pills debe quedar:

- Opciones configuradas - user;project
- Valor por defecto - user

La configuración del ci combo debe quedar:

- Campo filtrado - pills.
- Dato filtrado - collection.
- Tipo de filtro - OR.

Ahora, vamos a crear un filtro más complejo. Creamos dos fieldlets, el primero será un ci combo con id 'ci_combo' y la siguiente
configuración:

- Roles - Todos
- Clase CI - project

A continuación, creamos un topic selector con id 'topic_selector' y los siguientes parámetros:

- Filtro avanzado JSON - {'name_status': 'New'}
- Campo filtrado - ci_combo
- Tipo de filtro - system

Con este filtro, después de seleccionar un proyecto, obtendremos todos los tópicos asociados a ese proyecto y que se encuentren en estado 'New'.