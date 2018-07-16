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
import FirebaseMLModelInterpreter

/// Defines the requirements for managing cloud and local models.
public protocol ModelManaging {

  /// Returns a Bool indicating whether the cloud model source was successfully registered or had
  /// already been registered.
  func register(_ cloudModelSource: CloudModelSource) -> Bool

  /// Returns a Bool indicating whether the local model source was successfully registered or had
  /// already been registered.
  func register(_ localModelSource: LocalModelSource) -> Bool
}

public enum ModelInterpreterError: Int, CustomNSError {
  case invalidImageData = 1
  case invalidResults = 2

  // MARK: - CustomNSError

  public static var errorDomain: String {
    return "com.google.firebaseml.sampleapps.modelinterpreter"
  }

  public var errorCode: Int { return rawValue }
  public var errorUserInfo: [String: Any] { return [:] }
}

public enum ModelInterpreterConstants {

  // MARK: - Public

  public static let modelExtension = "tflite"
  public static let labelsExtension = "txt"
  public static let topResultsCount: Int = 5
  public static let dimensionComponents: NSNumber = 3

  // MARK: - Fileprivate

  fileprivate static let labelsSeparator = "\n"
  fileprivate static let labelsFilename = "labels"
  fileprivate static let modelFilename = "mobilenet_v1_1.0_224"
  fileprivate static let quantizedLabelsFilename = "labels_quant"
  fileprivate static let quantizedModelFilename = "mobilenet_quant_v1_224"

  fileprivate static let modelInputIndex: UInt = 0
  fileprivate static let dimensionBatchSize: NSNumber = 1
  fileprivate static let dimensionImageWidth: NSNumber = 224
  fileprivate static let dimensionImageHeight: NSNumber = 224
  fileprivate static let maxRGBValue: Float32 = 255.0

  fileprivate static let inputDimensions = [
    dimensionBatchSize,
    dimensionImageWidth,
    dimensionImageHeight,
    dimensionComponents,
  ]
}

public class ModelInterpreterManager {

  public typealias DetectObjectsCompletion = ([(label: String, confidence: Float)]?, Error?) -> Void

  private let modelManager: ModelManaging
  private let modelInputOutputOptions = ModelInputOutputOptions()
  private var registeredCloudModelNames = Set<String>()
  private var registeredLocalModelNames = Set<String>()
  private var cloudModelOptions: ModelOptions?
  private var localModelOptions: ModelOptions?
  private var modelInterpreter: ModelInterpreter?
  private var modelElementType: ModelElementType = .uInt8
  private var isModelQuantized = true
  private var labels = [String]()
  private var labelsCount: Int = 0

  /// Creates a new instance with the given object that conforms to `ModelManaging`.
  public init(modelManager: ModelManaging = ModelManager.modelManager()) {
    self.modelManager = modelManager
  }

  /// Sets up a cloud model by creating a `CloudModelSource` and registering it with the given name.
  ///
  /// - Parameters:
  ///   - name: The name for the cloud model.
  /// - Returns: A `Bool` indicating whether the cloud model was successfully set up and registered.
  public func setUpCloudModel(withName name: String) -> Bool {
    let conditions = ModelDownloadConditions(isWiFiRequired: false, canDownloadInBackground: true)
    let cloudModelSource = CloudModelSource(
      modelName: name,
      enableModelUpdates: true,
      initialConditions: conditions,
      updateConditions: conditions
    )
    guard registeredCloudModelNames.contains(name) || modelManager.register(cloudModelSource) else {
      print("Failed to register the cloud model source with name: \(name)")
      return false
    }
    cloudModelOptions = ModelOptions(cloudModelName: name, localModelName: nil)
    registeredCloudModelNames.insert(name)
    return true
  }

  /// Sets up a local model by creating a `LocalModelSource` and registering it with the given name.
  ///
  /// - Parameters:
  ///   - name: The name for the local model.
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the local model was successfully set up and registered.
  public func setUpLocalModel(withName name: String, bundle: Bundle = .main) -> Bool {
    guard let localModelFilePath = bundle.path(
            forResource: ModelInterpreterConstants.quantizedModelFilename,
            ofType: ModelInterpreterConstants.modelExtension)
    else {
      print("Failed to get the local model file path.")
      return false
    }
    let localModelSource = LocalModelSource(
      modelName: name,
      path: localModelFilePath
    )
    guard registeredLocalModelNames.contains(name) || modelManager.register(localModelSource) else {
      print("Failed to register the local model source with name: \(name)")
      return false
    }
    localModelOptions = ModelOptions(cloudModelName: nil, localModelName: name)
    registeredLocalModelNames.insert(name)
    return true
  }

  /// Loads the registered cloud model with the `ModelOptions` created during setup.
  ///
  /// - Parameters:
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the cloud model was successfully loaded.
  public func loadCloudModel(bundle: Bundle = .main) -> Bool {
    guard let cloudModelOptions = cloudModelOptions else {
      print("Failed to load the cloud model because the options are nil.")
      return false
    }
    return loadModel(options: cloudModelOptions, bundle: bundle)
  }

  /// Loads the registered local model with the `ModelOptions` created during setup.
  ///
  /// - Parameters:
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the local model was successfully loaded.
  public func loadLocalModel(bundle: Bundle = .main) -> Bool {
    guard let localModelOptions = localModelOptions else {
      print("Failed to load the local model because the options are nil.")
      return false
    }
    return loadModel(options: localModelOptions, bundle: bundle)
  }

  /// Detects objects in the given image data, represented as `Data` or an array of pixel values.
  /// The completion is called with detection results as an array of tuples where each tuple
  /// contains a label and confidence value.
  ///
  /// - Parameters
  ///   - imageData: The data or pixel array representation of the image to detect objects in.
  ///   - topResultsCount: The number of top results to return.
  ///   - completion: The handler to be called on the main thread with detection results or error.
  public func detectObjects(
    in imageData: Any?,
    topResultsCount: Int = ModelInterpreterConstants.topResultsCount,
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
      // Add the image data to the model input.
      try inputs.addInput(imageData)
    } catch let error as NSError {
      print("Failed to add the image data input with error: \(error.localizedDescription)")
      safeDispatchOnMain {
        completion(nil, error)
      }
      return
    }

    // Run the interpreter for the model with the given inputs.
    modelInterpreter?.run(inputs: inputs, options: modelInputOutputOptions) { (outputs, error) in
      guard error == nil, let outputs = outputs else {
        completion(nil, error)
        return
      }
      self.process(outputs, topResultsCount: topResultsCount, completion: completion)
    }
  }

  /// Scales the given image to the default size that the model was trained on.
  ///
  /// - Parameters:
  ///   - image: The image to scale.
  ///   - componentsCount: The number of components in the scaled image. A component is a red,
  ///       green, blue, or alpha value. The default value is 3, indicating that the model was
  ///       trained on an image that contains only RGB components (i.e. the alpha component was
  ///       removed).
  /// - Returns: The scaled image as `Data` or `nil` if the image could not be scaled. Scaling can
  ///     fail for the following reasons: 1) components count is not less than or equal to the
  ///     components count of the given image 2) the given image's size or CGImage is invalid.
  public func scaledImageData(
    from image: UIImage,
    componentsCount: Int = ModelInterpreterConstants.dimensionComponents.intValue
  ) -> Data? {
    let imageWidth = ModelInterpreterConstants.dimensionImageWidth.doubleValue
    let imageHeight = ModelInterpreterConstants.dimensionImageHeight.doubleValue
    let imageSize = CGSize(width: imageWidth, height: imageHeight)
    guard let scaledImageData = image.scaledImageData(
            with: imageSize,
            componentsCount: componentsCount,
            batchSize: ModelInterpreterConstants.dimensionBatchSize.intValue)
    else {
      print("Failed to scale image to size: \(imageSize).")
      return nil
    }
    return scaledImageData
  }

  /// Scales the given image to the default size that the model was trained on.
  ///
  /// - Parameters:
  ///   - image: The image to scale.
  ///   - componentsCount: The number of components in the scaled image. A component is a red,
  ///       green, blue, or alpha value. The default value is 3, indicating that the model was
  ///       trained on an image that contains only RGB components (i.e. the alpha component was
  ///       removed).
  ///   - isQuantized: Whether the model uses quantization (i.e. 8-bit fixed point weights and
  ///       activations). See https://www.tensorflow.org/performance/quantization for more details.
  ///       If false, a floating point model is used. The default is `true`.
  /// - Returns: A multidimensional array of fixed point (`UInt8`) values, if `isQuantized` is true,
  ///     or floating point (`Float32`) values, if `isQuantized` is false, or `nil` if the image
  ///     could not be scaled. The returned pixel array contains an array of horizontal pixels with
  ///     a count equal to the default width of the image. Each horizontal pixel contains of an
  ///     array of veritcal pixels with a count equal to the default height of the image. Each
  ///     horizontal pixel contains an array of the components with a count equal to the given
  ///     `componentsCount`. Scaling can fail for the following reasons: 1) components count is not
  ///     less than or equal to the components count of the given image 2) the given image's size or
  ///     CGImage is invalid.
  public func scaledPixelArray(
    from image: UIImage,
    componentsCount: Int = ModelInterpreterConstants.dimensionComponents.intValue,
    isQuantized: Bool = true
  ) -> [[[[Any]]]]? {
    let imageWidth = ModelInterpreterConstants.dimensionImageWidth.doubleValue
    let imageHeight = ModelInterpreterConstants.dimensionImageHeight.doubleValue
    let imageSize = CGSize(width: imageWidth, height: imageHeight)
    guard let scaledPixelArray = image.scaledPixelArray(
            with: imageSize,
            componentsCount: componentsCount,
            batchSize: ModelInterpreterConstants.dimensionBatchSize.intValue,
            isQuantized: isQuantized)
    else {
      print("Failed to scale image to size: \(imageSize).")
      return nil
    }
    return scaledPixelArray
  }

  // MARK: - Private

  /// Loads a model with the given options and input and output dimensions.
  ///
  /// - Parameters:
  ///   - options: The model options consisting of the cloud and/or local sources to be loaded.
  ///   - isQuantized: Whether the model uses quantization (i.e. 8-bit fixed point weights and
  ///     activations). See https://www.tensorflow.org/performance/quantization for more details. If
  ///     false, a floating point model is used. The default is `true`.
  ///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
  ///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
  ///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
  ///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
  ///   - bundle: The bundle to load model resources from. The default is the main bundle.
  /// - Returns: A `Bool` indicating whether the model was successfully loaded. If both local and
  ///     cloud model sources were provided in the `ModelOptions`, the cloud model takes priority
  ///     and is loaded. If the cloud model has not been downloaded yet from the Firebase console,
  ///     the model download request is created and the local model is loaded as a fallback.
  private func loadModel(
    options: ModelOptions,
    isQuantized: Bool = true,
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

    isModelQuantized = isQuantized

    do {
      let encoding = String.Encoding.utf8.rawValue
      guard let labelsFilePath = bundle.path(
              forResource: ModelInterpreterConstants.quantizedLabelsFilename,
              ofType: ModelInterpreterConstants.labelsExtension)
      else {
        print("Failed to get the labels file path.")
        return false
      }
      let contents = try NSString(contentsOfFile: labelsFilePath, encoding: encoding)
      labels = contents.components(separatedBy: ModelInterpreterConstants.labelsSeparator)
      labelsCount = labels.count
      let modelOutputDimensions = outputDimensions ?? [
          ModelInterpreterConstants.dimensionBatchSize,
          NSNumber(value: labelsCount),
        ]
      modelInterpreter = ModelInterpreter.modelInterpreter(options: options)
      modelElementType = isModelQuantized ? .uInt8 : .float32
      let modelInputDimensions = inputDimensions ?? ModelInterpreterConstants.inputDimensions
      try modelInputOutputOptions.setInputFormat(
        index: ModelInterpreterConstants.modelInputIndex,
        type: modelElementType,
        dimensions: modelInputDimensions
      )
      try modelInputOutputOptions.setOutputFormat(
        index: ModelInterpreterConstants.modelInputIndex,
        type: modelElementType,
        dimensions: modelOutputDimensions
      )
    } catch let error as NSError {
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
    let outputArrayOfArrays: Any
    do {
      // Get the output for the first batch, since `dimensionBatchSize` is 1.
      outputArrayOfArrays = try outputs.output(index: 0)
    } catch let error as NSError {
      print("Failed to process detection outputs with error: \(error.localizedDescription)")
      completion(nil, error)
      return
    }

    // Get the first output from the array of output arrays.
    guard let outputNSArray = outputArrayOfArrays as? NSArray,
          let firstOutputNSArray = outputNSArray.firstObject as? NSArray,
          var outputArray = firstOutputNSArray as? [NSNumber]
    else {
      print("Failed to get the results array from output.")
      completion(nil, ModelInterpreterError.invalidResults)
      return
    }

    // Convert the output from quantized 8-bit fixed point format to 32-bit floating point format.
    if isModelQuantized {
      outputArray = outputArray.map {
        NSNumber(value: $0.floatValue / ModelInterpreterConstants.maxRGBValue)
      }
    }

    // Create an array of indices that map to each label in the labels text file.
    var indexesArray = [Int](repeating: 0, count: labelsCount)
    for index in 0..<labelsCount {
      indexesArray[index] = index
    }

    // Create a zipped array of tuples ("confidence" as NSNumber, "labelIndex" as Int).
    let zippedArray = zip(outputArray, indexesArray)

    // Sort the zipped array of tuples ("confidence" as NSNumber, "labelIndex" as Int) by confidence
    // value in ascending order.
    var sortedResults = zippedArray.sorted {
      let confidenceValue1 = ($0 as (NSNumber, Int)).0
      let confidenceValue2 = ($1 as (NSNumber, Int)).0
      return confidenceValue1.floatValue > confidenceValue2.floatValue
    }

    // Resize the sorted results array to match the `topResultsCount`.
    sortedResults = Array(sortedResults.prefix(topResultsCount))

    // Create an array of tuples with the results as [("label" as String, "confidence" as Float)].
    let results = sortedResults.map { (confidence, labelIndex) -> (String, Float) in
      return (labels[labelIndex], confidence.floatValue)
    }
    completion(results, nil)
  }
}

// MARK: - ModelManaging

extension ModelManager: ModelManaging {}

// MARK: - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
fileprivate func safeDispatchOnMain(_ block: @escaping () -> Void) {
  if Thread.isMainThread {
    block()
  } else {
    DispatchQueue.main.async {
      block()
    }
  }
}
