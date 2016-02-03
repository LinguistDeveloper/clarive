---
title: API Keys
index: 5000
icon: lock_small
---

* The API Keys preference page allows you to create keys that can be used 
to access your subscription data without using your username 
and password. However, any application using the API Key you 
generated will have access and be tracked as if you logged 
in with your username and password. API Keys do not require an additional 
Clarive license because they are an extension of your own user license.

* API Keys are strings that authenticate a user when accessing the 
Clarive Web Services API. However, unlike a session token, 
the API Key does not expire. API Keys obey the permissions of 
the user that generated them - it is just like using that 
user’s credentials. Keys are valid as long as 
the user desires, and can be deleted or reset.

* Clarive administrators may view, delete, and reset 
all active keys in a installation from the API Keys page.

<br />
<p class="help-note">
<b>Note</b> If API Keys are disabled at the installation level, a user trying to setup a new API Key or 
edit an existing API Key will see an error message that 
states API Keys are disabled. Please contact your Clarive Administrator 
to enable this functionality. 
</p>

<br />
### To create a new key

* Open the user preferences pane or use the administrator user preference management option. 

* Click the `Generate API Key` button or enter an API key value. Then hit `Save API Key`.

