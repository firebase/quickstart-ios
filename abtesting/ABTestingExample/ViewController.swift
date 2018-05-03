//
//  Copyright (c) Google Inc.
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
import FirebaseInstanceID
import FirebaseRemoteConfig

enum ColorScheme {
  case light
  case dark
}

extension RemoteConfigFetchStatus {
  var debugDescription: String {
    switch self {
    case .failure:
      return "failure"
    case .noFetchYet:
      return "pending"
    case .success:
      return "success"
    case .throttled:
      return "throttled"
    }
  }
}

class ViewController: UIViewController, UITableViewDataSource {

  @IBOutlet var tableView: UITableView!

  var colorScheme: ColorScheme = .light {
    didSet {
      switchToColorScheme(colorScheme)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.dataSource = self
    self.tableView.tableFooterView = UIView()

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(printInstanceIDToken),
                                           name: .InstanceIDTokenRefresh,
                                           object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    RemoteConfig.remoteConfig().fetch(withExpirationDuration: 0) { (status, error) in
      if let error = error {
        print("Error fetching config: \(error)")
      }
      print("Config fetch completed with status: \(status.debugDescription)")
      self.setAppearance()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setAppearance()
  }

  func setAppearance() {
    RemoteConfig.remoteConfig().activateFetched()
    let configValue = RemoteConfig.remoteConfig()["color_scheme"]
    print("Config value: \(configValue.stringValue ?? "null")")
    if configValue.stringValue == "dark" {
      colorScheme = .dark
    } else {
      colorScheme = .light
    }
  }

  @objc func printInstanceIDToken() {
    let instanceID = InstanceID.instanceID().token() ?? "null"
    print("InstanceID token: \(instanceID)")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - UI Colors

  func switchToColorScheme(_ scheme: ColorScheme) {
    switch scheme {

    case .light:
      navigationController?.navigationBar.barTintColor = ViewController.lightColors.primary
      navigationController?.navigationBar.barStyle = .`default`
      navigationController?.navigationBar.titleTextAttributes = [
        NSForegroundColorAttributeName: UIColor.black
      ]
      tableView.separatorColor = .gray
      tableView.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)

    case .dark:
      navigationController?.navigationBar.barTintColor = ViewController.darkColors.primary
      navigationController?.navigationBar.barStyle = .black
      navigationController?.navigationBar.titleTextAttributes = [
        NSForegroundColorAttributeName: UIColor.white
      ]
      tableView.separatorColor = .lightGray
      tableView.backgroundColor = ViewController.darkColors.secondary
    }

    tableView.reloadData()
  }

  static let darkColors = (
    primary: UIColor(red: 0x61 / 0xff, green: 0x61 / 0xff, blue: 0x61 / 0xff, alpha: 1),
    secondary: UIColor(red: 0x42 / 0xff, green: 0x42 / 0xff, blue: 0x42 / 0xff, alpha: 1)
  )

  static let lightColors = (
    primary: UIColor(red: 0xff / 0xff, green: 0xc1 / 0xff, blue: 0x07 / 0xff, alpha: 1),
    secondary: UIColor(red: 0xff / 0xff, green: 0xc1 / 0xff, blue: 0x07 / 0xff, alpha: 1)
  )

  // MARK: - UITableViewDataSource

  let data = [
    ("Getting Started with Firebase", "An Introduction to Firebase"),
    ("Google Cloud Firestore", "Powerful Querying and Automatic Scaling"),
    ("Analytics", "Simple App Insights"),
    ("Remote Config", "Parameterize App Behavior")
  ]

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return data.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "GenericSubtitleCell", for: indexPath)
    cell.textLabel?.text = data[indexPath.row].0
    cell.detailTextLabel?.text = data[indexPath.row].1
    cell.detailTextLabel?.alpha = 0.8

    switch colorScheme {
    case .light:
      cell.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)
      cell.textLabel?.textColor = .black
      cell.detailTextLabel?.textColor = .black
    case .dark:
      cell.backgroundColor = ViewController.darkColors.secondary
      cell.textLabel?.textColor = .white
      cell.detailTextLabel?.textColor = .white
    }

    return cell
  }

}
