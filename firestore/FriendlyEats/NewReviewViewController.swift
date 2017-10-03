//
//  Copyright (c) 2016 Google Inc.
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
import FirebaseFirestore
import FirebaseAuth

class NewReviewViewController: UIViewController, UITextFieldDelegate {

  static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)) -> NewReviewViewController {
    let controller = storyboard.instantiateViewController(withIdentifier: "NewReviewViewController") as! NewReviewViewController
    return controller
  }

  weak var delegate: NewReviewViewControllerDelegate?

  @IBOutlet var doneButton: UIBarButtonItem!

  @IBOutlet var ratingView: RatingView! {
    didSet {
      ratingView.addTarget(self, action: #selector(ratingDidChange(_:)), for: .valueChanged)
    }
  }

  @IBOutlet var reviewTextField: UITextField! {
    didSet {
      reviewTextField.addTarget(self, action: #selector(textFieldTextDidChange(_:)), for: .editingChanged)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    doneButton.isEnabled = false
    reviewTextField.delegate = self
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    let review = Review(rating: ratingView.rating!,
                        userID: Auth.auth().currentUser!.uid,
                        username: Auth.auth().currentUser?.displayName ?? "Anonymous",
                        text: reviewTextField.text!, date: Date())
    delegate?.reviewController(self, didSubmitFormWithReview: review)
  }

  @objc func ratingDidChange(_ sender: Any) {
    updateSubmitButton()
  }

  func textFieldIsEmpty() -> Bool {
    guard let text = reviewTextField.text else { return true }
    return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func updateSubmitButton() {
    doneButton.isEnabled = (ratingView.rating != nil && !textFieldIsEmpty())
  }

  @objc func textFieldTextDidChange(_ sender: Any) {
    updateSubmitButton()
  }

}

protocol NewReviewViewControllerDelegate: NSObjectProtocol {
  func reviewController(_ controller: NewReviewViewController, didSubmitFormWithReview review: Review)
}


