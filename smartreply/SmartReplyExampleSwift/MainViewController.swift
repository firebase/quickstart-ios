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

import Firebase
import MaterialComponents

@objc(MainViewController)
class MainViewController: MDCCollectionViewController, UITextFieldDelegate {
  var controller: MDCTextInputControllerUnderline!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.styler.cellStyle = .card
    self.styler.cellLayoutType = .list
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    return 181
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let commentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "message", for: indexPath) as! CommentCell
      commentCell.inputField.delegate = self
      controller = MDCTextInputControllerUnderline(textInput: commentCell.inputField)

      commentCell.button.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
      commentCell.button.setElevation(ShadowElevation.raisedButtonPressed, for: .highlighted)
      return commentCell
    }
  }
}
 
