---
title: Introduction
index: 100
---

JavaScript is the language of choice for writing automation rules code in Clarive.

JavaScript, shorted as JS in many places, is the perfect language for such task, as its syntax is simple and universally
known and understood. Everyday new libraries, both client and server alike, are being implemented
to extend the language and diversify its reach and approach.

JavaScript has the following attractive features:

- simple-yet-powerful data structures
- fast interpreter
- widely adopted, which translates into many tools and resources available from the internet to
enable development

Additionally, the implementation of JavaScript in Clarive adds the following:

- a threading model, for writing concurrent tasks
- template literals, for multi-line strings with flexible and powerful templating
- heredocs, also for multi-line strings but without iterpolation for `${...}` variables
- an embedded module loading system (`require`) that enables you to leverage the power of
opensource and commercial extensions.

### Why do I need to write JavaScript in rules?

Sometimes using palette operations in rules is not enough. Complexities
of data manipulation and other processing may be required by your automation
workflow. For example:

- extracting a substring out of text entered into a topic field
- writing to a file in the filesystem
- analyzing the different relationships among topics in a release
- etc.

That's when JavaScript comes in. Using rule Server Code operations
enables Clarive administrators to develop new functionality that expands
the usability of the automation rules to the next level.

### JavaScript API in Clarive

Clarive's JavaScript API is built as an extension to the language
through the singleton object `Cla`.

The API is robust and allows developers to use the following
library areas:

- Filesystem
- Mongo Database access
- Configuration Items (CIs), with access to data, relationships and class methods
- Clarive security (user, roles, etc)
- Events, semaphores and other system control utilities which are handy for automation
- Generic utilities for data manipulation, including a powerful regular expression engine
- Unicode suppport
- and much more!

### Version of JavaScript implemented in Clarive

The current JavaScript interpreter is based on the [Duktape](http://duktape.org)
embedded interpreter engine, which
is [Ecmascript v5/v5.1 compliant](http://www.ecma-international.org/ecma-262/5.1/),
although some Ecmascript v6 features are also available:

List of Ecmascript v6 features supported by Duktape is available [here](http://duktape.org/guide.html#es6features)


