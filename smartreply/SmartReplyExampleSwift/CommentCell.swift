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
  @IBOutlet weak var resultField1: UITextField!
  @IBOutlet weak var resultField2: UITextField!
  @IBOutlet weak var resultField3: UITextField!
  @IBOutlet weak var button: MDCButton!
  // [START predictor_instance]
  lazy var predictor = Text.text().smartReplyPredictor
  // [END predictor_instance]

  @IBAction func didTapAddMessage(_ sender: Any) {
    let inputText = inputField.text
    // [START predictor_predict]
    predictor.predictReply(text: inputText) { (replies, error) in
      guard error == nil, let replies = replies, !replies.isEmpty else {
        return
      }
      // Successfully predicted message replies.
      for reply in replies {
        print("Suggested reply (confidence: \(reply.confidence)): \(reply.text)")
      }
      // [START_EXCLUDE]
      if let reply = replies[0] {
        resultField1.text = "\(reply.text) - \(reply.confidence)"
      }
      if let reply = replies[1] {
        resultField2.text = "\(reply.text) - \(reply.confidence)"
      }
      if let reply = replies[2] {
        resultField3.text = "\(reply.text) - \(reply.confidence)"
      }
      // [END_EXCLUDE]
    }
    // [END predictor_predict]
  }
}
