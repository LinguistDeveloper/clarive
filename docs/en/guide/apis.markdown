---
title: Using Clarive APIs
index: 4000
---

The Clarive API does not offer out-of-the box URL endpoints.  You have to
expose them first. This means creating webservice rules, then exposing the
endpoint to your external application.

Webservices rules can be exposed as either REST or SOAP
endpoints, which improves connectivity and centralizes
the execution of automation logic.

The Clarive API powerful primitives are available within the rule,
using operations or with JavaScript code directly.

Therefore, the Clarive recommended way to implement calls to our API is:

1) write a webservice rule that exposes the endpoint URL
2) call that URL externally, setting the return data format in the URL

#### Why we don't offer just a simple REST API?

Exposing REST APIs means you can automate logical sequences
from external tools, programming languages or scripts.

We firmily believe creating scripts outside of the tool is problematic,
specially when Clarive is an automation tool is advanced monitoring, logging,
concurrency control and event handling built in. Also, we include
testing and dry-run modes that can help you debug your delivery automation
logic in one go. When you take automation logic outside of
Clarive into other tools

For example, you could write a script that creates a topic,
fills out some data, then promotes the topic to the next status.

But, instead, the same can be done in a webservice rule, you write
a webservice rule that does that, then call that endpoint
with something like cURL (the `curl` commmand, which can be used
to call REST URLs.

#### Building Plugins

If you are an independent vendor or programmer who wants to
integrate your tool with Clarive by writing a plugin, you
have to write part of your plugin that runs under Clarive, then have
it installed under the `CLARIVE_BASE/plugins` directory.

### The Clarive API

Here are a list of the primitives of the Clarive API, exposed
through the rule operations:

- create, update, delete, list topics
- create, update, delete, list CIs
- deployment and job management
- notifications
- event management
- semaphores
- provisioning
- impact analysis
- MongoDB operations
- etc.

Please refer to the [development guide](devel/intro) for
a detailed explanation on what the Clarive API offers.

#### Return Data Formats

Return data formats from webservice rules can be:

- JSON
- YAML
- XML
- Raw - just plain text or binary data returned by a rule

Just set the desired format in the URL, following the
webservice URL format:

    http(s)://clariveserver/rule/[json|yaml|xml|raw]/[rule-id]

### Authentication

Webservice endpoints can be either authenticated or public.

Public endpoints can be accessed by anyone. Never implement public webservices
that run sensitive operations.  Public webservices are useful for maybe
reporting data that is public as JSON, for instance.

The authentication method is through an **api-key**. API keys are
managed on a per-user basis.

We recommend creating specific users, set their permissions,
then grab the api-key for that user to be used in the URL.

