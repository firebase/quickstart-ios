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
import FirebaseAnalytics
import FirebaseMessaging
import FirebaseInstanceID

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var connectedToFCM = false
  var subscribedToTopic = false
  var fcmSenderID: String?
  var registrationToken: String?

  let registrationKey = "onRegistrationCompleted"
  let messageKey = "onMessageReceived"
  let subscriptionTopic = "/topics/global"

  // [START register_for_remote_notifications]
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions:
      [NSObject: AnyObject]?) -> Bool {
    // [START_EXCLUDE]
    // Configure the Google context: parses the GoogleService-Info.plist, and initializes
    // the services that have entries in the file
    FIRApp .configure()

    fcmSenderID = FIRApp.defaultApp()?.options.GCMSenderID
    // [END_EXCLUDE]
    // Register for remote notifications
    if #available(iOS 8.0, *) {
      let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    } else {
      // Fallback
      let types: UIRemoteNotificationType = [.Alert, .Badge, .Sound]
      application.registerForRemoteNotificationTypes(types)
    }

  // [END register_for_remote_notifications]
    return true
  }

  func subscribeToTopic() {
    // If the app has a registration token and is connected to GCM, proceed to subscribe to the
    // topic
    if(registrationToken != nil && connectedToFCM) {
      FIRMessaging().subscribeToTopic(subscriptionTopic)
      self.subscribedToTopic = true
      print("Subscribed to \(self.subscriptionTopic)")
    }
  }

  // [START connect_gcm_service]
  func applicationDidBecomeActive( application: UIApplication) {
    // Connect to the GCM server to receive non-APNS notifications
    FIRMessaging().connectWithCompletion { (error) in
      if let error = error {
        print("Could not connect to GCM: \(error.localizedDescription)")
        return
      }
      self.connectedToFCM = true
      print("Connected to GCM")
      // [START_EXCLUDE]
      self.subscribeToTopic()
      // [END_EXCLUDE]
    }
  }
  // [END connect_gcm_service]

  // [START disconnect_gcm_service]
  func applicationDidEnterBackground(application: UIApplication) {
    FIRMessaging().disconnect()
    // [START_EXCLUDE]
    self.connectedToFCM = false
    // [END_EXCLUDE]
  }
  // [END disconnect_gcm_service]

  // [START receive_apns_token]
  func application( application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken
      deviceToken: NSData ) {
  // [END receive_apns_token]
        // [START get_gcm_reg_token]
        // Start the GGLInstanceID shared instance with that config and request a registration
        // token to enable reception of notifications
        FIRInstanceID().setAPNSToken(deviceToken, type: .Sandbox)
        FIRInstanceID().tokenWithAuthorizedEntity(fcmSenderID!,
          scope: kFIRInstanceIDScopeFirebaseMessaging, options: nil, handler: registrationHandler)
        // [END get_gcm_reg_token]
  }

  // [START receive_apns_token_error]
  func application( application: UIApplication, didFailToRegisterForRemoteNotificationsWithError
      error: NSError ) {
    print("Registration for remote notification failed with error: \(error.localizedDescription)")
  // [END receive_apns_token_error]
    let userInfo = ["error": error.localizedDescription]
    NSNotificationCenter.defaultCenter().postNotificationName(
        registrationKey, object: nil, userInfo: userInfo)
  }

  // [START ack_message_reception]
  func application( application: UIApplication,
    didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
      print("Notification received: \(userInfo)")
      // This works only if the app started the GCM service
      FIRMessaging().appDidReceiveMessage(userInfo);
      // Handle the received message
      // [START_EXCLUDE]
      NSNotificationCenter.defaultCenter().postNotificationName(messageKey, object: nil,
          userInfo: userInfo)
      // [END_EXCLUDE]
  }

  func application( application: UIApplication,
    didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
    fetchCompletionHandler handler: (UIBackgroundFetchResult) -> Void) {
      print("Notification received: \(userInfo)")
      // This works only if the app started the GCM service
      FIRMessaging().appDidReceiveMessage(userInfo);
      // Handle the received message
      // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
      // [START_EXCLUDE]
      NSNotificationCenter.defaultCenter().postNotificationName(messageKey, object: nil,
        userInfo: userInfo)
      handler(UIBackgroundFetchResult.NoData);
      // [END_EXCLUDE]
  }
  // [END ack_message_reception]

  func registrationHandler(registrationToken: String?, error: NSError?) {
    if let registrationToken = registrationToken {
      self.registrationToken = registrationToken
      print("Registration Token: \(registrationToken)")
      self.subscribeToTopic()
      let userInfo = ["registrationToken": registrationToken]
      NSNotificationCenter.defaultCenter().postNotificationName(
        self.registrationKey, object: nil, userInfo: userInfo)
    } else {
      print("Registration to GCM failed with error: \(error!.localizedDescription)")
      let userInfo = ["error": error!.localizedDescription]
      NSNotificationCenter.defaultCenter().postNotificationName(
        self.registrationKey, object: nil, userInfo: userInfo)
    }
  }

  // [START on_token_refresh]
  func onTokenRefresh() {
    // A rotation of the registration tokens is happening, so the app needs to request a new token.
    print("The GCM registration token needs to be changed.")
    FIRInstanceID().tokenWithAuthorizedEntity(fcmSenderID!,
                                              scope: kFIRInstanceIDScopeFirebaseMessaging, options: nil, handler: registrationHandler)
  }
  // [END on_token_refresh]

  // [START upstream_callbacks]
  func willSendDataMessageWithID(messageID: String!, error: NSError!) {
    if (error != nil) {
      // Failed to send the message.
    } else {
      // Will send message, you can save the messageID to track the message
    }
  }

  func didSendDataMessageWithID(messageID: String!) {
    // Did successfully send message identified by messageID
  }
  // [END upstream_callbacks]

  func didDeleteMessagesOnServer() {
    // Some messages sent to this device were deleted on the GCM server before reception, likely
    // because the TTL expired. The client should notify the app server of this, so that the app
    // server can resend those messages.
  }

}
