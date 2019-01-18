//
// Copyright (c) 2015 Google Inc.
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
import FirebaseMLNLLanguageID
import FirebaseMLNaturalLanguage

@objc(ViewController)
final class ViewController: UIViewController {
  @IBOutlet weak var inputTextView: UITextView!
  @IBOutlet weak var outputTextView: UITextView!

  lazy var languageId = NaturalLanguage.naturalLanguage().languageIdentification()

  override func viewDidLoad() {
    super.viewDidLoad()
    inputTextView.text = "Type here"
  }

  @IBAction func identifyLanguage(_ sender: Any) {
    languageId.identifyLanguage(for: inputTextView.text) { (languageCode, error) in
      if let error = error {
        self.outputTextView.text = "Failed with error: \(error)"
        return
      }

      if let languageCode = languageCode {
        self.outputTextView.text = "Identified Language: \(languageCode)"
      } else {
        self.outputTextView.text = "No language was identified"
      }
    }
  }

  @IBAction func identifyPossibleLanguages(_ sender: Any) {
    languageId.identifyPossibleLanguages(for: inputTextView.text) { (identifiedLanguages, error) in
      if let error = error {
        self.outputTextView.text = "Failed with error: \(error)"
        return
      }
      guard let identifiedLanguages = identifiedLanguages, !identifiedLanguages.isEmpty else {
        self.outputTextView.text = "No language was identified";
        return
      }

      self.outputTextView.text = "Identified Languages:\n" +
        identifiedLanguages.map {
          String(format: "(%@, %.2f)", $0.languageCode, $0.confidence)
          }.joined(separator: "\n");
    }
  }
}
