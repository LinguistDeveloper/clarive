---
title: Plugins
index: 5000
icon: page
---

The Clarive plugin system is the official way of
extending the product. Every official entry point
into the product should be available to plugins.

## Plugin locations

There are 2 directories where plugins can be
kept:

- under the `CLARIVE_BASE/plugins` directory, intended for
user-created, installation-specific or public-available downloable plugins.
- under the `CLARIVE_HOME/plugins` directory, where **only
product propietary** plugins are kept.

## Overwriting plugins

Public plugins can overwrite product plugins at anytime, as
public plugins have precedence over product ones.

To overwrite a product plugin, just create a plugin
with the same name as the private ones and overwrite
them.

**NOTE** - overwriting product plugins may lead to
unstable behaviour. In most cases, it's better to
just use a different module/library name.

## Plugin directory structure

The plugin system loads files from a predefined folder structure.
The folder structure determines **where and when** the plugin files will
be loaded, but it does not determine what the exact contents of the loaded file will have.

This is the directory structure:

- `plugin/modules` - modules that can be required on demand by the Clarive JS DSL with the function `require()`
- `plugin/init` - code executed at startup, that can load CI classes or register menus, actions and other structural code
- `plugin/forms` - Web JS forms that can be used in the interface
- `plugin/rules` - Rule DSL that can used independently or as part of a program

## What happened to Clarive Features?

Features are still there. They remain as the Clarive provided lab additions
to the product.

The feature system is not intended for general availability and
customization and any features added to the product are not officially
supported unless previously agreed up.

The feature system is totally separate from the plugin system, with
a different directory structure, hook points and language.


