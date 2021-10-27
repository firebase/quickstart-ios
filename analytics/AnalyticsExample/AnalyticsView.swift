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

  // MARK: Auxillary Views for Layout Purposes

  private var descriptionLabel: UILabel!

  private var userPropertiesLabel: UILabel!

  private var unitsLabel: UILabel!

  private var logEventsLabel: UILabel!

  private var preferredTemperatureFeelLabel: UILabel!

  private var preferredConditionsPickerLabel: UILabel!

  private var preferredTemperatureLabel: UILabel!

  private var imageViewBackgroundView: UIView!

  private var backgroundLabel: UILabel!

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
    descriptionLabel = buildLabel(
      text: "Interact with the various controls to start collecting analytics data.",
      textColor: .secondaryLabel, numberOfLines: 2
    )
    addSubview(descriptionLabel)

    // MARK: - User Properties Controls

    /// Label for the `Set user properties` section.
    userPropertiesLabel = buildLabel(
      text: "Set user properties",
      font: .preferredFont(forTextStyle: .title3)
    )
    addSubview(userPropertiesLabel)

    // MARK: - User's Favorite Season UISegmentedControl & UIImageView

    /// Adds a `UISegmentedControl` so users can select their favorite season.
    seasonPicker = UISegmentedControl(items: ["Spring", "Summer", "Autumn", "Winter"])
    seasonPicker.translatesAutoresizingMaskIntoConstraints = false
    addSubview(seasonPicker)

    /// Sets up the `UIImageView` for the `seasonPicker`.
    setupImageViewSection()

    // MARK: - Preferred Temperature Units (°C or °F) UISegmentedControl

    /// Static `UILabel` associated with `preferredTemperatureFeelPicker`.
    unitsLabel = buildLabel(text: "Preferred Temperature Units:", textColor: .secondaryLabel)
    addSubview(unitsLabel)

    /// Adds a `UISegmentedControl` so users can select their preferred temperature units.
    preferredUnitsPicker = UISegmentedControl(items: ["°C", "°F"])
    addSubview(preferredUnitsPicker)

    // MARK: - Log Events Controls

    /// Label for the `Log user interactions with events` section.
    logEventsLabel = buildLabel(text: "Log user interactions with events",
                                font: .preferredFont(forTextStyle: .title3))
    addSubview(logEventsLabel)

    // MARK: - Preferred Temperature Feel (Hot or Cold) UISegmentedControl

    /// Static `UILabel` associated with `preferredTemperatureFeelPicker`.
    preferredTemperatureFeelLabel = buildLabel(
      text: "Hot or cold weather?",
      textColor: .secondaryLabel
    )
    addSubview(preferredTemperatureFeelLabel)

    /// Adds a `UISegmentedControl` so users can select from a pair of weather conditions.
    preferredTemperatureFeelPicker = UISegmentedControl(items: ["Hot", "Cold"])
    preferredTemperatureFeelPicker.translatesAutoresizingMaskIntoConstraints = false
    addSubview(preferredTemperatureFeelPicker)

    // MARK: - Preferred Conditions (Rainy or Sunny) UISegmentedControl

    /// Static `UILabel` associated with `preferredConditionsPicker`.
    preferredConditionsPickerLabel = buildLabel(
      text: "Rainy or sunny days?",
      textColor: .secondaryLabel
    )
    addSubview(preferredConditionsPickerLabel)

    /// Adds a `UISegmentedControl` so users can select whether a day was `Rainy` or `Sunny`.
    preferredConditionsPicker = UISegmentedControl(items: ["Rainy", "Sunny"])
    preferredConditionsPicker.translatesAutoresizingMaskIntoConstraints = false
    addSubview(preferredConditionsPicker)

    // MARK: - Preferred Temperature UISlider

    /// Static `UILabel` associated with `temperatureSlider`.
    preferredTemperatureLabel = buildLabel(
      text: "Preferred temperature:",
      textColor: .secondaryLabel
    )
    addSubview(preferredTemperatureLabel)

    /// `UILabel` representing current value of `temperatureSlider`.
    sliderTemperatureLabel = buildLabel(
      text: "0°",
      font: .boldSystemFont(ofSize: 22),
      textColor: .label,
      textAlignment: .right
    )
    addSubview(sliderTemperatureLabel)

    /// A `UISlider` representing a user's preferred temperature.
    addSubview(temperatureSlider)

    // MARK: - Post Button

    addSubview(postButton)
  }

  /// Sets up an image view (and its support views) for diplaying seasons.
  private func setupImageViewSection() {
    /// Creates a background view that will be covered when an image is set to `seasonImageView`.
    imageViewBackgroundView = UIView(frame: .zero)
    imageViewBackgroundView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(imageViewBackgroundView)
    imageViewBackgroundView.clipsToBounds = true
    imageViewBackgroundView.layer.cornerRadius = 16
    imageViewBackgroundView.backgroundColor = .secondarySystemFill

    backgroundLabel = buildLabel(
      text: "Set user properties when a user \nselects their favorite season ↑ or \n" +
        "preferred temperature units ↓",
      textColor: .secondaryLabel, numberOfLines: 3, textAlignment: .center
    )
    addSubview(backgroundLabel)

    /// Create the UIImageView that can display a user's favorite season.
    seasonImageView = UIImageView()
    seasonImageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(seasonImageView)
    seasonImageView.contentMode = .scaleAspectFill
    seasonImageView.clipsToBounds = true
    seasonImageView.layer.cornerRadius = 16
    seasonImageView.backgroundColor = .clear
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
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = font
    label.textColor = textColor
    label.numberOfLines = numberOfLines
    label.textAlignment = textAlignment
    return label
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    descriptionLabel.frame = CGRect(
      x: xOrigin, y: safeAreaInsets.top,
      width: insetWidth, height: 50
    )
    userPropertiesLabel.frame = CGRect(
      x: xOrigin, y: descriptionLabel.frame.maxY + padding(.element),
      width: insetWidth, height: 25
    )
    seasonPicker.frame = CGRect(
      x: xOrigin, y: userPropertiesLabel.frame.maxY + padding(.pair),
      width: insetWidth, height: 40
    )
    imageViewBackgroundView.frame = CGRect(
      x: xOrigin, y: seasonPicker.frame.maxY + padding(.pair),
      width: insetWidth, height: 0.22 * height
    )

    backgroundLabel.sizeToFit()
    backgroundLabel.center = imageViewBackgroundView.center

    seasonImageView.frame = CGRect(
      x: xOrigin, y: seasonPicker.frame.maxY + padding(.pair),
      width: insetWidth, height: 0.22 * height
    )
    unitsLabel.frame = CGRect(
      x: xOrigin, y: seasonImageView.frame.maxY + padding(.element),
      width: insetWidth - 90, height: 30
    )
    preferredUnitsPicker.frame = CGRect(
      x: frame.width - 95, y: seasonImageView.frame.maxY + padding(.element),
      width: 80, height: 40
    )
    logEventsLabel.frame = CGRect(
      x: xOrigin, y: unitsLabel.frame.maxY + padding(.element),
      width: insetWidth, height: 25
    )
    preferredTemperatureFeelLabel.frame = CGRect(
      x: xOrigin, y: logEventsLabel.frame.maxY + padding(.pair),
      width: insetWidth - 75, height: 30
    )
    preferredTemperatureFeelPicker.frame = CGRect(
      x: frame.width - 115, y: logEventsLabel.frame.maxY + padding(.pair),
      width: 100, height: 40
    )
    preferredConditionsPickerLabel.frame = CGRect(
      x: xOrigin, y: preferredTemperatureFeelPicker.frame.maxY + padding(.pair),
      width: insetWidth - 75, height: 30
    )
    preferredConditionsPicker.frame = CGRect(
      x: frame.width - 115, y: preferredConditionsPickerLabel.frame.minY,
      width: 100, height: 40
    )
    preferredTemperatureLabel.frame = CGRect(
      x: xOrigin, y: preferredConditionsPickerLabel.frame.maxY + 10, width: insetWidth - 75,
      height: 30
    )
    sliderTemperatureLabel.frame = CGRect(
      x: frame.width - 65, y: preferredConditionsPickerLabel.frame.maxY + 10, width: 50, height: 30
    )
    temperatureSlider.frame = CGRect(
      origin: CGPoint(x: xOrigin, y: preferredTemperatureLabel.frame.maxY + padding(.section)),
      size: CGSize(width: insetWidth, height: 20)
    )

    var maxY: CGFloat = temperatureSlider.frame.maxY
    postButton.frame = CGRect(
      x: 15, y: temperatureSlider.frame.maxY + padding(.section),
      width: insetWidth, height: 45
    )
    maxY = postButton.frame.maxY

    // MARK: - Content Size

    /// Sets the appropriate `contentSize` of self (a `UIScrollview`) so the entire
    /// content can scroll to fit on smaller screens.
    contentSize = CGSize(width: frame.width, height: maxY + 20)
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
