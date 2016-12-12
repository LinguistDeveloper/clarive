---
title: Init Job Home
index: 5000
icon: job
---

This service is required for a correct job startup. Create or
clean job directory depending if it exits or not.

Job directory is formed using the path:

`$ENV{CLARIVE_JOBDIR}/`


Or

`$CLARIVE_BASE/jobs/` - If environment variable above is not defined.


And

`<N|B>.<bl>-<job_id>` - Where parameters are:

- `<N|B>` - Depending on the job type, N for promote or static jobs or B for demote jobs.
- `<bl>` -  Environment.
- `<job_id>` - Unique number from mongo.

