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
import FirebaseMLVision
// [END import_vision]
import FirebaseMLModelInterpreter

// swiftlint:disable colon opening_brace
/// Main view controller class.
class ViewController:
  UIViewController,
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  // swiftlint:enable colon opening_brace

  /// Firebase vision instance. Instantiated in `viewDidLoad`.
  var vision: Vision?

  /// Firebase vision text detector. Instantiated in `viewDidLoad`.
  var textDetector: VisionTextDetector?

  /// Detector service that manages loading models and detecting objects.
  let detectorService = DetectorService()

  /// Indicates whether the download cloud model button was selected.
  var downloadCloudModelButtonSelected = false

  /// A layer on the view for the drawing frame results.
  var frameSublayer = CALayer()

  /// An image picker for accessing the photo library or camera.
  var imagePicker = UIImagePickerController()

  // MARK: - IBOutlets

  /// Index 0 = cloud model 1, Index 1 = cloud model 2.
  @IBOutlet private weak var modelPicker: UISegmentedControl!

  @IBOutlet private weak var imageView: UIImageView!
  @IBOutlet private weak var resultsTextView: UITextView!
  @IBOutlet private weak var cameraButton: UIBarButtonItem!
  @IBOutlet private weak var downloadModelButton: UIBarButtonItem!

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    // [START init_vision]
    vision = Vision.vision()
    // [END init_vision]
    textDetector = vision?.textDetector()

    imageView.image = UIImage(named: Constants.graceHopperImage)
    imageView.layer.addSublayer(frameSublayer)

    imagePicker.delegate = self
    imagePicker.sourceType = .photoLibrary

    if !UIImagePickerController.isCameraDeviceAvailable(.front) ||
      !UIImagePickerController.isCameraDeviceAvailable(.rear) {
      cameraButton.isEnabled = false
    }
  }

  // MARK: - Vision Detection

  /// Detects landmarks on the specified image and draws a frame for them.
  func detectLandmarksCloud() {
    guard let image = imageView.image else { return }

    // Create a landmark detector.
    // [START config_landmark_cloud]
    let options = VisionCloudDetectorOptions()
    options.modelType = .latest
    options.maxResults = 20
    // [END config_landmark_cloud]

    // [START init_landmark_cloud]
    let landmarkDetector = vision?.cloudLandmarkDetector(options: options)
    // [END init_landmark_cloud]

    // Initialize a VisionImage object with a UIImage.
    // [START init_image]
    let visionImage = VisionImage(image: image)
    // [END init_image]

    // Define the metadata for the image.
    // [START set_image_metadata]
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = .topLeft

    visionImage.metadata = imageMetadata
    // [END set_image_metadata]

    // [START detect_landmarks_cloud]
    landmarkDetector?.detect(in: visionImage) { (landmarks, error) in
      guard error == nil, let landmarks = landmarks, !landmarks.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Landmark detection failed with error: \(errorString)")
        self.resultsTextView.text = "Landmark Detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Recognized landmarks
      // [START_EXCLUDE]
      self.resultsTextView.text = landmarks.map { landmark -> String in
        self.addFrameView(
          featureFrame: landmark.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasforTesting(landmark: landmark)
        return "Frame: \(landmark.frame)"
      }.joined(separator: "\n")
      // [END_EXCLUDE]
    }
    // [END detect_landmarks_cloud]
  }

  private func logExtrasforTesting(landmark: VisionCloudLandmark) {
    print("Landmark text: \(landmark.landmark ?? "")")
    print("Landmark frame: \(landmark.frame)")
    print("Landmark entityID: \(landmark.entityId ?? "")")
    print("Landmark confidence: \(landmark.confidence ?? 0)")
    if let locations = landmark.locations {
      for location in locations {
        print("Landmark location latitude: \(location.latitude ?? 0), longitude: \(location.longitude ?? 0)")
      }
    }
  }

  /// Detects faces on the specified image and draws a frame for them.
  func detectFaces() {
    guard let image = imageView.image else { return }

    // Create a face detector.
    // [START config_face]
    let options = VisionFaceDetectorOptions()
    options.modeType = .accurate
    options.landmarkType = .all
    options.classificationType = .all
    options.minFaceSize = CGFloat(0.1)
    options.isTrackingEnabled = true
    // [END config_face]

    // [START init_face]
    let faceDetector = vision?.faceDetector(options: options)
    // [END init_face]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = detectorOrientationFrom(image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_faces]
    faceDetector?.detect(in: visionImage) { (faces, error) in
      guard error == nil, let faces = faces, !faces.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Face detection failed with error: \(errorString)")
        self.resultsTextView.text = "Face Detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Faces detected
      // [START_EXCLUDE]
      self.resultsTextView.text = faces.map { face -> String in
        self.addFrameView(
          featureFrame: face.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasforTesting(face: face)
        return "Frame: \(face.frame)"
      }.joined(separator: "\n")
      // [END_EXCLUDE]
    }
    // [END detect_faces]
  }

  private func logExtrasforTesting(face: VisionFace) {
    print("Face frame: \(face.frame)")
    print("Face euler angle Y: \(face.headEulerAngleY)")
    print("Face euler angle Z: \(face.headEulerAngleZ)")

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

    print("Face left eye open probability: \(face.leftEyeOpenProbability)")
    print("Face right eye open probability: \(face.rightEyeOpenProbability)")
    print("Face smiling probability: \(face.smilingProbability)")
    print("Face tracking id: \(face.trackingID)")
  }

  /// Detects labels on the specified image and prints the results.
  func detectLabels() {
    guard let image = imageView.image else { return }

    // [START config_label]
    let options = VisionLabelDetectorOptions(
      confidenceThreshold: Constants.labelConfidenceThreshold
    )
    // [END config_label]

    // [START init_label]
    let labelDetector = vision?.labelDetector(options: options)
    // [END init_label]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = detectorOrientationFrom(image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_label]
    labelDetector?.detect(in: visionImage) { (labels, error) in
      guard error == nil, let labels = labels, !labels.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Label detection failed with error: \(errorString)")
        self.resultsTextView.text = "Label detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Labeled image
      // [START_EXCLUDE]
      self.logExtrasForTesting(labels: labels)
      self.resultsTextView.text = labels.map { label -> String in
        // TODO(b/78151345): Draw a frame for image labeling detection in the sample app.
        "Label: \(label.label), Confidence: \(label.confidence), EntityID: " +
        "\(label.entityID), Frame: \(label.frame)"
      }.joined(separator: "\n")
      // [END_EXCLUDE]
    }
    // [END detect_label]
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

    // [START init_label_cloud]
    let labelDetector = Vision.vision().cloudLabelDetector()
    // [END init_label_cloud]

    // Initialize a VisionImage object with a UIImage.
    let visionImage = VisionImage(image: image)

    // [START detect_label_cloud]
    labelDetector.detect(in: visionImage) { (labels: [VisionCloudLabel]?, error: Error?) in
      guard error == nil, let labels = labels, !labels.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Label detection failed with error: \(errorString)")
        self.resultsTextView.text = "Label detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Labeled image
      // [START_EXCLUDE]
      self.logExtrasForTesting(cloudlabels: labels)
      self.resultsTextView.text = labels.map { label -> String in
        // TODO(b/78151345): Draw a frame for image labeling detection in the sample app.
        "Label: \(label.label ?? ""), Confidence: \(label.confidence ?? 0), EntityID: " +
        "\(label.entityId ?? "")"
        }.joined(separator: "\n")
      // [END_EXCLUDE]
    }
    // [END detect_label_cloud]
  }

  private func logExtrasForTesting(cloudlabels: [VisionCloudLabel]) {
    for label in cloudlabels {
      print("Label \(label.label ?? ""), " +
        "entity id: \(label.entityId ?? ""), confidence: \(label.confidence ?? 0)")
    }
  }

  /// Detects texts on the specified image and draws a frame for them.
  func detectTexts() {
    guard let image = imageView.image else { return }

    // Create a text detector.
    // [START init_text]
    let textDetector = vision?.textDetector()
    // [END init_text]

    // Initialize a VisionImage with a UIImage.
    let visionImage = VisionImage(image: image)

    // [START detect_text]
    textDetector?.detect(in: visionImage) { (features, error) in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Text detection failed with error: \(errorString)")
        self.resultsTextView.text = "Text detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Recognized and extracted text
      print("Detected text has: \(features.count) blocks")
      // [START_EXCLUDE]
      self.resultsTextView.text = features.map { feature in
        self.addFrameView(
          featureFrame: feature.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasForTesting(text: feature)
        return "Text: \(feature.text)"
      }.joined(separator: "\n")
      // [END_EXCLUDE]
    }
    // [END detect_text]
  }

  private func logExtrasForTesting(text: VisionText) {
    print("Detected text: \(text.text), frame: \(text.frame)")
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
          print("Detected text element says: \(element.text)")
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

    // [START config_text_cloud]
    let options = VisionCloudDetectorOptions()
    options.modelType = .latest
    // options.maxResults has no effect with this API
    // [END config_text_cloud]

    // Create a text detector.
    // [START init_text_cloud]
    let textDetector = vision?.cloudTextDetector()
    // [END init_text_cloud]

    // Initialize a VisionImage with a UIImage.
    let visionImage = VisionImage(image: image)

    // [START detect_text_cloud]
    textDetector?.detect(in: visionImage) { (cloudText, error) in
      guard error == nil, let cloudText = cloudText else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Text detection failed with error: \(errorString)")
        self.resultsTextView.text = "Text detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Recognized and extracted text
      // [START_EXCLUDE]
      self.logExtrasForTesting(cloudText: cloudText)
      if let pages = cloudText.pages {
        self.resultsTextView.text = pages.map { page in
          if let blocks = page.blocks {
            let text = blocks.map { block in
              self.addFrameView(
                featureFrame: block.frame,
                imageSize: image.size,
                viewFrame: self.imageView.frame
              )
            }
          }
          return "" //fix later
        }.joined(separator: "\n")
      }
      // [END_EXCLUDE]
    }
    // [START detect_text_cloud]
  }

  private func logExtrasForTesting(cloudText: VisionCloudText) {
    print("Detected text: \(cloudText.text ?? "")")
    if let pages = cloudText.pages {
      for page in pages {
        if let blocks = page.blocks {
          for block in blocks {
            if let paragraphs = block.paragraphs {
              for paragraph in paragraphs {
                if let words = paragraph.words {
                  for word in words {
                    if let symbols = word.symbols {
                      for symbol in symbols {
                        print("Detected text symbol: \(symbol.text ?? "")")
//                        print("Detected text symbol text property: \(symbol.textProperty. ?? "")")
                        print("Detected text symbol confidence: \(symbol.confidence ?? 0)")
                        print("Detected text symbol frame: \(symbol.frame)")
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  /// Detects barcodes on the specified image and draws a frame for them.
  func detectBarcodes() {
    guard let image = imageView.image else { return }

    // Define the options for a barcode detector.
    // [START config_barcode]
    let format = VisionBarcodeFormat.all
    // Or, e.g.: VisionBarcodeFormat.qrCode | VisionBarcodeFormat.aztec
    let options = VisionBarcodeDetectorOptions(formats: format)
    // [END config_barcode]

    // Create a barcode detector.
    // [START init_barcode]
    let barcodeDetector = vision?.barcodeDetector(options: options)
    // [END init_barcode]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = detectorOrientationFrom(image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_barcodes]
    barcodeDetector?.detect(in: visionImage) { (barcodes, error) in
      guard error == nil, let barcodes = barcodes, !barcodes.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        print("Barcode detection failed with error: \(errorString)")
        self.resultsTextView.text = "Barcode detection: \(errorString)"
        // [END_EXCLUDE]

        return
      }

      // Detected and read barcodes
      // [START_EXCLUDE]
      self.resultsTextView.text = barcodes.map { barcode in
        self.addFrameView(
          featureFrame: barcode.frame,
          imageSize: image.size,
          viewFrame: self.imageView.frame
        )
        self.logExtrasForTesting(barcode: barcode)
        return "DisplayValue: \(barcode.displayValue ?? ""), RawValue: " +
        "\(barcode.rawValue ?? ""), Frame: \(barcode.frame)"
      }.joined(separator: "\n")
      // [END_EXCLUDE]
    }
    // [END detect_barcodes]
  }

  private func logExtrasForTesting(barcode: VisionBarcode) {
    print("Detected barcode's bounding box: \(barcode.frame)")
    if let cornerPoints = barcode.cornerPoints {
      print("Expected corner point size is 4, get \(cornerPoints.count)")
      for point in cornerPoints {
        print("Corner point is located at: \(point)")
      }
    }
    print("Barcode display value: \(barcode.displayValue ?? "")")
    print("Barcode format: \(barcode.format)")
    print("Barcode raw value: \(barcode.rawValue ?? "")")
    print("Barcode value type: \(barcode.valueType)")

    if let email = barcode.email {
      print("Barcode email address: \(email.address ?? "")")
      print("Barcode email body: \(email.body ?? "")")
      print("Barcode email subject: \(email.subject ?? "")")
      print("Barcode email type: \(email.type)")
    }

    if let phone = barcode.phone {
      print("Barcode phone number: \(phone.number ?? "")")
      print("Barcode phone type: \(phone.type)")
    }

    if let calendarEvent = barcode.calendarEvent {
      print("Barcode calendar event start: \(calendarEvent.start?.description ?? "")")
      print("Barcode calendar event end: \(calendarEvent.end?.description ?? "")")
      print("Barcode calendar event description: \(calendarEvent.eventDescription ?? "")")
      print("Barcode calendar event location: \(calendarEvent.location ?? "")")
      print("Barcode calendar event organizer: \(calendarEvent.organizer ?? "")")
      print("Barcode calendar event status: \(calendarEvent.status ?? "")")
      print("Barcode calendar event summary: \(calendarEvent.summary ?? "")")
    }

    if let contactInfo = barcode.contactInfo {
      if let addresses = contactInfo.addresses {
        for address in addresses {
          print("Barcode contact info address: \(address)")
        }
      }
      if let emails = contactInfo.emails {
        for email in emails {
          print("Barcode contact info email address: \(email.address ?? "")")
          print("Barcode contact info email body: \(email.body ?? "")")
          print("Barcode contact info email subject: \(email.subject ?? "")")
          print("Barcode contact info email type: \(email.type)")
        }
      }
      if let phones = contactInfo.phones {
        for phone in phones {
          print("Barcode contact info phone number: \(phone.number ?? "")")
          print("Barcode contact info phone type: \(phone.type)")
        }
      }
      if let urls = contactInfo.urls {
        for url in urls {
          print("Barcode contact info url: \(url)")
        }
      }
      print("Barcode contact info job title: \(contactInfo.jobTitle ?? "")")
      if let name = contactInfo.name {
        print("Barcode contact info first name: \(name.first ?? "")")
        print("Barcode contact info formatted name: \(name.formattedName ?? "")")
        print("Barcode contact info last name: \(name.last ?? "")")
        print("Barcode contact info middle name: \(name.middle ?? "")")
        print("Barcode contact info name prefix: \(name.prefix ?? "")")
        print("Barcode contact info name suffix: \(name.suffix ?? "")")
        print("Barcode contact info name pronounciation: \(name.pronounciation ?? "")")
      }
      print("Barcode contact info organization: \(contactInfo.organization ?? "")")
    }

    if let geoPoint = barcode.geoPoint {
      print("Barcode geoPoint latitude: \(geoPoint.latitude)")
      print("Barcode geoPoint longitude: \(geoPoint.longitude)")
    }

    if let sms = barcode.sms {
      print("Barcode sms message: \(sms.message ?? "")")
      print("Barcode sms phone number: \(sms.phoneNumber ?? "")")
    }

    if let url = barcode.url {
      print("Barcode url title: \(url.title ?? "")")
      print("Barcode url: \(url.url ?? "")")
    }

    if let wifi = barcode.wifi {
      print("Barcode wifi ssid: \(wifi.ssid ?? "")")
      print("Barcode wifi password: \(wifi.password ?? "")")
      print("Barcode wifi type \(wifi.type)")
    }

    if let dl = barcode.driverLicense {
      print("Driver license city: \(dl.addressCity ?? "")")
      print("Driver license state: \(dl.addressState ?? "")")
      print("Driver license street: \(dl.addressStreet ?? "")")
      print("Driver license zip code: \(dl.addressZip ?? "")")
      print("Driver license birthday: \(dl.birthDate ?? "")")
      print("Driver license document type: \(dl.documentType ?? "")")
      print("Driver license expiry date: \(dl.expiryDate ?? "")")
      print("Driver license first name: \(dl.firstName ?? "")")
      print("Driver license middle name: \(dl.middleName ?? "")")
      print("Driver license last name: \(dl.lastName ?? "")")
      print("Driver license gender: \(dl.gender ?? "")")
      print("Driver license issue date: \(dl.issuingDate ?? "")")
      print("Driver license issue country: \(dl.issuingCountry ?? "")")
      print("Driver license number: \(dl.licenseNumber ?? "")")
    }
  }

  // MARK: - Model Interpreter

  /// Loads the cloud model.
  func loadCloudModel() {
    guard let labelsFilePath = Bundle.main.path(
      forResource: Constants.quantizedLabelsFilename,
      ofType: DetectorConstants.labelsExtension
      ) else {
        resultsTextView.text = "Failed to load the labels file. "
        return
    }
    let cloudModelName = (modelPicker.selectedSegmentIndex == 0) ?
      Constants.cloudModelName1 :
      Constants.cloudModelName2
    let conditions = ModelDownloadConditions(wiFiRequired: false, idleRequired: false)
    let cloudModelSource = CloudModelSource(
      modelName: cloudModelName,
      enableModelUpdates: true,
      initialConditions: conditions,
      updateConditions: conditions
    )
    let modelManager = ModelManager.modelManager()
    if !modelManager.register(cloudModelSource) {
      print("Failed to register the cloud model source.")
    }
    let options = ModelOptions(cloudModelName: cloudModelName, localModelName: nil)
    detectorService.loadModel(options: options, labelsPath: labelsFilePath)
  }

  /// Loads the local model.
  func loadLocalModel() {
    guard let localModelFilePath = Bundle.main.path(
      forResource: Constants.quantizedModelFilename,
      ofType: DetectorConstants.modelExtension
      ),
      let labelsFilePath = Bundle.main.path(
        forResource: Constants.quantizedLabelsFilename,
        ofType: DetectorConstants.labelsExtension
      )
      else {
        resultsTextView.text = "Failed to get the paths to the local model and labels files."
        return
    }
    let localModelSource = LocalModelSource(
      modelName: Constants.localModelName,
      path: localModelFilePath
    )
    let modelManager = ModelManager.modelManager()
    if !modelManager.register(localModelSource) {
      print ("Failed to register the local model source.")
    }
    let options = ModelOptions(cloudModelName: nil, localModelName: Constants.localModelName)
    detectorService.loadModel(options: options, labelsPath: labelsFilePath)
  }

  func detectObjects() {
    if !downloadCloudModelButtonSelected {
      resultsTextView.text = "Loading the local model...\n"
      loadLocalModel()
    }

    let image = imageView.image
    var newResultsTextString = "Starting inference...\n"
    if let currentText = resultsTextView.text {
      newResultsTextString = currentText + newResultsTextString
    }
    resultsTextView.text = newResultsTextString
    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = self.detectorService.scaledImageData(for: image)
      self.detectorService.detectObjects(imageData: imageData) { (results, error) in
        guard error == nil, let results = results, !results.isEmpty else {
          var errorString = error?.localizedDescription ?? Constants.failedToDetectObjectsMessage
          errorString = "Inference error: \(errorString)"
          print(errorString)
          self.resultsTextView.text = errorString
          return
        }

        var inferenceMessageString: String
        if self.downloadCloudModelButtonSelected {
          let keyString = (self.modelPicker.selectedSegmentIndex == 0) ?
            Constants.cloudModel1DownloadCompletedKey :
            Constants.cloudModel2DownloadCompletedKey
          UserDefaults.standard.set(true, forKey: keyString)
          inferenceMessageString = "Inference results using the cloud model:\n"
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
    guard UIImagePickerController.isCameraDeviceAvailable(.front) ||
      UIImagePickerController.isCameraDeviceAvailable(.rear)
      else {
        return
    }
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true)
  }

  @IBAction func downloadCloudModel(_ sender: Any) {
    clearResults()
    downloadCloudModelButtonSelected = true
    let keyString = (self.modelPicker.selectedSegmentIndex == 0) ?
      Constants.cloudModel1DownloadCompletedKey :
      Constants.cloudModel2DownloadCompletedKey
    let isCloudModelDownloaded = UserDefaults.standard.bool(forKey: keyString)
    resultsTextView.text = isCloudModelDownloaded ?
      "Cloud model loaded. Select the `Objects` button to start the inference." :
      "Downloading cloud model. Once the download has completed, select the `Objects` button to " +
    "start the inference."
    loadCloudModel()
  }

  @IBAction func modelSwitched(_ sender: Any) {
    clearResults()
  }

  // MARK: - UIImagePickerControllerDelegate

  public func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String: Any]
    ) {

    // Cleaning for the face and custom detectors visual results
    clearResults()

    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      updateImageView(with: pickedImage)
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

  lazy var picker: UIAlertController  = {
    let alertController = UIAlertController(title: "Select Detection",
                                            message: nil,
                                            preferredStyle: .alert)
    let deviceTextRecognition = UIAlertAction(title: "Text recognition (OCR)", style: .default) { (UIAlertAction) in
      self.detectTexts()
    }
    alertController.addAction(deviceTextRecognition)

    let deviceFaceDetection = UIAlertAction(title: "Face detection", style: .default) { (UIAlertAction) in
      self.detectFaces()
    }
    alertController.addAction(deviceFaceDetection)

    let deviceBarcodeScanning = UIAlertAction(title: "Barcode scanner", style: .default) { (UIAlertAction) in
      self.detectBarcodes()
    }
    alertController.addAction(deviceBarcodeScanning)

    let deviceLabelDetection = UIAlertAction(title: "Label Detection", style: .default) { (UIAlertAction) in
      self.detectLabels()
    }
    alertController.addAction(deviceLabelDetection)

    let cloudLandmarkDetection = UIAlertAction(title: "Cloud Landmark Detection", style: .default) { (UIAlertAction) in
      self.detectLandmarksCloud()
    }
    alertController.addAction(cloudLandmarkDetection)


    let cloudTextRecognition = UIAlertAction(title: "Cloud Text Recognition", style: .default) { (UIAlertAction) in
      self.detectTextsCloud()
    }
    alertController.addAction(cloudTextRecognition)

    let cloudLabelDetection = UIAlertAction(title: "Cloud Label Detection", style: .default) { (UIAlertAction) in
      self.detectLabelsCloud()
    }
    alertController.addAction(cloudLabelDetection)


    let customModel = UIAlertAction(title: "Custom Model Object Detection", style: .default) { (UIAlertAction) in
      self.detectObjects()
    }
    alertController.addAction(customModel)
    return alertController
  }()

  @IBAction func detect(_ sender: Any) {
    clearResults()
    present(picker, animated: true, completion: nil)
  }

  /// Converts a feature frame to a frame UIView that is displayed over the image.
  ///
  /// - Parameters:
  ///   - featureFrame: The rect of the feature with the same scale as the original image.
  ///   - imageSize: The size of original image.
  ///   - viewRect: The view frame rect on the screen.
  private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) {
    print("Frame: \(featureFrame).")

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

  /// Creates and draws a frame for the calculated rect as a sublayer.
  ///
  /// - Parameter rect: The rect to draw.
  private func drawFrame(_ rect: CGRect) {
    let bpath: UIBezierPath = UIBezierPath(rect: rect)
    let rectLayer: CAShapeLayer = CAShapeLayer()
    rectLayer.path = bpath.cgPath
    rectLayer.strokeColor = Constants.lineColor
    rectLayer.fillColor = Constants.fillColor
    rectLayer.lineWidth = Constants.lineWidth
    frameSublayer.addSublayer(rectLayer)
  }

  /// Removes the frame results from the image.
  private func removeFrames() {
    guard let sublayers = frameSublayer.sublayers else { return }
    for sublayer in sublayers {
      guard let frameLayer = sublayer as CALayer? else {
        print("Failed to remove frame layer.")
        continue
      }
      frameLayer.removeFromSuperlayer()
    }
  }

  /// Clears the results text view and removes any frames that are visible.
  private func clearResults() {
    resultsTextView.text = nil
    removeFrames()
  }

  /// Returns the `VisionDetectorImageOrientation` from the given `UIImageOrientation`.
  private func detectorOrientationFrom(
    _ imageOrientation: UIImageOrientation
    ) -> VisionDetectorImageOrientation {
    switch imageOrientation {
    case .up:
      return .topLeft
    case .down:
      return .bottomRight
    case .left:
      return .leftBottom
    case .right:
      return .rightTop
    case .upMirrored:
      return .topRight
    case .downMirrored:
      return .bottomLeft
    case .leftMirrored:
      return .leftTop
    case .rightMirrored:
      return .rightBottom
    }
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
        with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
      )
      scaledImage = scaledImage ?? image
      guard let finalImage = scaledImage else { return }
      DispatchQueue.main.async {
        self.imageView.image = finalImage
      }
    }
  }
}

// MARK: - Fileprivate

fileprivate enum Constants {
  // TODO: REPLACE THESE CLOUD MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
  static let cloudModelName1 = "image_classification"
  static let cloudModelName2 = "invalid_model"

  static let localModelName = "mobilenet"

  static let multiFaceImage = "multi-face.png"
  static let graceHopperImage = "grace_hopper.jpg"

  static let labelsFilename = "labels"
  static let modelFilename = "mobilenet_v1_1.0_224"
  static let quantizedLabelsFilename = "labels_quant"
  static let quantizedModelFilename = "mobilenet_quant_v1_224"

  static let cloudModel1DownloadCompletedKey = "FIRCloudModel1DownloadCompleted"
  static let cloudModel2DownloadCompletedKey = "FIRCloudModel2DownloadCompleted"

  static let detectionNoResultsMessage = "No results returned."
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."

  static let labelConfidenceThreshold: Float = 0.75
  static let lineWidth: CGFloat = 3.0
  static let lineColor = UIColor.yellow.cgColor
  static let fillColor = UIColor.clear.cgColor
}
