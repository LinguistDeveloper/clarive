---
title: Init Job Home
icon: job
---

<img src="/static/images/icons/job.png" /> This service is required for a correct job startup. Create or 
clean job directory depending if it exits or not.

* Job directory is formed using the path: 

`$ENV{CLARIVE_JOBDIR}/` 

* Or

`$CLARIVE_BASE/jobs/` - If environment variable above is not defined.

* And

`<N|B>.<bl>-<job_id>` - Where parameters are: <br />

&nbsp; &nbsp; • `<N|B>` - Depending on the job type, N for promote or static jobs or B for demote jobs. <br />

&nbsp; &nbsp; • `<bl>` -  Environment. <br />

&nbsp; &nbsp; • `<job_id>` - Unique number from mongo.

