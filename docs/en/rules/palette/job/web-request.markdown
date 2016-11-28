---
title: Web Request
index: 5000
icon: webservice-blue
---

Generates a request to webservices, URLs
or any HTTP/HTTPs based web protocol.

## Fields

- **URL** - the endpoint URL
- **Method** - the HTTP method to be used, typically `GET`, `POST`, `PUT`, `DELETE`
- **Encoding** - the encoding to be used, recommended (and default) is `utf-8`, but
others also available: `ansi`, `iso-8859-15`, etc.
- **Timeout** - timeout to wait for server response in seconds
- **User** - [optional] HTTP authentication user for the request
- **Password** - [optional] HTTP authentication password for the request
- **Accept Any Server Certificate** - check this if invalid HTTPS/SSL certificates are allowed

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

[https://en.wikipedia.org/wiki/List_of_HTTP_header_fields <img class='ext-link' src='static/images/icons/window-new.svg' />](https://en.wikipedia.org/wiki/List_of_HTTP_header_fields)

#### Body

Data to be sent the request body,
such as JSON data.

##### Sending a JSON request

For example, to dump a stash variable called `myvar`
as a JSON string, put the following into the body of the request:

```perl
${json(myvar)}
```

Which will in turn get parsed to a JSON representation
of the variable `myvar`.

Add the following key-value pair to the **Headers** section
and you're all set:

`Content-Type` ==> `application/json`

##### Sending a SOAP request

To send a SOAP request, it's better to create a body template
that has the correct XML structure that is needed by your
SOAP server.

This is an example SOAP XML request template, with
a variable, `myvar` that will be parsed with the stash data
before being sent over.

```xml
<?xml version="1.0"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2001/12/soap-envelope" SOAP-ENV:encodingStyle="http://www.w3.org/2001/12/soap-encoding" >
   <SOAP-ENV:Body xmlns:m="http://www.xyz.org/quotations" >
      <m:GetQuotation>
         <m:QuotationsName>${myvar}</m:QuotationsName>
      </m:GetQuotation>
   </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
```

Now, set the following key-value pair in the
**Header** section:

- `Content-Type` => `text/xml; charset=utf-8`

##### SOAP 1.1 Tester

Here's a good test for a SOAP 1.1 call:

- URL: `http://www.webservicex.net/globalweather.asmx?op=GetWeather`
- Method: `POST`

Headers:

- `Content-Type`   => `text/xml; charset=utf-8`,
- `SOAPAction`     => `"http://www.webserviceX.NET/GetWeather"`

Body:

```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetWeather xmlns="http://www.webserviceX.NET">
      <CityName>string</CityName>
      <CountryName>string</CountryName>
    </GetWeather>
  </soap:Body>
</soap:Envelope>
```

##### SOAP 1.2 Tester

- URL: `http://www.webservicex.net/globalweather.asmx?op=GetWeather`
- Method: `POST`

Headers:

- `Content-Type` => `application/soap+xml; charset=utf-8`

Body:

```xml
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <GetWeather xmlns="http://www.webserviceX.NET">
      <CityName>string</CityName>
      <CountryName>string</CountryName>
    </GetWeather>
  </soap12:Body>
</soap12:Envelope>
```

