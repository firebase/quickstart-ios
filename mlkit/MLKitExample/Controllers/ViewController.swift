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
import FirebaseMLVision
import FirebaseMLModelInterpreter

// swiftlint:disable colon opening_brace
/// Main view controller class.
class ViewController:
  UIViewController,
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  // swiftlint:enable colon opening_brace

  var detectorService = DetectorService()

  // A layer on the view for the face frames drawing
  var faceSublayer = CALayer()

  // An image picker to open the photo library or camera
  var imagePicker = UIImagePickerController()

  // Vision instance
  var vision = Vision()

  // Registered local model names
  var registeredLocalModelNames: Set<String> = Set<String>()

  // Registered cloud model names
  var registeredCloudModelNames: Set<String> = Set<String>()

  // MARK: - IBOutlets

  /// Index 0 = cloud model 1, Index 1 = cloud model 2.
  @IBOutlet private weak var modelPicker: UISegmentedControl!

  @IBOutlet private weak var imageView: UIImageView!
  @IBOutlet private weak var resultsTextView: UITextView!
  @IBOutlet private weak var openCameraButton: UIBarButtonItem!
  @IBOutlet private weak var takePictureButton: UIBarButtonItem!

  // MARK: - View controller lifecycle methods

  override func viewDidLoad() {
    vision = Vision.vision()
    imageView.image = getImage()
    imageView.layer.addSublayer(faceSublayer)

    imagePicker.delegate = self
    imagePicker.sourceType = .photoLibrary

    super.viewDidLoad()
  }

  // MARK: - Face detection methods

  /// Convertes a feature frame from the image scale
  /// to the scale of aspect fit image on the view and
  /// adds a frame view for it in scale of the view.
  ///
  /// - Parameters:
  ///   - featureFrame: The rect of the feature in scale of original image.
  ///   - imageSize: The size of original image.
  ///   - viewRect: The view frame rect on the screen.
  func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) {
    print("Found a face: \(featureFrame).")

    let viewSize = viewFrame.size

    // Find resolution for the view and image
    let rView = viewSize.width / viewSize.height
    let rImage = imageSize.width / imageSize.height

    // Define scale based on comparing resolutions
    var scale: CGFloat
    if rView > rImage {
      scale = viewSize.height / imageSize.height
    } else {
      scale = viewSize.width / imageSize.width
    }

    // Calculate scaled feature frame size
    let featureWidthScaled = featureFrame.size.width * scale
    let featureHeightScaled = featureFrame.size.height * scale

    // Calculate scaled feature frame top-left point
    let imageWidthScaled = imageSize.width * scale
    let imageHeightScaled = imageSize.height * scale

    let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
    let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2

    let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
    let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale

    // Define a rect for scaled feature frame
    let featureRectScaled = CGRect(x: featurePointXScaled,
                                   y: featurePointYScaled,
                                   width: featureWidthScaled,
                                   height: featureHeightScaled)

    drawFrame(featureRectScaled)
  }

  /// Detects landmarks on the specified image and draws a frame for them.
  func detectLandmarksCloud() {
    guard let image = imageView.image else { return }

    // Create a landmark detector.
    let landmarkDetectorOptions = VisionCloudDetectorOptions()
    landmarkDetectorOptions.modelType = .latest
    landmarkDetectorOptions.maxResults = 20

    let landmarkDetector = vision.cloudLandmarkDetector(options: landmarkDetectorOptions)

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = .topLeft

    // Initialize a VisionImage object with a UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    landmarkDetector.detect(in: visionImage) { (features, error) in
      guard error == nil, let features = features, !features.isEmpty else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Barcode detection failed with error: \(errorString)")
        self.resultsTextView.text = "Face Detection: \(errorString)"
        return
      }
//      features.forEach { feature in
//        self.addFrameView(
//          featureFrame: feature.,
//          imageSize: image.size,
//          viewFrame: self.imageView.frame
//        )
//      }
    }
  }

  /// Detects faces on the specified image and draws a frame for them.
  func detectFaces() {
    guard let image = imageView.image else { return }

    // Create a face detector.
    let faceDetectorOptions = VisionFaceDetectorOptions()
    faceDetectorOptions.landmarkType = .all
    let faceDetector = vision.faceDetector(options: faceDetectorOptions)

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = .topLeft

    // Initialize a VisionImage object with a UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    faceDetector.detect(in: visionImage) { (features, error) in
      guard error == nil, let features = features, !features.isEmpty else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Face detection failed with error: \(errorString)")
        self.resultsTextView.text = "Face Detection: \(errorString)"
        return
      }
      features.forEach { feature in
        self.addFrameView(
          featureFrame: feature.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasforTesting(face: feature)
      }
    }
  }

  private func logExtrasforTesting(face: VisionFace) {
    print(face.frame)
    print(face.headEulerAngleY)
    print(face.headEulerAngleZ)

    let landMarkTypes: [FaceLandmarkType] = [.mouthBottom, .mouthRight, .mouthLeft, .rightEye,
                                             .leftEye, .rightEar, .leftEar, .rightCheek,
                                             .leftCheek, .noseBase]

    for type in landMarkTypes {
      if let landmark = face.landmark(ofType: type) {
        let position = landmark.position
        print("Position for face landmark: \(type.rawValue) is: " +
          "x: \(position.x) y: \(position.y), z: \(position.z ?? 0)")
      } else {
        print("No landmark of type: \(type.rawValue) has been detected")
      }
    }

    print("face left eye open probability: \(face.leftEyeOpenProbability)")
    print("face right eye open probability: \(face.rightEyeOpenProbability)")
    print("face smiling probability: \(face.smilingProbability)")
    print("face tracking id: \(face.trackingID)")
  }

  /// Detects labels on the specified image and prints the results.
  func detectLabels() {
    guard let image = imageView.image else { return }

    let options = VisionLabelDetectorOptions(
      confidenceThreshold: Constants.labelConfidenceThreshold
    )
    let labelDetector = Vision.vision().labelDetector(options: options)

    // Initialize a VisionImage object with a UIImage.
    let visionImage = VisionImage(image: image)

    labelDetector.detect(in: visionImage) { (features: [VisionLabel]?, error: Error?) in
      guard error == nil, let features = features, !features.isEmpty else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Label detection failed with error: \(errorString)")
        self.resultsTextView.text = "Label detection: \(errorString)"
        return
      }
      self.logExtrasForTesting(labels: features)

//        self.resultsTextView.text = features.map { feature in
//          feature/
//          self.addFrameView(
//            featureFrame: feature.frame,
//            imageSize: image.size,
//            viewFrame: self.imageView.frame
//          )
//          return "\(feature.label) - \(feature.score)"
//          }.joined(separator: "\n")

        // Got labels. Access label info via VisionLabel.
        // TODO(b/78151345): Draw a frame for image labeling detection in the sample app.
      print(features.description)
    }
  }

  private func logExtrasForTesting(labels: [VisionLabel]) {
    for label in labels {
      print("Label \(label.label), frame: \(label.frame), " +
        "entity id: \(label.entityID), confidence: \(label.confidence)")
    }
  }


  /// Detects labels on the specified image and prints the results.
  func detectLabelsCloud() {
    guard let image = imageView.image else { return }

    let labelDetector = Vision.vision().cloudLabelDetector()

    // Initialize a VisionImage object with a UIImage.
    let visionImage = VisionImage(image: image)

    labelDetector.detect(in: visionImage) { (features: [VisionCloudLabel]?, error: Error?) in
      guard error == nil, let features = features, !features.isEmpty else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Label detection failed with error: \(errorString)")
        self.resultsTextView.text = "Label detection: \(errorString)"
        return
      }

//      self.resultsTextView.text = features.map { feature in
//        feature/
//        self.addFrameView(
//          featureFrame: feature.frame,
//          imageSize: image.size,
//          viewFrame: self.imageView.frame
//        )
//        return "\(feature.label) - \(feature.score)"
//        }.joined(separator: "\n")

      // Got labels. Access label info via VisionLabel.
      // TODO(b/78151345): Draw a frame for image labeling detection in the sample app.
      print(features.description)
    }
  }

  /// Detects texts on the specified image and draws a frame for them.
  func detectTexts() {
    guard let image = imageView.image else { return }

    // Create a text detector.
    let textDetector = vision.textDetector()

    // Initialize a VisionImage with a UIImage.
    let visionImage = VisionImage(image: image)

    textDetector.detect(in: visionImage) { (features, error) in
      guard error == nil, let features = features, !features.isEmpty else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Text detection failed with error: \(errorString)")
        self.resultsTextView.text = "Text detection: \(errorString)"
        return
      }
      print("Detected text has: \(features.count) blocks")

      self.resultsTextView.text = features.map { feature in
        self.addFrameView(
          featureFrame: feature.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasForTesting(text: feature)
        return feature.recognizedText
        }.joined(separator: "\n")
    }
  }

  private func logExtrasForTesting(text: VisionText) {
    print("Detected text: \(text.recognizedText), frame: \(text.frame)")
    print("Detected text has: \(text.cornerPoints.count) corner points.")
    for cornerPoint in text.cornerPoints {
      print("Cornerpoint: \(cornerPoint)")
    }
    if let block = text as? VisionTextBlock {
      let lines = block.lines
      print("Detected text block has \(lines.count) lines.")
      for line in lines {
        let elements = line.elements
        print("Detected text line has \(elements.count) elements.")
        for element in elements {
          print("Detected text element says: \(element.recognizedText)")
          print("Detected text element has a bounding box: \(element.frame)")
          let cornerPoints = element.cornerPoints
          print("Expected corner point size is 4, got \(cornerPoints.count)")
          for cornerPoint in cornerPoints {
            print("Cornerpoint: \(cornerPoint)")
          }
        }
      }
    }
  }

  /// Detects texts on the specified image and draws a frame for them.
  func detectTextsCloud() {
    guard let image = imageView.image else { return }

    // Create a text detector.
    let textDetector = vision.cloudTextDetector()

    // Initialize a VisionImage with a UIImage.
    let visionImage = VisionImage(image: image)

    textDetector.detect(in: visionImage) { (cloudText, error) in
      guard error == nil, let cloudText = cloudText else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Text detection failed with error: \(errorString)")
        self.resultsTextView.text = "Text detection: \(errorString)"
        return
      }

//      if let pages = cloudText.pages {
//      self.resultsTextView.text = pages.map { feature in
//        self.addFrameView(
//          featureFrame: feature.frame,
//          imageSize: image.size,
//          viewFrame: self.imageView.frame
//        )
//        return feature.recognizedText
//        }.joined(separator: "\n")
//
    }
  }

  /// Detects barcodes on the specified image and draws a frame for them.
  func detectBarcodes() {
    guard let image = imageView.image else { return }

    // Define the options for a barcode detector.
    let format = VisionBarcodeFormat.qrCode
    let barcodeOptions = VisionBarcodeDetectorOptions(formats: format)

    // Create a barcode detector.
    let barcodeDetector = vision.barcodeDetector(options: barcodeOptions)

    // Define the metadata for the image.
    let imageMetadata: VisionImageMetadata = VisionImageMetadata()
    imageMetadata.orientation = VisionDetectorImageOrientation.topLeft

    // Initialize a VisionImage with a UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    barcodeDetector.detect(in: visionImage) { (features, error) in
      guard error == nil, let features = features, !features.isEmpty else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Barcode detection failed with error: \(errorString)")
        self.resultsTextView.text = "Barcode detection: \(errorString)"
        return
      }
      features.forEach { feature in
        self.addFrameView(
          featureFrame: feature.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasForTesting(barcode: feature)
      }
    }
  }

  private func logExtrasForTesting(barcode: VisionBarcode) {
    print("Detected barcode's bounding box: \(barcode.frame)")
    if let cornerPoints = barcode.cornerPoints {
      print("Expected corner point size is 4, get \(cornerPoints.count)")
      for point in cornerPoints {
        print("Corner point is located at: \(point)")
      }
    }
    print("barcode display value: \(barcode.displayValue ?? "")")
    print("barcode raw value: \(barcode.rawValue ?? "")")
    if let dl = barcode.driverLicense {
      print("driver license city: \(dl.addressCity ?? "")")
      print("driver license state: \(dl.addressState ?? "")")
      print("driver license street: \(dl.addressStreet ?? "")")
      print("driver license zip code: \(dl.addressZip ?? "")")
      print("driver license birthday: \(dl.birthDate ?? "")")
      print("driver license document type: \(dl.documentType ?? "")")
      print("driver license expiry date: \(dl.expiryDate ?? "")")
      print("driver license first name: \(dl.firstName ?? "")")
      print("driver license middle name: \(dl.middleName ?? "")")
      print("driver license last name: \(dl.lastName ?? "")")
      print("driver license gender: \(dl.gender ?? "")")
      print("driver license issue date: \(dl.issuingDate ?? "")")
      print("driver license issue country: \(dl.issuingCountry ?? "")")
      print("driver license number: \(dl.licenseNumber ?? "")")
    }
  }

  // MARK: - Custom models interpretation methods

  /// Loads selected model and sets up input / output tensors using default values.
  func loadCustomModel() {
    guard let localModelFilePath = Bundle.main.path(
      forResource: Constants.quantizedModelFilename,
      ofType: DetectorConstants.modelExtension
      ),
      let labelsFilePath = Bundle.main.path(
        forResource: Constants.quantizedLabelsFilename,
        ofType: DetectorConstants.labelsExtension
      )
      else {
        resultsTextView.text = "Failed to load custom model."
        return
    }
    let cloudModelName = (modelPicker.selectedSegmentIndex == 0) ?
      Constants.cloudModelName1 :
      Constants.cloudModelName2
    let conditions = ModelDownloadConditions(
      wiFiRequired: false,
      idleRequired: false
    )
    let cloudModelSource = CloudModelSource(
      modelName: cloudModelName,
      enableModelUpdates: true,
      initialConditions: conditions,
      updateConditions: conditions
    )
    let localModelSource = LocalModelSource(
      modelName: Constants.localModelName,
      path: localModelFilePath
    )
    let modelManager = ModelManager.modelManager()
    if !registeredCloudModelNames.contains(cloudModelName) {
      modelManager.register(cloudModelSource)
      registeredCloudModelNames.insert(cloudModelName)
    }
    if !registeredLocalModelNames.contains(Constants.localModelName) {
      modelManager.register(localModelSource)
      registeredLocalModelNames.insert(Constants.localModelName)
    }

    let options = ModelOptions(
      cloudModelName: cloudModelName,
      localModelName: Constants.localModelName
    )
    detectorService.loadCustomModel(
      options: options,
      labelsPath: labelsFilePath
    )
  }

  // MARK: - Drawing and convenience methods

  /// Gets a default image for detection.
  ///
  /// - Returns: Image object
  func getImage() -> UIImage? {
    return UIImage(named: Constants.graceHopperImage)
  }

  /// Creates and draws a frame for the calculated rect as a sublayer.
  ///
  /// - Parameter rect: The rect to draw.
  func drawFrame(_ rect: CGRect) {
    let bpath: UIBezierPath = UIBezierPath(rect: rect)

    let rectLayer: CAShapeLayer = CAShapeLayer()
    rectLayer.path = bpath.cgPath
    rectLayer.strokeColor = Constants.lineColor
    rectLayer.fillColor = Constants.fillColor
    rectLayer.lineWidth = Constants.lineWidth

    faceSublayer.addSublayer(rectLayer)
  }

  /// Cleans face detector visual results.
  func cleanFaceFrames() {
    guard let sublayers = faceSublayer.sublayers else { return }
    for sublayer in sublayers {
      guard let faceLayer = sublayer as CALayer? else { fatalError("Error in layers.") }
      faceLayer.removeFromSuperlayer()
    }
  }

  lazy var picker: UIAlertController  = { 
    let alertController = UIAlertController(title: "Select Detection",
                      message: nil,
                      preferredStyle: .alert)
    let deviceTextRecognition = UIAlertAction(title: "On-Device Text Recognition", style: .default) { (UIAlertAction) in
      self.detectTexts()
    }
    alertController.addAction(deviceTextRecognition)

    let deviceBarcodeScanning = UIAlertAction(title: "Barcode Scanning", style: .default) { (UIAlertAction) in
      self.detectBarcodes()
    }
    alertController.addAction(deviceBarcodeScanning)

    let deviceLabelDetection = UIAlertAction(title: "On-Device Label Detection", style: .default) { (UIAlertAction) in
      self.detectLabels()
    }
    alertController.addAction(deviceLabelDetection)

    let deviceFaceDetection = UIAlertAction(title: "On-Device Face Detection", style: .default) { (UIAlertAction) in
      self.detectFaces()
    }
    alertController.addAction(deviceFaceDetection)

    let cloudTextRecognition = UIAlertAction(title: "Cloud Text Recognition", style: .default) { (UIAlertAction) in
      self.detectTextsCloud()
    }
    alertController.addAction(cloudTextRecognition)

    let cloudLabelDetection = UIAlertAction(title: "Cloud Label Detection", style: .default) { (UIAlertAction) in
      self.detectLabelsCloud()
    }
    alertController.addAction(cloudLabelDetection)

    let cloudLandmarkDetection = UIAlertAction(title: "Cloud Landmark Detection", style: .default) { (UIAlertAction) in
      self.detectLandmarksCloud()
    }
    alertController.addAction(cloudLandmarkDetection)

    let customModel = UIAlertAction(title: "Custom Model Object Detection", style: .default) { (UIAlertAction) in
      self.detectTexts()
    }
    alertController.addAction(customModel)
    return alertController
  }()

  /// Cleans custom detector visual results.
  func cleanObjectList() {
    resultsTextView.text = nil
  }

  @IBAction func detect(_ sender: Any) {
    resultsTextView.text = nil
    present(picker, animated: true, completion: nil)
  }

  @IBAction func detectObjects(_ sender: Any) {
    resultsTextView.text = nil
    loadCustomModel()
    let image = imageView.image
    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = self.detectorService.scaledImageData(for: image)
      self.detectorService.detectObjects(imageData: imageData) { (results, error) in
        guard error == nil, let results = results, !results.isEmpty else {
          let errorString = error?.localizedDescription ?? Constants.failedToDetectObjectsMessage
          print("Failed to detect objects with error: \(errorString)")
          self.resultsTextView.text = "Object Detection: \(errorString)"
          return
        }
        self.resultsTextView.text = "\(self.detectionResultsString(fromResults: results))"
      }
    }
  }


  @IBAction func openLibrary(_ sender: Any) {
    imagePicker.sourceType = .photoLibrary
    self.present(imagePicker, animated: true)
  }

  @IBAction func takePicture(_ sender: Any) {
    // Only show camera if there's a camera available
    if UIImagePickerController.isCameraDeviceAvailable(.front) ||
      UIImagePickerController.isCameraDeviceAvailable(.rear) {
      imagePicker.sourceType = .camera
      self.present(imagePicker, animated: true)
    }
  }

  @IBAction func modelSwitched(_ sender: Any) {
    // Cleaning for the face and custom detectors visual results
    cleanFaceFrames()
    cleanObjectList()

    loadCustomModel()
  }

  // MARK: - UIImagePickerControllerDelegate Methods

  public func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String: Any]
    ) {

    // Cleaning for the face and custom detectors visual results
    cleanFaceFrames()
    cleanObjectList()

    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      imageView.image = pickedImage
    }

    dismiss(animated: true)
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
}

// MARK: - Fileprivate

fileprivate enum Constants {
  static let labelConfidenceThreshold: Float = 0.75
  static let lineWidth: CGFloat = 3.0
  static let lineColor = UIColor.yellow.cgColor
  static let fillColor = UIColor.clear.cgColor

  // TODO: REPLACE THESE CLOUD MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
  static let localModelName = "mobilenet"

  static let cloudModelName1 = "invalid_model"
  static let cloudModelName2 = "image_classification"

  static let multiFaceImage = "multi-face.png"
  static let graceHopperImage = "grace_hopper.jpg"

  static let labelsFilename = "labels"
  static let modelFilename = "mobilenet_v1_1.0_224"
  static let quantizedLabelsFilename = "labels_quant"
  static let quantizedModelFilename = "mobilenet_quant_v1_224"

  static let detectionNoResultsMessage = "No results returned."
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."
}
