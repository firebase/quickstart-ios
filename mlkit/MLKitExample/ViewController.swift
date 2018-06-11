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
// [START import_vision]
import Firebase
// [END import_vision]

/// Main view controller class.
class ViewController:  UIViewController, UINavigationControllerDelegate {
  /// Firebase vision instance.
  // [START init_vision]
  lazy var vision = Vision.vision()
  // [END init_vision]

  // Create a text detector.
  // [START init_text]
  lazy var textDetector = vision.textDetector()
  // [END init_text]

  /// A string holding current results from detection.
  var resultsText = ""

  /// Indicates whether the download cloud model button was selected.
  var downloadCloudModelButtonSelected = false

  /// An overlay view that displays detection annotations.
  private lazy var annotationOverlayView: UIView = {
    precondition(isViewLoaded)
    let annotationOverlayView = UIView(frame: .zero)
    annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
    return annotationOverlayView
  }()

  /// An image picker for accessing the photo library or camera.
  var imagePicker = UIImagePickerController()

  // MARK: - IBOutlets

  @IBOutlet fileprivate weak var detectorPicker: UIPickerView!
  @IBOutlet fileprivate weak var imageView: UIImageView!
  @IBOutlet fileprivate weak var photoCameraButton: UIBarButtonItem!
  @IBOutlet fileprivate weak var videoCameraButton: UIBarButtonItem!

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    imageView.image = UIImage(named: Constants.graceHopperImage)
    imageView.addSubview(annotationOverlayView)
    NSLayoutConstraint.activate([
      annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
      annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
      annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
      annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
      ])

    imagePicker.delegate = self
    imagePicker.sourceType = .photoLibrary

    detectorPicker.delegate = self
    detectorPicker.dataSource = self

    if !UIImagePickerController.isCameraDeviceAvailable(.front) &&
      !UIImagePickerController.isCameraDeviceAvailable(.rear) {
      photoCameraButton.isEnabled = false
      videoCameraButton.isEnabled = false
    }

    let defaultRow = (DetectorPickerRow.rowsCount / 2) - 1
    detectorPicker.selectRow(defaultRow, inComponent: 0, animated: false)

    // Loads the local model using the `ModelInterpreter`. This check verifies that VisionDetection
    // and ModelInterpreter API calls work properly in the same app.
    loadLocalModel()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.navigationBar.isHidden = true
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    navigationController?.navigationBar.isHidden = false
  }

  // MARK: - IBActions

  @IBAction func detect(_ sender: Any) {
    clearResults()
    let row = detectorPicker.selectedRow(inComponent: 0)
    if let rowIndex = DetectorPickerRow(rawValue: row) {
      switch rowIndex {
      case .detectFaceOnDevice:
        detectFaces(image: imageView.image)
      case .detectTextOnDevice:
        detectTexts(image: imageView.image)
      case .detectBarcodeOnDevice:
        detectBarcodes(image: imageView.image)
      case .detectvImageLabelsOnDevice:
        detectLabels(image: imageView.image)
      case .detectTextInCloud:
        detectCloudTexts(image: imageView.image)
      case .detectDocumentTextInCloud:
        detectCloudDocumentTexts(image: imageView.image)
      case .detectImageLabelsInCloud:
        detectCloudLabels(image: imageView.image)
      case .detectLandmarkInCloud:
        detectCloudLandmarks(image: imageView.image)
      }
    } else {
      print("No such item at row \(row) in detector picker.")
    }
  }

  @IBAction func openPhotoLibrary(_ sender: Any) {
    imagePicker.sourceType = .photoLibrary
    present(imagePicker, animated: true)
  }

  @IBAction func openCamera(_ sender: Any) {
    guard UIImagePickerController.isCameraDeviceAvailable(.front) ||
      UIImagePickerController.isCameraDeviceAvailable(.rear)
      else {
        return
    }
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true)
  }

  // MARK: - Private

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

  /// Removes the detection annotations from the annotation overlay view.
  private func removeDetectionAnnotations() {
    for annotationView in annotationOverlayView.subviews {
      annotationView.removeFromSuperview()
    }
  }

  /// Clears the results text view and removes any frames that are visible.
  private func clearResults() {
    removeDetectionAnnotations()
  }

  private func showResults() {
    let resultsAlertController = UIAlertController(
      title: "Detection Results",
      message: nil,
      preferredStyle: .actionSheet
    )
    resultsAlertController.addAction(
      UIAlertAction(title: "OK", style: .destructive) { _ in
        resultsAlertController.dismiss(animated: true, completion: nil)
      }
    )
    resultsAlertController.message = resultsText
    present(resultsAlertController, animated: true, completion: nil)
    print(resultsText)
  }

  /// Updates the image view with a scaled version of the given image.
  private func updateImageView(with image: UIImage) {
    let orientation = UIApplication.shared.statusBarOrientation
    var scaledImageWidth: CGFloat = 0.0
    var scaledImageHeight: CGFloat = 0.0
    switch orientation {
    case .portrait, .portraitUpsideDown, .unknown:
      scaledImageWidth = imageView.bounds.size.width
      scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
    case .landscapeLeft, .landscapeRight:
      scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
      scaledImageHeight = imageView.bounds.size.height
    }
    DispatchQueue.global(qos: .userInitiated).async {
      // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
      var scaledImage = image.scaledImage(
        withSize: CGSize(width: scaledImageWidth, height: scaledImageHeight)
      )
      scaledImage = scaledImage ?? image
      guard let finalImage = scaledImage else { return }
      DispatchQueue.main.async {
        self.imageView.image = finalImage
      }
    }
  }

  /// Loads the local model using the `ModelInterpreter`.
  private func loadLocalModel() {
    guard let localModelFilePath = Bundle.main.path(
      forResource: Constants.quantizedModelFilename,
      ofType: Constants.modelExtension
      )
      else {
        resultsText = "Failed to get the path to the local model file."
        showResults()
        return
    }
    let localModelSource = LocalModelSource(
      modelName: Constants.localModelName,
      path: localModelFilePath
    )
    let modelManager = ModelManager.modelManager()
    if !modelManager.register(localModelSource) {
      print("Model source was already registered with name: \(localModelSource.modelName).")
    }
    let options = ModelOptions(cloudModelName: nil, localModelName: Constants.localModelName)
    _ = ModelInterpreter(options: options)
  }

  private func transformMatrix() -> CGAffineTransform {
    guard let image = imageView.image else { return CGAffineTransform() }
    let imageViewWidth = imageView.frame.size.width
    let imageViewHeight = imageView.frame.size.height
    let imageWidth = image.size.width
    let imageHeight = image.size.height

    let imageViewAspectRatio = imageViewWidth / imageViewHeight
    let imageAspectRatio = imageWidth / imageHeight
    let scale = (imageViewAspectRatio > imageAspectRatio) ?
      imageViewHeight / imageHeight :
      imageViewWidth / imageWidth

    // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
    // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
    let scaledImageWidth = imageWidth * scale
    let scaledImageHeight = imageHeight * scale
    let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
    let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

    var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
    transform = transform.scaledBy(x: scale, y: scale)
    return transform
  }

  private func landmarkPointFrom(_ visionPoint: VisionPoint) -> CGPoint {
    return CGPoint(x: CGFloat(visionPoint.x.floatValue), y: CGFloat(visionPoint.y.floatValue))
  }

  private func addLandmarks(forFace face: VisionFace, transform: CGAffineTransform) {
    // Mouth
    if let bottomMouthLandmark = face.landmark(ofType: .mouthBottom) {
      let landmarkPoint = landmarkPointFrom(bottomMouthLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.red,
        radius: Constants.smallDotRadius
      )
    }
    if let leftMouthLandmark = face.landmark(ofType: .mouthLeft) {
      let landmarkPoint = landmarkPointFrom(leftMouthLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.red,
        radius: Constants.smallDotRadius
      )
    }
    if let rightMouthLandmark = face.landmark(ofType: .mouthRight) {
      let landmarkPoint = landmarkPointFrom(rightMouthLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.red,
        radius: Constants.smallDotRadius
      )
    }

    // Nose
    if let noseBaseLandmark = face.landmark(ofType: .noseBase) {
      let landmarkPoint = landmarkPointFrom(noseBaseLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.yellow,
        radius: Constants.smallDotRadius
      )
    }

    // Eyes
    if let leftEyeLandmark = face.landmark(ofType: .leftEye) {
      let landmarkPoint = landmarkPointFrom(leftEyeLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.cyan,
        radius: Constants.largeDotRadius
      )
    }
    if let rightEyeLandmark = face.landmark(ofType: .rightEye) {
      let landmarkPoint = landmarkPointFrom(rightEyeLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.cyan,
        radius: Constants.largeDotRadius
      )
    }

    // Ears
    if let leftEarLandmark = face.landmark(ofType: .leftEar) {
      let landmarkPoint = landmarkPointFrom(leftEarLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.purple,
        radius: Constants.largeDotRadius
      )
    }
    if let rightEarLandmark = face.landmark(ofType: .rightEar) {
      let landmarkPoint = landmarkPointFrom(rightEarLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.purple,
        radius: Constants.largeDotRadius
      )
    }

    // Cheeks
    if let leftCheekLandmark = face.landmark(ofType: .leftCheek) {
      let landmarkPoint = landmarkPointFrom(leftCheekLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.orange,
        radius: Constants.largeDotRadius
      )
    }
    if let rightCheekLandmark = face.landmark(ofType: .rightCheek) {
      let landmarkPoint = landmarkPointFrom(rightCheekLandmark.position)
      let transformedPoint = landmarkPoint.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.orange,
        radius: Constants.largeDotRadius
      )
    }
  }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {

  // MARK: - UIPickerViewDataSource

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return DetectorPickerRow.componentsCount
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return DetectorPickerRow.rowsCount
  }

  // MARK: - UIPickerViewDelegate

  func pickerView(
    _ pickerView: UIPickerView,
    titleForRow row: Int,
    forComponent component: Int
    ) -> String? {
    return DetectorPickerRow(rawValue: row)?.description
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    clearResults()
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

/// Extension of ViewController for On-Device and Cloud detection.
extension ViewController {

  // MARK: - Vision On-Device Detection

  /// Detects faces on the specified image and draws a frame around the detected faces using
  /// On-Device face API.
  ///
  /// - Parameter image: The image.
  func detectFaces(image: UIImage?) {
    guard let image = image else { return }

    // Create a face detector with options.
    // [START config_face]
    let options = VisionFaceDetectorOptions()
    options.landmarkType = .all
    options.classificationType = .all
    options.modeType = .accurate
    // [END config_face]

    // [START init_face]
    let faceDetector = vision.faceDetector(options: options)
    // [END init_face]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_faces]
    faceDetector.detect(in: visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device face detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Faces detected
      // [START_EXCLUDE]
      self.resultsText = features.map { feature -> String in
        let transform = self.transformMatrix()
        let transformedRect = feature.frame.applying(transform)
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        self.addLandmarks(forFace: feature, transform: transform)
        return "Frame: \(feature.frame)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_faces]
  }

  /// Detects barcodes on the specified image and draws a frame around the detected barcodes using
  /// On-Device barcode API.
  ///
  /// - Parameter image: The image.
  func detectBarcodes(image: UIImage?) {
    guard let image = image else { return }

    // Define the options for a barcode detector.
    // [START config_barcode]
    let format = VisionBarcodeFormat.all
    let barcodeOptions = VisionBarcodeDetectorOptions(formats: format)
    // [END config_barcode]

    // Create a barcode detector.
    // [START init_barcode]
    let barcodeDetector = vision.barcodeDetector(options: barcodeOptions)
    // [END init_barcode]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_barcodes]
    barcodeDetector.detect(in: visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device barcode detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // [START_EXCLUDE]
      self.resultsText = features.map { feature in
        let transformedRect = feature.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        return "DisplayValue: \(feature.displayValue ?? ""), RawValue: " +
        "\(feature.rawValue ?? ""), Frame: \(feature.frame)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE
    }
    // [END detect_barcodes]
  }

  /// Detects labels on the specified image using On-Device label API.
  ///
  /// - Parameter image: The image.
  func detectLabels(image: UIImage?) {
    guard let image = image else { return }

    // [START config_label]
    let options = VisionLabelDetectorOptions(
      confidenceThreshold: Constants.labelConfidenceThreshold
    )
    // [END config_label]

    // [START init_label]
    let labelDetector = vision.labelDetector(options: options)
    // [END init_label]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_label]
    labelDetector.detect(in: visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device label detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // [START_EXCLUDE]
      self.resultsText = features.map { feature -> String in
        let transformedRect = feature.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        return "Label: \(String(describing: feature.label)), " +
          "Confidence: \(feature.confidence), " +
          "EntityID: \(String(describing: feature.entityID)), " +
          "Frame: \(feature.frame)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_label]
  }

  /// Detects texts on the specified image and draws a frame around the detect texts using On-Device
  /// text API.
  ///
  /// - Parameter image: The image.
  func detectTexts(image: UIImage?) {
    guard let image = image else { return }

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_text]
    textDetector.detect(in: visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device text detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // [START_EXCLUDE]
      self.resultsText = features.map { feature in
        let transformedRect = feature.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        return "Text: \(feature.text)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_text]
  }

  // MARK: - Vision Cloud Detection

  /// Detects texts on the specified image and draws a frame around the detected texts using cloud
  /// text API.
  ///
  /// - Parameter image: The image.
  func detectCloudTexts(image: UIImage?) {
    guard let image = image else { return }

    // [START config_text_cloud]
    let options = VisionCloudDetectorOptions()
    options.modelType = .latest
    // options.maxResults has no effect with this API
    // [END config_text_cloud]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START init_text_cloud]
    let cloudDetector = vision.cloudTextDetector(options: options)
    // Or, to use the default settings:
    // let textDetector = vision?.cloudTextDetector()
    // [END init_text_cloud]

    // [START detect_text_cloud]
    cloudDetector.detect(in: visionImage) { texts, error in
      guard error == nil, let texts = texts else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Cloud text detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Recognized and extracted text
      // [START_EXCLUDE]
      self.resultsText = texts.text ?? ""
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_text_cloud]
  }

  /// Detects document texts on the specified image and draws a frame around the detected texts
  /// using cloud document text API.
  ///
  /// - Parameter image: The image.
  func detectCloudDocumentTexts(image: UIImage?) {
    guard let image = image else { return }

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START init_document_text_cloud]
    let cloudDetector = vision.cloudDocumentTextDetector()
    // [END init_document_text_cloud]

    // [START detect_document_text_cloud]
    cloudDetector.detect(in: visionImage) { texts, error in
      guard error == nil, let texts = texts else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Cloud document text detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Recognized and extracted document text
      // [START_EXCLUDE]
      self.resultsText = texts.text ?? ""
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_document_text_cloud]
  }

  /// Detects landmarks on the specified image and draws a frame around the detected landmarks using
  /// cloud landmark API.
  ///
  /// - Parameter image: The image.
  func detectCloudLandmarks(image: UIImage?) {
    guard let image = image else { return }

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // Create a landmark detector.
    // [START config_landmark_cloud]
    let options = VisionCloudDetectorOptions()
    options.modelType = .latest
    options.maxResults = 20
    // [END config_landmark_cloud]

    // [START init_landmark_cloud]
    let cloudDetector = vision.cloudLandmarkDetector(options: options)
    // Or, to use the default settings:
    // let cloudDetector = vision.cloudLandmarkDetector()
    // [END init_landmark_cloud]

    // [START detect_landmarks_cloud]
    cloudDetector.detect(in: visionImage) { landmarks, error in
      guard error == nil, let landmarks = landmarks, !landmarks.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Cloud landmark detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Recognized landmarks
      // [START_EXCLUDE]
      self.resultsText = landmarks.map { landmark -> String in
        let transformedRect = landmark.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        return "Landmark: \(String(describing: landmark.landmark ?? "")), " +
          "Confidence: \(String(describing: landmark.confidence ?? 0) ), " +
          "EntityID: \(String(describing: landmark.entityId ?? "") ), " +
        "Frame: \(landmark.frame)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_landmarks_cloud]
  }

  /// Detects labels on the specified image using cloud label API.
  ///
  /// - Parameter image: The image.
  func detectCloudLabels(image: UIImage?) {
    guard let image = image else { return }

    // [START init_label_cloud]
    let labelDetector = vision.cloudLabelDetector()
    // Or, to change the default settings:
    // let labelDetector = Vision.vision().cloudLabelDetector(options: options)
    // [END init_label_cloud]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_label_cloud]
    labelDetector.detect(in: visionImage) { labels, error in
      guard error == nil, let labels = labels, !labels.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Cloud label detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Labeled image
      // START_EXCLUDE
      self.resultsText = labels.map { label -> String in
        "Label: \(String(describing: label.label ?? "")), " +
          "Confidence: \(label.confidence ?? 0), " +
        "EntityID: \(label.entityId ?? "")"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
  }
  // [END detect_label_cloud]
}

// MARK: - Enums

private enum DetectorPickerRow: Int {
  case detectFaceOnDevice = 0,
  detectTextOnDevice,
  detectBarcodeOnDevice,
  detectvImageLabelsOnDevice,
  detectTextInCloud,
  detectDocumentTextInCloud,
  detectImageLabelsInCloud,
  detectLandmarkInCloud

  static let rowsCount = 8
  static let componentsCount = 1

  public var description: String {
    switch self {
    case .detectFaceOnDevice:
      return "Face On-Device"
    case .detectTextOnDevice:
      return "Text On-Device"
    case .detectBarcodeOnDevice:
      return "Barcode On-Device"
    case .detectvImageLabelsOnDevice:
      return "Image Labeling On-Device"
    case .detectTextInCloud:
      return "Text in Cloud"
    case .detectDocumentTextInCloud:
      return "Document Text in Cloud"
    case .detectImageLabelsInCloud:
      return "Image Labeling in Cloud"
    case .detectLandmarkInCloud:
      return "Landmarks in Cloud"
    }
  }
}

private enum Constants {
  static let graceHopperImage = "grace_hopper.jpg"
  static let modelExtension = "tflite"
  static let localModelName = "mobilenet"
  static let quantizedModelFilename = "mobilenet_quant_v1_224"

  static let detectionNoResultsMessage = "No results returned."
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."

  static let labelConfidenceThreshold: Float = 0.75
  static let lineWidth: CGFloat = 3.0
  static let smallDotRadius: CGFloat = 5.0
  static let largeDotRadius: CGFloat = 10.0
  static let lineColor = UIColor.yellow.cgColor
  static let fillColor = UIColor.clear.cgColor
}
