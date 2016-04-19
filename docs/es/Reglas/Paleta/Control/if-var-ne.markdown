---
title: IF var ne value THEN
icon: if.gif
---
* Al contrario que el componente [if-var](Reglas/Paleta/Control/if-var), en este caso se procesa el bloque anidado si el valor **no** es igual al valor almacenado en el stash.

* Es necesario configurar los siguientes campos:

    **Variable**: Variable del stash a comprobar.

    **Valor**: Valor para comparar con la variable del stash.

* En caso de querer comparar valores dentro de un hash anidado, es necesario indicar la variable que almacena dicho *hash* en el campo *Clave de retorno* de las propiedades del elemento, a las que se accede pulsando con el botón derecho sobre el mismo.