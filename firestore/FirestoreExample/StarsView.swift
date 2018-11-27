//
//  Copyright (c) 2017 Google Inc.
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

class RatingView: UIControl {

  var highlightedColor: CGColor = Constants.highlightedColorOrange

  var rating: Int? {
    didSet {
      if let value = rating {
        setHighlighted(index: value - 1)
      } else {
        clearAll()
      }

      // highlight the appropriate amount of stars.
      sendActions(for: .valueChanged)
    }
  }

  private let starLayers: [CAShapeLayer]

  override init(frame: CGRect) {
    starLayers = (0 ..< 5).map {
      let layer = RatingView.starLayer()
      layer.frame = CGRect(x: $0 * 55, y: 0, width: 25, height: 25)
      return layer
    }
    super.init(frame: frame)

    starLayers.forEach {
      layer.addSublayer($0)
    }
  }

  private var starWidth: CGFloat {
    return intrinsicContentSize.width / 5
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let touch = touches.first else { return }
    let point = touch.location(in: self)
    let index = clamp(Int(point.x / starWidth))
    setHighlighted(index: index)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard let touch = touches.first else { return }
    let point = touch.location(in: self)
    let index = clamp(Int(point.x / starWidth))
    setHighlighted(index: index)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    guard let touch = touches.first else { return }
    let point = touch.location(in: self)
    let index = clamp(Int(point.x / starWidth))
    rating = index + 1 // Ratings are 1-indexed; things can be between 1-5 stars.
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    guard touches.first != nil else { return }

    // Cancelled touches should preserve the value before the interaction.
    if let oldRating = rating {
      let oldIndex = oldRating - 1
      setHighlighted(index: oldIndex)
    } else {
      clearAll()
    }
  }

  /// This is an awful func name. Index must be within 0 ..< 4, or crash.
  private func setHighlighted(index: Int) {
    // Highlight everything up to and including the star at the index.
    (0 ... index).forEach {
      let star = starLayers[$0]
      star.strokeColor = highlightedColor
      star.fillColor = highlightedColor
    }

    // Unhighlight everything after the index, if applicable.
    guard index < 4 else { return }
    ((index + 1) ..< 5).forEach {
      let star = starLayers[$0]
      star.strokeColor = highlightedColor
      star.fillColor = nil
    }
  }

  /// Unhighlights every star.
  private func clearAll() {
    (0 ..< 5).forEach {
      let star = starLayers[$0]
      star.strokeColor = highlightedColor
      star.fillColor = nil
    }
  }

  private func clamp(_ index: Int) -> Int {
    if index < 0 { return 0 }
    if index > 4 { return 4 }
    return index
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 270, height: 50)
  }

  override var isMultipleTouchEnabled: Bool {
    get { return false }
    set {}
  }

  private static func starLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()

    let mutablePath = CGMutablePath()

    let outerRadius: CGFloat = 18
    let outerPoints = stride(from: CGFloat.pi / -5, to: .pi * 2, by: 2 * .pi / 5).map {
      return CGPoint(x: outerRadius * sin($0) + 25,
                     y: outerRadius * cos($0) + 25)
    }

    let innerRadius: CGFloat = 6
    let innerPoints = stride(from: 0, to: .pi * 2, by: 2 * .pi / 5).map {
      return CGPoint(x: innerRadius * sin($0) + 25,
                     y: innerRadius * cos($0) + 25)
    }

    let points = zip(outerPoints, innerPoints).reduce([CGPoint]()) { (aggregate, pair) -> [CGPoint] in
      return aggregate + [pair.0, pair.1]
    }

    mutablePath.move(to: points[0])
    points.forEach {
      mutablePath.addLine(to: $0)
    }
    mutablePath.closeSubpath()

    layer.path = mutablePath.copy()
    layer.strokeColor = UIColor.gray.cgColor
    layer.lineWidth = 1
    layer.fillColor = nil

    return layer
  }

  @available(*, unavailable)
  required convenience init?(coder aDecoder: NSCoder) {
    // coder is ignored.
    self.init(frame: CGRect(x: 0, y: 0, width: 270, height: 50))
    self.translatesAutoresizingMaskIntoConstraints = false
  }

  private enum Constants {
    static let unhighlightedColor = UIColor.gray.cgColor
    static let highlightedColorOrange = UIColor(red: 255 / 255, green: 179 / 255, blue: 0 / 255, alpha: 1).cgColor
  }

  // MARK: Rating View Accessibility

  override var isAccessibilityElement: Bool {
    get { return true }
    set {}
  }

  override var accessibilityValue: String? {
    get {
      if let rating = rating {
        return NSLocalizedString("\(rating) out of 5", comment: "Format string for indicating a variable amount of stars out of five")
      }
      return NSLocalizedString("No rating", comment: "Read by VoiceOver to vision-impaired users indicating a rating that hasn't been filled out yet")
    }
    set {}
  }

  override var accessibilityTraits: UIAccessibilityTraits {
    get { return UIAccessibilityTraits.adjustable }
    set {}
  }

  override func accessibilityIncrement() {
    let currentRatingIndex = (rating ?? 0) - 1
    let highlightedIndex = clamp(currentRatingIndex + 1)
    rating = highlightedIndex + 1
  }

  override func accessibilityDecrement() {
    guard let rating = rating else { return } // Doesn't make sense to decrement no rating and get 1.
    let currentRatingIndex = rating - 1
    let highlightedIndex = clamp(currentRatingIndex - 1)
    self.rating = highlightedIndex + 1
  }
  
}

// This class is absolutely not immutable, but it's also not user-interactive.
class ImmutableStarsView: UIView {

  override var intrinsicContentSize: CGSize {
    get { return CGSize(width: 100, height: 20) }
    set {}
  }

  var highlightedColor: CGColor = Constants.highlightedColorOrange

  var rating: Int? {
    didSet {
      if let value = rating {
        setHighlighted(index: value - 1)
      } else {
        clearAll()
      }
    }
  }

  private let starLayers: [CAShapeLayer]

  override init(frame: CGRect) {
    starLayers = (0 ..< 5).map {
      let layer = ImmutableStarsView.starLayer()
      layer.frame = CGRect(x: $0 * 20, y: 0, width: 20, height: 20)
      return layer
    }
    super.init(frame: frame)

    starLayers.forEach {
      layer.addSublayer($0)
    }
  }

  private var starWidth: CGFloat {
    return intrinsicContentSize.width / 5
  }

  /// This is an awful func name. Index must be within 0 ..< 4, or crash.
  private func setHighlighted(index anyIndex: Int) {
    if anyIndex < 0 {
      clearAll()
      return
    }
    let index = self.clamp(anyIndex)
    // Highlight everything up to and including the star at the index.
    (0 ... index).forEach {
      let star = starLayers[$0]
      star.strokeColor = highlightedColor
      star.fillColor = highlightedColor
    }

    // Unhighlight everything after the index, if applicable.
    guard index < 4 else { return }
    ((index + 1) ..< 5).forEach {
      let star = starLayers[$0]
      star.strokeColor = Constants.unhighlightedColor
      star.fillColor = nil
    }
  }

  /// Unhighlights every star.
  private func clearAll() {
    (0 ..< 5).forEach {
      let star = starLayers[$0]
      star.strokeColor = Constants.unhighlightedColor
      star.fillColor = nil
    }
  }

  private func clamp(_ index: Int) -> Int {
    if index < 0 { return 0 }
    if index >= 5 { return 4 }
    return index
  }

  override var isUserInteractionEnabled: Bool {
    get { return false }
    set {}
  }

  private static func starLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()

    let mutablePath = CGMutablePath()

    let outerRadius: CGFloat = 9
    let outerPoints = stride(from: CGFloat.pi / -5, to: .pi * 2, by: 2 * .pi / 5).map {
      return CGPoint(x: outerRadius * sin($0) + 9,
                     y: outerRadius * cos($0) + 9)
    }

    let innerRadius: CGFloat = 4
    let innerPoints = stride(from: 0, to: .pi * 2, by: 2 * .pi / 5).map {
      return CGPoint(x: innerRadius * sin($0) + 9,
                     y: innerRadius * cos($0) + 9)
    }

    let points = zip(outerPoints, innerPoints).reduce([CGPoint]()) { (aggregate, pair) -> [CGPoint] in
      return aggregate + [pair.0, pair.1]
    }

    mutablePath.move(to: points[0])
    points.forEach {
      mutablePath.addLine(to: $0)
    }
    mutablePath.closeSubpath()

    layer.path = mutablePath.copy()
    layer.strokeColor = UIColor.gray.cgColor
    layer.lineWidth = 1
    layer.fillColor = nil

    return layer
  }

  @available(*, unavailable)
  required convenience init?(coder aDecoder: NSCoder) {
    // coder is ignored.
    self.init(frame: CGRect(x: 0, y: 0, width: 270, height: 50))
    self.translatesAutoresizingMaskIntoConstraints = false
  }

  private enum Constants {
    static let unhighlightedColor = UIColor.gray.cgColor
    static let highlightedColorOrange = UIColor(red: 255 / 255, green: 179 / 255, blue: 0 / 255, alpha: 1).cgColor
  }

}
