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

#import <UIKit/UIKit.h>

/// A `UIImage` category for scaling images.
@interface UIImage (TFLite)

/// Creates and returns a new image scaled to the given size. The image preserves its original PNG
/// or JPEG bitmap info.
///
/// - Parameter size: The size to scale the image to.
/// - Returns: The scaled image or `nil` if image could not be resized.
- (UIImage *)scaledImageWithSize:(CGSize)size;

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
- (nullable NSData *)scaledDataWithSize:(CGSize)size
                     byteCount:(int)byteCount
                   isQuantized:(BOOL)isQuantized;
@end
