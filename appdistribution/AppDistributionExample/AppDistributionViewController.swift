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

class AppDistributionViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
  }

  // MARK: - Firebase 🔥

  override func viewDidAppear(_ animated: Bool) {
    AppDistribution.appDistribution().checkForUpdate { release, error in
      guard let release = release else {
        print("No release found")
        return
      }

      let title = "New Version Available"
      let message = "Version \(release.displayVersion)(\(release.buildVersion)) is available."
      let uialert = UIAlertController(title: title, message: message, preferredStyle: .alert)

      uialert.addAction(UIAlertAction(title: "Update", style: UIAlertAction.Style.default) {
        alert in
        UIApplication.shared.open(release.downloadURL)
      })
      uialert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
        alert in
      })

      // self should be a UIViewController.
      self.present(uialert, animated: true, completion: nil)
    }
  }

  // MARK: - Private Helpers

  private func configureNavigationBar() {
    navigationItem.title = "Firebase App Distribution"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
  }
}
