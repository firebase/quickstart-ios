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
import UserNotifications

import Firebase
import FirebaseInstanceID
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    // [START register_for_notifications]
    if #available(iOS 10.0, *) {
      let authOptions : UNAuthorizationOptions = [.Alert, .Badge, .Sound]
      UNUserNotificationCenter.currentNotificationCenter().requestAuthorizationWithOptions(
        authOptions,
        completionHandler: {_,_ in })

      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.currentNotificationCenter().delegate = self
      // For iOS 10 data message (sent via FCM)
      FIRMessaging.messaging().remoteMessageDelegate = self

    } else {
      let settings: UIUserNotificationSettings =
      UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }


    // [END register_for_notifications]

    FIRApp.configure()

    // Add observer for InstanceID token refresh callback.
    NSNotificationCenter.defaultCenter().addObserver(self,
        selector: #selector(self.tokenRefreshNotification),
        name: kFIRInstanceIDTokenRefreshNotification,
        object: nil)

    return true
  }

  // [START receive_message]
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
                   fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification

    // Print message ID.
    print("Message ID: \(userInfo["gcm.message_id"]!)")

    // Print full message.
    print("%@", userInfo)
  }
  // [END receive_message]

  // [START refresh_token]
  func tokenRefreshNotification(notification: NSNotification) {
    if let refreshedToken = FIRInstanceID.instanceID().token() {
      print("InstanceID token: \(refreshedToken)")
    }

    // Connect to FCM since connection may have failed when attempted before having a token.
    connectToFcm()
  }
  // [END refresh_token]

  // [START connect_to_fcm]
  func connectToFcm() {
    FIRMessaging.messaging().connectWithCompletion { (error) in
      if (error != nil) {
        print("Unable to connect with FCM. \(error)")
      } else {
        print("Connected to FCM.")
      }
    }
  }
  // [END connect_to_fcm]

  func applicationDidBecomeActive(application: UIApplication) {
    connectToFcm()
  }

  // [START disconnect_from_fcm]
  func applicationDidEnterBackground(application: UIApplication) {
    FIRMessaging.messaging().disconnect()
    print("Disconnected from FCM.")
  }
  // [END disconnect_from_fcm]
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(center: UNUserNotificationCenter,
                              willPresentNotification notification: UNNotification,
    withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    // Print message ID.
    print("Message ID: \(userInfo["gcm.message_id"]!)")

    // Print full message.
    print("%@", userInfo)
  }
}

extension AppDelegate : FIRMessagingDelegate {
  // Receive data message on iOS 10 devices.
  func applicationReceivedRemoteMessage(remoteMessage: FIRMessagingRemoteMessage) {
    print("%@", remoteMessage.appData)
  }
}

// [END ios_10_message_handling]
