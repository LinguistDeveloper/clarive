---
title: Mainframe Delivery Automation
index: 4100
---

Clarive comes with native integration with the mainframe.  Clarive is the ideal
tool to implement an enterprise-wide delivery cycle that does not leave behind
the legacy systems.

### List of Mainframe Facilities Available

Here are the key mainframe integration points with Clarive:

- Build and Deployment of Z/OS artifacts stored in a open source code repository (ie. Git or SVN)
- Build and Deployment of Z/OS artifacts stored in the Z/OS file system
- Monitoring of deployment jobs
- Chaining of deployment spool results
- Parsing of spool log results for errors, etc.

Also, plan your implementation to get the most out of Clarive:

- Packaging, building and deployment of Z/OS programs is done by Clarive
- Compile and link programs using JCL preprocessed templates. Deploy DB2 items
  directly to the database
- Control what is each environment: Development, QA, Production, etc.  Schedule
  jobs according to individualized release and availability calendars and
  windows
- Request approval for critical deployment windows or sensitive applications or
  items.
- Keep the lifecycle in sync with external project and issue management
  applications.
- Run SQA on the changes promoted. Block deployment if a minimum Reliably
  rollback changes in Production.

### Sending files to Z/OS partitions

The Clarive USS agent manages the shipping of files directly into Z/OS or USS (OMVS)
partitions in the mainframe.

Clarive uses in-line JCL file wrapping to ship files using the FTP-JES mechanism.

### Identify Relationships – Impact Analysis

Clarive can parse source code to determine what other
programs need to be compiled when there's a change in an artifact.

### Submit JCL from templates

Define JCL templates in Clarive, then submit them as jobs into the Z/OS JES facility.

JCL templates can have variables that are defined for each environment, adding
a great layer of flexibility to JCL processing for implementing complex compile and deploy logic.

### Compile, Ship

Clarive JCLs can build and deploy just about any artifact that can
be automated by a job card in the mainframe.

The spool system controls nesting, so that if a JCL sends another JOB for
execution, Clarive will track down

### Retrieving Job Spool output

All jobs executed by Clarive are controlled for errors and other results.

Clarive manages the spool log generated while running JCLs in the mainframe, by
capturing and splitting its output so that results can be easily read in each
of its section from Clarive's web interface.

### Character translation maps

Clarive can translate characters in both job cards and source code
being sent from Clarive server.

Use the `Sed Parser` op in the Clarive rule to implement translations
as needed.

### REXX API

You can setup REXX on the mainframe to call into Clarive rules
using our webservice API.

Here's an example of how a REXX calling into Clarive would
look like:

    /* REXX */
    call claws '/rule/raw/is_release_ready', "api_key", "1234", "release_id", "r.2.3.4"

## Mainframe Requisites

There are only 2 requisites for mainframe compatibility with Clarive:

- FTP-JES facility enabled
- Optionally, a USS/OMVS partition for the ClaX agent -- not needed to ship
  files, submit jobs, etc. only for special integrations.
- REXX, for calling Clarive rule webservices

### FTP-JES Interface

Before starting, ensure the following:

- Your Z/OS machine has the FTP server running
- You have a suitably authorized user ID
- In addition, you can use any of several configuration parameters to control
  the behavior of the JES interface, including the most important
  configuration parameter `JESINTERFACELEVEL`

#### JES interface configuration parameters

- `JESINTERFACELEVEL` - Specifies the level of function the JES interface
  provides. Set to 2 for the most function.
- `JESENTRYLIMIT` - Limits how many jobs will be returned. The default is 200.
- `JESOWNER` - Limits jobs retrieved to jobs with this owner. If blank,
  defaults to the current user.
- `JESJOBNAME` - Limits jobs retrieved to jobs with this job name. If blank,
  defaults to the current user concatenated with an \*. Use \* to retrieve all
  jobs.
- `JESSTATUS` - Limits jobs retrieved to jobs with this status. If blank,
  defaults to all states. Valid states are OUTPUT, ACTIVE, and INPUT.

