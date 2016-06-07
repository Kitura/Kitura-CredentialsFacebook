# Kitura-CredentialsFacebook
A plugin for the Credentials framework that authenticates using Facebook

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
A plugin for [Kitura-Credentials](https://github.com/IBM-Swift/Kitura-Credentials) framework that authenticates using the [Facebook web login with OAuth](https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow).

## Table of Contents
* [Swift version](#swift-version)
* [Example](#example)
* [License](#license)

## Swift version
The latest version of Kitura-CredentialsFacebook works with the DEVELOPMENT-SNAPSHOT-2016-05-09-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Example
A complete sample can be found in [Kitura-Credentials-Sample](https://github.com/IBM-Swift/Kitura-Credentials-Sample).
<br>

First create an instance of `CredentialsFacebook` plugin and register it with `Credentials` framework:
```swift
import Credentials
import CredentialsFacebook

let credentials = Credentials()
let fbCredentials = CredentialsFacebook(clientId: fbClientId, clientSecret: fbClientSecret, callbackUrl: serverUrl + "/login/facebook/callback")
credentials.register(fbCredentials)
```
**Where:**
   - *fbClientId* is the App ID of your app in the Facebook Developer dashboard
   - *fbClientSecret* is the App Secret of your app in the Facebook Developer dashboard

**Note:** The *callbackUrl* parameter above is used to tell the Facebook web login page where the user's browser should be redirected when the login is successful. It should be a URL handled by the server you are writing.
Specify where to redirect non-authenticated requests:
```swift
credentials.options["failureRedirect"] = "/login/facebook"
```

Connect `credentials` middleware to requests to `/private`:

```swift
router.all("/private", middleware: credentials)
router.get("/private/data", handler:
    { request, response, next in
        ...  
        next()
})
```
And call `authenticate` to login with Facebook and to handle the redirect (callback) from the Facebook login web page after a successful login:

```swift
router.get("/login/facebook",
           handler: credentials.authenticate(fbCredentials.name))

router.get("/login/facebook/callback",
           handler: credentials.authenticate(fbCredentials.name))
```

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
