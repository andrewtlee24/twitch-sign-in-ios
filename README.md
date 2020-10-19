# Twitch Sign In (iOS)

## Description
A simple UIViewController that implements the Twitch sign in process using WKWebView.

## Installation
Create a new Application on the developer console [here](https://dev.twitch.tv/console/apps)  

Drag and drop TwitchSignInViewController.swift into your Xcode project.

## Example Usage
```
let twitchSignIn = TwitchSignInViewController(clientID: "CLIENT_ID", redirectURI: "REDIRECT_URI", scopes: ["scope1, scope2, etc"])
twitchSignIn.delegate = self
self.present(twitchSignIn, animated: true, completion: nil)
```

## Delegate
TwitchSignInDelegate defines three methods:  

```
func twitchSignInDismiss()
```  
This is to allow for the view controller to be presented in various ways and to be removed accordingly.  

```
func twitchSignInSuccessful(accessToken : String, authData : TwitchAuthorizationData)
```  
Returns:  
- the API access token that can be used for other requests that require authentication  
- an object containing the user authentication data

```
func twitchSignInError(error : TwitchSignInError)
```  
Returns:  
- an enumerator value regarding what error was encountered

## License

Twitch Sign In (iOS) is released under the MIT license.
