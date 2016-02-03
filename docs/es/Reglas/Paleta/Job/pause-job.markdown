---
title: Pause a Job
icon: job
---
* Paraliza un trabajo hasta que le usuario decida que se reanude. Esta pausa tiene un tiempo de espera máximo establecido en 1 día.
* Un job se puede pausar en el estado INIT y CHECK. Si un job se cancela mientras está parado, el job fallará.
* Los elementos configurables son los siguientes

<br />
### Motivo
* Mensaje que aparecerá en el Monitor tras parar un job.
* Si el campo está vacío se mostrara el mensaje `‘unspecified’`

<br />
### No falla en tiempo de espera
* Indica si el trabajo falla en caso de que expire la pausa.

<br />
### Detalles
* Campo para especificar los detalles de la pausa del job.