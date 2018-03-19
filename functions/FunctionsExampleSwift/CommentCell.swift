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

@objc(CommentCell)
class CommentCell: MDCCollectionViewCell {
  @IBOutlet weak var inputField: MDCTextField!
  @IBOutlet weak var resultField: UITextField!
  @IBOutlet weak var button: MDCButton!

  @IBAction func didTapAddMessage(_ sender: Any) {
    Functions.functions().httpsCallable("addMessage").call(["text": inputField.text]) { (result, error) in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      if let text = (result?.data as? [String: Any])?["text"] as? String {
        self.resultField.text = text
      }
    }
  }
}
