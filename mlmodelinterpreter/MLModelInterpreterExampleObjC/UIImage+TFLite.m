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

#import "UIImage+TFLite.h"

static Float32 const maxRGBValue = 255.0;
static CGFloat const jpegCompressionQuality = 0.8;
static int const alphaComponentBaseOffset = 4;
static int const alphaComponentModuloRemainder = 3;

@implementation UIImage (TFLite)

- (UIImage *)scaledImageWithSize:(CGSize)size {
  UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
  [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // Attempt to convert the scaled image to PNG or JPEG data to preserve the bitmap info.
  if (!scaledImage) {
    return nil;
  }
  NSData *imageData = UIImagePNGRepresentation(scaledImage);
  if (!imageData) {
    imageData = UIImageJPEGRepresentation(scaledImage, jpegCompressionQuality);
  }
  return [UIImage imageWithData:imageData];
}

- (nullable NSData *)scaledDataWithSize:(CGSize)size
                     byteCount:(int)byteCount
                   isQuantized:(BOOL)isQuantized {
  CGImageRef cgImage = self.CGImage;
  if (cgImage && CGImageGetWidth(cgImage) > 0 && CGImageGetHeight(cgImage) > 0) {
    NSData *imageData = [self imageDataFromCGImage:cgImage size:size];
    if (!imageData) {
      return nil;
    }
    const UInt8 *bytes = imageData.bytes;

    NSMutableData *scaledBytes = [NSMutableData dataWithLength:byteCount];
    UInt8 *mutableBytes = scaledBytes.mutableBytes;

    // Extract the RGB(A) components from the scaled image data while ignoring the alpha component.
    int pixelIndex = 0;
    for (int offset = 0; offset < imageData.length; offset++) {
      if ((offset % alphaComponentBaseOffset) ==
          alphaComponentModuloRemainder) {
        continue;
      }
      mutableBytes[pixelIndex++] = bytes[offset];
    }
    if (isQuantized) {
        return scaledBytes;
    }
    NSMutableData *scaledFloats = [NSMutableData dataWithLength:byteCount*4];
    Float32 *mutableFloats = scaledFloats.mutableBytes;
    for (int i = 0; i < byteCount; i++) {
      mutableFloats[i] = (Float32)mutableBytes[i]/maxRGBValue;
    }
      return scaledFloats;
  } else {
    return nil;
  }
}

#pragma mark - Private

/// Returns the image data from the given CGImage resized to the given width and height.
- (NSData *)imageDataFromCGImage:(CGImageRef)cgImage
                            size:(CGSize)size {
  uint32_t bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
  int width = size.width;
  int height = size.height;
  size_t scaledBytesPerRow = (CGImageGetBytesPerRow(cgImage) / CGImageGetWidth(cgImage)) * width;

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(cgImage), scaledBytesPerRow, colorSpace, bitmapInfo);
  CGColorSpaceRelease(colorSpace);
  if (!context) {
    return nil;
  }
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
  CGImageRef image = CGBitmapContextCreateImage(context);
  CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
  CFDataRef cfData = CGDataProviderCopyData(dataProvider);
  CGImageRelease(image);
  CGContextRelease(context);
  return (__bridge_transfer NSData*)cfData;
}

@end
