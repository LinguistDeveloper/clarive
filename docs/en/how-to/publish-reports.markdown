
---
title: Publish a static report
index: 1
icon: report
---

Every time a user makes an export (topic grid or a report) a new event is generated. This event calls *event.topic_list.export*, contains all information related to the export; format, parameters, title, author and the temporaly file generated.

This temporal file is automatically **removed** when event finishes but there is a way to store the report in a permanent and unique URL. To get this is neccesary create a event rule.


## Creating the rule

First of all, we need to create an event rule. The event name for this activity is *event.topic_list.export*. To create a basic rule, we are going to add the service *[service.artifacts.publish](rules/palette/services/publish_files_according_catalog)* which allows to public every export to artifacts repository.

Now we configure the service:

* **Repository**: Set the repostory as *public* to generate a public URL.

* **Path**: We set the name and the extension of the file.. The extension is given in the event properties that has a parameter call *export_format*. For the file, we can use a static name o a name given by a variable:

    * *Fixed names*: If we choose a fixed name, the file will be overwriteen in every export action: *myreport.html*

    * *Variable name*: This is the best way to use and made permanent reports. We set a variable for the name of the report and use the event parameter *export_format* for the extension of the file: *${my_variable}.${export_format}*.

* **Origin**: Set the file source. As we told before, the event created a temporal file, so we need to set this field as a reference to that parameter *${export_temp_file}*

Having done that, and after save the rule, we export a report or a topic grid with filter to one of the available formats (HTML, CSV o YAML). To check if the rule is correct, go to Tools - Artifacts to verify if in the public repostory is saved the report with the name we gave in the Rule config. In case you want to share the report, just copy public URL.

