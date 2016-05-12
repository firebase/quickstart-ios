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

import Foundation
import FirebaseAnalytics

/**
* PatternTabBarController exists as a subclass of UITabBarConttroller that
* supports a 'share' action. This will trigger a custom event to Analytics and
* display a dialog.
*/
@objc(PatternTabBarController)  // match the ObjC symbol name inside Storyboard
class PatternTabBarController: UITabBarController {

  override func viewDidAppear(animated: Bool) {
    if (getUserFavoriteFood() == nil) {
      askForFavoriteFood()
    }
  }

  @IBAction func didTapShare(sender: AnyObject) {
    // [START custom_event_swift]
    FIRAnalytics.logEventWithName(kFIREventSelectContent, parameters: [
      kFIRParameterContentType:"cont",
      kFIRParameterItemID:"1"
      ])
    // [END custom_event_swift]

    let title = "Share: \(self.selectedViewController!.title!)",
        message = "Share event sent to Analytics; actual share not implemented in this quickstart",
        alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "Ok")
    alert.show()
  }

  @IBAction func unwindToHome (segue: UIStoryboardSegue?) {

  }

  func getUserFavoriteFood() -> String? {
    return NSUserDefaults.standardUserDefaults().valueForKey("favorite_food") as! String?
  }

  func askForFavoriteFood() {
    performSegueWithIdentifier("pickFavoriteFood", sender: self)
  }

}