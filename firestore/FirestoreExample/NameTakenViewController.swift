//
//  Copyright (c) 2020 Google LLC.
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
import Combine

class NameTakenViewController: UIViewController {

  @IBOutlet weak var isAvailableLabel: UILabel!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var textField: UITextField!

  private var textFieldCancellable: AnyCancellable?
  private var queryCancellable: AnyCancellable?

  override func viewDidLoad() {
    super.viewDidLoad()
    hideActivityIndicator()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    func checkNameQuery(for name: String) -> Query {
      return Firestore.firestore().collection("restaurants").whereField("name", isEqualTo: name)
    }

    textFieldCancellable = textField.textPublisher.sink { value in
      guard let name = value else {
        self.queryCancellable?.cancel()
        self.hideActivityIndicator()
        return
      }
      self.displayActivityIndicator()
      self.queryCancellable = checkNameQuery(for: name).getDocuments().sink(
        receiveCompletion: { status in
          // do nothing on completion
        },
        receiveValue: { snapshot in
          self.updateUI(isTaken: snapshot.count > 0)
          self.hideActivityIndicator()
        }
      )
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    queryCancellable?.cancel()
    queryCancellable = nil
    textFieldCancellable?.cancel()
    textFieldCancellable = nil
  }

  private func updateUI(isTaken: Bool) {
    if isTaken {
      isAvailableLabel.text = "In use"
    } else {
      isAvailableLabel.text = "Available"
    }
  }

  private func displayActivityIndicator() {
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
  }

  private func hideActivityIndicator() {
    activityIndicator.stopAnimating()
    activityIndicator.isHidden = true
  }

}

extension UITextField {
  var textPublisher: AnyPublisher<String?, Never> {
    NotificationCenter.default
      .publisher(for: UITextField.textDidChangeNotification, object: self)
      .compactMap { $0.object as? UITextField }
      .map { $0.text }
      .eraseToAnyPublisher()
  }
}
