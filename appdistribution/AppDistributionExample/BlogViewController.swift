// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import Firebase

/// The `BlogViewController` demonstrates how to set a custom screen name for analytics tracking.
class BlogViewController: UIViewController, UITextViewDelegate {
  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    view.backgroundColor = .systemBackground
    setupSubviews()

    // Firebase 🔥 - Set a custom screen name for analytics tracking.
    Analytics.setScreenName("blog_view_controller", screenClass: classForCoder.description())
  }

  // MARK: - Private Helpers

  @objc
  private func buttonTapped() {
    // For demo purposes, the blog post is not really saved. However, the tap event is logged with Firebase Analytics.
    Analytics.logEvent("blog_saved", parameters: nil) // 🔥
  }

  private var doneButton: UIBarButtonItem {
    UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(dismissKeyboardOnTap)
    )
  }

  private func configureNavigationBar() {
    navigationItem.title = "Weather Blog"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
  }

  private func setupSubviews() {
    let description = UILabel()
    view.addSubview(description)
    description.text = "See the code to see how to set custom screen names for analytics tracking."
    description.textColor = .secondaryLabel
    description.numberOfLines = 2
    description.frame = CGRect(
      x: 15, y: navigationController!.navigationBar.frame.maxY,
      width: view.frame.width - 30, height: 50
    )

    let button = UIButton()
    view.addSubview(button)
    button.setTitle("Save Blog Post", for: .normal)
    button.setTitleColor(UIColor.white.highlighted, for: .highlighted)
    button.setBackgroundImage(UIColor.systemOrange.image, for: .normal)
    button.setBackgroundImage(UIColor.systemOrange.highlighted.image, for: .highlighted)
    button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    button.clipsToBounds = true
    button.layer.cornerRadius = 16
    button.backgroundColor = .systemOrange
    button.frame = CGRect(
      x: 15, y: view.frame.height * 0.83,
      width: view.frame.width - 30, height: 45
    )

    let textView = UITextView()
    view.addSubview(textView)
    textView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: -20, right: -20)
    textView.text = "Today, the weather was ... "
    textView.font = .preferredFont(forTextStyle: .body)
    textView.backgroundColor = .secondarySystemFill
    textView.layer.cornerRadius = 16
    textView.delegate = self
    textView.frame = CGRect(
      x: 15, y: description.frame.maxY + 15,
      width: view.frame.width - 30, height: view.frame.height * 0.50
    )
  }

  @objc
  private func dismissKeyboardOnTap() {
    view.endEditing(true)
    navigationItem.rightBarButtonItem = nil
  }

  // Dismisses keyboard when view is tapped.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    view.endEditing(true)
  }

  // MARK: UITextViewDelegate

  func textViewDidBeginEditing(_ textView: UITextView) {
    navigationItem.rightBarButtonItem = doneButton
  }
}
