---
title: cla db - database utilities
---

`cla db`: database diff and deploy tool.

This command is in charge of deploying Clarive schema to a database. The behavior is the same as the command `db-deploy`.
The option `–h` shows the command help with a short description of every option:

    >cla db -h

    NAME
     Clarive DB Schema Deploy

    DESCRIPTION
     Deploy Clarive's schema to a database.

    USAGE
    cla db-deploy [options]

    Options:

     -h			:this help
     -deploy		:actually execute statements in the db
                                	cla db-deploy --deploy
     -run		:Run DB statements interactively or from STDIN
     -quote		:quote table names
     -drop		:add drop statements
     -grep		:grep a string or re in the generated sql
     -env		:sets CLARIVE_ENV (local, test, prod, t, etc...)
     -schema		:schemas to deploy (does not work for migrations)
                        cla db-deploy --schema BaliUser --schema BaliProject

     Versioning Options:

    --diff		:diffs this schema against the database
    --installversion	:installs versioning tables if needed
    --upgrade		:upgrades database version
    --from <version>	:from version (replaces current db version)
    --to <version>	:to version (replaces current schema version)
    --grep <re>   	:filter diff statements with a reg. expression

      Examples:

      cla db-deploy --env t
      cla db-deploy --env t --diff
      cla db-deploy --env t --diff --deploy
      cla db-deploy --env t --installversion
      cla db-deploy --env t --upgrade     		# print migration scripts only, no changes made
      cla db-deploy --env t --upgrade –deploy		# print migration scripts only, no changes made
      cla db-deploy --env t --upgrade --show --to 2	# same, but with schema version 2
      cla db-deploy --env t --upgrade --show --from 1   # same, but with db version 2

