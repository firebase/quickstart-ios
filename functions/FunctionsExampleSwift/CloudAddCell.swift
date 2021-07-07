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

import MaterialComponents
import Firebase

@objc(CloudAddCell)
class CloudAddCell: MDCCollectionViewCell {
  @IBOutlet var number1Field: MDCTextField!
  @IBOutlet var number2Field: MDCTextField!
  @IBOutlet var button: MDCButton!
  @IBOutlet private var resultField: UITextField!
  // [START functions_instance]
  lazy var functions = Functions.functions()
  // [END functions_instance]

  @IBAction func didTapAdd(_ sender: Any) {
    // [START function_add_numbers]
    let data = ["firstNumber": Int(number1Field.text!),
                "secondNumber": Int(number2Field.text!)]
    functions.httpsCallable("addNumbers").call(data) { result, error in
      // [START function_error]
      if let error = error as NSError? {
        if error.domain == FunctionsErrorDomain {
          let code = FunctionsErrorCode(rawValue: error.code)
          let message = error.localizedDescription
          let details = error.userInfo[FunctionsErrorDetailsKey]
        }
        // [START_EXCLUDE]
        print(error)
        return
          // [END_EXCLUDE]
      }
      // [END function_error]
      if let operationResult = (result?.data as? [String: Any])?["operationResult"] as? Int {
        self.resultField.text = "\(operationResult)"
      }
    }
    // [END function_add_numbers]
  }
}
