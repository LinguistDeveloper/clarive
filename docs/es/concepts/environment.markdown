---
title: Entornos
index: 5000
icon: baseline
---

En DevOps, un entorno se define típicamente como un lugar donde se despliegan
los cambios. Pero más que eso, podemos decir que un entorno es un grupo lógico
de elementos de configuración o recursos.

### CI Entorno

En Clarive, un entorno por si mismo es un CI. Crea un nuevo CI y estarás creando
un nuevo entorno.

### ¿Como puedo configurar el contenido de un entorno?

Se puede hacer principalmente de 2 formas:

- Para cada CI que creemos podemos definir a que entorno pertenece.
Algunos CIs no soportan esto como los CIs de clase Proyecto, pero otros sí
como servidores o estados.
- Para cada alcance o proyecto, podemos definir que CIs pertenecen a un entorno
dado para ese alcance en particular.

### Nombrado de entornos

DEV, TEST, QA, PRE, PREP (preproducción), PRO, PROD (producción)
son todos los nombres que se usan habitualmente. Por convención.
proponemos que el nombre de los entornos esté limitado ente 2 y 4
letras.

### El Entono Común (*)

El entorno común es un entorno especial en Clarive que espera CIs, recursos y
variables que son comunes para todos los entornos o que no tienen entorno
especificado.

Por ejemplo, en estos CIs:

- una clase de CI GenericServer estará disponible para todos los entornos o
solo para algunos. Aquí el entono común significa **TODOS**.
- en una clase de CI GitRepository se asignará el entorno común, pero significa
**NINGUNO**, ya que un repositorio de código fuente no tiene el concepto de entorno por
sí mismo (por ejemplo, no creas un repositorio de Git para cada entorno).

### Legacy: Baseline and a bl

Las antiguas versiones de Clarive tienen el concepto de *"bl"*, que se
traduce como línea base, pero actualmente eso significa entorno.

Internamente, entorno es almacenado con el nombre `bl`, y
por lo tanto es visible así en YAML y otros sitios.
