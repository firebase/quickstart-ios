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

#import "ModelInterpreterManager.h"
#import "UIImage+TFLite.h"
@import Firebase;

static NSString *const labelsSeparator = @"\n";
static NSString *const labelsFilename = @"labels";
static NSString *const modelFilename = @"mobilenet_v1_1.0_224";
static NSString *const quantizedLabelsFilename = @"labels_quant";
static NSString *const quantizedModelFilename = @"mobilenet_quant_v1_224";

static uint const modelInputIndex = 0;
static int const dimensionBatchSize = 1;
static float const dimensionImageWidth = 224;
static float const dimensionImageHeight = 224;
static Float32 const maxRGBValue = 255.0;

typedef NS_ENUM(NSInteger, ModelInterpreterErrorCode) {
  ModelInterpreterErrorCodeInvalidImageData = 1,
  ModelInterpreterErrorCodeInvalidResults = 2
};

@interface FIRModelManager (ModelManaging) <ModelManaging>
@end

@interface ModelInterpreterError : NSError
  -(instancetype) initWithCode:(int)code;
@end

@implementation ModelInterpreterError

-(instancetype) initWithCode:(int)code {
  return [self initWithDomain:@"com.google.firebaseml.sampleapps.modelinterpreter" code:code userInfo:[NSDictionary dictionary]];
}
@end

@interface ModelInterpreterManager ()

@property (nonatomic) NSArray *inputDimensions;

@property(nonatomic) id<ModelManaging> modelManager;
  @property(nonatomic) FIRModelInputOutputOptions *modelInputOutputOptions;
  @property(nonatomic) NSMutableSet<NSString *> *registeredCloudModelNames;
  @property(nonatomic) NSMutableSet<NSString *> *registeredLocalModelNames;
  @property(nonatomic) FIRModelOptions *cloudModelOptions;
  @property(nonatomic) FIRModelOptions *localModelOptions;
  @property(nonatomic) FIRModelInterpreter *modelInterpreter;
  @property(nonatomic) FIRModelElementType modelElementType;
  @property(nonatomic) BOOL isModelQuantized;
  @property(nonatomic) NSArray<NSString *> *labels;
  @property(nonatomic) int labelsCount;

@end

@implementation ModelInterpreterManager

- (instancetype)init {
  return [self initWithModelManager:[FIRModelManager modelManager]];
}

/// Creates a new instance with the given object that conforms to `ModelManaging`.
- (instancetype)initWithModelManager:(id<ModelManaging>)modelManager {
  self.modelManager = modelManager;
  self.inputDimensions = @[
                           [NSNumber numberWithInt:dimensionBatchSize],
                           [NSNumber numberWithFloat:dimensionImageWidth],
                           [NSNumber numberWithFloat:dimensionImageHeight],
                           [NSNumber numberWithInt:dimensionComponents]
                           ];
  self.modelInputOutputOptions = [FIRModelInputOutputOptions new];
  self.isModelQuantized = YES;
  self.labels = [NSArray new];
  self.labelsCount = 0;
  self.registeredCloudModelNames = [NSMutableSet new];
  self.registeredLocalModelNames = [NSMutableSet new];
  self.modelElementType = FIRModelElementTypeUInt8;
  return self;
}

/// Sets up a cloud model by creating a `CloudModelSource` and registering it with the given name.
///
/// - Parameters:
///   - name: The name for the cloud model.
/// - Returns: A `Bool` indicating whether the cloud model was successfully set up and registered.
- (BOOL)setUpCloudModelWithName:(NSString *)name {
  FIRModelDownloadConditions *conditions = [[FIRModelDownloadConditions alloc] initWithIsWiFiRequired:NO canDownloadInBackground:YES];
  FIRCloudModelSource *cloudModelSource = [[FIRCloudModelSource alloc] initWithModelName:name enableModelUpdates:YES initialConditions:conditions updateConditions:conditions];
  if ([_registeredCloudModelNames containsObject:name] || [_modelManager registerCloudModelSource:cloudModelSource]) {
    self.cloudModelOptions = [[FIRModelOptions alloc] initWithCloudModelName:name localModelName:nil];
    [_registeredCloudModelNames addObject:name];
    return YES;
  } else {
    NSLog(@"Failed to register the cloud model source with name: %@", name);
    return NO;
  }
}

/// Sets up a local model by creating a `LocalModelSource` and registering it with the given name.
///
/// - Parameters:
///   - name: The name for the local model.
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the local model was successfully set up and registered.
- (BOOL)setUpLocalModelWithName:(NSString *)name bundle:(nullable NSBundle *)bundle {
  if (!bundle) {
    bundle = NSBundle.mainBundle;
  }

  NSString *localModelFilePath = [bundle pathForResource:quantizedModelFilename ofType:modelExtension];
  if(!localModelFilePath) {
    NSLog(@"%@",@"Failed to get the local model file path.");
    return NO;
  }

  FIRLocalModelSource *localModelSource = [[FIRLocalModelSource alloc] initWithModelName:name path:localModelFilePath];
  if ([_registeredLocalModelNames containsObject:name] || [_modelManager registerLocalModelSource:localModelSource]) {
    self.localModelOptions = [[FIRModelOptions alloc] initWithCloudModelName:nil localModelName:name];
    [_registeredLocalModelNames addObject:name];
    return YES;
  }
  else {
    NSLog(@"Failed to register the local model source with name: %@", name);
    return NO;
  }
}

/// Loads the registered cloud model with the `ModelOptions` created during setup.
///
/// - Parameters:
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the cloud model was successfully loaded.
- (BOOL)loadCloudModel:(nullable NSBundle *)bundle {
  if (!bundle) {
    bundle = NSBundle.mainBundle;
  }

  if (_cloudModelOptions) {
    return [self loadModelWithOptions:_cloudModelOptions isQuantized:nil inputDimensions:nil outputDimensions:nil bundle:bundle];
  } else {
    NSLog(@"%@", @"Failed to load the cloud model because the options are nil.");
    return NO;
  }
}

/// Loads the registered local model with the `ModelOptions` created during setup.
///
/// - Parameters:
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the local model was successfully loaded.
- (BOOL)loadLocalModel:(nullable NSBundle *)bundle {
  if (!bundle) {
    bundle = NSBundle.mainBundle;
  }

  if (_localModelOptions) {
    return [self loadModelWithOptions:_localModelOptions isQuantized:nil inputDimensions:nil outputDimensions:nil bundle:bundle];
  } else {
    NSLog(@"%@", @"Failed to load the local model because the options are nil.");
    return NO;
  }
}

/// Detects objects in the given image data, represented as `Data` or an array of pixel values.
/// The completion is called with detection results as an array of tuples where each tuple
/// contains a label and confidence value.
///
/// - Parameters
///   - imageData: The data or pixel array representation of the image to detect objects in.
///   - topResultsCount: The number of top results to return.
///   - completion: The handler to be called on the main thread with detection results or error.
- (void)detectObjectsInImageData:(NSObject *)imageData
             topResultsCount:(nullable NSNumber *)topResultsCount
                  completion:(DetectObjectsCompletion)completion {
  int topResCount = topResultsCount ? topResultsCount.intValue : topResultsCountInt;
  if (!imageData) {
    [self safeDispatchOnMain:completion objects:nil error:[[ModelInterpreterError alloc] initWithCode:ModelInterpreterErrorCodeInvalidImageData]];
    return;
  }
  FIRModelInputs *inputs = [FIRModelInputs new];
  NSError *error;
  // Add the image data to the model input.
  [inputs addInput:imageData error:&error];
  if (error) {
    NSLog(@"Failed to add the image data input with error: %@", error.localizedDescription);
    [self safeDispatchOnMain:completion objects:nil error:error];
    return;
  }

  // Run the interpreter for the model with the given inputs.
  [_modelInterpreter runWithInputs:inputs options:_modelInputOutputOptions completion:^(FIRModelOutputs * _Nullable outputs, NSError * _Nullable error) {
    if (error || !outputs) {
      completion(nil, error);
      return;
    }
    [self process:outputs
  topResultsCount:topResCount
       completion:completion];
  }];
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
- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image
                              componentsCount:(nullable NSNumber *)componentsCount {
  int componentsCountInt = componentsCount ? componentsCount.intValue : dimensionComponents;

  CGSize imageSize = CGSizeMake(dimensionImageWidth, dimensionImageHeight);

  NSData *scaledImageData = [image scaledImageDataWithSize:imageSize componentsCount:componentsCountInt batchSize:dimensionBatchSize];
  if(!scaledImageData) {
    NSLog(@"Failed to scale image to size: %@.", NSStringFromCGSize(imageSize));
    return nil;
  }
  return scaledImageData;
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
///       If NO, a floating point model is used. The default is `YES`.
/// - Returns: A multidimensional array of fixed point (`UInt8`) values, if `isQuantized` is YES,
///     or floating point (`Float32`) values, if `isQuantized` is NO, or `nil` if the image
///     could not be scaled. The returned pixel array contains an array of horizontal pixels with
///     a count equal to the default width of the image. Each horizontal pixel contains of an
///     array of veritcal pixels with a count equal to the default height of the image. Each
///     horizontal pixel contains an array of the components with a count equal to the given
///     `componentsCount`. Scaling can fail for the following reasons: 1) components count is not
///     less than or equal to the components count of the given image 2) the given image's size or
///     CGImage is invalid.
- (NSArray *) scaledPixelArrayFromImage:(UIImage *)image
                        componentsCount:(nullable NSNumber *)componentsCount
                            isQuantized:(nullable NSNumber *)isQuantized {
  int componentsCountInt = (componentsCount) ? componentsCount.intValue : dimensionComponents;
  BOOL isQuantizedBool = (isQuantized) ? isQuantized.boolValue : YES;

  CGSize imageSize = CGSizeMake(dimensionImageWidth, dimensionImageHeight);

  NSArray *scaledPixelArray = [image scaledPixelArrayWithSize:imageSize componentsCount:componentsCountInt batchSize:dimensionBatchSize isQuantized:isQuantizedBool];
  if(!scaledPixelArray) {
    NSLog(@"Failed to scale image to size: %@.", NSStringFromCGSize(imageSize));
    return nil;
  }
  return scaledPixelArray;
}

#pragma mark - Private

/// Loads a model with the given options and input and output dimensions.
///
/// - Parameters:
///   - options: The model options consisting of the cloud and/or local sources to be loaded.
///   - isQuantized: Whether the model uses quantization (i.e. 8-bit fixed point weights and
///     activations). See https://www.tensorflow.org/performance/quantization for more details. If
///     NO, a floating point model is used. The default is `YES`.
///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the model was successfully loaded. If both local and
///     cloud model sources were provided in the `ModelOptions`, the cloud model takes priority
///     and is loaded. If the cloud model has not been downloaded yet from the Firebase console,
///     the model download request is created and the local model is loaded as a fallback.
- (BOOL)loadModelWithOptions:(FIRModelOptions *)options
                 isQuantized:(nullable NSNumber *)isQuantized
             inputDimensions:(nullable NSArray<NSNumber *> *)inputDimensions
            outputDimensions:(nullable NSArray<NSNumber *> *)outputDimensions
                      bundle:(nullable NSBundle *)bundle {
  if (!bundle) {
    bundle = NSBundle.mainBundle;
  }
  BOOL isQuantizedBool = isQuantized ? isQuantized.boolValue : YES;
  if ((inputDimensions && !outputDimensions) || (!inputDimensions && outputDimensions)) {
    NSLog(@"%@", @"Invalid input and output dimensions provided.");
    return NO;
  }

  _isModelQuantized = isQuantizedBool;
  NSString *labelsFilePath = [bundle pathForResource:quantizedLabelsFilename ofType:labelsExtension];
  if(!labelsFilePath) {
    NSLog(@"%@", @"Failed to get the labels file path.");
    return NO;
  }
  NSError *stringError;
  NSString *contents = [NSString stringWithContentsOfFile:labelsFilePath encoding:NSUTF8StringEncoding error:&stringError];
  if (stringError || !contents) {
    NSLog(@"Failed to load the model with error: %@", stringError.localizedDescription);
    return NO;
  }
  _labels = [contents componentsSeparatedByString:labelsSeparator];
  _labelsCount = (int)_labels.count;

  NSArray<NSNumber *> *modelOutputDimensions;
  modelOutputDimensions = outputDimensions ? outputDimensions : @[ [NSNumber numberWithInt:dimensionBatchSize], [NSNumber numberWithInt:_labelsCount] ];
  self.modelInterpreter = [FIRModelInterpreter modelInterpreterWithOptions:options];

  _modelElementType = _isModelQuantized ? FIRModelElementTypeUInt8 : FIRModelElementTypeFloat32;
  NSArray *modelInputDimensions = inputDimensions ? inputDimensions : _inputDimensions;
  NSError *inputError;
  [_modelInputOutputOptions setInputFormatForIndex:modelInputIndex type:_modelElementType dimensions:modelInputDimensions error:&inputError];
  if (inputError) {
    NSLog(@"Failed to load the model with error: %@", inputError.localizedDescription);
    return NO;
  }
  NSError *outputError;
  [_modelInputOutputOptions setOutputFormatForIndex:modelInputIndex type:_modelElementType dimensions:modelOutputDimensions error:&outputError];
  if (outputError) {
    NSLog(@"Failed to load the model with error: %@", outputError.localizedDescription);
    return NO;
  }
  return YES;
}

-(void) process:(FIRModelOutputs *)outputs
topResultsCount:(int)topResultsCount
     completion:(DetectObjectsCompletion)completion {

  // Get the output for the first batch, since `dimensionBatchSize` is 1.
  NSError *error;
  NSArray <NSArray<NSNumber *> *>*outputArrayOfArrays = [outputs outputAtIndex:0 error:&error];
  if (error) {
    NSLog(@"Failed to process detection outputs with error: %@", error.localizedDescription);
    completion(nil, error);
    return;
  }

  // Get the first output from the array of output arrays.
  if(!outputArrayOfArrays || !outputArrayOfArrays.firstObject || ![outputArrayOfArrays.firstObject isKindOfClass:[NSArray class]] || !outputArrayOfArrays.firstObject.firstObject || ![outputArrayOfArrays.firstObject.firstObject isKindOfClass:[NSNumber class]]) {
    NSLog(@"%@", @"Failed to get the results array from output.");
    completion(nil, [[ModelInterpreterError alloc] initWithCode:ModelInterpreterErrorCodeInvalidResults]);
    return;
  }

  NSArray<NSNumber *> *outputArray = outputArrayOfArrays.firstObject;

  // Convert the output from quantized 8-bit fixed point format to 32-bit floating point format.
  if (_isModelQuantized) {
    NSMutableArray<NSNumber *> *quantizedArray = [[NSMutableArray alloc] initWithCapacity:outputArray.count];
    for (NSNumber *number in outputArray) {
      [quantizedArray addObject:[NSNumber numberWithFloat:number.floatValue / maxRGBValue]];
    }
    outputArray = quantizedArray;
  }

  // Create a zipped array of tuples ("confidence" as NSNumber, "labelIndex" as Int).
  NSMutableArray *zippedArray = [[NSMutableArray alloc] initWithCapacity:_labelsCount];
  for (int i = 0; i < _labelsCount; i++) {
    [zippedArray addObject:@[
                             outputArray[i],
                              [NSNumber numberWithInt:i]
                              ]];
  }

  // Sort the zipped array of tuples ("confidence" as NSNumber, "labelIndex" as Int) by confidence
  // value in descending order.
  [zippedArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
    float confidenceValue1 = ((NSNumber *)((NSArray *)obj1).firstObject).floatValue;
    float confidenceValue2 = ((NSNumber *)((NSArray *)obj2).firstObject).floatValue;
    return confidenceValue1 < confidenceValue2;
  }];

  // Resize the sorted results array to match the `topResultsCount`.
  NSArray<NSArray *> *sortedResults =[zippedArray subarrayWithRange:NSMakeRange(0, topResultsCount)];

  // Create an array of tuples with the results as [("label" as String, "confidence" as Float)].
  NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:topResultsCount];
  for (NSArray *sortedResult in sortedResults) {
    int labelIndex = ((NSNumber *)sortedResult[1]).intValue;
    [results addObject:@[
                         _labels[labelIndex],
                         (NSNumber *)sortedResult[0]
                         ]];
  }
  completion(results, nil);
}

#pragma mark - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
-(void) safeDispatchOnMain:(DetectObjectsCompletion)block
                   objects:(NSArray *_Nullable)objects
                     error:(NSError *_Nullable)error {
  if (NSThread.isMainThread) {
    block(objects, error);
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      block(objects, error);
    });
  }
}

@end
