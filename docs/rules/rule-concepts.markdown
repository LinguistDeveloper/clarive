---
title: Rule Concepts
---

Once the different needs are recorded and managed through the 
various states that make up their lifecycle, they must be deployed and delivered for final operation. 
It is highly related to Change set Management.  
Rule Management is in charge of automation and deployment among systems.     

Automation is done through rules executions; they must be 
created first using Clarive process definition, also Clarive supplies 
all needed tools to manage rules. For rule management, a number of 
Clarive concepts are describe here.     
   
### Types of rules

There are 3 types of rules:

* *Job Chain*: Chain through. There are three possible final steps.     

      &nbsp; &nbsp; • promote    
      &nbsp; &nbsp; • static    
      &nbsp; &nbsp; • demote         

* *Event* - triggers or triggers based on actions performed on the system.     
* *Independent* - little rules to include within more complex rules, simplifying the system.     

### Job Steps         

When a rule is created, 5 steps are displayed, these are:    

* CHECK: check before creating the job, job object not yet available.
* INIT: check after creation, but in order to job longer available.
* PRE: immediate implementation prior to the scheduled time.
* RUN: run at the scheduled time.
* POST: runs allways when job finishes right or wrong.

### Types of Tasks  

It is divided in three types of tasks:

* *Statements*: Provide control flow rule, they are IFs and Fors, and ad- hoc tasks.
* *Services*: Operating in the pass,  they can be:     

      &nbsp; &nbsp; • Job Services. Tasks associated to a job.    
      &nbsp; &nbsp; • Generic Services. General type.
    
* *Rules*: Allow including rules within other rules, these rules to be include have to be of independent type.

### Stash

The stash of the rules is Clarive system that keeps the state of the pass between runs. Stash variables are used to communicate between tasks and it is used to replace the variables in the different configurations.



