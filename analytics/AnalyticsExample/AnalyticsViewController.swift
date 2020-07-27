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

class AnalyticsViewController: UIViewController {
  private lazy var analyticsView = AnalyticsView(frame: view.frame)

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    view.addSubview(analyticsView)
    configureControls()
  }

  // MARK: - Firebase 🔥

  // MARK: Set User Properties

  @objc
  private func seasonDidChange(_ control: UISegmentedControl) {
    let season = control.titleForSegment(at: control.selectedSegmentIndex)!
    analyticsView.seasonImageView.image = UIImage(named: season)
    Analytics.setUserProperty(season, forName: "favorite_season") // 🔥
  }

  @objc
  private func unitsDidChange(_ control: UISegmentedControl) {
    let preferredUnits = control.titleForSegment(at: control.selectedSegmentIndex)!
    Analytics.setUserProperty(preferredUnits, forName: "preferred_units") // 🔥
  }

  // MARK: Event Logging

  @objc
  private func preferredTemperatureFeelDidChange(_ control: UISegmentedControl) {
    let temperatureFeelPreference = control.titleForSegment(at: control.selectedSegmentIndex)!
    Analytics.logEvent("hot_or_cold_switch", parameters: ["value": temperatureFeelPreference]) // 🔥
  }

  @objc
  private func preferredConditionsDidChange(_ control: UISegmentedControl) {
    let conditionsPreference = control.titleForSegment(at: control.selectedSegmentIndex)!
    Analytics.logEvent("rainy_or_sunny_switch", parameters: ["value": conditionsPreference]) // 🔥
  }

  @objc
  private func sliderDidChange(_ control: UISlider) {
    let value = Int(control.value)
    analyticsView.sliderTemperatureLabel.text = "\(value)°"
    Analytics.logEvent("preferred_temperature_changed", parameters: ["preference": value]) // 🔥
  }

  @objc
  private func buttonTapped() {
    Analytics.logEvent("blog_button_tapped", parameters: nil) // 🔥
    let navController = UINavigationController(rootViewController: BlogViewController())
    navigationController?.present(navController, animated: true)
  }

  // MARK: - Private Helpers

  private func configureControls() {
    analyticsView.seasonPicker.addTarget(
      self,
      action: #selector(seasonDidChange(_:)),
      for: .valueChanged
    )

    analyticsView.preferredUnitsPicker.addTarget(
      self,
      action: #selector(unitsDidChange(_:)),
      for: .valueChanged
    )

    analyticsView.temperatureSlider.addTarget(
      self,
      action: #selector(sliderDidChange(_:)),
      for: .valueChanged
    )

    analyticsView.preferredTemperatureFeelPicker.addTarget(
      self,
      action: #selector(preferredTemperatureFeelDidChange(_:)),
      for: .valueChanged
    )

    analyticsView.preferredConditionsPicker.addTarget(
      self,
      action: #selector(preferredConditionsDidChange(_:)),
      for: .valueChanged
    )

    analyticsView.postButton.addTarget(
      self,
      action: #selector(buttonTapped),
      for: .touchUpInside
    )
  }

  private func configureNavigationBar() {
    navigationItem.title = "Firebase Analytics"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
  }
}
