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

//
// For more information on setting up and running this sample code, see
// https://firebase.google.com/docs/analytics/ios/start
//

import UIKit
import Firebase

@objc(FoodPickerViewController) // match the ObjC symbol name inside Storyboard
class FoodPickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
  let foodStuffs = ["Hot Dogs", "Hamburger", "Pizza"]

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let food = foodStuffs[row]
    UserDefaults.standard.set(food, forKey: "favorite_food")

    // [START user_property]
    Analytics.setUserProperty(food, forName: "favorite_food")
    // [END user_property]

    performSegue(withIdentifier: "goToShareScreen", sender: self)
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return foodStuffs.count
  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                  forComponent component: Int) -> String? {
    return foodStuffs[row]
  }
}
