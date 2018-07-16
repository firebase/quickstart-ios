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
static Float32 const meanRGBValue = maxRGBValue / 2.0;
static Float32 const stdRGBValue = maxRGBValue / 2.0;
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

- (NSData *)scaledImageDataWithSize:(CGSize)size
                    componentsCount:(int)newComponentsCount
                          batchSize:(int)batchSize {
  CGImageRef cgImage = self.CGImage;
  if (cgImage && CGImageGetWidth(cgImage) > 0 && CGImageGetHeight(cgImage) > 0) {
    unsigned long oldComponentsCount = CGImageGetBytesPerRow(cgImage) / CGImageGetWidth(cgImage);
    if (newComponentsCount > oldComponentsCount) {
      return nil;
    }
    CFDataRef imageData = [self imageDataFromImage:cgImage size:size componentsCount:(int)oldComponentsCount];
    if (!imageData) {
      return nil;
    }
    const UInt8 *bytes = CFDataGetBytePtr(imageData);

    int bytesCount = size.width * size.height * newComponentsCount * batchSize;

    UInt8 *scaledBytes = malloc(sizeof(*scaledBytes) * bytesCount);

    // Extract the RGB(A) components from the scaled image data while ignoring the alpha component.
    int pixelIndex = 0;
    for (int offset = 0; offset < CFDataGetLength(imageData); offset++) {
      if ((offset % alphaComponentBaseOffset) ==
          alphaComponentModuloRemainder) {
        continue;
      }
      scaledBytes[pixelIndex++] = bytes[offset];
    }
    return [NSData dataWithBytes:scaledBytes length:bytesCount];
  } else {
    return nil;
  }
}

- (NSArray *)scaledPixelArrayWithSize:(CGSize)size
                      componentsCount:(int)newComponentsCount
                            batchSize:(int)batchSize
                          isQuantized:(BOOL)isQuantized {
  CGImageRef cgImage = self.CGImage;
  if (cgImage && CGImageGetWidth(cgImage) > 0 && CGImageGetHeight(cgImage) > 0) {
    unsigned long oldComponentsCount = CGImageGetBytesPerRow(cgImage) / CGImageGetWidth(cgImage);
    if (newComponentsCount > oldComponentsCount) {
      return nil;
    }
    CFDataRef imageData = [self imageDataFromImage:cgImage size:size componentsCount:(int)oldComponentsCount];
    if (!imageData) {
      return nil;
    }
    const UInt8 *bytes = CFDataGetBytePtr(imageData);

    NSMutableArray *columnArray = [[NSMutableArray alloc] initWithCapacity:size.width];
    for (int yCoordinate = 0; yCoordinate < size.width; yCoordinate++) {
      NSMutableArray *rowArray = [[NSMutableArray alloc] initWithCapacity:size.height];;
      for (int xCoordinate = 0; xCoordinate < size.height; xCoordinate++) {
        NSMutableArray *pixelArray = [[NSMutableArray alloc] initWithCapacity:newComponentsCount];
        for (int component = 0; component < newComponentsCount; component++) {
          int inputIndex =
          (yCoordinate * size.height * oldComponentsCount) +
          (xCoordinate * oldComponentsCount + component);
          UInt8 pixel = bytes[inputIndex];
          if (isQuantized) {
            [pixelArray addObject:[NSNumber numberWithUnsignedChar:pixel]];
          } else {
            // Convert pixel values from [0, 255] to [-1, 1] scale.
            pixel = (Float32)pixel - meanRGBValue / stdRGBValue;
            [pixelArray addObject:[NSNumber numberWithFloat:pixel]];
          }
        }
        [rowArray addObject:pixelArray];
      }
      [columnArray addObject:rowArray];
    }
    return @[columnArray];
  } else {
    return nil;
  }
}

#pragma mark - Private

/// Returns the image data from the given CGImage resized to the given width and height.
- (CFDataRef)imageDataFromImage:(CGImageRef)image
                          size:(CGSize)size
               componentsCount:(int)componentsCount {
  uint32_t bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
  CGContextRef context = CGBitmapContextCreate(nil, size.width, size.height, CGImageGetBitsPerComponent(image), componentsCount * size.width, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
  if (!context) {
    return nil;
  }
  CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
  CFDataRef cfData = CGDataProviderCopyData(CGImageGetDataProvider(CGBitmapContextCreateImage(context)));
  return cfData;
}

@end
