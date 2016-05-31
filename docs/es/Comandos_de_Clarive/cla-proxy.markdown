---
title: cla proxy - Cliente proxy
icon: console.svg
---
* `cla proxy`: Es un cliente proxy que ayuda a depurar el tráfico de la red.
* Depura todo el tráfico que sale o entra del servidor web de Clarive.
* Pueder ser muy útil en caso de integrar Clarive con herramientas externas.
        
        cla proxy
        cla proxy --port 5555
        cla proxy --listen localhost:6565

### Opción Unpack
La opción `--unpack` traduce los datos entrantes (no los salientes) en hexadecimal, para que se pueda rastrear mejor los datos entrantes.
            
        cla proxy --unpack

* Datos con la flecha hacia la derecha `-->` indica los datos que van desde el cliente al servidor Clarive.
* Datos con la flecha hacia la izquierda `<--` indica datos procedentes del servidor Clarive y que se devuelven al cliente.

Por ejemplo, para rastrear los comandos de Unix, se puede configurar el proxy con una variable env, llamada `http_proxy`:
            
        http_proxy=localhost:8089 git push origin master
        http_proxy=localhost:8089 curl http://localhost:3000/rule/json/myrule?api_key=99999999999999

O bien, se puede configurar el navegador para hacer lo mismo, utilizando la dirección `cla proxy` como proxy.
