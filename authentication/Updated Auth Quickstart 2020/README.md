# Firebase Auth Quickstart

This Firebase quickstart is written in Swift and aims to showcase how Firebase Auth can help manage user authentication. 

## Getting Started

Clone this project and `cd` into the `Swifty Auth` directory. Run `pod install`. This command will install all of the required cocoapods for this quickstart and generates the `.xcworkspace` project that you can open in Xcode.


## Configuring Identity Providers

To enable sign in with each of the following identity providers, there are a few configuration steps required to make   

### Google Sign In
1. ensure `pod 'GoogleSignIn'` is included in your `Podfile`
2. 

### Sign in with Apple
#### Setup
1. enable sign in with apple device capabilities

### Twitter

### Microsoft
1. Go to micrsoft website and configure an app
2. firebase console paste in stuff

### GitHub
1. Go to micrsoft website and configure an app
2. firebase console paste in stuff

### Yahoo
1. Go to micrsoft website and configure an app
2. firebase console paste in stuff

### Facebook
1.  `pod 'FBSDKLoginKit'`
2.  enable it and paste in the stuff
3. get the 



## Other Auth Methods

### Email Link/Passwordless

Email Link authentication, which is also referred to as Passwordless authentication, works by sending a verification email to a user requesting to sign in. This verification email contains a special `Dynamic Link` that links the user back to your app, completing authentication in the process. In order to configure this method of authentication, we will use [Firebase Dynamic Links](link), which we will need to set up.

If this is your first time working with Dynamic Links, here's a great [introduction](link). Note, we will outline most of the steps covered in this tutorial below!

#### Setup
1. Firebase Console -> Email Password -> Select Passwordless
2. Enable Dynamic Links
3. Create a dynamic link
4. Associated Domains in Capabilities (add the dynamic links domain)


### So how does this work?

We will start by taking a look at `PasswordlessViewController.swift`. If you are currently running the quickstart app, select the "Email Link/Passwordless" authentication option. 

The user is prompted for an email to be used in the verification process. When  the "Send Sign In Link" button is tapped, we configure our verification link by adding the user's email to the dynamic link we created earlier. Then we send a send the link to the user's email. You can edit the format of these verification emails on the [Firebase Console](link!).

When the user receives the verification email, they can open the link contained in the email to be redirected back to the app (using the power of [Dynamic Links]() 😎). On apps using the [`SceneDelegate`]() API,  opening the incoming dynamic link will be handled in `UIWindowSceneDelegate`'s  `func scene(_ scene: UIScene, continue userActivity: NSUserActivity)` method. This method can be implemented in  `SceneDelegate.swift`. Since the quickstart uses the `SceneDelegate` API, you can check out the implementation [here](). We basically pass the incoming link to a helper method that will do a few things:

```swift
private func handleIncomingDynamicLink(_ incomingURL: URL) {
    DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { (dynamicLink, error) in
        // handle error
        
        guard let link = dynamicLink?.url?.absoluteString else { return }
                
        // Here, we check if our dynamic link is a sign-link (the one we emailed our user!) 
        if Auth.auth().isSignIn(withEmailLink: link) {
            // Save the link as it will be used in the next step to complete login
            UserDefaults.standard.set(link, forKey: "Link")
            
            // Post a notification to the PasswordlessViewController to resume authentication
            NotificationCenter.default.post(Notification(name: Notification.Name("PasswordlessEmailNotificationSuccess")))
        }
    }
}
```

If the incoming dynamic link is a sign-in link, then we post a notification that pretty much says: "Hey! A user just opened a verification dynamic link that we emailed them and we need to complete the authentication!"

This takes us back to our  `PasswordlessViewController.swift`, where [we registered for this exact notification](link)! When the notification is posted, we will receive it here and call the `passwordlessSignIn()` method to complete the authentication. In this method, we used Firebase Auth's `Auth.auth().signIn(withEmail: String, link: String)` which, behind the scenes, checks that this link was the link we originally sent to the associated email and if so, signs in the user! 🥳


### Phone Number

Note that for Xcode's device simulator, Silent APN notifcations are not yet supported. Because of this, Firebase Auth will present a reCAPTCHA verification flow instead. 

If you are running the quickstart on a real device, ensure APN notifications have properly been configured. If they aren't Firebase Auth will present a reCAPTCHA verification flow.   

#### Setup
1. enable sign in 

See the official [Firebase docs](link!) for more info!

### Anonymous Authentication

### Custom Auth System

Firebase Auth can manage authentication for use cases that utilize a custom auth system. Ensure you have an authentication server capable of producing custom signed tokens. When a user signs in, make a request for a signed token from your authentication server.

After your server returns the token, pass that into  Firebase Auth's `signIn(withCustomtoken: String)` method to complete the authentication process. In the quickstart, you can demo signing in with tokens you generate. See `CustomAuthViewController.swift` for more info. 


