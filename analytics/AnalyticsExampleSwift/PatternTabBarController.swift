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

/**
* PatternTabBarController exists as a subclass of UITabBarConttroller that
* supports a 'share' action. This will trigger a custom event to Analytics and
* display a dialog.
*/
@objc(PatternTabBarController)  // match the ObjC symbol name inside Storyboard
class PatternTabBarController: UITabBarController {

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if getUserFavoriteFood() == nil {
      askForFavoriteFood()
    }
  }

  @IBAction func didTapShare(_ sender: AnyObject) {
    let name = "Pattern~\(self.selectedViewController!.title!)",
        text = "I'd love you to hear about\(name)"

    // [START custom_event_swift]
    Analytics.logEvent("share_image", parameters: [
      "name": name as NSObject,
      "full_text": text as NSObject
      ])
    // [END custom_event_swift]

    let title = "Share: \(self.selectedViewController!.title!)",
        message = "Share event sent to Analytics; actual share not implemented in this quickstart",
		alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
  }

  @IBAction func unwindToHome(_ segue: UIStoryboardSegue?) {

  }

  func getUserFavoriteFood() -> String? {
    return UserDefaults.standard.string(forKey: "favorite_food")
  }

  func askForFavoriteFood() {
    performSegue(withIdentifier: "pickFavoriteFood", sender: self)
  }

}
