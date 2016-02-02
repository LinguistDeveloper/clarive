---
title: Trabajo
icon: job
---

* Los trabajos (o pases) son reglas ejecutadas por el servidor de Clarive.

* Se ejecutarán siempre que estén planificados, si el usuario quiere ejecutar 'ahora' un trabajo o en 3 meses, siempre se incluye en la planificador antes de que el demonio de trabajos haga su función y lo ejecute.

* Los trabajos pueden ser ejecutados las veces que se quiera a traves de [reejecuciones](es/Conceptos/rerun).

* Si el usuario desea que un pase se ejecute de manera frecuente (por ejemplo, diariamente, cada dos dias, mensual, etc...) puede hacer uso del [planificador](es/Conceptos/scheduler).

<br />
## Los pases son CIs

* El nombre del pase identifica al pase. Pero los pases, al igual que el resto de CIs poseen un [mid](es/Conceptos/mid) con el que poder trabajar.