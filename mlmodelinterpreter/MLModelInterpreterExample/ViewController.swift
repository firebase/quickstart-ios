//
//  Copyright (c) 2018 Google Inc.
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
import FirebaseMLCommon

@objc(ViewController)
class ViewController: UIViewController, UINavigationControllerDelegate {

  // MARK: - Properties

  /// A map of `ModelInterpreterManager` instances where the key is cloud+local model name string.
  private lazy var modelInterpreterManagerMap = [String: ModelInterpreterManager]()

  /// The `ModelInterpreterManager` for the current cloud and local models.
  private lazy var manager = ModelInterpreterManager()

  /// Indicates whether the download cloud model button was selected.
  private var downloadCloudModelButtonSelected = false

  /// An image picker for accessing the photo library or camera.
  private var imagePicker = UIImagePickerController()

  /// The currently selected cloud model type.
  private var currentCloudModelType: CloudModelType {
    precondition(Thread.isMainThread)
    guard let currentCloudModel = CloudModelType(rawValue: modelControl.selectedSegmentIndex) else {
      preconditionFailure("Invalid cloud model type for selected segment index.")
    }
    return currentCloudModel
  }

  /// The currently selected local model type.
  private var currentLocalModelType: LocalModelType {
    precondition(Thread.isMainThread)
    guard let currentLocalModel = LocalModelType(rawValue: modelControl.selectedSegmentIndex) else {
      preconditionFailure("Invalid local model type for selected segment index.")
    }
    return currentLocalModel
  }

  private var isModelQuantized: Bool {
    return isCloudModelDownloaded ?
      currentCloudModelType == .quantized :
      currentLocalModelType == .quantized
  }

  private var isCloudModelDownloaded: Bool {
    return UserDefaults.standard.bool(forKey: currentCloudModelType.downloadCompletedKey)
  }

  // MARK: - IBOutlets

  /// A segmented control for changing models (0 = float, 1 = quantized, 2 = invalid).
  @IBOutlet private var modelControl: UISegmentedControl!

  @IBOutlet private var imageView: UIImageView!
  @IBOutlet private var resultsTextView: UITextView!
  @IBOutlet private var detectButton: UIBarButtonItem!
  @IBOutlet private var cameraButton: UIBarButtonItem!
  @IBOutlet private var downloadModelButton: UIBarButtonItem!

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    imageView.image = UIImage(named: Constant.defaultImage)
    imagePicker.delegate = self
    if !UIImagePickerController.isCameraDeviceAvailable(.front) ||
      !UIImagePickerController.isCameraDeviceAvailable(.rear) {
      cameraButton.isEnabled = false
    }
    updateModelInterpreterManager()
    setUpCloudModel()
    setUpLocalModel()
  }

  // MARK: - IBActions

  @IBAction func detectObjects(_ sender: Any) {
    updateResultsText()
    guard let image = imageView.image else {
      updateResultsText("Image must not be nil.\n")
      return
    }

    if !downloadCloudModelButtonSelected {
      updateResultsText("Loading the local model...\n")
      if !manager.loadLocalModel(isModelQuantized: (currentLocalModelType == .quantized)) {
        updateResultsText("Failed to load the local model.")
        return
      }
    }
    var newResultsTextString = "Starting inference...\n"
    if let currentText = resultsTextView.text {
      newResultsTextString = currentText + newResultsTextString
    }
    updateResultsText(newResultsTextString)
    let cloudModelType = currentCloudModelType
    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = self.manager.scaledImageData(from: image)
      self.manager.detectObjects(in: imageData) { (results, error) in
        guard error == nil, let results = results, !results.isEmpty else {
          var errorString = error?.localizedDescription ?? Constant.failedToDetectObjectsMessage
          errorString = "Inference error: \(errorString)"
          print(errorString)
          self.updateResultsText(errorString)
          return
        }

        var inferenceMessageString = "Inference results using "
        if self.downloadCloudModelButtonSelected {
          UserDefaults.standard.set(true, forKey: cloudModelType.downloadCompletedKey)
          inferenceMessageString += "`\(cloudModelType.description)` cloud model:\n"
        } else {
          inferenceMessageString += "`\(self.currentLocalModelType.description)` local model:\n"
        }
        self.updateResultsText(inferenceMessageString +
          "\(self.detectionResultsString(fromResults: results))")
      }
    }
  }

  @IBAction func openPhotoLibrary(_ sender: Any) {
    imagePicker.sourceType = .photoLibrary
    present(imagePicker, animated: true)
  }

  @IBAction func openCamera(_ sender: Any) {
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true)
  }

  @IBAction func downloadCloudModel(_ sender: Any) {
    updateResultsText()
    downloadCloudModelButtonSelected = true
    updateResultsText(isCloudModelDownloaded ?
      "Cloud model loaded. Select the `Detect` button to start the inference." :
      "Downloading cloud model...This text view will notify you when the downloaded model is " +
      "ready to be used."
    )
    if !manager.loadCloudModel(isModelQuantized: (currentCloudModelType == .quantized)) {
      updateResultsText("Failed to load the cloud model.")
    }
  }

  @IBAction func modelSwitched(_ sender: Any) {
    updateResultsText()
    updateModelInterpreterManager()
    setUpLocalModel()
    setUpCloudModel()
  }

  // MARK: - Private

  /// Updates the `ModelInterpreterManager` instance based on the current cloud and local models.
  private func updateModelInterpreterManager() {
    precondition(Thread.isMainThread)
    let key = currentCloudModelType.description + "\(currentCloudModelType.rawValue)" +
      currentLocalModelType.description + "\(currentLocalModelType.rawValue)"
    manager = modelInterpreterManagerMap[key] ?? ModelInterpreterManager()
    modelInterpreterManagerMap[key] = manager
  }

  /// Sets up the currently selected cloud model.
  private func setUpCloudModel() {
    let modelName = currentCloudModelType.description
    if !manager.setUpCloudModel(name: modelName) {
      updateResultsText("\(resultsTextView.text ?? "")\nFailed to set up the `\(modelName)` " +
        "cloud model.")
    }
  }

  /// Sets up the local model.
  private func setUpLocalModel() {
    let modelName = currentLocalModelType.description
    if !manager.setUpLocalModel(name: modelName, filename: modelName) {
      updateResultsText("\(resultsTextView.text ?? "")\nFailed to set up the local model.")
    }
  }

  /// Updates the `downloadCompletedKey` in the User Defaults to true for the given cloud model.
  private func updateUserDefaults(for cloudModel: CloudModelSource) {
    let type = CloudModelType.allCases.first { $0.description == cloudModel.name }
    guard let key = type?.downloadCompletedKey else { return }
    UserDefaults.standard.set(true, forKey: key)
  }

  /// Returns a string representation of the detection results.
  private func detectionResultsString(
    fromResults results: [(label: String, confidence: Float)]?
    ) -> String {
    guard let results = results else { return Constant.failedToDetectObjectsMessage }
    return results.reduce("") { (resultString, result) -> String in
      let (label, confidence) = result
      return resultString + "\(label): \(String(describing: confidence))\n"
    }
  }

  /// Updates the results text view with the given text. The default is `nil`, so calling
  /// `updateResultsText()` will clear the results.
  private func updateResultsText(_ text: String? = nil) {
    let updater = { self.resultsTextView.text = text }
    if Thread.isMainThread { updater(); return }
    DispatchQueue.main.async { updater() }
  }

  /// Updates the image view with a scaled version of the given image.
  private func updateImageView(with image: UIImage) {
    let orientation = UIApplication.shared.statusBarOrientation
    let imageWidth = image.size.width
    let imageHeight = image.size.height
    guard imageWidth > .ulpOfOne, imageHeight > .ulpOfOne else {
      self.imageView.image = image
      print("Failed to update image view because image has invalid size: \(image.size)")
      return
    }

    var scaledImageWidth: CGFloat = 0.0
    var scaledImageHeight: CGFloat = 0.0
    switch orientation {
    case .portrait, .portraitUpsideDown, .unknown:
      scaledImageWidth = imageView.bounds.size.width
      scaledImageHeight = imageHeight * scaledImageWidth / imageWidth
    case .landscapeLeft, .landscapeRight:
      scaledImageWidth = imageWidth * scaledImageHeight / imageHeight
      scaledImageHeight = imageView.bounds.size.height
    }
    DispatchQueue.global(qos: .userInitiated).async {
      // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
      let scaledImage = image.scaledImage(
        with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
      )
      DispatchQueue.main.async {
        self.imageView.image = scaledImage ?? image
      }
    }
  }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    updateResultsText()
    if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      updateImageView(with: pickedImage)
    }
    dismiss(animated: true)
  }
}

// MARK: - Constants

private enum Constant {
  static let defaultImage = "grace_hopper.jpg"
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."
}

private enum CloudModelType: Int, CustomStringConvertible {
  case quantized = 0
  case float = 1
  case invalid = 2

  var downloadCompletedKey: String {
    switch self {
    case .quantized:
      return "FIRCloudModel1DownloadCompleted"
    case .float:
      return "FIRCloudModel2DownloadCompleted"
    case .invalid:
      return "FIRCloudInvalidModel"
    }
  }

  // MARK: - CustomStringConvertible

  // REPLACE THESE CLOUD MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
  var description: String {
    switch self {
    case .quantized:
      return "image-classification-quant-v2"
    case .float:
      return "image-classification-float-v2"
    case .invalid:
      return "invalid_model"
    }
  }
}

private enum LocalModelType: Int, CustomStringConvertible {
  case quantized = 0
  case float = 1
  case invalid = 2

  // MARK: - CustomStringConvertible

  var description: String {
    switch self {
    case .quantized:
      return MobileNet.quantizedModelInfo.name
    case .float:
      return MobileNet.floatModelInfo.name
    case .invalid:
      return MobileNet.invalidModelInfo.name
    }
  }
}

// MARK: - Extensions

#if !swift(>=4.2)
extension UIImagePickerController {
public typealias InfoKey = String
}

extension UIImagePickerController.InfoKey {
public static let originalImage = UIImagePickerControllerOriginalImage
}
#endif  // !swift(>=4.2)

#if swift(>=4.2)
extension CloudModelType: CaseIterable {}
#else
extension CloudModelType {
static let allCases: [CloudModelType] = [.quantized, .float, .invalid]
}
#endif  // swift(>=4.2)
