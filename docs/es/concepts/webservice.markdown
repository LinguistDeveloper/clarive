---
title: Servicio Web
index: 5000
icon: webservice-blue
---

En Clarive, un webservice es un tipo de [regla](concepts/rule) que pueden ser
llamados desde fuera de Clarive.

Los servicios web son la mejor forma de automatizar operaciones de Clarive desde
fuera de la herramienta.

En lugar de llamar directamente a las API de manera directa (por ejemplo, "Crear
un tópico"), se recomienda la creación de una regla de tipo webservice que cree
el tópico. A continuación esa llamada se podrá realizar desde la línea de comandos
o desde otras aplicaciones o servicios.