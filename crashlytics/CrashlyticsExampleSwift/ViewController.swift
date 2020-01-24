//
//  Copyright (c) 2018 Google Inc.
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
import FirebaseCrashlytics

@objc(ViewController)
class ViewController: UIViewController {
  lazy var crashlytics = Crashlytics.crashlytics()

  override func viewDidLoad() {
    super.viewDidLoad()

    // Log that the view did load, CLSNSLogv is used here so the log message will be
    // shown in the console output. If CLSLogv is used the message is not shown in
    // the console output.
    Crashlytics.crashlytics().log("View loaded")

    Crashlytics.crashlytics().setCustomValue(42, forKey: "MeaningOfLife")
    Crashlytics.crashlytics().setCustomValue("Test value", forKey: "last_UI_action")
    Crashlytics.crashlytics().setUserID("123456789")

    let userInfo = [
      NSLocalizedDescriptionKey: NSLocalizedString("The request failed.", comment: ""),
      NSLocalizedFailureReasonErrorKey: NSLocalizedString("The response returned a 404.", comment: ""),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Does this page exist?", comment:""),
      "ProductID": "123456",
      "UserID": "Jane Smith"
    ]
    let error = NSError(domain: NSURLErrorDomain, code: -1001, userInfo: userInfo)
    Crashlytics.crashlytics().record(error: error)
  }

  @IBAction func initiateCrash(_ sender: AnyObject) {
    // [START log_and_crash_swift]
    Crashlytics.crashlytics().log("Cause Crash button clicked")
    fatalError()
    // [END log_and_crash_swift]
  }
}
