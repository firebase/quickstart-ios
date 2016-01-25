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
import Firebase

@objc(ViewController)
class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Log that the view did load, true is used here so the log message will be
    // shown in the console output. If false is used the message is not shown in
    // the console output.
    GCRLog(true, "View loaded", [])
  }

  @IBAction func initiateCrash(sender: AnyObject) {
    // [START log_and_crash_swift]
    GCRLog(false, "Cause Crash button clicked", [])
    fatalError()
    // [END log_and_crash_swift]
  }

  // GCRLog is a convenience method for using FCRLogv.
  func GCRLog(logToConsole: Bool, _ format: String, _ args: CVarArgType...) {
    withVaList(args) {
      FCRLogv(logToConsole, format, $0)
    }
  }
}
