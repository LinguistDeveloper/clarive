---
title: API Key
---

An application programming interface key (API key) is a code passed in by external commands
calling Clarive API (application programming interface) to identify the calling user.

API keys are an alternative to using login credentials. They simply identify 
the user without having to send the password. 

API keys are sensitive information, store them with care. If stolen, an API key can give access
to the data your Clarive user is entitled to seeing. 

## Usage

API keys can be used in 2 forms:

- as a query parameter calling a Clarive URL
- as an alternative password to a user

## Global API Key access setup 

API keys cannot be used to logon into the Clarive web interface or access any URL, except
when the system configuration option `api_key_authentication` is set to a true value. 

     api_key_authentication: 1

### api-key authentication is not enabled for this url

This error message indicates that the URL accessed is not 
allowed for API keys. Either write a [webservice rule](concepts/webservice)
or enable global API key access.

