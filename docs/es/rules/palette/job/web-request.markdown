---
title: Petición web
index: 5000
icon: webservice
---

Genera una petición a servicios web, URLs o cualquier sistema basado en el protocolo web HTTP/HTTPs.

## Campos

- **URL** - La URL destino
- **Método** - El método HTTP para usar, generalmente `GET`, `POST`, `PUT` o `DELETE`
- **Encoding** - El tipo de codificación, se recomienda `utf-8`, pero hay otros disponibles como: `ansi`, `iso-8859-15`, etc.
- **Timeout** - Establece el tiempo de espera para las respuestas del servidor (en segundos).
- **Usuario** - [opcional] El usuario a utilizar para la autenticación HTTP de las peticiones.
- **Contraseña**: [opcional] La contraseña a utilizar para la autenticación HTTP de las peticiones.
- **Aceptar de cualquier servidor certificado** - Comprueba si el certificados inválidos HTTP/SSL están permitidos.


### Datos

#### Argumentos formales

Introduzca pares de clave valor como argumentos de la petición HTTP.

#### Cabeceras

Introduzca pares clave-valor para cada valor de la cabecera de la petición HTTP.

Algunos de los parámetros comunes que se pueden establecer aquí son:

- `Content-Type` - El tipo de contenido que se envía, como `application/json` o `application/x-www-form-urlencoded` dependiendo de lo que se haya establecido en el servidor destino.
- `Content-Length` - El tamaño del contenido (debería ser establecido por Clarive).
- `User-Agent` - Identifica quién está llamando al servicio.
- `Cookie` - Establece las cookies al otro lado.

Aquí hay una lista de los campos de cabecera que se pueden añadir:

[https://en.wikipedia.org/wiki/List_of_HTTP_header_fields <img class='ext-link' src='static/images/icons/new_window_link.svg' />](https://en.wikipedia.org/wiki/List_of_HTTP_header_fields)

#### Body

Datos que se enviarán en el cuerpo de la petición como datos JSON.

##### Enviando una petición JSON

Por ejemplo, para descargar la variable stash llamada `mivar` a un string JSON, hay que poner lo sisguiente en el cuerpo de la petición:

```perl
${json(mivar)}
```

El cual realiza una representación en JSON de la variable `mivar`.

Añadiendo el siguiente par clave-valor a la sección de **Cabecera** estaría todo listo:

`Content-Type` ==> `application/json`

##### Enviar una petición SOAP

Para enviar una petición SOAP, es mejor crear una plantilla para el body que contenga la estructura XML que es necesaria para su servidor SOAP.

Esto es un ejemplo de una plantilla XML de petición SOAP, con una variable `mivar` que se paseará con los datos del stash antes de ser enviada.

```xml
<?xml version="1.0"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2001/12/soap-envelope" SOAP-ENV:encodingStyle="http://www.w3.org/2001/12/soap-encoding" >
   <SOAP-ENV:Body xmlns:m="http://www.xyz.org/quotations" >
      <m:GetQuotation>
         <m:QuotationsName>${mivar}</m:QuotationsName>
      </m:GetQuotation>
   </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
```

Ahora, añada el siguiente clave-valor a la sección de **Cabecera**:

- `Content-Type` => `text/xml; charset=utf-8`

##### SOAP 1.1 Tester

Este es un buen test para una llamada a SOAP 1.1:

- URL: `http://www.webservicex.net/globalweather.asmx?op=GetWeather`
- Method: `POST`

Cabecera:

- `Content-Type`   => `text/xml; charset=utf-8`,
- `SOAPAction`     => `"http://www.webserviceX.NET/GetWeather"`

Cuerpo:

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

Cabecera:

- `Content-Type` => `application/soap+xml; charset=utf-8`

Cuerpo:

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

