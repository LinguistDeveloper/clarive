---
title: Análisis para la preparación de una release
index: 1000
---

## Lista de comprobación para la preparación

A continuación se muestra una lista de comprobación para la revisión de preparación de la Release y la auditoría previa
a la Entrega. Es útil tanto para los managers de proyectos como para los analistas de calidad de software.

¿La entrega va en contra de un Contrato / Declaración de trabajo / orden de trabajo aprobado? Si no es así, ¿está el
correo para la aprobación de la alta dirección disponible para la entrega?

¿Ha sido validado y aprobado por el cliente el documento de requisitos / FSD?

¿Se aplican todos los requisitos según el documento de requisitos aprobado o documento de especificación o de acuerdo
con el cliente? Si no, ¿está documentado en las notas de la release / nota de entrega, etc. y la aprobación ha sido
tomada por el responsable del cliente / entrega?

¿Están cubiertos / completados todos los requisitos no técnicos / no funcionales?

¿Se ha realiza la verificación de la construcción antes de la fase de Testing?

¿Están todos los casos actualizados asegurar la cobertura completa de las pruebas?

¿Están todos los ciclos de testing completados y las incidencias cerradas? Si hay alguna abierta, ¿está documentada en
las notas de la release / nota de entrega etc.. y aprobada por el responsable de la entrega o cliente?

¿Se han cerrado todos los defectos de revisión?

¿Se cumple la meta de cobertura de las pruebas como se menciona en el plan de pruebas?

¿Existe trazabilidad desde los requisitos al código fuente hasta los casos de prueba y los resultados de las pruebas
están documentados y disponibles para su revisión?

¿Se cumple el objetivo de la prueba del sistema / pruebas funcionales o cualquier otro tipo de pruebas?

¿Se han identificado y documentado todos los casos de prueba para las pruebas de aceptación?

¿Se realizan auditorías para todos los elementos identificados en el plan de aseguramiento de la calidad del software?

¿Se han cerrado las conclusiones de FCA / PCA / otras auditorías (si las hay)?

¿Se han ejecutado los casos de prueba en el entorno de destino (o un entorno similar al de destino)?

¿Está disponible el criterio de aceptación para la validación del sistema?

¿El producto / aplicación final cumple los criterios de aceptación durante las pruebas del sistema?

¿Está el historial de modificación de código actualizado y los archivos de código se etiquetan correctamente en la
herramienta de configuración?

¿Todos los productos de trabajo, entregables y código son consistentes?

¿Están los CIs de todo el paquete de la release identificados?

¿Están todos y cada uno de los CIs incluidos en la release testeados / revisados / aprobados?

¿Se han cerrado todos las conclusiones de las pruebas / revisiones de los CI?

¿Están las credenciales de FTP o la clave de CD documentadas? ¿Se comunican con el cliente / consumidor?

¿Se verifica el medio de la release y su acceso está verificado antes de enviar la información al cliente?

Están disponibles los siguientes documentos / entregables / productos de trabajo: FSD, ADS, DDS, Plan de Prueba, Caso de
Prueba, Nota de Lanzamiento, Producto Instalable, Código Fuente, Programas de Pruebas, Controladores, Archivo Léame,
Archivo de Licencia, Lista de Problemas Conocidos, Procedimiento de Instalación , instalación de scripts, Manual del
usuario, Manual del programador, Manual del administrador, Informes de prueba, Material de instrucción o cualquier otro
producto requerido por el cliente?

¿La entrega se realiza desde la carpeta estática de VSS?

Aparte de los puntos anteriores, también se puede comprobar el estado de los puntos siguientes:

Bases de los resultados en la herramienta de gestión de la configuración.

Fin de la copia de seguridad del proyecto  y restauración de la copia de seguridad.

Preparación del plan de mantenimiento / apoyo.

¿Se documenta el procedimiento de notificación de problemas y se comunica al cliente?

¿Están las personas de contacto documentadas y comunicadas al cliente?

¿Está preparada la plantilla de notificación de defectos post-release?

¿Se ha hecho una petición a TI para hacer que el repositorio del proyecto esté bajo VSS solo lectura?
