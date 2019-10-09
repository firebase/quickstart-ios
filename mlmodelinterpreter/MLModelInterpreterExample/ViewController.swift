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

import Firebase

@objc(ViewController)
class ViewController: UIViewController, UINavigationControllerDelegate {

  typealias DetectObjectsCompletion = ([(label: String, confidence: Float)]?, Error?) -> Void

  // MARK: - Properties

  private let initialConditions = ModelDownloadConditions(
    allowsCellularAccess: true,
    allowsBackgroundDownloading: true)

  private let updateConditions = ModelDownloadConditions(
    allowsCellularAccess: false,
    allowsBackgroundDownloading: true)

  private var imagePicker = UIImagePickerController()
  private var remoteModels = [ModelType: CustomRemoteModel]()
  private var localModels = [ModelType: CustomLocalModel]()
  private lazy var modelManager = ModelManager.modelManager()

  private var currentModelType: ModelType {
    precondition(Thread.isMainThread)
    guard let type = ModelType(rawValue: modelControl.selectedSegmentIndex) else {
      preconditionFailure("Invalid model type for selected segment index.")
    }
    return type
  }

  private var currentRemoteModel: CustomRemoteModel {
    precondition(Thread.isMainThread)
    guard let remoteModel = remoteModels[currentModelType] else {
      preconditionFailure("Could not find the remote model for current model type.")
    }
    return remoteModel
  }

  private var currentLocalModel: CustomLocalModel {
    precondition(Thread.isMainThread)
    guard let localModel = localModels[currentModelType] else {
      preconditionFailure("Could not find the local model for current model type.")
    }
    return localModel
  }

  private var labels: [String] = {
    guard
      let labelsPath = Bundle.main.path(
        forResource: MobileNet.labelsInfo.name,
        ofType: MobileNet.labelsInfo.extension)
    else {
      preconditionFailure("Failed to get the labels file path.")
    }
    let contents: String
    do {
      contents = try String(contentsOfFile: labelsPath, encoding: .utf8)
    } catch let error {
      preconditionFailure("Failed to read labels with error: \(error.localizedDescription).")
    }
    return contents.components(separatedBy: .newlines)
  }()

  // MARK: - IBOutlets

  @IBOutlet private var modelControl: UISegmentedControl!
  @IBOutlet private var imageView: UIImageView!
  @IBOutlet private var resultsTextView: UITextView!
  @IBOutlet private var detectButton: UIBarButtonItem!
  @IBOutlet private var cameraButton: UIBarButtonItem!
  @IBOutlet private var downloadModelButton: UIBarButtonItem!
  @IBOutlet private var downloadProgressView: UIProgressView!

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    imageView.image = UIImage(named: Constant.defaultImage)
    imagePicker.delegate = self
    if !UIImagePickerController.isCameraDeviceAvailable(.front) || !UIImagePickerController
      .isCameraDeviceAvailable(.rear)
    {
      cameraButton.isEnabled = false
    }
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(remoteModelDownloadDidSucceed(_:)),
      name: .firebaseMLModelDownloadDidSucceed,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(remoteModelDownloadDidFail(_:)),
      name: .firebaseMLModelDownloadDidFail,
      object: nil
    )
    setUpRemoteModels()
    setUpLocalModels()
    detectButton.isEnabled = modelManager.isModelDownloaded(currentRemoteModel)
  }

  // MARK: - IBActions

  @IBAction func detectObjects(_ sender: Any) {
    updateResultsText()
    guard let image = imageView.image else {
      updateResultsText("Image must not be nil.\n")
      return
    }
    detectButton.isEnabled = false
    let remoteModel = currentRemoteModel
    let localModel = currentLocalModel
    let modelType = currentModelType
    let modelInterpreter: ModelInterpreter
    switch modelType {
    case .float:
      if modelManager.isModelDownloaded(remoteModel) {
        modelInterpreter = ModelInterpreter.modelInterpreter(remoteModel: remoteModel)
      } else {
        modelInterpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
      }
    case .quantized, .invalid:
      modelInterpreter = ModelInterpreter.modelInterpreter(remoteModel: remoteModel)
    }

    var newResultsTextString = "Starting inference...\n"
    if let currentText = resultsTextView.text {
      newResultsTextString = currentText + newResultsTextString
    }
    updateResultsText(newResultsTextString)
    let isQuantized = modelType == .quantized
    DispatchQueue.global(qos: .userInitiated).async {
      let imageData = self.scaledImageData(from: image, isQuantized: isQuantized)
      self.runInference(
        on: imageData,
        modelInterpreter: modelInterpreter,
        isQuantized: isQuantized
      ) { results, error in
        guard error == nil, let results = results, !results.isEmpty else {
          var errorString = error?.localizedDescription ?? Constant.failedToDetectObjectsMessage
          errorString = "Inference error: \(errorString)"
          print(errorString)
          self.updateResultsText(errorString)
          self.detectButton.isEnabled = true
          return
        }
        var inferenceMessageString = "Inference results using "
        if self.modelManager.isModelDownloaded(remoteModel) {
          inferenceMessageString += "`\(self.remoteModelName(for: modelType))` remote model:\n"
        } else {
          inferenceMessageString += "`\(self.localModelInfo(for: modelType).0)` local model:\n"
        }
        self.updateResultsText(
          inferenceMessageString + "\(self.detectionResultsString(fromResults: results))")
        self.detectButton.isEnabled = true
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

  @IBAction func downloadModel(_ sender: Any) {
    defer { downloadModelButton.isEnabled = false }
    updateResultsText()
    switch currentModelType {
    case .quantized:
      downloadProgressView.isHidden = false
      let conditions: ModelDownloadConditions
      if modelManager.isModelDownloaded(currentRemoteModel) {
        conditions = updateConditions
        updateResultsText("The remote model has already been downloaded, checking with the " +
          "Firebase Console to see if a newer version of the model is available for download. " +
          "This text view will notify you if a newer version was downloaded.\n")
      } else {
        conditions = initialConditions
        updateResultsText("The remote model is being downloaded. Follow the progress view to " +
          "determine when the model download has completed.\n")
      }
      downloadProgressView.observedProgress = modelManager.download(
        currentRemoteModel,
        conditions: conditions)
    case .float:
      if modelManager.isModelDownloaded(currentRemoteModel) {
        updateResultsText("Deleting the downloaded remote model. Once the model has been " +
          "deleted, you can always redownload it by pressing the download button.\n")
        modelManager.deleteDownloadedModel(currentRemoteModel) { error in
          guard error == nil else { preconditionFailure("Failed to delete the float model.") }
          self.updateResultsText("The downloaded remote model has been successfully deleted.\n")
          self.downloadModelButton.isEnabled = true
        }
      } else {
        updateResultsText("The remote model has not been downloaded yet. Loading the local model " +
          "so it can be used as a fallback while the remote model is being downloaded. This text " +
          "view will notify you once the download has completed.\n")
        let _ = modelManager.download(currentRemoteModel, conditions: initialConditions)
      }
    case .invalid:
      updateResultsText("Downloading the current model. This text view will notify you once the " +
        "download has completed.\n")
      let _ = modelManager.download(currentRemoteModel, conditions: initialConditions)
    }
  }

  @IBAction func modelSwitched(_ sender: Any) {
    defer { downloadModelButton.isEnabled = true }
    updateResultsText()
    switch currentModelType {
    case .quantized:
      detectButton.isEnabled = modelManager.isModelDownloaded(currentRemoteModel)
    case .float, .invalid:
      downloadProgressView.isHidden = true
      detectButton.isEnabled = true
    }
  }

  // MARK: - Notifications

  @objc
  private func remoteModelDownloadDidSucceed(_ notification: Notification) {
    let notificationHandler = {
      self.updateResultsText()
      self.downloadModelButton.isEnabled = true
      guard let userInfo = notification.userInfo,
        let remoteModel = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? RemoteModel
      else {
        self.updateResultsText(
          "firebaseMLModelDownloadDidSucceed notification posted without a "
            + "RemoteModel instance.")
        return
      }
      if remoteModel.name == self.currentRemoteModel.name {
        self.detectButton.isEnabled = true
      }
      self.updateResultsText(
        "Successfully downloaded the remote model with name: "
          + "\(remoteModel.name). The model is ready for detection.")
    }
    if Thread.isMainThread {
      notificationHandler()
      return
    }
    DispatchQueue.main.async { notificationHandler() }
  }

  @objc
  private func remoteModelDownloadDidFail(_ notification: Notification) {
    let notificationHandler = {
      self.updateResultsText()
      self.detectButton.isEnabled = self.currentModelType != .quantized
      self.downloadModelButton.isEnabled = true
      guard let userInfo = notification.userInfo,
        let remoteModel = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? RemoteModel,
        let error = userInfo[ModelDownloadUserInfoKey.error.rawValue] as? NSError
      else {
        self.updateResultsText(
          "firebaseMLModelDownloadDidFail notification posted without a "
            + "RemoteModel instance or error.")
        return
      }
      self.updateResultsText(
        "Failed to download the remote model with name: " + "\(remoteModel.name), error: \(error).")
    }
    if Thread.isMainThread { notificationHandler();return }
    DispatchQueue.main.async { notificationHandler() }
  }

  // MARK: - Private

  private func setUpRemoteModels() {
    ModelType.allCases.forEach {
      remoteModels[$0] = CustomRemoteModel(name: remoteModelName(for: $0))
    }
  }

  private func setUpLocalModels() {
    ModelType.allCases.forEach {
      let (name, ext) = localModelInfo(for: $0)
      guard let modelPath = Bundle.main.path(forResource: name, ofType: ext) else {
        preconditionFailure("Failed to get the local model file path for model with name: \(name).")
      }
      localModels[$0] = CustomLocalModel(modelPath: modelPath)
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

  /// Updates the results text view with the given text. The default is `nil`, so calling
  /// `updateResultsText()` will clear the results.
  private func updateResultsText(_ text: String? = nil) {
    let updater = { self.resultsTextView.text = text }
    if Thread.isMainThread { updater();return }
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
    @unknown default:
      print("Unrecognized UIInterfaceOrientation.")
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

  private func remoteModelName(for modelType: ModelType) -> String {
    switch modelType {
    case .quantized:
      return "image-classification-quant-v2"
    case .float:
      return "image-classification-float-v2"
    case .invalid:
      return "invalid_model"
    }
  }

  private func localModelInfo(for modelType: ModelType) -> (String, String) {
    switch modelType {
    case .quantized:
      return MobileNet.quantizedModelInfo
    case .float:
      return MobileNet.floatModelInfo
    case .invalid:
      return MobileNet.invalidModelInfo
    }
  }

  private func scaledImageData(
    from image: UIImage,
    with size: CGSize = MobileNet.imageSize,
    isQuantized: Bool = false,
    componentCount: Int = MobileNet.componentCount,
    batchSize: Int = MobileNet.batchSize
  ) -> Data? {
    guard
      let scaledImageData = image.scaledData(
        with: size,
        byteCount: Int(size.width) * Int(size.height) * componentCount * batchSize,
        isQuantized: isQuantized)
    else {
      print("Failed to get scaled image data with size: \(size).")
      return nil
    }
    return scaledImageData
  }

  private func runInference(
    on imageData: Data?,
    modelInterpreter: ModelInterpreter,
    isQuantized: Bool,
    topResultsCount: Int = MobileNet.topResultsCount,
    completion: @escaping DetectObjectsCompletion
  ) {
    guard let imageData = imageData else {
      safeDispatchOnMain {
        completion(nil, ModelInterpreterError.invalidImageData)
      }
      return
    }
    let inputs = ModelInputs()
    let modelElementType: ModelElementType
    let modelInputOutputOptions = ModelInputOutputOptions()
    do {
      try inputs.addInput(imageData)
      modelElementType = isQuantized ? .uInt8 : .float32
      try modelInputOutputOptions.setInputFormat(
        index: MobileNet.inputOutputIndex,
        type: modelElementType,
        dimensions: MobileNet.inputDimensions
      )
      try modelInputOutputOptions.setOutputFormat(
        index: MobileNet.inputOutputIndex,
        type: modelElementType,
        dimensions: MobileNet.outputDimensions
      )
    } catch let error {
      print("Failed to set up the input/output options with error: \(error.localizedDescription)")
      safeDispatchOnMain {
        completion(nil, error)
      }
      return
    }
    modelInterpreter.run(inputs: inputs, options: modelInputOutputOptions) { (outputs, error) in
      guard error == nil, let outputs = outputs else {
        completion(nil, error)
        return
      }
      self.process(
        outputs,
        modelElementType: modelElementType,
        topResultsCount: topResultsCount,
        completion: completion)
    }
  }

  private func process(
    _ outputs: ModelOutputs,
    modelElementType: ModelElementType,
    topResultsCount: Int,
    completion: @escaping DetectObjectsCompletion
  ) {
    let output: [[NSNumber]]?
    do {
      // Get the output for the first batch, since the default batch size is 1.
      output = try outputs.output(index: 0) as? [[NSNumber]]
    } catch let error {
      print("Failed to process detection outputs with error: \(error.localizedDescription)")
      completion(nil, error)
      return
    }

    guard let firstOutput = output?.first else {
      print("Failed to get the results array from output.")
      completion(nil, ModelInterpreterError.invalidResults)
      return
    }

    let confidences: [Float]
    switch modelElementType {
    case .uInt8:
      confidences = firstOutput.map { quantizedValue in
        Softmax.scale * Float(quantizedValue.intValue - Softmax.zeroPoint)
      }
    case .float32:
      confidences = firstOutput.map { $0.floatValue }
    default:
      completion(nil, ModelInterpreterError.invalidModelDataType)
      return
    }

    // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
    let zippedResults = zip(labels.indices, confidences)

    // Sort the zipped results by confidence value in descending order.
    let sortedResults = zippedResults.sorted { $0.1 > $1.1 }.prefix(topResultsCount)

    // Create an array of tuples with the results as [(label: String, confidence: Float)].
    let results = sortedResults.isEmpty ? nil : sortedResults.map { (labels[$0], $1) }
    completion(results, nil)
  }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
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

private enum ModelType: Int, Hashable {
  case quantized = 0
  case float = 1
  case invalid = 2
}

enum ModelInterpreterError: Error {
  case invalidImageData
  case invalidResults
  case invalidModelDataType
}

/// Values for the MobileNet image classification model.
enum MobileNet {
  static let quantizedModelInfo = (name: "mobilenet_quant_v2_1.0_299", extension: "tflite")
  static let floatModelInfo = (name: "mobilenet_float_v2_1.0_299", extension: "tflite")
  static let invalidModelInfo = (name: "mobilenet_v1_1.0_224", extension: "tflite")
  static let labelsInfo = (name: "labels", extension: "txt", count: 1001)
  static let topResultsCount: Int = 5
  static let componentCount: Int = 3
  static let batchSize: Int = 1
  static let imageSize = CGSize(width: 299, height: 299)

  // MARK: - Fileprivate

  fileprivate static let inputOutputIndex: UInt = 0

  fileprivate static let inputDimensions = [
    NSNumber(value: batchSize),
    NSNumber(value: Double(imageSize.width)),
    NSNumber(value: Double(imageSize.height)),
    NSNumber(value: componentCount),
  ]

  fileprivate static let outputDimensions = [
    NSNumber(value: batchSize),
    NSNumber(value: labelsInfo.count),
  ]
}

/// Default quantization parameters for Softmax. The Softmax function is normally implemented as the
/// final layer, just before the output layer, of a neural-network based classifier.
///
/// Quantized values can be mapped to float values using the following conversion:
///   `realValue = scale * (quantizedValue - zeroPoint)`.
enum Softmax {
  static let zeroPoint: Int = 0
  static var scale: Float { return Float(1.0 / (maxUInt8QuantizedValue + normalizerValue)) }

  // MARK: - Private

  private static let maxUInt8QuantizedValue = 255.0
  private static let normalizerValue = 1.0
}

// MARK: - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
fileprivate func safeDispatchOnMain(_ block: @escaping () -> Void) {
  if Thread.isMainThread {
    block()
    return
  }
  DispatchQueue.main.async { block() }
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
  extension ModelType: CaseIterable {}
#else
  extension ModelType {
    static let allCases: [ModelType] = [.quantized, .float, .invalid]
  }
#endif  // swift(>=4.2)
