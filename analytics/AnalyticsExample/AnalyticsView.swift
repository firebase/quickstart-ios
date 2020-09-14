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

/// Represents the main view shown in AnalyticsViewController.
final class AnalyticsView: UIScrollView {
  // MARK: - UI Properties & Controls

  public var seasonPicker: UISegmentedControl!

  public var seasonImageView: UIImageView!

  public var preferredUnitsPicker: UISegmentedControl!

  public var preferredConditionsPicker: UISegmentedControl!

  public var preferredTemperatureFeelPicker: UISegmentedControl!

  public var sliderTemperatureLabel: UILabel!

  public lazy var postButton: UIButton = {
    let button = UIButton()
    button.setTitle("Post about the weather", for: .normal)
    button.setTitleColor(UIColor.white.highlighted, for: .highlighted)
    button.setBackgroundImage(UIColor.systemOrange.image, for: .normal)
    button.setBackgroundImage(UIColor.systemOrange.highlighted.image, for: .highlighted)
    button.clipsToBounds = true
    button.layer.cornerRadius = 16
    button.backgroundColor = .systemOrange
    return button
  }()

  public lazy var temperatureSlider: UISlider = {
    let slider = UISlider()
    slider.minimumTrackTintColor = .systemGray
    slider.minimumValue = 0
    slider.maximumValue = 100
    return slider
  }()

  // MARK: Private Layout Convenience Properties

  private let xOrigin: CGFloat = 15
  private var insetWidth: CGFloat { frame.width - 30 }
  private var height: CGFloat { frame.height }

  // MARK: - Initializers

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentInsetAdjustmentBehavior = .never
    backgroundColor = .systemBackground
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Subviews Setup

  private func setupSubviews() {
    /// Adds a description label under navigation bar.
    let descriptionLabel = buildLabel(
      text: "Interact with the various controls to start collecting analytics data.",
      textColor: .secondaryLabel, numberOfLines: 2
    )
    addSubview(descriptionLabel)
    descriptionLabel.frame = CGRect(
      x: xOrigin, y: height * 0.17,
      width: insetWidth, height: 50
    )

    // MARK: - User Properties Controls

    /// Label for the `Set user properties` section.
    let userPropertiesLabel = buildLabel(
      text: "Set user properties",
      font: .preferredFont(forTextStyle: .title3)
    )
    addSubview(userPropertiesLabel)
    userPropertiesLabel.frame = CGRect(
      x: xOrigin, y: descriptionLabel.frame.maxY + padding(.element),
      width: insetWidth, height: 25
    )

    // MARK: - User's Favorite Season UISegmentedControl & UIImageView

    /// Adds a `UISegmentedControl` so users can select their favorite season.
    seasonPicker = UISegmentedControl(items: ["Spring", "Summer", "Autumn", "Winter"])
    addSubview(seasonPicker)
    seasonPicker.frame = CGRect(
      x: xOrigin, y: userPropertiesLabel.frame.maxY + padding(.pair),
      width: insetWidth, height: 40
    )

    /// Sets up the `UIImageView` for the `seasonPicker`.
    setupImageViewSection()

    // MARK: - Preferred Temperature Units (°C or °F) UISegmentedControl

    /// Static `UILabel` associated with `preferredTemperatureFeelPicker`.
    let unitsLabel = buildLabel(text: "Preferred Temperature Units:", textColor: .secondaryLabel)
    addSubview(unitsLabel)
    unitsLabel.frame = CGRect(
      x: xOrigin, y: seasonImageView.frame.maxY + padding(.element),
      width: insetWidth - 90, height: 30
    )

    /// Adds a `UISegmentedControl` so users can select their preferred temperature units.
    preferredUnitsPicker = UISegmentedControl(items: ["°C", "°F"])
    addSubview(preferredUnitsPicker)
    preferredUnitsPicker.frame = CGRect(
      x: frame.width - 95, y: seasonImageView.frame.maxY + padding(.element),
      width: 80, height: 40
    )

    // MARK: - Log Events Controls

    /// Label for the `Log user interactions with events` section.
    let logEventsLabel = buildLabel(text: "Log user interactions with events",
                                    font: .preferredFont(forTextStyle: .title3))
    addSubview(logEventsLabel)
    logEventsLabel.frame = CGRect(
      x: xOrigin, y: unitsLabel.frame.maxY + padding(.element),
      width: insetWidth, height: 25
    )

    // MARK: - Preferred Temperature Feel (Hot or Cold) UISegmentedControl

    /// Static `UILabel` associated with `preferredTemperatureFeelPicker`.
    let preferredTemperatureFeelLabel = buildLabel(
      text: "Hot or cold weather?",
      textColor: .secondaryLabel
    )
    addSubview(preferredTemperatureFeelLabel)
    preferredTemperatureFeelLabel.frame = CGRect(
      x: xOrigin, y: logEventsLabel.frame.maxY + padding(.pair),
      width: insetWidth - 75, height: 30
    )

    /// Adds a `UISegmentedControl` so users can select from a pair of weather conditions.
    preferredTemperatureFeelPicker = UISegmentedControl(items: ["Hot", "Cold"])
    addSubview(preferredTemperatureFeelPicker)
    preferredTemperatureFeelPicker.frame = CGRect(
      x: frame.width - 115, y: logEventsLabel.frame.maxY + padding(.pair),
      width: 100, height: 40
    )

    // MARK: - Preferred Conditions (Rainy or Sunny) UISegmentedControl

    /// Static `UILabel` associated with `preferredConditionsPicker`.
    let preferredConditionsPickerLabel = buildLabel(
      text: "Rainy or sunny days?",
      textColor: .secondaryLabel
    )
    addSubview(preferredConditionsPickerLabel)
    preferredConditionsPickerLabel.frame = CGRect(
      x: xOrigin, y: preferredTemperatureFeelPicker.frame.maxY + padding(.pair),
      width: insetWidth - 75, height: 30
    )

    /// Adds a `UISegmentedControl` so users can select whether a day was `Rainy` or `Sunny`.
    preferredConditionsPicker = UISegmentedControl(items: ["Rainy", "Sunny"])
    addSubview(preferredConditionsPicker)
    preferredConditionsPicker.frame = CGRect(
      x: frame.width - 115, y: preferredConditionsPickerLabel.frame.minY,
      width: 100, height: 40
    )

    // MARK: - Preferred Temperature UISlider

    /// Static `UILabel` associated with `temperatureSlider`.
    let preferredTemperatureLabel = buildLabel(
      text: "Preferred temperature:",
      textColor: .secondaryLabel
    )
    addSubview(preferredTemperatureLabel)
    preferredTemperatureLabel.frame = CGRect(
      x: xOrigin, y: preferredConditionsPickerLabel.frame.maxY + 10, width: insetWidth - 75,
      height: 30
    )

    /// `UILabel` representing current value of `temperatureSlider`.
    sliderTemperatureLabel = buildLabel(
      text: "0°",
      font: .boldSystemFont(ofSize: 22),
      textColor: .label,
      textAlignment: .right
    )
    addSubview(sliderTemperatureLabel)
    sliderTemperatureLabel.frame = CGRect(
      x: frame.width - 65, y: preferredConditionsPickerLabel.frame.maxY + 10, width: 50, height: 30
    )

    /// A `UISlider` representing a user's preferred temperature.
    addSubview(temperatureSlider)
    temperatureSlider.frame = CGRect(
      origin: CGPoint(x: xOrigin, y: preferredTemperatureLabel.frame.maxY + padding(.section)),
      size: CGSize(width: insetWidth, height: 20)
    )

    // MARK: - Post Button

    addSubview(postButton)
    postButton.frame = CGRect(
      x: 15, y: temperatureSlider.frame.maxY + padding(.section),
      width: insetWidth, height: 45
    )

    // MARK: - Content Size

    /// Sets the appropriate `contentSize` of self (a `UIScrollview`) so the entire
    /// content can scroll to fit on smaller screens.
    contentSize = CGSize(width: frame.width, height: postButton.frame.maxY + 20)
  }

  /// Sets up an image view (and its support views) for diplaying seasons.
  private func setupImageViewSection() {
    /// Creates a background view that will be covered when an image is set to `seasonImageView`.
    let imageViewBackgroundView = UIView()
    addSubview(imageViewBackgroundView)
    imageViewBackgroundView.clipsToBounds = true
    imageViewBackgroundView.layer.cornerRadius = 16
    imageViewBackgroundView.backgroundColor = .secondarySystemFill
    imageViewBackgroundView.frame = CGRect(
      x: xOrigin, y: seasonPicker.frame.maxY + padding(.pair),
      width: insetWidth, height: 0.22 * height
    )

    let backgroundLabel = buildLabel(
      text: "Set user properties when a user \nselects their favorite season ↑ or \n" +
            "preferred temperature units ↓",
      textColor: .secondaryLabel, numberOfLines: 3, textAlignment: .center
    )
    addSubview(backgroundLabel)
    backgroundLabel.sizeToFit()
    backgroundLabel.center = imageViewBackgroundView.center

    /// Create the UIImageView that can display a user's favorite season.
    seasonImageView = UIImageView()
    addSubview(seasonImageView)
    seasonImageView.contentMode = .scaleAspectFill
    seasonImageView.clipsToBounds = true
    seasonImageView.layer.cornerRadius = 16
    seasonImageView.backgroundColor = .clear
    seasonImageView.frame = CGRect(
      x: xOrigin, y: seasonPicker.frame.maxY + padding(.pair),
      width: insetWidth, height: 0.22 * height
    )
  }

  /// Builds and returns a UILabel.
  /// - Parameters:
  ///   - text: A String for the label's text property.
  ///   - font: A UIFont for the label's displayed text.
  ///   - textColor: The UIColor of the label's displayed text.
  ///   - numberOfLines: The number of lines available to display text content.
  ///   - textAlignment: The NSTextAligment used by the label to format it's text.
  /// - Returns: A label that has been configured based on the passed in parameters.
  private func buildLabel(text: String, font: UIFont = .preferredFont(forTextStyle: .body),
                          textColor: UIColor = .label, numberOfLines: Int = 1,
                          textAlignment: NSTextAlignment = .left) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = textColor
    label.numberOfLines = numberOfLines
    label.textAlignment = textAlignment
    return label
  }

  // MARK: - Private Layout Helpers

  /// Represents different levels of spacing to pad UI Elements.
  private enum Spacing {
    case section
    case element
    case pair
  }

  private func padding(_ spaceType: Spacing) -> CGFloat {
    switch spaceType {
    case .section:
      return (0.03 * height)
    case .element:
      return (0.02 * height)
    case .pair:
      return (0.01 * height)
    }
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
