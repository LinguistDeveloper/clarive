---
title: Carga y descubrimiento de entornos
index: 120
---

Para crear y mapear todos los CIs necesarios para finalizar el modelo del
entornos y terminar con la implementación en Clarive, recomendamos realizar
alguna de las siguientes actividades:

- Probar y descubrir infraestructuras usando reglas
- Cargar CIs de una base de datos u hoja de cálculo.
- Duplicar la configuración desde/a modelos actuales.


### Descubrimiento

Para descubrir entornos, utilice las operaciones de exploración de Clarive para
configurar la lógica de detección encargada de encontrar y configurar los
recursos de la infraestructura de su red.

Pasos:

- Crear una nueva regla de tipo `Acción` y seleccione donde estará disponible
  la acción seleccionada.
- Añadir operaciones de exploración que se adapten al tipo de CIs que quiere
  descubrir. Las operaciones de exploración dependen de los plugins y features
instaladas en su instalación.


### Cargando CIs

La carga de CIs en Clarive se puede realizar por dos vías:

- Importando un fichero CSV, YAML o JSON.
- Llamando a un servicio web.

#### Importar desde un fichero

Use la opción del menú `Import`de cada grid de CI disponible para importar
información.

#### Llamar a un servicio web de Clarive

Llamando a la API de Clarive utilizando un servicio web es otro método de
cargar (y actualizar) las IC en el sistema.

Escriba una regla de tipo webservice en las `Reglas` para crear y cargar CIs.
