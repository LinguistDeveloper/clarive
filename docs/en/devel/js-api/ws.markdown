---
title: cla/ws - webservice namespace
---

This namespace holds Clarive webservice call
management and is useful for writting webservice
rules that listens for incoming calls on a Clarive 
URL. 

For every webservice rule, the developer needs to 
cater to a *consumer*, which is the user that 
makes the call to the webservice. 

### ws.request()

Returns the request object, with the 
following values:

#### req.args()

Returns the request path arguments broken down
into an Array.

```javascript
var ws = require("cla/ws");
var req = ws.request();
var args = req.args();
for( var i=0; i<args.length; i++) {
    print( args[i] );
}
```

For instance, if the rule was invoked with
the URL `http://clariveurl/rule/json/myrule/path1/path2`,
the `req.args()` will return the array `['path1','path2']`.

#### req.body()

Returns the request body.  

```javascript
var ws = require("cla/ws");
var req = ws.request();
print( req.body() );  // the body can be a huge text string
```

#### req.headers([header])

Returns the request headers as an object. If the 
header parameters is sent, returns only the value for that given header.

```javascript
var ws = require("cla/ws");
var req = ws.request();
print( req.headers('accept-language') ); 
```

Some common headers one may get from a browser call:

https://en.wikipedia.org/wiki/List_of_HTTP_header_fields

How to send headers (myheader and another) with a `curl` command call:

`curl -Hmyheader=123 -Hanother=bar http://clariveurl/rule/json/myrule`

#### req.params()

Returns the request query parameters.

```javascript
var ws = require("cla/ws");
var req = ws.request();
var fooParam = req.params('foo');  // in case this was called http://.../?foo=bar
```

#### req.type()

Returns the expected request format by the consumer.
Usually this format should be transparent to the developer, 
but it maybe useful when returning specifically built responses.

#### req.url()

The full URL of the request. 

```javascript
var ws = require("cla/ws");
var req = ws.request();
print( req.url() );   // something like: http://clariveurl/rule/json/myrule
```

### ws.response()

Manipulate the webservice response values and options.

```javascript
var ws = require("cla/ws");
var res = ws.response();
```

#### res.data(key,value)

Sets a key-value pair in a hashed (object) response data. 

This is useful for returning JSON formats for webservice-like consumers.

```javascript
var ws = require("cla/ws");
var res = ws.response();
res.data("foo", 1234);
res.data("bar", { xx: 10, yy: [1,2,100] });
```

#### res.body(value)

The response body let's you freely define
what text will be in the content body. 

```javascript
var ws = require("cla/ws");
var res = ws.response();
res.body("<html><body><h1>Title</h1></body></html>");
```

**Important**: remember that the client expects 
a different output format depending on the request 
URL: json, yaml, raw and soap. So make sure that the response 
follows what the requester is expecting when setting the `res.body()`
directly. 

Setting a response body will erase all previous key-value pairs
that were set before.

#### res.status(code)

Let the developer set the response status code.


