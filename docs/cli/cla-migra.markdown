---
title: cla migra - migrate
---

Runs database migrations, which are needed to level the
database version with the current version of Clarive
after installing patches. 

## Subcommands:

### migra-init

Initializes the migrations

### migra-start

Upgrade/Downgrade the migrations. Options:

      --init run initialization before migrating
      --path path to migrations instead of default

### migra-set

Manually set the latest migrations version

      --version the version to be set

### migra-fix

Removes the error from last migration. Use *ONLY* when the issue is really
fixed

### migra-specific

Upgrade/Downgrade manually by passing the migration name (upgrade by
default). Options:

      --name name of the migration
      --downgrade run downgrade instead of upgrading
