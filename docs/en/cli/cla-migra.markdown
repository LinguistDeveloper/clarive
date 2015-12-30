---
title: cla migra - Migrations
icon: console
---

<img src="/static/images/icons/console.png" /> `cla migra`: Runs database migrations, which are needed to level the database version with the current version of Clarive after installing patches. 

<br />
## Subcommands
<br />

### migra-init

* Initializes the migrations

<br />
### migra-start

* Upgrade/Downgrade the migrations. Options are:
            
        --init run initialization before migrating
        --path path to migrations instead of default

<br />
### migra-set

* Manually set the latest migrations version
            
        --version the version to be set


<br />
### migra-fix

* Removes the error from last migration. Use *ONLY* when the issue is really
fixed

<br />
### migra-specific

* Upgrade/Downgrade manually by passing the migration name (upgrade by
default). Options are:
            
        --name name of the migration
        --downgrade run downgrade instead of upgrading



     
