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
import Crashlytics

@objc(ViewController)
class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Log that the view did load, CLSNSLogv is used here so the log message will be
    // shown in the console output. If CLSLogv is used the message is not shown in
    // the console output.
    CLSNSLogv("%@", getVaList(["View loaded"]))

    Crashlytics.sharedInstance().setIntValue(42, forKey: "MeaningOfLife")
    Crashlytics.sharedInstance().setObjectValue("Test value", forKey: "last_UI_action")
    Crashlytics.sharedInstance().setUserIdentifier("123456789")

    let userInfo = [
      NSLocalizedDescriptionKey: NSLocalizedString("The request failed.", comment: ""),
      NSLocalizedFailureReasonErrorKey: NSLocalizedString("The response returned a 404.", comment: ""),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Does this page exist?", comment:""),
      "ProductID": "123456",
      "UserID": "Jane Smith"
    ]
    let error = NSError.init(domain: NSURLErrorDomain, code: -1001, userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(error)
  }

  @IBAction func initiateCrash(_ sender: AnyObject) {
    // CLSLogv is used here to indicate that the log message
    // will not be shown in the console output. Use CLSNSLogv to have the
    // log message show in the console output.
    // [START log_and_crash_swift]
    CLSLogv("%@", getVaList(["Cause Crash button clicked"]))
    Crashlytics.sharedInstance().crash()
    // [END log_and_crash_swift]
  }
}
