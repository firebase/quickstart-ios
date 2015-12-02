//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

//
// For more information on setting up and running this sample code, see
// https://developers.google.com/firebase/docs/auth/ios/user-auth
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // [START firebase_configure]
    // Use Firebase library to configure APIs
    do {
      try FIRContext.sharedInstance().configure()
    } catch let configureError as NSError{
      print ("Error configuring Firebase services: \(configureError)")
    }
    // [END firebase_configure]

    // [START usermanagement_initialize]
    // Configure the default Firebase application
    let googleSignIn = FIRGoogleSignInAuthProvider.init(clientId: FIRContext.sharedInstance().serviceInfo.clientID)

    let firebaseOptions = FIRFirebaseOptions()
    firebaseOptions.APIKey = FIRContext.sharedInstance().serviceInfo.apiKey
    firebaseOptions.authWidgetURL = NSURL(string: "https://gitkitmobile.appspot.com/gitkit.jsp")
    firebaseOptions.signInProviders = [googleSignIn!];
    FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID, options: firebaseOptions)
    // [END usermanagement_initialize]

    return true
  }

  func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    if #available(iOS 9.0, *) {
      if (FIRFirebaseApp.handleOpenURL(url, sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as! String)) {
          return true
        }
    } else {
        // Fallback on earlier versions
    }
    return false
  }
}

