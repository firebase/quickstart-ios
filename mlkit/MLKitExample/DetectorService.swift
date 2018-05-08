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

public enum DetectorError: Int, CustomNSError {
  case failedToDetectObjectsInvalidImage = 1
  case failedToDetectObjectsInvalidResults = 2

  // MARK: - CustomNSError

  public static var errorDomain: String { return "com.google.firebaseml.sampleapp.detectorservice" }
  public var errorCode: Int { return rawValue }
  public var errorUserInfo: [String: Any] { return [:] }
}

public enum DetectorConstants {

  // MARK: - Public

  public static let modelExtension = "tflite"
  public static let labelsExtension = "txt"

  public static let topResultsCount: Int = 5

  // MARK: - Fileprivate

  fileprivate static let labelsSeparator = "\n"

  fileprivate static let modelInputIndex: UInt = 0

  fileprivate static let dimensionBatchSize: NSNumber = 1
  fileprivate static let dimensionImageWidth: NSNumber = 224
  fileprivate static let dimensionImageHeight: NSNumber = 224
  fileprivate static let dimensionComponents: NSNumber = 3

  fileprivate static let inputDimensions = [
    dimensionBatchSize,
    dimensionImageWidth,
    dimensionImageHeight,
    dimensionComponents,
    ]

  fileprivate static let unsupportedElementByteSize: Int = 0
  fileprivate static let maxRGBValue: Float32 = 255.0
}

public class DetectorService: NSObject {

  public typealias DetectObjectsCompletion = ([(label: String, confidence: Float)]?, Error?) -> Void

  let modelInputOutputOptions = ModelInputOutputOptions()
  var modelInterpreter: ModelInterpreter?
  var modelElementType: ModelElementType = .uInt8
  var isModelQuantized = true
  var modelInputDimensions = DetectorConstants.inputDimensions
  var modelOutputDimensions = [NSNumber]()
  var labels = [String]()

  /// Loads a model with the given options and labels path.
  ///
  /// - Parameters:
  ///   - options: The model options containing the source(s) to load.
  ///   - labelsPath: The labels file path.
  ///   - isQuantized: Indicates whether the model uses quantization (i.e. 8-bit fixed point
  ///     weights and activations). See https://www.tensorflow.org/performance/quantization for more
  ///     details. If false, a floating point model is used. The default is `true`.
  ///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
  ///     if `inputDimensions` are specified.
  ///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
  ///     if `outputDimensions` are specified.
  public func loadModel(
    options: ModelOptions,
    labelsPath: String,
    isQuantized: Bool = true,
    inputDimensions: [NSNumber]? = nil,
    outputDimensions: [NSNumber]? = nil
    ) {
    guard (inputDimensions != nil && outputDimensions != nil) ||
      (inputDimensions == nil && outputDimensions == nil)
      else {
        print("Invalid input and output dimensions provided.")
        return
    }

    isModelQuantized = isQuantized
    if let inputDimensions = inputDimensions {
      modelInputDimensions = inputDimensions
    }

    do {
      let encoding = String.Encoding.utf8.rawValue
      let contents = try NSString(contentsOfFile: labelsPath, encoding: encoding)
      labels = contents.components(separatedBy: DetectorConstants.labelsSeparator)
      if let outputDimensions = outputDimensions {
        modelOutputDimensions = outputDimensions
      } else {
        modelOutputDimensions = [
          DetectorConstants.dimensionBatchSize,
          NSNumber(value: labels.count),
        ]
      }
      modelInterpreter = ModelInterpreter(options: options)
      modelElementType = isModelQuantized ? .uInt8 : .float32
      try modelInputOutputOptions.setInputFormat(
        index: DetectorConstants.modelInputIndex,
        type: modelElementType,
        dimensions: modelInputDimensions
      )
      try modelInputOutputOptions.setOutputFormat(
        index: DetectorConstants.modelInputIndex,
        type: modelElementType,
        dimensions: modelOutputDimensions
      )
    } catch let error as NSError {
      fatalError("Failed to load model with error: \(error.localizedDescription)")
    }
  }

  /// Gets the results from detecting objects from the given image data.
  ///
  /// - Parameters
  ///   - imageData: The data representation of the image to detect objects in.
  ///   - topResultsCount: The number of top results to return.
  ///   - completion: The handler to be called on the main thread with detection results or error.
  public func detectObjects(
    imageData: [Any]?,
    topResultsCount: Int = DetectorConstants.topResultsCount,
    completion: @escaping DetectObjectsCompletion
    ) {
    guard let imageData = imageData else {
      safeDispatchOnMain {
        completion(nil, DetectorError.failedToDetectObjectsInvalidImage)
      }
      return
    }
    let inputs = ModelInputs()
    do {
      // Add the image data as the model input.
      try inputs.addInput(imageData)
    } catch let error as NSError {
      print("Failed to detect objects with error: \(error.localizedDescription)")
      safeDispatchOnMain {
        completion(nil, error)
      }
      return
    }

    // Run the interpreter for the model with the given input.
    modelInterpreter?.run(inputs: inputs, options: modelInputOutputOptions) { (outputs, error) in
      guard error == nil, let outputs = outputs else {
        completion(nil, error)
        return
      }
      self.process(outputs, topResultsCount: topResultsCount, completion: completion)
    }
  }

  /// Returns scaled image data for the given image.
  ///
  /// - Parameters:
  ///   - image: The image to scale.
  /// - Returns: The scaled image data or `nil` if the image could not be scaled.
  public func scaledImageData(for image: UIImage?) -> [Any]? {
    let imageWidth = DetectorConstants.dimensionImageWidth.intValue
    let imageHeight = DetectorConstants.dimensionImageHeight.intValue
    let scaledImageSize = CGSize(width: imageWidth, height: imageHeight)
    guard let scaledImageData = image?.scaledImageData(
      with: scaledImageSize,
      componentsCount: DetectorConstants.dimensionComponents.intValue,
      batchSize: DetectorConstants.dimensionBatchSize.intValue,
      isQuantized: isModelQuantized
      ) else {
        print("Failed to scale image to size \(scaledImageSize).")
        return nil
    }
    return scaledImageData
  }

  // MARK: - Private

  private func process(
    _ outputs: ModelOutputs,
    topResultsCount: Int,
    completion: @escaping DetectObjectsCompletion
    ) {
    let outputArrayOfArrays: Any
    do {
      // Get the output for the first and only batch as batch size is 1.
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
        completion(nil, DetectorError.failedToDetectObjectsInvalidResults)
        return
    }

    // Convert the output from quantized 8-bit fixed point format to 32-bit floating point format.
    if isModelQuantized {
      outputArray = outputArray.map {
        NSNumber(value: Float32($0.int32Value & 0xff) / DetectorConstants.maxRGBValue)
      }
    }

    // Create a an array of indices that map to each label in the labels text file.
    let labelsCount = modelOutputDimensions[1].intValue
    var indexesArray = [Int](repeating: 0, count: labelsCount)
    for index in 0..<labelsCount {
      indexesArray[index] = index
    }

    // Create a zipped array of tuples ("confidence" as NSNumber, "labelIndex" as Int).
    let zippedArray = zip(outputArray, indexesArray)

    // Sort the zipped array of confidence values in ascending order.
    var sortedResults = zippedArray.sorted {
      ($0 as (NSNumber, Int)).0.floatValue > ($1 as (NSNumber, Int)).0.floatValue
    }

    // Resize the sorted results array to match the `topResultsCount`.
    sortedResults = Array(sortedResults.prefix(topResultsCount))

    // Create an array of results [("label" as String, "confidence" as Float)].
    let results = sortedResults.map { result -> (String, Float) in
      let (confidence, labelIndex) = result
      return (labels[labelIndex], confidence.floatValue)
    }
    completion(results, nil)
  }
}

// MARK: - Fileprivate

fileprivate func safeDispatchOnMain(_ block: @escaping () -> Void) {
  if Thread.isMainThread {
    block()
  } else {
    DispatchQueue.main.async {
      block()
    }
  }
}
