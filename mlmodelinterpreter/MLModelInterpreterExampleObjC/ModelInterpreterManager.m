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
@import FirebaseMLModelInterpreter;

static NSString *const labelsName = @"labels";
static int const labelsCount = 1001;

static uint const inputOutputIndex = 0;
static int const batchSize = 1;
static float const dimensionImageWidth = 299;
static float const dimensionImageHeight = 299;

typedef NS_ENUM(NSInteger, ModelInterpreterErrorCode) {
  ModelInterpreterErrorCodeInvalidImageData = 1,
  ModelInterpreterErrorCodeInvalidResults = 2,
  ModelInterpreterErrorCodeInvalidModelDataType = 3
};

/// Default quantization parameters for Softmax. The Softmax function is normally implemented as the
/// final layer, just before the output layer, of a neural-network based classifier.
///
/// Quantized values can be mapped to float values using the following conversion:
///   `realValue = scale * (quantizedValue - zeroPoint)`.
static int const SoftmaxZeroPoint = 0;
static float const SoftmaxMaxUInt8QuantizedValue = 255.0;
static float const SoftmaxNormalizerValue = 1.0;
static float const SoftmaxScale = 1.0 / (SoftmaxMaxUInt8QuantizedValue + SoftmaxNormalizerValue);

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
@property (nonatomic) NSArray *outputDimensions;

@property(nonatomic) id<ModelManaging> modelManager;
@property(nonatomic) FIRModelInputOutputOptions *modelInputOutputOptions;
@property(nonatomic) NSMutableSet<NSString *> *registeredRemoteModelNames;
@property(nonatomic) NSMutableSet<NSString *> *registeredLocalModelNames;
@property(nonatomic) FIRModelOptions *remoteModelOptions;
@property(nonatomic) FIRModelOptions *localModelOptions;
@property(nonatomic) FIRModelInterpreter *modelInterpreter;
@property(nonatomic) FIRModelElementType modelElementType;
@property(nonatomic) NSArray<NSString *> *labels;
@property(nonatomic) int labelsCount;

@end

@implementation ModelInterpreterManager

- (instancetype)init {
  return [self initWithModelManager:[FIRModelManager modelManager]];
}
/// Creates a new instance with the given object that conforms to `ModelManaging`.
- (instancetype)initWithModelManager:(id<ModelManaging>)modelManager {
  self = [super init];
  if (self != nil) {
    _modelManager = [FIRModelManager modelManager];
    _inputDimensions = @[
                         @(batchSize),
                         @(dimensionImageWidth),
                         @(dimensionImageHeight),
                         @(componentCount)];
    _outputDimensions = @[@(batchSize), @(labelsCount)];
    _modelInputOutputOptions = [FIRModelInputOutputOptions new];
    _labels = [NSArray new];
    _registeredRemoteModelNames = [NSMutableSet new];
    _registeredLocalModelNames = [NSMutableSet new];
    _modelElementType = FIRModelElementTypeUInt8;
  }
  return self;
}

// Sets up a remote model by creating a `RemoteModel` and registering it with the given name.
///
/// - Parameters:
///   - name: The name for the remote model.
/// - Returns: `Bool` indicating whether the remote model was successfully set up and registered.
- (BOOL)setUpRemoteModelWithName:(NSString *)name {
  FIRModelDownloadConditions *conditions = [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:YES
                                                                                allowsBackgroundDownloading:YES];
  FIRRemoteModel *remoteModel = [[FIRRemoteModel alloc] initWithName:name
                                                  allowsModelUpdates:YES
                                                   initialConditions:conditions
                                                    updateConditions:conditions];
  if ([_registeredRemoteModelNames containsObject:name] || [_modelManager registerRemoteModel:remoteModel]) {
    self.remoteModelOptions = [[FIRModelOptions alloc] initWithRemoteModelName:name localModelName:nil];
    [_registeredRemoteModelNames addObject:name];
    return YES;
  } else {
    NSLog(@"Failed to register the remote model with name: %@", name);
    return NO;
  }
}

- (BOOL)setUpLocalModelWithName:(NSString *)name filename:(NSString *)filename {
  return [self setUpLocalModelWithName:name filename:filename bundle:NSBundle.mainBundle];
}

/// Sets up a local model by creating a `LocalModel` and registering it with the given name.
///
/// - Parameters:
///   - name: The name for the local model.
///   - filename: The name for the local model file.
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the local model was successfully set up and registered.
- (BOOL)setUpLocalModelWithName:(NSString *)name filename:(NSString *)filename bundle:(NSBundle *)bundle {
  NSString *localModelFilePath = [bundle pathForResource:filename ofType:modelExtension];
  if(!localModelFilePath) {
    NSLog(@"%@",@"Failed to get the local model file path.");
    return NO;
  }

  FIRLocalModel *localModel = [[FIRLocalModel alloc] initWithName:name path:localModelFilePath];
  if ([_registeredLocalModelNames containsObject:name] || [_modelManager registerLocalModel:localModel]) {
    self.localModelOptions = [[FIRModelOptions alloc] initWithRemoteModelName:nil localModelName:name];
    [_registeredLocalModelNames addObject:name];
    return YES;
  }
  else {
    NSLog(@"Failed to register the local model with name: %@", name);
    return NO;
  }
}

- (BOOL)loadRemoteModelWithIsModelQuantized:(BOOL)isModelQuantized {
  return [self loadRemoteModelWithBundle:NSBundle.mainBundle isModelQuantized:isModelQuantized];
}

/// Loads the registered remote model with the `ModelOptions` created during setup and the given
/// input and output dimensions.
///
/// - Parameters:
///   - isModelQuantized: Indicates if the model is quantized. The default is `false`.
///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the remote model was successfully loaded.
- (BOOL)loadRemoteModelWithBundle:(NSBundle *)bundle isModelQuantized:(BOOL)isModelQuantized {
  if (_remoteModelOptions != nil) {
    return [self loadModelWithOptions:_remoteModelOptions isModelQuantized:isModelQuantized inputDimensions:nil outputDimensions:nil bundle:bundle];
  } else {
    NSLog(@"%@", @"Failed to load the remote model because the options are nil.");
    return NO;
  }
}

- (BOOL)loadLocalModelWithIsModelQuantized:(BOOL)isModelQuantized {
  return [self loadLocalModelWithBundle:NSBundle.mainBundle isModelQuantized:isModelQuantized];
}

/// Loads the registered local model with the `ModelOptions` created during setup and the given
/// input and output dimensions.
///
/// - Parameters:
///   - isModelQuantized: Indicates if the model is quantized. The default is `false`.
///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the local model was successfully loaded.
- (BOOL)loadLocalModelWithBundle:(NSBundle *)bundle isModelQuantized:(BOOL)isModelQuantized {

  if (_localModelOptions) {
    return [self loadModelWithOptions:_localModelOptions isModelQuantized:isModelQuantized inputDimensions:nil outputDimensions:nil bundle:bundle];
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
- (void)detectObjectsInImageData:(NSData *)imageData
                 topResultsCount:(nullable NSNumber *)topResultsCount
                      completion:(DetectObjectsCompletion)completion {
  int topResCount = topResultsCount != nil ? topResultsCount.intValue : topResultsCountInt;
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

- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image {
  return [self scaledImageDataFromImage:image
                               withSize:CGSizeMake(dimensionImageWidth, dimensionImageHeight)
                         componentCount:componentCount
                              batchSize:batchSize];
}

/// Returns the data representation of the given image scaled to the given image size that the
/// model was trained on.
///
/// - Parameters:
///   - image: The image to scale.
///   - size: The size to scale the image to. The default is `MobileNet.imageSize`.
///   - componentCount: The number of components in the scaled image. A component is a red, green,
///       blue, or alpha value. The default value is 3, indicating that the model was trained on
///       an image that contains only RGB components (i.e. the alpha component was removed).
///   - batchSize: The fixed number of examples in a batch. The default is 1.
/// - Returns: The scaled image as `Data` or `nil` if the image could not be scaled.
- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image
                                     withSize:(CGSize)size
                               componentCount:(int)componentCount
                                    batchSize:(int)batchSize {
  NSData *scaledImageData = [image scaledDataWithSize:size
                                            byteCount:size.width * size.height * componentCount * batchSize
                                          isQuantized:(_modelElementType == FIRModelElementTypeUInt8)];
  if(!scaledImageData) {
    NSLog(@"Failed to scale image to size: %@.", NSStringFromCGSize(size));
    return nil;
  }
  return scaledImageData;
}


#pragma mark - Private

/// Loads a model with the given options and input and output dimensions.
///
/// - Parameters:
///   - options: The model options consisting of the remote and/or local models to be loaded.
///   - isModelQuantized: Whether the model uses quantization (i.e. 8-bit fixed point weights and
///     activations). See https://www.tensorflow.org/performance/quantization for more details. If
///     false, a floating point model is used.
///   - inputDimensions: An array of the input tensor dimensions. Must include `outputDimensions`
///     if `inputDimensions` are specified. Pass `nil` to use the default input dimensions.
///   - outputDimensions: An array of the output tensor dimensions. Must include `inputDimensions`
///     if `outputDimensions` are specified. Pass `nil` to use the default output dimensions.
///   - bundle: The bundle to load model resources from. The default is the main bundle.
/// - Returns: A `Bool` indicating whether the model was successfully loaded. If both local and
///     remote models were provided in the `ModelOptions`, the remote model takes priority and is
///     loaded. If the remote model has not been downloaded yet from the Firebase console, the
///     model download request is created and the local model is loaded as a fallback.
- (BOOL)loadModelWithOptions:(FIRModelOptions *)options
            isModelQuantized:(BOOL)isModelQuantized
             inputDimensions:(nullable NSArray<NSNumber *> *)inputDimensions
            outputDimensions:(nullable NSArray<NSNumber *> *)outputDimensions
                      bundle:(nullable NSBundle *)bundle {
  if (!bundle) {
    bundle = NSBundle.mainBundle;
  }
  if ((inputDimensions && !outputDimensions) || (!inputDimensions && outputDimensions)) {
    NSLog(@"%@", @"Invalid input and output dimensions provided.");
    return NO;
  }

  NSString *labelsFilePath = [bundle pathForResource:labelsName ofType:labelsExtension];
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
  _labels = [contents componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
  self.modelInterpreter = [FIRModelInterpreter modelInterpreterWithOptions:options];
  _modelElementType = isModelQuantized ? FIRModelElementTypeUInt8 : FIRModelElementTypeFloat32;
  NSArray *modelInputDimensions = inputDimensions ? inputDimensions : _inputDimensions;
  NSError *inputError;
  [_modelInputOutputOptions setInputFormatForIndex:inputOutputIndex type:_modelElementType dimensions:modelInputDimensions error:&inputError];
  if (inputError) {
    NSLog(@"Failed to load the model with error: %@", inputError.localizedDescription);
    return NO;
  }
  NSArray *modelOutputDimensions = outputDimensions ? outputDimensions : _outputDimensions;
  NSError *outputError;
  [_modelInputOutputOptions setOutputFormatForIndex:inputOutputIndex type:_modelElementType dimensions:modelOutputDimensions error:&outputError];
  if (outputError) {
    NSLog(@"Failed to load the model with error: %@", outputError.localizedDescription);
    return NO;
  }
  return YES;
}

- (void)process:(FIRModelOutputs *)outputs
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
  if(outputArrayOfArrays == nil || outputArrayOfArrays.firstObject == nil || ![outputArrayOfArrays.firstObject isKindOfClass:[NSArray class]] || outputArrayOfArrays.firstObject.firstObject == nil || ![outputArrayOfArrays.firstObject.firstObject isKindOfClass:[NSNumber class]]) {
    NSLog(@"%@", @"Failed to get the results array from output.");
    completion(nil, [[ModelInterpreterError alloc] initWithCode:ModelInterpreterErrorCodeInvalidResults]);
    return;
  }

  NSArray<NSNumber *> *firstOutput = outputArrayOfArrays.firstObject;
  NSMutableArray<NSNumber *> *confidences = [[NSMutableArray alloc] initWithCapacity:firstOutput.count];
  
  switch (_modelElementType) {
      case FIRModelElementTypeUInt8:
      for (NSNumber *number in firstOutput) {
        [confidences addObject:[NSNumber numberWithFloat:SoftmaxScale * (number.intValue - SoftmaxZeroPoint)]];
      }
      firstOutput = confidences;
      break;
      case FIRModelElementTypeFloat32:
      break;
    default:
      completion(nil, [[ModelInterpreterError alloc] initWithCode:ModelInterpreterErrorCodeInvalidModelDataType]);
  }

  // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
  NSMutableArray *zippedResults = [[NSMutableArray alloc] initWithCapacity:firstOutput.count];
  for (int i = 0; i < firstOutput.count; i++) {
    [zippedResults addObject:@[
                               [NSNumber numberWithInt:i],
                               firstOutput[i],
                               ]];
  }

  // Sort the zipped results by confidence value in descending order.
  [zippedResults sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
    float confidenceValue1 = ((NSNumber *)((NSArray *)obj1)[1]).floatValue;
    float confidenceValue2 = ((NSNumber *)((NSArray *)obj2)[1]).floatValue;
    return confidenceValue1 < confidenceValue2;
  }];

  // Resize the sorted results array to match the `topResultsCount`.
  NSArray<NSArray *> *sortedResults =[zippedResults subarrayWithRange:NSMakeRange(0, topResultsCount)];

  // Create an array of tuples with the results as [(label: String, confidence: Float)].
  NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:topResultsCount];
  for (NSArray *sortedResult in sortedResults) {
    int labelIndex = ((NSNumber *)sortedResult[0]).intValue;
    [results addObject:@[
                         _labels[labelIndex],
                         (NSNumber *)sortedResult[1]
                         ]];
  }
  completion(results, nil);
}

#pragma mark - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
- (void)safeDispatchOnMain:(DetectObjectsCompletion)block
                   objects:(NSArray *_Nullable)objects
                     error:(NSError *_Nullable)error {
  if (NSThread.isMainThread) {
    block(objects, error);
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    block(objects, error);
  });
}

@end
