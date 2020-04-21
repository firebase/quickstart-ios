//
//  Copyright (c) 2020 Google LLC
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

private class SaveAlertHandle {
  static var alertHandle: UIAlertController?

  class func set(_ handle: UIAlertController) {
    alertHandle = handle
  }

  class func clear() {
    alertHandle = nil
  }

  class func get() -> UIAlertController? {
    return alertHandle
  }
}

extension UIViewController {
  /*! @fn showMessagePrompt
   @brief Displays an alert with an 'OK' button and a message.
   @param message The message to display.
   */
  func showMessagePrompt(_ message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okAction)
    present(alert, animated: false, completion: nil)
  }

  /*! @fn showTextInputPromptWithMessage
   @brief Shows a prompt with a text field and 'OK'/'Cancel' buttons.
   @param message The message to display.
   @param completion A block to call when the user taps 'OK' or 'Cancel'.
   */
  func showTextInputPrompt(withMessage message: String,
                           completionBlock: @escaping ((Bool, String?) -> Void)) {
    let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
      completionBlock(false, nil)
    }
    weak var weakPrompt = prompt
    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      guard let text = weakPrompt?.textFields?.first?.text else { return }
      completionBlock(true, text)
    }
    prompt.addTextField(configurationHandler: nil)
    prompt.addAction(cancelAction)
    prompt.addAction(okAction)
    present(prompt, animated: true, completion: nil)
  }

  /*! @fn showSpinner
   @brief Shows the please wait spinner.
   @param completion Called after the spinner has been hidden.
   */
  func showSpinner(_ completion: (() -> Void)?) {
    let alertController = UIAlertController(title: nil, message: "Please Wait...\n\n\n\n",
                                            preferredStyle: .alert)
    SaveAlertHandle.set(alertController)
    let spinner = UIActivityIndicatorView(style: .whiteLarge)
    spinner.color = UIColor(ciColor: .black)
    spinner.center = CGPoint(x: alertController.view.frame.midX,
                             y: alertController.view.frame.midY)
    spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                .flexibleLeftMargin, .flexibleRightMargin]
    spinner.startAnimating()
    alertController.view.addSubview(spinner)
    present(alertController, animated: true, completion: completion)
  }

  /*! @fn hideSpinner
   @brief Hides the please wait spinner.
   @param completion Called after the spinner has been hidden.
   */
  func hideSpinner(_ completion: (() -> Void)?) {
    if let controller = SaveAlertHandle.get() {
      SaveAlertHandle.clear()
      controller.dismiss(animated: true, completion: completion)
    }
  }
}
