---
title: cla queue - Queue management tools
index: 5000
icon: console
---

`cla queue`: Queue management tools is performed through redis pub/sub
implementation, so a redis server and a worker is needed to run this command.

`cla-queue`: Without any option, it displays all workers registered.
It supports the option `–v`, display worker configuration.

Subcommands supported can be displayed with the help option:

        > cla help queue

        usage: cla [-h] [-v] [--config file] command <command-args>

        Subcommands available for queue (queue management tools):
        queue-pin
        queue-worker
        queue-de
        queue-key
        queue-flush

        cla help <command> to get all subcommands
        cla <command> -h for command options.

`cla queue-ping`: It needs the parameter`–wid <workerid>`: worker id for trying to ping worker.

If the connection is established, the output displays the worker status and config.

`cla queue-workers`: Same behavior as running the command alone.

`cla queue-keys`: Displays all keys matching  a mask, this mask can be set:

      - As an argument to the command  `--mask <mask_name>`. It displays all keys with mask_name.

      - If no argument is found, the mask is set ‘*’, and all keys will be displayed.


`cla queue-del`: Delete all keys matching a mask, this mask can be set:

      - As an argument to the command `--mask <mask_name>`,it deletes all keys with mask_name.

      - If no argument is found, the mask is set ‘*’, and all keys will be deleted.


`cla queue-flush`: It tries to ping every worker registered, if succeeded,
a messaged is displayed saying all workers online, if any worker doesn’t response,
it removes the worker from the queue and a message is displayed to inform.

