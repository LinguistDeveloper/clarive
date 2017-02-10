---
title: Modelando Entornos
index: 100
---

Como parte de la implementación de su ciclo de vida de entrega en Clarive, el
primer paso es definir el conjunto de entornos lógico que representan las
diferentes configuraciones de su infraestructura física o virtual.

Un entorno de Clarive es la especificación de una configuración y sus versiones
dado un estado.

- Los entornos representa el punto de partida inicial de la configuración del
  ciclo de vida.
- Los entornos aíslan áreas funcionales de trabajo. Ellos determinan qué
  versión de software, servicios y aplicaciones son desplegadas.
- Los entornos pueden ser configurados por proyecto.




Los entornos pueden ser modelados. Un modelo es un conjunto de variables de
configuración que pueden aplicarse a aplicaciones, microservicios, etc. Los
modelos son un tipo de regla que se construye agrupando y definiendo relaciones
entre un conjunto que puede tener:

- Variables de configuración.
- Elementos de configuración (CIs).
- Reglas de modelo.



## CI de Entorno

Este es el requisito más básico que necesita para cumplir en este punto.
¿Cuales son sus entornos? Aquí hay algunas ideas. Tenga en cuenta el uso de
MAYÚSCULAS, por convención, en las abreviaturas de los nombres de entorno. Esto
es recomendado porque mejor la lectura entre sistemas, código y componentes
visuales.

- `DEV` - Entorno de desarrollo compartido, para pruebas unitarias individuales 
o cambios en un espacio compartido.
- `INT` - Entorno para la integración continua (o discreta).
- `TEST` - Otro nombre para entornos de prueba de integración
- `QA` - Para testing funcional, sistemas y otros entornos.
- `UAT` - Entorno para realizar las pruebas de aceptación.
- `TRAIN` - Entorno de entrenamiento, para entrenar a usuarios con las nuevas
  versiones
- `PRE` - Preproducción
- `PROD` - Producción
- `PROD-APAC` - Producción Asia
- `PROD-EMEA` - Producción Europa, Oriente-Medio y África
- ...

## Variables

En su estructura más básica, los entornos son modelados como un conjunto de
variables que almacenan la configuración para un ámbito determinado.  Este
ámbito es normalmente un Proyecto, que mapea una aplicación.


Las variables pueden contener muchos tipos de datos:

- Valores de texto y áreas de texto
- Combo desplegable y arrays (lista).
- Contraseñas (las cuales se encriptan de manera automática).
- CIs


Las variables también son CIs. Esto significa que pueden mantener relaciones
entre sus valores, sus ámbitos y sus entornos al cual se han aplicado.

## Valores por defecto

Para cada variable, se puede definir un valor por defecto, ya sea para el
entorno `Común` como para entornos individuales.

Para poder añadir un valor por defecto a una variable CI, es necesario guardar
primero la variable y recargar la pestaña.


## Elementos de configuración

El núcleo del sistema de modelado son los elementos de configuración (CI).

Los elementos de configuración contienen el conjunto de campos que conforman el
CI.

Los CIs también pueden soportar relaciones, por lo que el usuario puede
definirlas como por ejemplo, una relación entre un contenedor de Docker y su
padre Amazon ECS.


## Configuración del proyecto (aplicación)


Las aplicaciones se pueden configurar utilizando la variable Proyecto CI y el
campo del modelo.

Para cada entorno, seleccione una de las pestañas de entorno. Utilice la
pestaña `Común` para establecer los valores globales que se comparten entre
todos los entornos.

Para variables específicas de cada entorno, establezca la variable
correspondiente en el campo `Variables` de cada entorno.


## Entorno del proyecto

Un entorno de proyecto es un CI es automáticamente mantenido por el sistema.

Cada vez que se configura una variable para un proyecto, se almacena la
relación entre el proyecto, y los CIs de Entorno.

## Definiendo el modelo

La manera más sencilla de describir un modelo en Clarive es como un grupo de
variables que pueden ser aplicadas sobre proyectos de manera que los usuarios
conoces qué es lo que necesita ser configurado desde un principio.

Sin modelos, tendríamos que escoger y elegir las variables de una lista enorme
y despues esperar a ver escogido las correctas.


Supongamos que tenemos que definir el modelo para una aplicación Tomcat:

    host: ${tomcat.nombreservidor} port: ${tomcat.puerto} path: ${tomcat.ruta}
url: ${tomcat.url} home: ${tomcat.home}


Esto sería un modelo muy simple, pero da una idea de cómo las cosas podrían ser
para modelos mucho más grandes. Llamemos ahora a este modelo "Aplicación
Tomcat". Por lo tanto, el modelo define una aplicación que se ejecuta en un
servidor de aplicaciones Tomcat.

Los modelos no son una forma obligatoria de configurar los entornos, pero son
muy recomendables.


### Modelos como patrones


Normalmente, las organizaciones quieren crear un modelo o un patrón de modelos
para combinar las diferentes tecnologías utilizadas por su IT. Estos patrones
de modelos pueden aplicarse a aplicaciones nuevas o ya existentes, ya que están
incluidas en Clarive.

Aquí hay algunos ejemplos de modelos que representan mejor las aplicaciones en
el mundo real:

- aplicaciones .NET + MSSQL.
- NodeJS + MongoDB + Docker + ECS contenedor de microservicios
- Java + Tomcat + Oracle DB
- etc.

Existen dos enfoques para definir los patrones del modelo:

- **top-down**: el usuario sabe como quiere que sea su patrón, declara un
  conjunto de variables agrupadas y después define la lógica (reglas) que las
implementan.
- **bottom-up**: el usuario define variables sueltas y reglas que implementan
  el despliegue o la lógica de provisión. Ahora se quiere que el sistema
automáticamente las extraiga.
