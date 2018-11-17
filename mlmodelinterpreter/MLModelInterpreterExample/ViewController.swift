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

@objc(ViewController)
class ViewController: UIViewController, UINavigationControllerDelegate {

  // MARK: - Properties

  /// Model interpreter manager that manages loading models and detecting objects.
  private lazy var modelManager = ModelInterpreterManager()

  /// Indicates whether the download cloud model button was selected.
  private var downloadCloudModelButtonSelected = false

  /// An image picker for accessing the photo library or camera.
  private var imagePicker = UIImagePickerController()

  /// The currently selected cloud model.
  private var currentCloudModel: CloudModel {
    precondition(Thread.isMainThread)
    guard let currentCloudModel = CloudModel(rawValue: modelControl.selectedSegmentIndex) else {
      preconditionFailure("Invalid cloud model for selected segment index.")
    }
    return currentCloudModel
  }

  /// The currently selected local model.
  private var currentLocalModel: LocalModel {
    precondition(Thread.isMainThread)
    guard let currentLocalModel = LocalModel(rawValue: modelControl.selectedSegmentIndex) else {
      preconditionFailure("Invalid local model for selected segment index.")
    }
    return currentLocalModel
  }

  private var isModelQuantized: Bool {
    return isCloudModelDownloaded ?
      currentCloudModel == .quantized :
      currentLocalModel == .quantized
  }

  private var isCloudModelDownloaded: Bool {
    return UserDefaults.standard.bool(forKey: currentCloudModel.downloadCompletedKey)
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

    setUpCloudModel()
    setUpLocalModel()
  }

  // MARK: - IBActions

  @IBAction func detectObjects(_ sender: Any) {
    clearResults()
    guard let image = imageView.image else {
      resultsTextView.text = "Image must not be nil.\n"
      return
    }

    if !downloadCloudModelButtonSelected {
      resultsTextView.text = "Loading the local model...\n"
      if !modelManager.loadLocalModel(isModelQuantized: (currentLocalModel == .quantized)) {
        resultsTextView.text = "Failed to load the local model."
        return
      }
    }
    var newResultsTextString = "Starting inference...\n"
    if let currentText = resultsTextView.text {
       newResultsTextString = currentText + newResultsTextString
    }
    resultsTextView.text = newResultsTextString
    let cloudModel = currentCloudModel
    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = self.modelManager.scaledImageData(from: image)
      self.modelManager.detectObjects(in: imageData) { (results, error) in
        guard error == nil, let results = results, !results.isEmpty else {
          var errorString = error?.localizedDescription ?? Constant.failedToDetectObjectsMessage
          errorString = "Inference error: \(errorString)"
          print(errorString)
          self.resultsTextView.text = errorString
          return
        }

        var inferenceMessageString = "Inference results using "
        if self.downloadCloudModelButtonSelected {
          UserDefaults.standard.set(true, forKey: cloudModel.downloadCompletedKey)
          inferenceMessageString += "`\(cloudModel.description)` cloud model:\n"
        } else {
          inferenceMessageString += "`\(self.currentLocalModel.description)` local model:\n"
        }
        self.resultsTextView.text =
          inferenceMessageString + "\(self.detectionResultsString(fromResults: results))"
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
    clearResults()
    downloadCloudModelButtonSelected = true
    resultsTextView.text = isCloudModelDownloaded ?
      "Cloud model loaded. Select the `Detect` button to start the inference." :
      "Downloading cloud model. Once the download has completed, select the `Detect` button to " +
      "start the inference."
    if !modelManager.loadCloudModel(isModelQuantized: (currentCloudModel == .quantized)) {
      resultsTextView.text = "Failed to load the cloud model."
    }
  }

  @IBAction func modelSwitched(_ sender: Any) {
    clearResults()
    setUpLocalModel()
    setUpCloudModel()
  }

  // MARK: - Private

  /// Sets up the currently selected cloud model.
  private func setUpCloudModel() {
    let modelName = currentCloudModel.description
    if !modelManager.setUpCloudModel(name: modelName) {
      resultsTextView.text = "\(resultsTextView.text ?? "")\nFailed to set up the `\(modelName)` " +
        "cloud model."
    }
  }

  /// Sets up the local model.
  private func setUpLocalModel() {
    let localModelName = currentLocalModel.description
    if !modelManager.setUpLocalModel(name: localModelName, filename: localModelName) {
      resultsTextView.text = "\(resultsTextView.text ?? "")\nFailed to set up the local model."
    }
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

  /// Clears the results from the last inference call.
  private func clearResults() {
    resultsTextView.text = nil
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
    clearResults()
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

private enum CloudModel: Int, CustomStringConvertible {
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

private enum LocalModel: Int, CustomStringConvertible {
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
