//
//  Copyright (c) Google Inc.
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
import FirebaseAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  // [START didfinishlaunching]
  func application(application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Use Firebase library to configure APIs
    FIRApp .configure()
    // Initialize sign-in
    GINInvite.applicationDidFinishLaunchingWithOptions(launchOptions)

      return true
  }
  // [END didfinishlaunching]

  // [START openurl]
  @available(iOS 9.0, *)
  func application(application: UIApplication, openURL url: NSURL, options: [String : AnyObject])
    -> Bool {
      return self.application(application, openURL: url, sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String, annotation: "")
  }

  func application(application: UIApplication,
    openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
      if let invite = GINInvite.handleURL(url, sourceApplication:sourceApplication, annotation:annotation) as? GINReceivedInvite {
        let matchType =
            (invite.matchType == GINReceivedInviteMatchType.Weak) ? "Weak" : "Strong"
        print("Invite received from: \(sourceApplication) Deeplink: \(invite.deepLink)," +
            "Id: \(invite.inviteId), Type: \(matchType)")
        return true
      }

      return GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApplication, annotation: annotation)
  }
  // [END openurl]
}

