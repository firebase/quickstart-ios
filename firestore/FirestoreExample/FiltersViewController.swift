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

class FiltersViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
  weak var delegate: FiltersViewControllerDelegate?

  static func fromStoryboard(delegate: FiltersViewControllerDelegate? = nil) ->
    (navigationController: UINavigationController, filtersController: FiltersViewController) {
    let navController = UIStoryboard(name: "Main", bundle: nil)
      .instantiateViewController(withIdentifier: "FiltersViewController")
      as! UINavigationController
    let controller = navController.viewControllers[0] as! FiltersViewController
    controller.delegate = delegate
    return (navigationController: navController, filtersController: controller)
  }

  @IBOutlet var categoryTextField: UITextField! {
    didSet {
      categoryTextField.inputView = categoryPickerView
    }
  }

  @IBOutlet var cityTextField: UITextField! {
    didSet {
      cityTextField.inputView = cityPickerView
    }
  }

  @IBOutlet var priceTextField: UITextField! {
    didSet {
      priceTextField.inputView = pricePickerView
    }
  }

  @IBOutlet var sortByTextField: UITextField! {
    didSet {
      sortByTextField.inputView = sortByPickerView
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Blue bar with white color
    navigationController?.navigationBar.barTintColor =
      UIColor(red: 0x3D / 0xFF, green: 0x5A / 0xFF, blue: 0xFE / 0xFF, alpha: 1.0)
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedString.Key.foregroundColor: UIColor.white]
  }

  private func price(from string: String) -> Int? {
    switch string {
    case "$":
      return 1
    case "$$":
      return 2
    case "$$$":
      return 3

    case _:
      return nil
    }
  }

  @IBAction func didTapDoneButton(_ sender: Any) {
    let price = priceTextField.text.flatMap { self.price(from: $0) }
    delegate?.controller(self, didSelectCategory: categoryTextField.text,
                         city: cityTextField.text, price: price, sortBy: sortByTextField.text)
    navigationController?.dismiss(animated: true, completion: nil)
  }

  @IBAction func didTapCancelButton(_ sender: Any) {
    navigationController?.dismiss(animated: true, completion: nil)
  }

  func clearFilters() {
    categoryTextField.text = ""
    cityTextField.text = ""
    priceTextField.text = ""
    sortByTextField.text = ""
  }

  private lazy var sortByPickerView: UIPickerView = {
    let pickerView = UIPickerView()
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()

  private lazy var pricePickerView: UIPickerView = {
    let pickerView = UIPickerView()
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()

  private lazy var cityPickerView: UIPickerView = {
    let pickerView = UIPickerView()
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()

  private lazy var categoryPickerView: UIPickerView = {
    let pickerView = UIPickerView()
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()

  private let sortByOptions = ["name", "category", "city", "price", "avgRating"]
  private let priceOptions = ["$", "$$", "$$$"]
  private let cityOptions = Restaurant.cities
  private let categoryOptions = Restaurant.categories

  // MARK: UIPickerViewDataSource

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    switch pickerView {
    case sortByPickerView:
      return sortByOptions.count
    case pricePickerView:
      return priceOptions.count
    case cityPickerView:
      return cityOptions.count
    case categoryPickerView:
      return categoryOptions.count

    case _:
      fatalError("Unhandled picker view: \(pickerView)")
    }
  }

  // MARK: - UIPickerViewDelegate

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
    switch pickerView {
    case sortByPickerView:
      return sortByOptions[row]
    case pricePickerView:
      return priceOptions[row]
    case cityPickerView:
      return cityOptions[row]
    case categoryPickerView:
      return categoryOptions[row]

    case _:
      fatalError("Unhandled picker view: \(pickerView)")
    }
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    switch pickerView {
    case sortByPickerView:
      sortByTextField.text = sortByOptions[row]
    case pricePickerView:
      priceTextField.text = priceOptions[row]
    case cityPickerView:
      cityTextField.text = cityOptions[row]
    case categoryPickerView:
      categoryTextField.text = categoryOptions[row]

    case _:
      fatalError("Unhandled picker view: \(pickerView)")
    }
  }
}

protocol FiltersViewControllerDelegate: NSObjectProtocol {
  func controller(_ controller: FiltersViewController,
                  didSelectCategory category: String?,
                  city: String?, price: Int?, sortBy: String?)
}
