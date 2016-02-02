---
title: Writing Custom Authentication Rules
icon: rule
---

* It's possible to write custom authentication rules
using the Clarive Rule editor. 

* To create your own, customized authentication rule, 
do the following:

<br />
### Create an Event Rule for a Login Attempt

* From the Rule editor, create a new rule of type 
`event` associated to the event `User Login Attempt`
(`event.auth.attempt`).

<br />
### Write your rule specifics

* Do your own authentication routines within 
the rule, for instance, calling a web-service 
or looking-up a user through a command.

* The variables made available in the stash for you, are: <br />

&nbsp; &nbsp;• `Username` - The user id, should match the record in the user database in Clarive. <br />

&nbsp; &nbsp;• `Login` - The full text entered into the login box. <br />

&nbsp; &nbsp;• `Password` - The password entered by the user *Caution*, be careful where you write this information. <br />

&nbsp; &nbsp;• `Realm` - The login authentication realm the user has entered, could be empty (default) or could be something like
'local' for local users, etc.

<br />
### Allow the user to authenticate

* Drag and drop an `Authorize User Login` task from the palette
into your rule to authorize the user. 

<br />
### Deny the user authentication

* Drag and drop an `Deny User Login` task from the palette
into your rule to deny the user login. 

* Consider also using the palette task `Login Error Message`
to publish an error message back to the user letting her know 
why the login was denied. 

<br />
### Notes

* If you neither allow nor deny the user authentication, Clarive will follow its normal authentication checks.
* This rule is now invoked for auth_key (api) authentication.

<br />
### Example

* This rule snippet  is an example of the basic structure for validating a user in a 
rule. 
* Use the right-click `Import here` option in the rule editor to import this snippet. <br />

            
        [{
        "attributes": {
            "palette": false,
            "icon": "/static/images/icons/if.gif",
            "disabled": false,
            "on_drop_js": null,
            "key": "statement.if.var",
            "text": "IF username == root",
            "expanded": true,
            "run_sub": true,
            "leaf": false,
            "name": "IF var THEN",
            "active": 1,
            "holds_children": true,
            "data": {
                "variable": "username",
                "value": "root"
            },
            "nested": "0",
            "on_drop": ""
        },
        "children": [{
            "attributes": {
                "icon": "/static/images/icons/user_delete.gif",
                "palette": false,
                "disabled": false,
                "active": 1,
                "name": "Deny User Login",
                "data": {},
                "key": "service.auth.deny",
                "text": "Deny User Login",
                "expanded": false,
                "leaf": true
            },
            "children": []
        }, {
            "attributes": {
                "icon": "/static/images/icons/user_delete.gif",
                "palette": false,
                "disabled": false,
                "active": 1,
                "name": "Login Error Message",
                "data": {
                    "msg": "User no way",
                    "args": []
                },
                "key": "service.auth.message",
                "text": "Login Error Message",
                "expanded": false,
                "leaf": true
            },
            "children": []
        }]
        }, {
        "attributes": {
            "palette": false,
            "icon": "/static/images/icons/if.gif",
            "disabled": false,
            "on_drop_js": null,
            "key": "statement.if.else",
            "text": "ELSE",
            "expanded": true,
            "run_sub": true,
            "leaf": false,
            "name": "ELSE",
            "active": 1,
            "holds_children": true,
            "data": {},
            "nested": "1",
            "on_drop": ""
        },
        "children": [{
            "attributes": {
                "icon": "/static/images/icons/user_add.gif",
                "palette": false,
                "disabled": false,
                "active": 1,
                "name": "Authorize User Login",
                "data": {},
                "key": "service.auth.ok",
                "text": "Authorize User Login",
                "expanded": false,
                "leaf": true
            },
            "children": []
        }]
        }]



    

