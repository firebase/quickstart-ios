//
//  Copyright (c) 2016 Google Inc.
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

// [START auth_import]
import Firebase
// [END auth_import]

import GoogleSignIn
import FBSDKCoreKit
import Fabric
import TwitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions
      launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // [START firebase_configure]
    // Use Firebase library to configure APIs
    FIRApp.configure()
    // [END firebase_configure]
    FBSDKApplicationDelegate.sharedInstance().application(application,
        didFinishLaunchingWithOptions:launchOptions)
    let key = Bundle.main.object(forInfoDictionaryKey: "consumerKey"),
        secret = Bundle.main.object(forInfoDictionaryKey: "consumerSecret")
    if let key = key as? String, let secret = secret as? String
        , !key.isEmpty && !secret.isEmpty {
      Twitter.sharedInstance().start(withConsumerKey: key, consumerSecret: secret)
    }
    return true
  }

  @available(iOS 9.0, *)
  func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
    -> Bool {
      return self.application(application,
                              open: url,
                              sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?,
                              annotation: [:])
  }

  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    if GIDSignIn.sharedInstance().handle(url,
                                            sourceApplication: sourceApplication,
                                            annotation: annotation) {
      return true
    }
    return FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                 open: url,
                                                                 sourceApplication: sourceApplication,
                                                                 annotation: annotation)
  }
}

