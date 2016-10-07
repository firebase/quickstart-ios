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

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    // [START register_for_notifications]
    if #available(iOS 10.0, *) {
      let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_,_ in })

      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.current().delegate = self
      // For iOS 10 data message (sent via FCM)
      FIRMessaging.messaging().remoteMessageDelegate = self

    } else {
      let settings: UIUserNotificationSettings =
      UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    // [END register_for_notifications]

    FIRApp.configure()

    // Add observer for InstanceID token refresh callback.
    NotificationCenter.default.addObserver(self,
        selector: #selector(self.tokenRefreshNotification),
        name: .firInstanceIDTokenRefresh,
        object: nil)

    return true
  }

  // [START receive_message]
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
  func tokenRefreshNotification(_ notification: Notification) {
    if let refreshedToken = FIRInstanceID.instanceID().token() {
      print("InstanceID token: \(refreshedToken)")
    }

    // Connect to FCM since connection may have failed when attempted before having a token.
    connectToFcm()
  }
  // [END refresh_token]

  // [START connect_to_fcm]
  func connectToFcm() {
    FIRMessaging.messaging().connect { (error) in
      if (error != nil) {
        print("Unable to connect with FCM. \(error)")
      } else {
        print("Connected to FCM.")
      }
    }
  }
  // [END connect_to_fcm]

  func applicationDidBecomeActive(_ application: UIApplication) {
    connectToFcm()
  }

  // [START disconnect_from_fcm]
  func applicationDidEnterBackground(_ application: UIApplication) {
    FIRMessaging.messaging().disconnect()
    print("Disconnected from FCM.")
  }
  // [END disconnect_from_fcm]
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    // Print message ID.
    print("Message ID: \(userInfo["gcm.message_id"]!)")

    // Print full message.
    print("%@", userInfo)
  }
}

extension AppDelegate : FIRMessagingDelegate {
  // Receive data message on iOS 10 devices.
  func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
    print("%@", remoteMessage.appData)
  }
}

// [END ios_10_message_handling]
