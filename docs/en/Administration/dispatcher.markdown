---
title: Dispatcher
index: 3
---
* The dispatcher is responsible for implementing the program batch operations separately from the online calls made by the web client and web-services.
* For example, Dispatcher is responsible for making passes environments or send email notifications to users.
* This is a separate server process, you can lift more processes on demand in the queue of pending jobs.