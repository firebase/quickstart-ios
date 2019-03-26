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
import FirebaseMLModelInterpreter

/// Defines the requirements for managing remote and local models.
public protocol ModelManaging {

  /// Returns a Bool indicating whether the remote model was successfully registered or had already
  /// been registered.
  func register(_ remoteModel: RemoteModel) -> Bool

  /// Returns a Bool indicating whether the local model was successfully registered or had already
  /// been registered.
  func register(_ localModel: LocalModel) -> Bool
}

public enum ModelInterpreterError: Error {
  case invalidImageData
  case invalidResults
  case invalidModelDataType
}

/// Values for the MobileNet image classification model.
public enum MobileNet {

  // MARK: - Public

  public static let quantizedModelInfo = (name: "mobilenet_quant_v2_1.0_299", extension: "tflite")
  public static let floatModelInfo = (name: "mobilenet_float_v2_1.0_299", extension: "tflite")
  public static let invalidModelInfo = (name: "mobilenet_v1_1.0_224", extension: "tflite")
  public static let labelsInfo = (name: "labels", extension: "txt", count: 1001)
  public static let topResultsCount: Int = 5
  public static let componentCount: Int = 3
  public static let batchSize: Int = 1
  public static let imageSize = CGSize(width: 299, height: 299)

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
    NSNumber(value: labelsInfo.count)
  ]
}

public class ModelInterpreterManager {

  public typealias DetectObjectsCompletion = ([(label: String, confidence: Float)]?, Error?) -> Void

  private let modelManager: ModelManaging
  private let modelInputOutputOptions = ModelInputOutputOptions()
  private var registeredRemoteModelNames = Set<String>()
  private var registeredLocalModelNames = Set<String>()
  private var remoteModelOptions: ModelOptions?
  private var localModelOptions: ModelOptions?
  private var modelInterpreter: ModelInterpreter?
  private var modelElementType: ModelElementType = .uInt8
  private var labels = [String]()

  /// Creates a new instance with the given object that conforms to `ModelManaging`.
  public init(modelManager: ModelManaging = ModelManager.modelManager()) {
    self.modelManager = modelManager
  }

  // Sets up a remote model by creating a `RemoteModel` and registering it with the given name.
  ///
  /// - Parameters:
  ///   - name: The name for the remote model.
  /// - Returns: `Bool` indicating whether the remote model was successfully set up and registered.
  public func setUpRemoteModel(name: String) -> Bool {
    let conditions = ModelDownloadConditions(
      allowsCellularAccess: true,
      allowsBackgroundDownloading: true
    )
    let remoteModel = RemoteModel(
      name: name,
      allowsModelUpdates: true,
      initialConditions: conditions,
      updateConditions: conditions
    )
    guard registeredRemoteModelNames.contains(name) || modelManager.register(remoteModel) else {
      print("Failed to register the remote model with name: \(name)")
      return false
    }
    remoteModelOptions = ModelOptions(remoteModelName: name, localModelName: nil)
    registeredRemoteModelNames.insert(name)
    return true
  }

  /// Sets up a local model by creating a `LocalModel` and registering it with the given name.
  ///
  /// - Parameters:
  ///   - name: The name for the local model.
  ///   - filename: The name for the local model file.
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the local model was successfully set up and registered.
  public func setUpLocalModel(name: String, filename: String, bundle: Bundle = .main) -> Bool {
    guard let localModelFilePath = bundle.path(
      forResource: filename,
      ofType: MobileNet.quantizedModelInfo.extension)
      else {
        print("Failed to get the local model file path.")
        return false
    }
    let localModel = LocalModel(name: name, path: localModelFilePath)
    guard registeredLocalModelNames.contains(name) || modelManager.register(localModel) else {
      print("Failed to register the local model with name: \(name)")
      return false
    }
    localModelOptions = ModelOptions(remoteModelName: nil, localModelName: name)
    registeredLocalModelNames.insert(name)
    return true
  }

  /// Loads the registered remote model with the `ModelOptions` created during setup and the given
  /// input and output dimensions.
  ///
  /// - Parameters:
  ///   - isModelQuantized: Indicates if the model is quantized. The default is `false`.
  ///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
  ///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
  ///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
  ///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the remote model was successfully loaded.
  public func loadRemoteModel(
    isModelQuantized: Bool = false,
    inputDimensions: [NSNumber]? = nil,
    outputDimensions: [NSNumber]? = nil,
    bundle: Bundle = .main
    ) -> Bool {
    guard let remoteModelOptions = remoteModelOptions else {
      print("Failed to load the remote model because the options are nil.")
      return false
    }
    return loadModel(
      options: remoteModelOptions,
      isModelQuantized: isModelQuantized,
      inputDimensions: inputDimensions,
      outputDimensions: outputDimensions,
      bundle: bundle
    )
  }

  /// Loads the registered local model with the `ModelOptions` created during setup and the given
  /// input and output dimensions.
  ///
  /// - Parameters:
  ///   - isModelQuantized: Indicates if the model is quantized. The default is `false`.
  ///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
  ///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
  ///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
  ///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the local model was successfully loaded.
  public func loadLocalModel(
    isModelQuantized: Bool = false,
    inputDimensions: [NSNumber]? = nil,
    outputDimensions: [NSNumber]? = nil,
    bundle: Bundle = .main
    ) -> Bool {
    guard let localModelOptions = localModelOptions else {
      print("Failed to load the local model because the options are nil.")
      return false
    }
    return loadModel(
      options: localModelOptions,
      isModelQuantized: isModelQuantized,
      inputDimensions: inputDimensions,
      outputDimensions: outputDimensions,
      bundle: bundle
    )
  }

  /// Detects objects in the given image data, represented as `Data`. The completion is called with
  /// detection results as an array of tuples where each tuple contains a label and confidence
  /// value.
  ///
  /// - Parameters
  ///   - imageData: The data  representation of the image to detect objects in.
  ///   - topResultsCount: The number of top results to return.
  ///   - completion: The handler to be called on the main thread with detection results or error.
  public func detectObjects(
    in imageData: Data?,
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
    do {
      try inputs.addInput(imageData)
    } catch let error {
      print("Failed to add the image data input with error: \(error.localizedDescription)")
      safeDispatchOnMain {
        completion(nil, error)
      }
      return
    }
    modelInterpreter?.run(inputs: inputs, options: modelInputOutputOptions) { (outputs, error) in
      guard error == nil, let outputs = outputs else {
        completion(nil, error)
        return
      }
      self.process(outputs, topResultsCount: topResultsCount, completion: completion)
    }
  }

  /// Returns the data representation of the given image scaled to the given image size that the
  /// model was trained on.
  ///
  /// - Parameters:
  ///   - image: The image to scale.
  ///   - size: The size to scale the image to. The default is `MobileNet.imageSize`.
  ///   - componentCount: The number of components in the scaled image. A component is a red, green,
  ///       blue, or alpha value. The default value is 3, indicating that the model was trained on
  ///       an image that contains only RGB components (i.e. the alpha component was removed).
  ///   - batchSize: The fixed number of examples in a batch. The default is 1.
  /// - Returns: The scaled image as `Data` or `nil` if the image could not be scaled.
  public func scaledImageData(
    from image: UIImage,
    with size: CGSize = MobileNet.imageSize,
    componentCount: Int = MobileNet.componentCount,
    batchSize: Int = MobileNet.batchSize
    ) -> Data? {
    guard let scaledImageData = image.scaledData(
      with: size,
      byteCount: Int(size.width) * Int(size.height) * componentCount * batchSize,
      isQuantized: (modelElementType == .uInt8))
      else {
        print("Failed to get scaled image data with size: \(size).")
        return nil
    }
    return scaledImageData
  }

  // MARK: - Private

  /// Loads a model with the given options and input and output dimensions.
  ///
  /// - Parameters:
  ///   - options: The model options consisting of the remote and/or local models to be loaded.
  ///   - isModelQuantized: Whether the model uses quantization (i.e. 8-bit fixed point weights and
  ///     activations). See https://www.tensorflow.org/performance/quantization for more details. If
  ///     false, a floating point model is used.
  ///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
  ///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
  ///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
  ///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the model was successfully loaded. If both local and
  ///     remote models were provided in the `ModelOptions`, the remote model takes priority and is
  ///     loaded. If the remote model has not been downloaded yet from the Firebase console, the
  ///     model download request is created and the local model is loaded as a fallback.
  private func loadModel(
    options: ModelOptions,
    isModelQuantized: Bool,
    inputDimensions: [NSNumber]? = nil,
    outputDimensions: [NSNumber]? = nil,
    bundle: Bundle = .main
    ) -> Bool {
    guard (inputDimensions != nil && outputDimensions != nil) ||
      (inputDimensions == nil && outputDimensions == nil)
      else {
        print("Invalid input and output dimensions provided.")
        return false
    }

    do {
      guard let labelsPath = bundle.path(
        forResource: MobileNet.labelsInfo.name,
        ofType: MobileNet.labelsInfo.extension)
        else {
          print("Failed to get the labels file path.")
          return false
      }
      let contents = try String(contentsOfFile: labelsPath, encoding: .utf8)
      labels = contents.components(separatedBy: CharacterSet.newlines)
      modelInterpreter = ModelInterpreter.modelInterpreter(options: options)
      modelElementType = isModelQuantized ? .uInt8 : .float32
      let modelInputDimensions = inputDimensions ?? MobileNet.inputDimensions
      try modelInputOutputOptions.setInputFormat(
        index: MobileNet.inputOutputIndex,
        type: modelElementType,
        dimensions: modelInputDimensions
      )
      let modelOutputDimensions = outputDimensions ?? MobileNet.outputDimensions
      try modelInputOutputOptions.setOutputFormat(
        index: MobileNet.inputOutputIndex,
        type: modelElementType,
        dimensions: modelOutputDimensions
      )
    } catch let error {
      print("Failed to load the model with error: \(error.localizedDescription)")
      return false
    }
    return true
  }

  private func process(
    _ outputs: ModelOutputs,
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

// MARK: - Internal

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

// MARK: - ModelManaging

extension ModelManager: ModelManaging {}

// MARK: - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
fileprivate func safeDispatchOnMain(_ block: @escaping () -> Void) {
  if Thread.isMainThread { block(); return }
  DispatchQueue.main.async { block() }
}
