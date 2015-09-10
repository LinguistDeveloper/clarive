---
title: Pause a Job    
---

Pause a job until the user decides to go on. This pause has a maximum timeout, 
set as default to 1 day. A job can be paused on INIT and CHECK status. If job gets cancel or an error is produced 
while in pausing, the job will fail. Form to configure has the following fields:    

* **reason**: Message to display in monitor after pausing a job. If empty the message ‘unspecified’ will be displayed.     

* **no_fail**: checkbox to indicate if job fails in case the pause expire.    

* **details**: Details about pausing a job.     

