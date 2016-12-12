---
title: Dispatcher
index: 5000
icon: page
---

El dispatcher es el proceso responsable de mantener todos los demonios de Clarive [demonios](admin/daemon) inicializados y funcionando.

Si un demonio no se ejecuta o deja de funcionar, el dispatcher se encargará de reiniciar el proceso.

El dispatcher puede iniciarse en uno o más servidores, donde va a controlar la afinidad de procesos del servidor, la tolerancia a fallos el balanceo de carga.