---
title: Web Request
---

Generates a request to webservices, URLs
or any HTTP/HTTPs based web protocol.

## Fields

- **URL**: the endpoint URL
- **Method**: the HTTP method to be used, typically `GET`, `POST`, `PUT`, `DELETE`
- **Encoding**:
- **Timeout**:
- **User**:
- **Password**:
- **Accept Any Server Certificate**:

### Data Section

#### Form

Enter key-value pairs for each
HTTP request form parameters.

This will be sent in the request as
a form/multipart section.

#### Header

Enter key-value pairs for each
HTTP request header values.

Some common HTTP request headers you can set:

- `Content-Type` - the type of content you be sending, like `application/json` or `application/x-www-form-urlencoded`
depending of what's being set to the endpoint server.
- `Content-Length` - the length of the content (should be automatically set by Clarive)
- `User-Agent` - identifies who's calling the service
- `Cookie` - sets cookies at the other side

And many more. Here's a good list of available request headers:

https://en.wikipedia.org/wiki/List_of_HTTP_header_fields

#### Body

Data to be sent the request body,
such as JSON data.

For example, to dump a stash variable called `myvar`
as a JSON string, put the following into the body of the request:

```perl
${json(myvar)}
```

Which will in turn get parsed to a JSON representation
of the variable `myvar`.
