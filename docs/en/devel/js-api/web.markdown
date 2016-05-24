---
title: cla/web - Web tools
---

This namespace contains useful functions
for web protocol and communications, such 
as invoking REST and SOAP apis and general 
webservices. 

<pre>
 KEY                     DEFAULT                     
---------------------------------------------------------
agent                    "clarive/js"        
from                     undef                      
conn_cache               undef                      
cookie_jar               undef                      
default_headers          HTTP::Headers->new         
local_address            undef                      
ssl_opts                 { verify_hostname:   1 }   
max_size                 undef                      
max_redirect             7                          
parse_head               1                          
protocols_allowed        undef                      
protocols_forbidden      undef                      
requests_redirectable    ['GET', 'HEAD']            
timeout                  180                        
---------------------------------------------------------
</pre>

### web.agent(options) 

Creates a new web agent object. 
The web agent object is analogous to a browser 
or a `curl` command, in a way that it can be used to craft 
elaborate web requests.

In this example, we invoke a REST `GET` webservice
that returns JSON content. 

```javascript
var web = require("cla/web");
var util = require("cla/util");
var ag = web.agent();
var res = ag.get('http://jsonplaceholder.typicode.com/posts');
if( res.isSuccess() ) {
    var content = res.content();   // this is text content, in JSON format
    var arr = util.loadJSON( res.content() );
    cla.dump( arr[4] );
    cla.printf( "The title is: %s", arr[4].title );
} else {
    cla.printf("Something went wrong (code=%d): %s", res.code(), res.message() )
    // or: throw Error( cla.sprintf("Something went wrong (code=%d): %s", res.code(), res.message() ) );
}
```

Here are the agent REST methods, which have very similar handling:

- `GET` - agent.get(url,options)
- `POST` - agent.post(url,options)
- `PUT` - agent.put(url,options)
- `DELETE` - agent.delete(url,options)
- `HEAD` - agent.head(url,options)

Common arguments to REST methods:

- `agent.METHOD(url)` - invoke the given URL with the specified method
- `agent.METHOD(url,{ key: value, ... })` - where form is a key-value set of form data
- `agent.METHOD(url,{ key: value, ... }, 'Field', Value, ...)` - where other fields can be added, such
as `Content-Type`, etc.
- `agent.METHOD(url,[ 'Header', val, 'Content', { ..form content..} ])` - this is for more elaborate forms, 
with different header and content formats

```javascript
var web = require("cla/web");
var ag = web.agent();
var url = 'http://jsonplaceholder.typicode.com/posts';
ag.post( url, { foo: 11, bar: 22 });
```

All methods return a `response` object, which is described bellow:

#### response.content([bytes])

Returns the content body with which the server replied.

The `bytes` optional argument allows for the control of the amount of
bytes returned by the function.

#### response.code()

The status code of the response.

#### response.message()

The response message for the given code, ie. an error message. 

#### response.isSuccess()

Returns true if the request was successful. 

#### agent.request(request,file)

This is a generic request 

#### agent.mirror(url,file)

Mirror (downloads) the URL to the file, but only
if necessary (ie. it has changed and files differ).

```javascript
var web = require("cla/web");
var ag = web.agent();
ag.mirror('http://jsonplaceholder.typicode.com/posts', '/tmp/posts.json');
```

#### agent.isOnline(options)

Checks if the agent is online and can make requests, ie. if 
the Clarive server has network connectivity.

```javascript
var web = require("cla/web");
var ag = web.agent();
if( ag.isOnline() ) {
    // ... call some webservices ...
}
```

