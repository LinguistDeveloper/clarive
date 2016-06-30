---
title: Mobile App Delivery
index: 4000
---

Clarive supports deploying to both
the Apple App Store and Google Play Store using their corresponding
APIs and a library/command-line tool called **fastlane**, which
is bundled in the Clarive mobile plugin.

### Publishing the App to the Store

Publishing an app to a mobile store, such as Apple's and Google's, involves quite a few steps
that you need to plan well before implementing.

- maintaining the store profile
- signing the app code with certificates
- maintain push notification profiles
- create application screenshots
- build, test and deploy the app

### Signing and Maintaining Certificates

You have to plan running `PRE` step where
code is signed using the organizational
certificates CIs with a rule.

### Accessing the Store

For each store, we recommend using a different set
of libraries that need to installed separately in the Clarive
server.

#### Apple Store

Clarive App Store feature relies on the spaceship library.

**spaceship** exposes both the Apple Developer Center and the iTunes Connect API.

This fast and powerful API powers parts of Clarive, and can be leveraged for
more advanced Clarive features.

`https://idmsa.apple.com`

- Used to authenticate to get a valid session

`https://developerservices2.apple.com`

- Get a detailed list of all available provisioning profiles
- This API returns the devices, certificates and app for each of the profiles
- Register new devices

`https://developer.apple.com`

- List all devices, certificates, apps and app groups
- Create new certificates, provisioning profiles and apps
- Disable/enable services on apps and assign them to app groups
- Delete certificates and apps
- Repair provisioning profiles
- Download provisioning profiles
- Team selection

`https://itunesconnect.apple.com`

- Managing apps
- Managing beta testers
- Submitting updates to review
- Managing app metadata

`https://du-itc.itunesconnect.apple.com`

- Upload icons, screenshots, trailers ...

#### Google Play Store

Clarive also supports deployment to the Google Play store.

Setup consists of setting up your Google Developers Service Account:

- Open the Google Play Console
- Select Settings tab, followed by the API access tab
- Click the Create Service Account button and follow the Google Developers
  Console link in the dialog
- Click Create credentials and select Service account
- Select JSON as the Key type and click Create
- Make a note of the file name of the JSON file downloaded to your computer,
  and close the dialog
- Back on the Google Play developer console, click Done to close the dialog
- Click on Grant Access for the newly added service account
- Choose Release Manager from the Role dropdown and click Send Invitation to
  close the dialog


