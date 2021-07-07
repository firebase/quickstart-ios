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
import Firebase

@objc(ViewController)
class ViewController: UIViewController {
  @IBOutlet var fcmTokenMessage: UILabel!
  @IBOutlet var remoteFCMTokenMessage: UILabel!

  override func viewDidLoad() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(displayFCMToken(notification:)),
      name: Notification.Name("FCMToken"),
      object: nil
    )
  }

  @IBAction func handleLogTokenTouch(_ sender: UIButton) {
    // [START log_fcm_reg_token]
    let token = Messaging.messaging().fcmToken
    print("FCM token: \(token ?? "")")
    // [END log_fcm_reg_token]
    fcmTokenMessage.text = "Logged FCM token: \(token ?? "")"

    // [START log_iid_reg_token]
    Messaging.messaging().token { token, error in
      if let error = error {
        print("Error fetching remote FCM registration token: \(error)")
      } else if let token = token {
        print("Remote instance ID token: \(token)")
        self.remoteFCMTokenMessage.text = "Remote FCM registration token: \(token)"
      }
    }
    // [END log_iid_reg_token]
  }

  @IBAction func handleSubscribeTouch(_ sender: UIButton) {
    // [START subscribe_topic]
    Messaging.messaging().subscribe(toTopic: "weather") { error in
      print("Subscribed to weather topic")
    }
    // [END subscribe_topic]
  }

  @objc func displayFCMToken(notification: NSNotification) {
    guard let userInfo = notification.userInfo else { return }
    if let fcmToken = userInfo["token"] as? String {
      fcmTokenMessage.text = "Received FCM token: \(fcmToken)"
    }
  }
}
