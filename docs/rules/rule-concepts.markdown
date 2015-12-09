---
title: Rule Concepts
---

* Once the different needs are recorded and managed through the 
various states that make up their lifecycle, they must be deployed and delivered for final operation. 
It is highly related to Change set Management.
Rule Management is in charge of automation and deployment among systems.

* Automation is done through rules executions; they must be 
created first using Clarive process definition, also Clarive supplies 
all needed tools to manage rules. For rule management, a number of 
Clarive concepts are describe here.
  
<br /> 
### Types of rules

* There are 3 types of rules:

&nbsp; &nbsp;• **Job Chain**: Chain through. There are three possible final steps. <br />
    &nbsp; &nbsp;&nbsp; &nbsp; • Promote <br />
    &nbsp; &nbsp;&nbsp; &nbsp; • Static <br />
    &nbsp; &nbsp;&nbsp; &nbsp; • Demote <br />
&nbsp; &nbsp;• **Event** - Triggers or triggers based on actions performed on the system. <br />
&nbsp; &nbsp;• **Independent** - Little rules to include within more complex rules, simplifying the system.

<br />
### Job Steps

* When a rule is created, 5 steps are displayed, these are: <br />

&nbsp; &nbsp;• **CHECK**: Check before creating the job, job object not yet available. <br />
&nbsp; &nbsp;• **INIT**: Check after creation, but in order to job longer available. <br />
&nbsp; &nbsp;• **PRE**: Immediate implementation prior to the scheduled time. <br />
&nbsp; &nbsp;• **RUN**: Run at the scheduled time. <br />
&nbsp; &nbsp;• **POST**: Runs allways when job finishes right or wrong.

<br />
### Types of Tasks  

* It is divided in three types of tasks:

&nbsp; &nbsp;• **Statements**: Provide control flow rule, they are IFs and Fors, and ad- hoc tasks. <br />
&nbsp; &nbsp;• **Services**: Operating in the pass,  they can be: <br />
      &nbsp; &nbsp;&nbsp; &nbsp; • *Job Services* - Tasks associated to a job.<br />
      &nbsp; &nbsp;&nbsp; &nbsp; • *Generic Services* - General type. <br />
&nbsp; &nbsp;• **Rules**: Allow including rules within other rules, these rules to be include have to be of independent type.

<br />
### Stash

* The stash of the rules is Clarive system that keeps the state of the pass between runs. Stash variables are used to communicate between tasks and it is used to replace the variables in the different configurations.



