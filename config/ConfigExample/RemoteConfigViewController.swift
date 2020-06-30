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

class RemoteConfigViewController: UIViewController {
  private var remoteConfig: RemoteConfig!
  private var remoteConfigView: RemoteConfigView { view as! RemoteConfigView }

  private let topLabelKey = "topLabelKey"
  private let recipeKey = "recipeKey"
  private let bottomLabelKey = "bottomLabelKey"

  override func loadView() {
    view = RemoteConfigView()
  }

  /// Convenience init for injecting Remote Config instances during testing
  /// - Parameter remoteConfig: a Remote Config instance
  convenience init(remoteConfig: RemoteConfig) {
    self.init()
    self.remoteConfig = remoteConfig
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    setupRemoteConfig()
    configureFetchButtonAction()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    fetchAndActivateRemoteConfig()
  }

  // MARK: - Firebase 🔥

  /// Initializes defaults from `RemoteConfigDefaults.plist` and sets config's settings to developer mode
  private func setupRemoteConfig() {
    remoteConfig = RemoteConfig.remoteConfig()
    remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")

    let settings = RemoteConfigSettings()
    settings.minimumFetchInterval = 0
    remoteConfig.configSettings = settings
  }

  /// Fetches remote config values from the server
  private func fetchRemoteConfig() {
    remoteConfig.fetch { status, error in
      guard error == nil else { return self.displayError(error) }
      print("Remote config successfully fetched!")
    }
  }

  /// Activates remote config values, making them available to use in your app
  private func activateRemoteConfig() {
    remoteConfig.activate { success, error in
      guard error == nil else { return self.displayError(error) }
      print("Remote config successfully activated!")
      DispatchQueue.main.async {
        self.updateUI()
      }
    }
  }

  /// Fetches and activates remote config values
  @objc
  private func fetchAndActivateRemoteConfig() {
    remoteConfig.fetchAndActivate { status, error in
      guard error == nil else { return self.displayError(error) }
      print("Remote config successfully fetched & activated!")
      DispatchQueue.main.async {
        self.updateUI()
      }
    }
  }

  /// This method applies our remote config values to our UI
  private func updateUI() {
    remoteConfigView.topLabel.text = remoteConfig["topLabelKey"].stringValue
    updateJSONView()
    remoteConfigView.bottomLabel.text = remoteConfig["bottomLabelKey"].stringValue
  }

  // MARK: - Private Helpers

  private func configureNavigationBar() {
    navigationItem.title = "Firebase Config"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
  }

  private func configureFetchButtonAction() {
    remoteConfigView.fetchButton.addTarget(
      self,
      action: #selector(fetchAndActivateRemoteConfig),
      for: .touchUpInside
    )
  }

  private func updateJSONView() {
    let jsonView = remoteConfigView.jsonView!
    let displayedJSON = jsonView.subviews
    displayedJSON.forEach { label in
      UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
        label.alpha = 0
            }) { _ in
        label.removeFromSuperview()
      }
    }

    // Specify keys in the order we would like to display the information in
    let keys = [
      "recipe_name",
      "ingredients",
      "prep_time",
      "cook_time",
      "instructions",
      "yield",
      "serving_size",
      "notes",
    ]
    guard let recipeDictionary = remoteConfig[recipeKey].jsonValue as? [String: Any] else { return }

    keys.enumerated().forEach { index, key in
      guard var value = recipeDictionary[key] else { return }

      if let list = value as? [String] {
        let joinedValue = list.joined(separator: " • ")
        value = joinedValue
      } else if let stringValue = value as? String {
        value = stringValue
      }

      guard let stringValue = value as? String else { return }

      var formattedKey = key.capitalized
      formattedKey = formattedKey.replacingOccurrences(of: "_", with: " ")
      formattedKey.append(": ")

      let attributedKey = NSAttributedString(
        string: formattedKey,
        attributes: [.foregroundColor: UIColor.secondaryLabel]
      )
      let attributedValue = NSAttributedString(
        string: stringValue,
        attributes: [.foregroundColor: UIColor.systemOrange]
      )
      let labelAttributedText = NSMutableAttributedString()
      labelAttributedText.append(attributedKey)
      labelAttributedText.append(attributedValue)

      let label = UILabel()
      label.attributedText = labelAttributedText
      label.alpha = 0
      label.sizeToFit()
      jsonView.addSubview(label)
      animateFadeIn(for: label, duration: 0.3)

      let height = jsonView.frame.height
      let step = height / CGFloat(keys.count)
      let offset = height * 0.2 * 1 / CGFloat(keys.count)

      let x: CGFloat = jsonView.frame.width * 0.05
      let y: CGFloat = step * CGFloat(index) + offset

      label.frame.origin = CGPoint(x: x, y: y)
    }
  }

  private func animateFadeIn(for view: UIView, duration: TimeInterval) {
    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
      view.alpha = 1
        })
  }
}

extension UIViewController {
  public func displayError(_ error: Error?, from function: StaticString = #function) {
    guard let error = error else { return }
    print("🚨 Error in \(function): \(error.localizedDescription)")
    let message = "\(error.localizedDescription)\n\n Ocurred in \(function)"
    let errorAlertController = UIAlertController(
      title: "Error",
      message: message,
      preferredStyle: .alert
    )
    errorAlertController.addAction(UIAlertAction(title: "OK", style: .default))
    present(errorAlertController, animated: true, completion: nil)
  }
}
