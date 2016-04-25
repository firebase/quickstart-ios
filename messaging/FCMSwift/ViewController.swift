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
import FirebaseInstanceID
import FirebaseMessaging

@objc(ViewController)
class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func handleLogTokenTouch(sender: UIButton) {
    // [START get_iid_token]
    let token = FIRInstanceID.instanceID().token()
    print("InstanceID token: \(token!)")
    // [END get_iid_token]
  }

  @IBAction func handleSubscribeTouch(sender: UIButton) {
    // [START subscribe_topic]
    FIRMessaging.messaging().subscribeToTopic("/topics/news")
    print("Subscribed to news topic")
    // [END subscribe_topic]
  }

}
