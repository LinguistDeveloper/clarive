---
title: Webservice
icon: webservice
---

* In Clarive, a webservice is a type of [rule](concepts/rule) that can be called from outside Clarive. 

* Webservices are the preferred way of automating Clarive operations from the outside world. 

* Instead of calling API primitives directly (ie. "create a topic"), 
we recommend creating a Webservice rule that creates a topic.
Then call that from the command-line or from other applications
and services. 
