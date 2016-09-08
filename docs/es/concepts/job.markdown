---
title: Trabajo
icon: job
---

Los trabajos (o pases) son reglas ejecutadas por el servidor de Clarive.

Se ejecutarán siempre que estén planificados, si el usuario quiere ejecutar
'ahora' un trabajo o en 3 meses, siempre se incluye en la planificador antes de que
el demonio de trabajos lo ejecute.

Los trabajos pueden ser ejecutados las veces que se quiera a traves
de [reejecuciones](concepts/rerun).

No funciona como en Jenkins, los jobs no son planificados de forma
estática por entidad. No puedes planificar jobs de forma repetitiva. Los
Jobs se *planifican una vez* y se *ejeucutan una vez* (aunque de forma manual
se pueden replicanificar y relanzar tantas veces como se quiera )

Si el usuario desea que un pase se ejecute de manera frecuente (por ejemplo,
diariamente, cada dos dias, mensual, etc...) puede hacer uso del [planificador](admin/scheduler).

## Los pases son CIs

El nombre del pase identifica al pase. Pero los pases, al igual que el resto de
CIs poseen un [mid](concepts/mid) con el que poder trabajar.
