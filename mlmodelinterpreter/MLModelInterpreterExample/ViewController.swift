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

  // MARK: - IBOutlets

  /// A segmented control for changing models (0 = `cloudModelName1`, 1 = `cloudModelName2`).
  @IBOutlet private var modelControl: UISegmentedControl!

  @IBOutlet private var imageView: UIImageView!
  @IBOutlet private var resultsTextView: UITextView!
  @IBOutlet private var detectButton: UIBarButtonItem!
  @IBOutlet private var cameraButton: UIBarButtonItem!
  @IBOutlet private var downloadModelButton: UIBarButtonItem!

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    imageView.image = UIImage(named: Constants.defaultImage)
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
      if !modelManager.loadLocalModel() {
        resultsTextView.text = "Failed to load the local model."
        return
      }
    }
    var newResultsTextString = "Starting inference...\n"
    if let currentText = resultsTextView.text {
       newResultsTextString = currentText + newResultsTextString
    }
    resultsTextView.text = newResultsTextString
    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = self.modelManager.scaledImageData(from: image)
      self.modelManager.detectObjects(in: imageData) { (results, error) in
        guard error == nil, let results = results, !results.isEmpty else {
          var errorString = error?.localizedDescription ?? Constants.failedToDetectObjectsMessage
          errorString = "Inference error: \(errorString)"
          print(errorString)
          self.resultsTextView.text = errorString
          return
        }

        var inferenceMessageString: String
        if self.downloadCloudModelButtonSelected {
          UserDefaults.standard.set(true, forKey: self.currentCloudModelKey())
          inferenceMessageString = "Inference results using `\(self.currentCloudModelName())` " +
            "cloud model:\n"
        } else {
          inferenceMessageString = "Inference results using the local model:\n"
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
    let isCloudModelDownloaded = UserDefaults.standard.bool(forKey: self.currentCloudModelKey())
    resultsTextView.text = isCloudModelDownloaded ?
      "Cloud model loaded. Select the `Detect` button to start the inference." :
      "Downloading cloud model. Once the download has completed, select the `Detect` button to " +
      "start the inference."
    if !modelManager.loadCloudModel() {
      resultsTextView.text = "Failed to load the cloud model."
    }
  }

  @IBAction func modelSwitched(_ sender: Any) {
    clearResults()
    setUpCloudModel()
  }

  // MARK: - Private

  /// Returns the name for the currently selected cloud model.
  private func currentCloudModelName() -> String {
    return (modelControl.selectedSegmentIndex == 0) ?
      Constants.cloudModelName1 :
      Constants.cloudModelName2
  }

  /// Returns the key for the currently selected cloud model.
  private func currentCloudModelKey() -> String {
    return (modelControl.selectedSegmentIndex == 0) ?
      Constants.cloudModel1DownloadCompletedKey :
      Constants.cloudModel2DownloadCompletedKey
  }

  /// Sets up the currently selected cloud model.
  private func setUpCloudModel() {
    let name = currentCloudModelName()
    if !modelManager.setUpCloudModel(withName: name) {
      resultsTextView.text = "\(resultsTextView.text ?? "")\nFailed to set up the `\(name)` " +
        "cloud model."
    }
  }

  /// Sets up the local model.
  private func setUpLocalModel() {
    if !modelManager.setUpLocalModel(withName: Constants.localModelName) {
      resultsTextView.text = "\(resultsTextView.text ?? "")\nFailed to set up the local model."
    }
  }

  /// Returns a string representation of the detection results.
  private func detectionResultsString(
    fromResults results: [(label: String, confidence: Float)]?
  ) -> String {
    guard let results = results else { return Constants.failedToDetectObjectsMessage }
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

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String: Any]
  ) {
    clearResults()
    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      updateImageView(with: pickedImage)
    }
    dismiss(animated: true)
  }
}

// MARK: - Constants

private enum Constants {

  // REPLACE THESE CLOUD MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
  static let cloudModelName1 = "image_classification"
  static let cloudModelName2 = "invalid_model"

  static let localModelName = "mobilenet"

  static let defaultImage = "grace_hopper.jpg"
  static let cloudModel1DownloadCompletedKey = "FIRCloudModel1DownloadCompleted"
  static let cloudModel2DownloadCompletedKey = "FIRCloudModel2DownloadCompleted"
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."
}
