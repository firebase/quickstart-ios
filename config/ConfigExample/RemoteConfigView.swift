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

/// Represents the main view shown in RemoteConfigViewController
class RemoteConfigView: UIView {
  var topLabel: UILabel!
  var jsonView: UIView!
  var bottomLabel: UILabel!

  lazy var fetchButton: UIButton = {
    let button = UIButton()
    button.setTitle("Fetch & Activate Config", for: .normal)
    button.setTitleColor(UIColor.white.highlighted, for: .highlighted)
    button.setBackgroundImage(UIColor.systemOrange.image, for: .normal)
    button.setBackgroundImage(UIColor.systemOrange.highlighted.image, for: .highlighted)
    button.clipsToBounds = true
    button.layer.cornerRadius = 14
    return button
  }()

  convenience init() {
    self.init(frame: .zero)
    backgroundColor = .systemBackground
    setupSubviews()
  }

  // MARK: - Label Text

  private var topInfoLabelText: NSAttributedString {
    let labelText = "Use config to change a label's text %@"
    let symbolName = "wand.and.stars"
    let attributedText = NSMutableAttributedString(
      text: labelText,
      textColor: .secondaryLabel,
      symbol: symbolName,
      symbolColor: .systemYellow
    )
    attributedText.setColorForText(text: "text", color: .systemYellow)
    return attributedText
  }

  private var jsonInfoLabelText: NSAttributedString {
    let labelText = "%@ Use JSON to configure complex entities"
    let symbolName = "arrow.down.doc.fill"
    let attributedText = NSMutableAttributedString(text: labelText, textColor: .secondaryLabel,
                                                   symbol: symbolName, symbolColor: .systemOrange)
    attributedText.setColorForText(text: "JSON", color: .systemOrange)
    return attributedText
  }

  private var bottomLabelInfoText: NSAttributedString {
    let labelText = "%@ Define platform or locale-specific content"
    let symbolName = "clock.fill"
    let attributedText = NSMutableAttributedString(
      text: labelText,
      textColor: .secondaryLabel,
      symbol: symbolName,
      symbolColor: .systemOrange
    )
    return attributedText
  }

  // MARK: - Subview Setup

  private func setupSubviews() {
    setupTopSubviews()
    setupJSONSubview()
    setupBottomSubviews()
    setupFetchButton()
  }

  /// Sets up an info label with a remotely configurable label below it
  private func setupTopSubviews() {
    let label = UILabel()
    label.attributedText = topInfoLabelText
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)

    topLabel = UILabel()
    topLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    topLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(topLabel)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 15),
      label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
      topLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
      topLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
      topLabel.trailingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.trailingAnchor,
        constant: -15
      ),
    ])
  }

  /// Sets up the container view to display data from JSON objects
  private func setupJSONSubview() {
    jsonView = UIView()
    jsonView.backgroundColor = .secondarySystemBackground
    jsonView.layer.cornerRadius = 16
    jsonView.clipsToBounds = true
    jsonView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(jsonView)

    let label = UILabel()
    label.attributedText = jsonInfoLabelText
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)

    NSLayoutConstraint.activate([
      label.bottomAnchor.constraint(equalTo: jsonView.topAnchor, constant: -10),
      label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
      jsonView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
      jsonView.trailingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.trailingAnchor,
        constant: -15
      ),
      jsonView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: -30),
      jsonView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.37),
    ])
  }

  /// Sets up an info label with a remotely configurable label below it
  private func setupBottomSubviews() {
    let label = UILabel()
    label.attributedText = bottomLabelInfoText
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)

    bottomLabel = UILabel()
    bottomLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    bottomLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(bottomLabel)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: jsonView.bottomAnchor, constant: 30),
      label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
      bottomLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
      bottomLabel.leadingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.leadingAnchor,
        constant: 15
      ),
      bottomLabel.trailingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.trailingAnchor,
        constant: -15
      ),
    ])
  }

  private func setupFetchButton() {
    fetchButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(fetchButton)
    NSLayoutConstraint.activate([
      fetchButton.leadingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.leadingAnchor,
        constant: 15
      ),
      fetchButton.trailingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.trailingAnchor,
        constant: -15
      ),
      fetchButton.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: -50),
      fetchButton.topAnchor.constraint(
        greaterThanOrEqualTo: bottomLabel.bottomAnchor,
        constant: 20
      ),
      fetchButton.heightAnchor.constraint(equalToConstant: 45),
    ])
  }
}

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
