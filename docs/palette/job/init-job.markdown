---
title: Init Job Home
---

This service is required for a correct job startup. Create or 
clean job directory depending if it exits or not.  

Job directory is formed using the path: 

* **$ENV{CLARIVE_JOBDIR}/** or    

* **$CLARIVE_BASE/jobs/** if environment variable above is not defined.    
and

* **< N|B >.< bl >-< job_id >** where parameters are:    

      &nbsp; &nbsp; • N / B: depending on the job type, N for promote or static jobs or B for demote jobs.     
      &nbsp; &nbsp; • < bl >: Environment.    
      &nbsp; &nbsp; • < job_id >: unique number from mongo.     

