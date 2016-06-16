---
title: Send a notification
icon: job.svg
---
Service to send notifications. Form to configure has the following fields:

* **TO**: Users to send the notification. You can add users, roles or emails.

* **CC**: Users to send the notification in copy. Like in *TO* field you have three options to fill it. Optional field.

* **Subject**: Subject of the message. Can be a variable value using *${variable}*

* **Body**: Message body. Users can use variables values using *${variable}*

* **Attachment path**: Attach a file or a directory. Must be added the path of the file or a directory path which is being attached.
The maximum size is the value of *max_attach_size* configured in `Config List`.
If you attach a directory, all files will be contained in a zip file.
Can be a variable value using *${variable}*.

Some useful examples

	${home}/tmp/clarive/docs.zip

	/tmp/${clarive_home}/doc${version}.doc

	${clarive_home}/output/file.${file_extension}


*Note*: If the file exceeds the maximum size, the notification will be sent without attached files.

* **Output filename**: Rename attachment. If this field is empty, the name of the attachment will be the name by default.