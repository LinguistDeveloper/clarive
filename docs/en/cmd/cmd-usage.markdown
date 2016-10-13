---
title: Using the Command-line
icon: console
index: 1
---

All Clarive command-line interface (CLI) commands
share a few commonalities.

## Getting help

To get help for a command,
just write:

    cla help [command]

For a list of commands available,
type:

    cla help

The list can vary according to the installed
features and plugins.

## Passing options

Most options can be passed using command line arguments
(sometimes called flags) preppended by double dash `--`.

For instance:

    --max_workers 20

In the command-line, options with underscore
may be replaced with a dash `-`, so you could also write:

    --max-workers 30

**NOTE**: Although this is valid for the command-line
options, it does not hold true for environment config files.

The value passed to the command-line option
may be followed by an equal sign or separated by a space, so
this is also a valid format:

    --max_workers=30

## Config overwriting

The same command line options can be set in
your environment config file `[env].yml`, by
writing the option into your config file:

```yaml
max_workers: 30
```
## Nested data as command-line options

It's also possible to assign values to nested keys 
through the command-line, by using a JSON-style attribute notation:

    --cache_config.expire_seconds 3000

Any dots `.` found in a command-line argument will be 
translated to nested value. In the case above, the `[env].yml`
equivalent would be:

```yaml
cache_config:
  expire_seconds: 3000
```

Another of doing this is to load a JSON-formatted string object
into the command-line with the `--json` option:

    --json '{ cache_config: { expire_seconds: 3000 } }'

## Checking the loaded config

The final environment + command-line setup may
be checked to see what values Clarive is finally loading
by running the command `cla config-show`

    cla config-show

Dumps a YAML representation of the current data.
