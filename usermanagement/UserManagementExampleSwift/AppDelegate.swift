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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Use Firebase library to configure APIs
    do {
      try FIRContext.sharedInstance().configure()
    } catch let configureError as NSError{
      print ("Error configuring Firebase services: \(configureError)")
    }

    // Configure the default Firebase application:
    let firebaseOptions = FIRFirebaseOptions()
    firebaseOptions.GITkitAPIKey = FIRContext.sharedInstance().serviceInfo.apiKey
    firebaseOptions.GITkitWidgetURL = NSURL(string: "https://gitkitmobile.appspot.com/gitkit.jsp")
    FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID, options: firebaseOptions)

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

