---
title: cla proxy - a proxy client
---

`cla proxy` is a proxy client that helps debug network traffic. 

It's meant to debug incoming/outgoing traffic to/from the Clarive web server.
This can be useful when integrating Clarive with extraneous tools.

    cla proxy
    cla proxy --port 5555
    cla proxy --listen localhost:6565

## Unpack option

The `--unpack` option translates the *incoming* data in hexadecimal,
(but not outgoing), so that you can better trace incoming data. 

    cla proxy --unpack

Data with the arrow to the right  `-->` indicate data going from the client to the Clarive server.

Data with the arrow to the left  `<--` indicate data coming from the Clarive Server and going back to the client.

For instance, to trace Unix commands, one can configure the proxy with a env variable, 
called `http_proxy`:

     http_proxy=localhost:8089 git push origin master

     http_proxy=localhost:8089 curl http://localhost:3000/rule/json/myrule?api_key=99999999999999

Or you can configure the browser to do the same, using the `cla proxy` address as proxy. 

