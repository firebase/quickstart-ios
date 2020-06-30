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

extension UIColor {
  var highlighted: UIColor { withAlphaComponent(0.8) }

  var image: UIImage {
    let pixel = CGSize(width: 1, height: 1)
    return UIGraphicsImageRenderer(size: pixel).image { context in
      self.setFill()
      context.fill(CGRect(origin: .zero, size: pixel))
    }
  }
}

extension NSMutableAttributedString {
  /// Convenience init for generating attributred string with SF Symbols
  /// - Parameters:
  ///   - text: The text for the attributed string.
  ///           Add a `%@` at the location for the SF Symbol.
  ///   - symbol: the name of the SF symbol
  convenience init(text: String, textColor: UIColor = .label, symbol: String? = nil,
                   symbolColor: UIColor = .label) {
    var symbolAttachment: NSAttributedString?
    if let symbolName = symbol, let symbolImage = UIImage(systemName: symbolName) {
      let configuredSymbolImage = symbolImage.withTintColor(
        symbolColor,
        renderingMode: .alwaysOriginal
      )
      let imageAttachment = NSTextAttachment(image: configuredSymbolImage)
      symbolAttachment = NSAttributedString(attachment: imageAttachment)
    }

    let splitStrings = text.components(separatedBy: "%@")
    let attributedString = NSMutableAttributedString()

    if let symbolAttachment = symbolAttachment, let range = text.range(of: "%@") {
      let shouldAddSymbolAtEnd = range.contains(text.endIndex)
      splitStrings.enumerated().forEach { index, string in

        let attributedPart = NSAttributedString(string: string)
        attributedString.append(attributedPart)
        if index < splitStrings.endIndex - 1 {
          attributedString.append(symbolAttachment)
        } else if index == splitStrings.endIndex - 1, shouldAddSymbolAtEnd {
          attributedString.append(symbolAttachment)
        }
      }
    }

    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColor]
    attributedString.addAttributes(
      attributes,
      range: NSRange(location: 0, length: attributedString.length)
    )

    self.init(attributedString: attributedString)
  }

  func setColorForText(text: String, color: UIColor) {
    let range = mutableString.range(of: text, options: .caseInsensitive)
    addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
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
