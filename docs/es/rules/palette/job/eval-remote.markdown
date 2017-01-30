---
title: Evaluación remota
index: 5000
icon: service-scripting-eval
---

Agente relacionado con el [CI](concepts/ci) servidor que evalúa el código dado, mostrando un mensaje de error en caso de fallo durante la ejecución o devolviendo el código y su resultado en caso de que haya ido de manera correcta.

La lista de configuración del elemento incluye las siguientes opciones:

- **Servidor** - Servidor donde se aloja el código.
- **Usuario** - Usuario necesario para conectar al servidor.
- **Código** - Código a evaluar en el servido escogido.