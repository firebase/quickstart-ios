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

#import <Foundation/Foundation.h>
@import UIKit;
@import FirebaseMLCommon;

NS_ASSUME_NONNULL_BEGIN

/// Defines the requirements for managing remote and local models.
@protocol ModelManaging

/// Returns a Bool indicating whether the remote model was successfully registered or had
/// already been registered.
- (BOOL)registerRemoteModel:(FIRRemoteModel *)remoteModel;

/// Returns a Bool indicating whether the local model was successfully registered or had
/// already been registered.
- (BOOL)registerLocalModel:(FIRLocalModel *)localModel;

@end

static NSString *const modelExtension = @"tflite";
static NSString *const labelsExtension = @"txt";
static int const topResultsCountInt = 5;
static int const componentCount = 3;
static NSString *const invalidModelFilename = @"mobilenet_v1_1.0_224";
static NSString *const quantizedModelFilename = @"mobilenet_quant_v2_1.0_299";
static NSString *const floatModelFilename = @"mobilenet_float_v2_1.0_299";

@interface ModelInterpreterManager : NSObject

typedef void (^DetectObjectsCompletion)(NSArray *_Nullable objects, NSError *_Nullable error);

- (BOOL)setUpRemoteModelWithName:(NSString *)name;
- (BOOL)setUpLocalModelWithName:(NSString *)name filename:(NSString *)filename;
- (BOOL)setUpLocalModelWithName:(NSString *)name filename:(NSString *)filename bundle:(NSBundle *)bundle;
- (BOOL)loadRemoteModelWithIsModelQuantized:(BOOL)isModelQuantized;
- (BOOL)loadLocalModelWithIsModelQuantized:(BOOL)isModelQuantized;
- (void)detectObjectsInImageData:(NSData *)imageData
                 topResultsCount:(nullable NSNumber *)topResultsCount
                      completion:(DetectObjectsCompletion)completion;
- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
