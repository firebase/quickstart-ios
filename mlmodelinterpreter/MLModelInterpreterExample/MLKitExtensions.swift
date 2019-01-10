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

import CoreGraphics
import Foundation
import UIKit

// MARK: - UIImage

extension UIImage {

  /// Creates and returns a new image scaled to the given size. The image preserves its original PNG
  /// or JPEG bitmap info.
  ///
  /// - Parameter size: The size to scale the image to.
  /// - Returns: The scaled image or `nil` if image could not be resized.
  public func scaledImage(with size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: size))
    return UIGraphicsGetImageFromCurrentImageContext()?.data.flatMap(UIImage.init)
  }

  /// Returns the data representation of the image after scaling to the given `size` and removing
  /// the alpha component.
  ///
  /// - Parameters
  ///   - size: Size to scale the image to (i.e. image size used while training the model).
  ///   - byteCount: The expected byte count for the scaled image data calculated using the values
  ///       that the model was trained on: `imageWidth * imageHeight * componentsCount * batchSize`.
  ///   - isQuantized: Whether the model is quantized (i.e. fixed point values rather than floating
  ///       point values).
  /// - Returns: The scaled image as data or `nil` if the image could not be scaled.
  public func scaledData(with size: CGSize, byteCount: Int, isQuantized: Bool) -> Data? {
    guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
    guard let imageData = imageData(from: cgImage, with: size) else { return nil }
    var scaledBytes = [UInt8](repeating: 0, count: byteCount)
    var index = 0
    for component in imageData.enumerated() {
      let offset = component.offset
      let isAlphaComponent =
        (offset % Constant.alphaComponent.baseOffset) == Constant.alphaComponent.moduloRemainder
      guard !isAlphaComponent else { continue }
      scaledBytes[index] = component.element
      index += 1
    }
    if isQuantized { return Data(bytes: scaledBytes) }
    let scaledFloats = scaledBytes.map { Float32($0) / Constant.maxRGBValue }
    return Data(copyingBufferOf: scaledFloats)
  }

  // MARK: - Private

  /// The PNG or JPEG data representation of the image or `nil` if the conversion failed.
  private var data: Data? {
    #if swift(>=4.2)
    return self.pngData() ?? self.jpegData(compressionQuality: Constant.jpegCompressionQuality)
    #else
    return UIImagePNGRepresentation(self) ??
    UIImageJPEGRepresentation(self, Constant.jpegCompressionQuality)
    #endif  // swift(>=4.2)
  }

  /// Returns the image data for the given CGImage based on the given `size`.
  private func imageData(from cgImage: CGImage, with size: CGSize) -> Data? {
    let bitmapInfo = CGBitmapInfo(
      rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    )
    let width = Int(size.width)
    let scaledBytesPerRow = (cgImage.bytesPerRow / cgImage.width) * width
    guard let context = CGContext(
      data: nil,
      width: width,
      height: Int(size.height),
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: scaledBytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo.rawValue)
      else {
        return nil
    }
    context.draw(cgImage, in: CGRect(origin: .zero, size: size))
    return context.makeImage()?.dataProvider?.data as Data?
  }
}

// MARK: - Data

extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }
}

// MARK: - Constants

private enum Constant {
  static let jpegCompressionQuality: CGFloat = 0.8
  static let alphaComponent = (baseOffset: 4, moduloRemainder: 3)
  static let maxRGBValue: Float32 = 255.0
}
