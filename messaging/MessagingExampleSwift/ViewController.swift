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

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func handleLogTokenTouch(_ sender: UIButton) {
    // [START log_fcm_reg_token]
    let token = Messaging.messaging().fcmToken
    print("FCM token: \(token ?? "")")
    // [END log_fcm_reg_token]
  }

  @IBAction func handleSubscribeTouch(_ sender: UIButton) {
    // [START subscribe_topic]
    Messaging.messaging().subscribe(toTopic: "news")
    print("Subscribed to news topic")
    // [END subscribe_topic]
  }

}
