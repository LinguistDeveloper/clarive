---
title: Remove Attached Files
icon: topic.svg
---

Service that removes the assets attached from a [topic](concepts/topic). Form to configure has the following fields:

* **Remove by**: Choose remove attachment by assets mids or by topic fieldlets.

	* **Asset mids**: Text field to introduce assets mid, it accepts multiple values separated by commas or variable of type array or string.

	* **Fields**: Text field to introduce fieldlets ids, it accepts multiple values separated by commas or variable of type array or string. 
		It removes all the attachment into the fieldlet selected.

* **Topic Mid**: Text field to introduce topic mid, it only accepts one value. Is possible to use variables to define the topic mid.

* **User**: User that removes the assets or Clarive if not provided. Is possible to use variables to define the user.
