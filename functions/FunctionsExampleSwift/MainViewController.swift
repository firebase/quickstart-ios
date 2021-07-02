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
  var controller1: MDCTextInputControllerUnderline!
  var controller2: MDCTextInputControllerUnderline!
  var controller3: MDCTextInputControllerUnderline!

  override func viewDidLoad() {
    super.viewDidLoad()
    styler.cellStyle = .card
    styler.cellLayoutType = .list
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 181
    }
    return 230
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.section == 0 {
      let addCell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "add",
        for: indexPath
      ) as! CloudAddCell
      addCell.number1Field.delegate = self
      controller1 = MDCTextInputControllerUnderline(textInput: addCell.number1Field)
      addCell.number2Field.delegate = self
      controller2 = MDCTextInputControllerUnderline(textInput: addCell.number2Field)

      addCell.button.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
      addCell.button.setElevation(ShadowElevation.raisedButtonPressed, for: .highlighted)
      return addCell
    } else {
      let commentCell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "message",
        for: indexPath
      ) as! CommentCell
      commentCell.inputField.delegate = self
      controller3 = MDCTextInputControllerUnderline(textInput: commentCell.inputField)

      commentCell.button.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
      commentCell.button.setElevation(ShadowElevation.raisedButtonPressed, for: .highlighted)
      return commentCell
    }
  }
}
