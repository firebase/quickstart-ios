//
// Copyright (c) 2019 Google Inc.
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

import FirebaseMLNaturalLanguage
import FirebaseMLNLTranslate

@objc(ViewController)
class ViewController: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

  @IBOutlet var inputTextView: UITextView!
  @IBOutlet var outputTextView: UITextView!
  @IBOutlet var inputPicker: UIPickerView!
  @IBOutlet var outputPicker: UIPickerView!

  var translator: Translator!
  lazy var allLanguages = Array(TranslatorLanguage.allLanguages())

  override func viewDidLoad() {
    inputPicker.dataSource = self
    outputPicker.dataSource = self
    inputPicker.selectRow(allLanguages.index(of: TranslatorLanguage.EN.rawValue as NSNumber) ?? 0, inComponent: 0, animated: false)
    outputPicker.selectRow(allLanguages.index(of: TranslatorLanguage.ES.rawValue as NSNumber) ?? 0, inComponent: 0, animated: false)
    inputPicker.delegate = self
    outputPicker.delegate = self
    inputTextView.delegate = self
    pickerView(inputPicker, didSelectRow: 0, inComponent: 0)
  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return TranslatorLanguage(rawValue: allLanguages[row].uintValue)?.toLanguageCode()
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return allLanguages.count
  }

  func textViewDidChange(_ textView: UITextView) {
    translate()
  }

  @IBAction func didTapSwap() {
    let inputSelectedRow = inputPicker.selectedRow(inComponent: 0)
    inputPicker.selectRow(outputPicker.selectedRow(inComponent: 0), inComponent: 0, animated: false)
    outputPicker.selectRow(inputSelectedRow, inComponent: 0, animated: false)
    inputTextView.text = outputTextView.text
    pickerView(inputPicker, didSelectRow: 0, inComponent: 0)
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard let inputLanguage = TranslatorLanguage(rawValue: allLanguages[inputPicker.selectedRow(inComponent: 0)].uintValue) else { return }
    guard let outputLanguage = TranslatorLanguage(rawValue: allLanguages[outputPicker.selectedRow(inComponent: 0)].uintValue) else { return }
    let options = TranslatorOptions(sourceLanguage: inputLanguage, targetLanguage: outputLanguage)
    translator = NaturalLanguage.naturalLanguage().translator(options: options)
    translate()
  }

  func translate() {
    translator.ensureModelDownloaded { error in
      guard error == nil else {
        self.outputTextView.text = "Failed to ensure model downloaded with error \(error!)"
        return
      }
      self.translator.translate(self.inputTextView.text ?? "") { result, error in
        guard error == nil else {
          self.outputTextView.text = "Failed with error \(error!)"
          return
        }
        self.outputTextView.text = result
      }
    }
  }
}

