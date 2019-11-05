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

import Firebase

@objc(ViewController)
class ViewController: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

  @IBOutlet var inputTextView: UITextView!
  @IBOutlet var outputTextView: UITextView!
  @IBOutlet var statusTextView: UITextView!
  @IBOutlet var inputPicker: UIPickerView!
  @IBOutlet var outputPicker: UIPickerView!
  @IBOutlet var sourceDownloadDeleteButton: UIButton!
  @IBOutlet var targetDownloadDeleteButton: UIButton!

  var translator: Translator!
  lazy var allLanguages = TranslateLanguage.allLanguages().compactMap {
    TranslateLanguage(rawValue: $0.uintValue)
  }

  override func viewDidLoad() {
    inputPicker.dataSource = self
    outputPicker.dataSource = self
    inputPicker.selectRow(allLanguages.firstIndex(of: TranslateLanguage.en) ?? 0, inComponent: 0, animated: false)
    outputPicker.selectRow(allLanguages.firstIndex(of: TranslateLanguage.es) ?? 0, inComponent: 0, animated: false)
    inputPicker.delegate = self
    outputPicker.delegate = self
    inputTextView.delegate = self
    inputTextView.returnKeyType = .done
    pickerView(inputPicker, didSelectRow: 0, inComponent: 0)
    setDownloadDeleteButtonLabels()

    NotificationCenter.default.addObserver(self, selector:#selector(remoteModelDownloadDidComplete(notification:)), name:.firebaseMLModelDownloadDidSucceed, object:nil)
    NotificationCenter.default.addObserver(self, selector:#selector(remoteModelDownloadDidComplete(notification:)), name:.firebaseMLModelDownloadDidFail, object:nil)
  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return allLanguages[row].toLanguageCode()
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return allLanguages.count
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                replacementText text: String) -> Bool {
    // Hide the keyboard when "Done" is pressed.
    // See: https://stackoverflow.com/questions/26600359/dismiss-keyboard-with-a-uitextview
    if (text == "\n") {
      textView.resignFirstResponder()
      return false
    }
    return true
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

  func model(forLanguage: TranslateLanguage) -> TranslateRemoteModel {
    return TranslateRemoteModel.translateRemoteModel(language: forLanguage)
  }

  func isLanguageDownloaded(_ language: TranslateLanguage) -> Bool {
    let model = self.model(forLanguage: language)
    let modelManager = ModelManager.modelManager()
    return modelManager.isModelDownloaded(model)
  }

  func handleDownloadDelete(picker: UIPickerView, button: UIButton) {
    let language = allLanguages[picker.selectedRow(inComponent: 0)]
    button.setTitle("working...", for: .normal)
    let model = self.model(forLanguage: language)
    let modelManager = ModelManager.modelManager()
    if modelManager.isModelDownloaded(model) {
      self.statusTextView.text = "Deleting " + language.toLanguageCode()
      modelManager.deleteDownloadedModel(model) { error in
        self.statusTextView.text = "Deleted " + language.toLanguageCode()
        self.setDownloadDeleteButtonLabels()
      }
    } else {
      self.statusTextView.text = "Downloading " + language.toLanguageCode()
      let conditions = ModelDownloadConditions(
        allowsCellularAccess: true,
        allowsBackgroundDownloading: true
      )
      modelManager.download(model, conditions:conditions)
    }
  }

  @IBAction func didTapDownloadDeleteSourceLanguage() {
    self.handleDownloadDelete(picker: inputPicker, button: self.sourceDownloadDeleteButton)
  }

  @IBAction func didTapDownloadDeleteTargetLanguage() {
    self.handleDownloadDelete(picker: outputPicker, button: self.targetDownloadDeleteButton)
  }

  @IBAction func listDownloadedModels() {
    let msg = "Downloaded models:" + ModelManager.modelManager()
      .downloadedTranslateModels
      .map { model in model.language.toLanguageCode() }
      .joined(separator: ", ");
    self.statusTextView.text = msg
  }

  @objc
  func remoteModelDownloadDidComplete(notification: NSNotification) {
    let userInfo = notification.userInfo!
    guard let remoteModel =
      userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? TranslateRemoteModel else {
        return
    }
    DispatchQueue.main.async {
      if notification.name == .firebaseMLModelDownloadDidSucceed {
        self.statusTextView.text = "Download succeeded for " + remoteModel.language.toLanguageCode()
      } else {
        self.statusTextView.text = "Download failed for " + remoteModel.language.toLanguageCode()
      }
      self.setDownloadDeleteButtonLabels()
    }
  }

  func setDownloadDeleteButtonLabels() {
    let inputLanguage = allLanguages[inputPicker.selectedRow(inComponent: 0)]
    let outputLanguage = allLanguages[outputPicker.selectedRow(inComponent: 0)]
    if self.isLanguageDownloaded(inputLanguage) {
      self.sourceDownloadDeleteButton.setTitle("Delete model", for: .normal)
    } else {
      self.sourceDownloadDeleteButton.setTitle("Download model", for: .normal)
    }
    if self.isLanguageDownloaded(outputLanguage) {
      self.targetDownloadDeleteButton.setTitle("Delete model", for: .normal)
    } else {
      self.targetDownloadDeleteButton.setTitle("Download model", for: .normal)
    }
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let inputLanguage = allLanguages[inputPicker.selectedRow(inComponent: 0)]
    let outputLanguage = allLanguages[outputPicker.selectedRow(inComponent: 0)]
    self.setDownloadDeleteButtonLabels()
    let options = TranslatorOptions(sourceLanguage: inputLanguage, targetLanguage: outputLanguage)
    translator = NaturalLanguage.naturalLanguage().translator(options: options)
    translate()
  }

  func translate() {
    let translatorForDownloading = self.translator!

    translatorForDownloading.downloadModelIfNeeded { error in
      guard error == nil else {
        self.outputTextView.text = "Failed to ensure model downloaded with error \(error!)"
        return
      }
      self.setDownloadDeleteButtonLabels()
      if translatorForDownloading == self.translator {
        translatorForDownloading.translate(self.inputTextView.text ?? "") { result, error in
          guard error == nil else {
            self.outputTextView.text = "Failed with error \(error!)"
            return
          }
          if translatorForDownloading == self.translator {
            self.outputTextView.text = result
          }
        }
      }
    }
  }
}
