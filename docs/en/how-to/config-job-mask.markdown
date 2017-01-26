---
title: Config Job Mask
index: 5000
icon: job
---

By default, when you see job monitor, the job names are created following this rule:

- **Prefix.Environment-Sequence**

This can be changed by editing the configuration variable `config.job.mask`. To edit this variable, go to Admin>Config
List and search it.

Here, you can use internal variables of the job. For example, to show the id of the job following by the environment,
you can configure the variable like this:

- **${mid}-${bl}**
