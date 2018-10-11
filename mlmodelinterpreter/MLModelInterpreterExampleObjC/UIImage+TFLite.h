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

/// Returns image scaled according to the given size.
///
/// - Parameter size: Maximum size of the returned image.
/// - Return: Image scaled according to the give size or `nil` if image resize fails.
- (UIImage *)scaledImageWithSize:(CGSize)size;

/// Returns scaled image data representation of the image from the given values.
///
/// - Parameters
///   - size: Size to scale the image to (i.e. expected size of the image in the trained model).
///   - componentsCount: Number of color components for the image.
///   - batchSize: Batch size for the image.
/// - Returns: The scaled image data or `nil` if the image could not be scaled.
- (NSData *)scaledImageDataWithSize:(CGSize)size
                    componentsCount:(int)newComponentsCount
                          batchSize:(int)batchSize;

/// Returns a scaled pixel array representation of the image from the given values.
///
/// - Parameters
///   - size: Size to scale the image to (i.e. expected size of the image in the trained model).
///   - componentsCount: Number of color components for the image.
///   - batchSize: Batch size for the image.
///   - isQuantized: Indicates whether the model uses quantization. If `true`, apply
///     `(value) / 255` to each pixel to convert the data from Int(0, 255) scale to
///     Float([0, 1]).
/// - Returns: The scaled pixel array or `nil` if the image could not be scaled.
- (NSArray *)scaledPixelArrayWithSize:(CGSize)size
                      componentsCount:(int)newComponentsCount
                            batchSize:(int)batchSize
                          isQuantized:(BOOL)isQuantized;

@end

