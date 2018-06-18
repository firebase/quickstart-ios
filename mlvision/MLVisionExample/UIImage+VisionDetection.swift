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
import UIKit

/// A `UIImage` category used for vision detection.
extension UIImage {
  /// Returns a scaled image to the given size.
  ///
  /// - Parameter size: Maximum size of the returned image.
  /// - Return: Image scaled according to the give size or `nil` if image resize fails.
  public func scaledImage(withSize size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    // Attempt to convert the scaled image to PNG or JPEG data to preserve the bitmap info.
    guard let image = scaledImage else { return nil }
    let imageData = UIImagePNGRepresentation(image) ??
      UIImageJPEGRepresentation(image, Constants.jpegCompressionQuality)
    return imageData.map { UIImage(data: $0) } ?? nil
  }
}

// MARK: - Constants

private enum Constants {
  static let jpegCompressionQuality: CGFloat = 0.8
}
