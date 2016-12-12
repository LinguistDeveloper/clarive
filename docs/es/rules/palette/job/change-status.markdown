---
title: Cambiar estado de tópico
index: 5000
icon: topic
---

Servicio para cambiar el estado de un [tópico](concepts/topic) o varios.

Todos los campos admiten el uso de variables para definir los parámetros.
La lista de configuración del elemento incluye las siguientes opciones:

- **Tópicos** - Campo de texto donde introducir el MID del tópico o tópicos a transitar. Acepta múltiples valores separando los MIDs mediante comas.
- **Estados actuales** - Indica en que estado o estados está actualmente el tópico o tópicos.
- **Nuevo estado** - Indica el estado al que va a transitar el tópico.
- **Usuario** - Permite definir el autor de la transición entre tópicos. El usuario tiene que tener los permisos necesarios para realizar la transición.