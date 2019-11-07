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

#import "ViewController.h"
#import "UIImage+TFLite.h"

@import Firebase;

static NSString *const failedToDetectObjectsMessage = @"Failed to detect objects in image.";
static NSString *const defaultImage = @"grace_hopper.jpg";
static NSString *const modelExtension = @"tflite";
static NSString *const labelsExtension = @"txt";
static NSString *const invalidModelFilename = @"mobilenet_v1_1.0_224";
static NSString *const quantizedModelFilename = @"mobilenet_quant_v2_1.0_299";
static NSString *const floatModelFilename = @"mobilenet_float_v2_1.0_299";
static NSString *const invalidRemoteModelName = @"invalid_model";
static NSString *const quantizedRemoteModelName = @"image-classification-quant-v2";
static NSString *const floatRemoteModelName = @"image-classification-float-v2";
static int const topResultsCountInt = 5;
static int const componentCountInt = 3;
static NSString *const labelsName = @"labels";
static int const labelsCount = 1001;

static uint const inputOutputIndex = 0;
static int const batchSizeInt = 1;
static float const dimensionImageWidth = 299;
static float const dimensionImageHeight = 299;

typedef void (^DetectObjectsCompletion)(NSArray *_Nullable objects, NSError *_Nullable error);

typedef NS_ENUM(NSInteger, ModelInterpreterErrorCode) {
  ModelInterpreterErrorCodeInvalidImageData = 1,
  ModelInterpreterErrorCodeInvalidResults = 2,
  ModelInterpreterErrorCodeInvalidModelDataType = 3
};

typedef NS_ENUM(NSInteger, ModelType) {
  ModelTypeQuantized = 0,
  ModelTypeFloat = 1,
  ModelTypeInvalid = 2
};

NSUInteger ModelTypeSize() { return 3; }

/// Default quantization parameters for Softmax. The Softmax function is normally implemented as the
/// final layer, just before the output layer, of a neural-network based classifier.
///
/// Quantized values can be mapped to float values using the following conversion:
///   `realValue = scale * (quantizedValue - zeroPoint)`.
static int const SoftmaxZeroPoint = 0;
static float const SoftmaxMaxUInt8QuantizedValue = 255.0;
static float const SoftmaxNormalizerValue = 1.0;
static float const SoftmaxScale = 1.0 / (SoftmaxMaxUInt8QuantizedValue + SoftmaxNormalizerValue);

@interface ModelInterpreterError : NSError
- (instancetype)initWithCode:(int)code;
@end

@implementation ModelInterpreterError

- (instancetype)initWithCode:(int)code {
  return [self initWithDomain:@"com.google.firebaseml.sampleapps.modelinterpreter"
                         code:code
                     userInfo:[NSDictionary dictionary]];
}
@end

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/// An image picker for accessing the photo library or camera.
@property(nonatomic) UIImagePickerController *imagePicker;

@property(nonatomic, readonly) ModelType currentModelType;

@property(weak, nonatomic) IBOutlet UISegmentedControl *modelControl;

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UITextView *resultsTextView;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *downloadModelButton;
@property(weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@property(nonatomic) FIRModelDownloadConditions *initialConditions;
@property(nonatomic) FIRModelDownloadConditions *updateConditions;

@property(nonatomic) FIRModelManager *modelManager;
@property(nonatomic, readonly) NSArray<NSString *> *labels;
@property(nonatomic) int labelsCount;

@property(nonatomic) NSMutableArray *remoteModels;
@property(nonatomic) NSMutableArray *localModels;

@end

@implementation ViewController

- (ModelType)currentModelType {
  return self.modelControl.selectedSegmentIndex;
}

- (FIRCustomRemoteModel *)currentRemoteModel {
  return self.remoteModels[[self currentModelType]];
}

- (FIRCustomLocalModel *)currentLocalModel {
  return self.localModels[[self currentModelType]];
}

- (NSArray<NSString *> *)labels {
  NSString *labelsFilePath = [NSBundle.mainBundle pathForResource:labelsName
                                                           ofType:labelsExtension];
  if (!labelsFilePath) {
    NSLog(@"%@", @"Failed to get the labels file path.");
    return nil;
  }
  NSError *stringError;
  NSString *contents = [NSString stringWithContentsOfFile:labelsFilePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:&stringError];
  if (stringError || !contents) {
    NSLog(@"Failed to read labels with error: %@", stringError.localizedDescription);
    return nil;
  }
  return [contents componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.modelManager = [FIRModelManager modelManager];

  self.initialConditions = [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:YES
                                                                allowsBackgroundDownloading:YES];

  self.updateConditions = [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:NO
                                                               allowsBackgroundDownloading:YES];

  self.imagePicker = [UIImagePickerController new];
  self.imageView.image = [UIImage imageNamed:defaultImage];
  self.imagePicker.delegate = self;
  if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
      ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
    self.cameraButton.enabled = NO;
  }
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(remoteModelDownloadDidSucceed:)
                                             name:FIRModelDownloadDidSucceedNotification
                                           object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(remoteModelDownloadDidFail:)
                                             name:FIRModelDownloadDidFailNotification
                                           object:nil];
  [self setUpRemoteModels];
  [self setUpLocalModels];
  self.detectButton.enabled = [self.modelManager isModelDownloaded:[self currentRemoteModel]];
}

#pragma mark - IBActions

- (IBAction)detectObjects:(id)sender {
  [self updateResultsText:nil];
  UIImage *image = self.imageView.image;
  if (!image) {
    [self updateResultsText:@"Image must not be nil.\n"];
    return;
  }

  self.detectButton.enabled = NO;
  FIRCustomRemoteModel *remoteModel = [self currentRemoteModel];
  FIRCustomLocalModel *localModel = [self currentLocalModel];
  ModelType modelType = [self currentModelType];
  FIRModelInterpreter *modelInterpreter;
  switch (modelType) {
    case ModelTypeFloat:
      if ([self.modelManager isModelDownloaded:remoteModel]) {
        modelInterpreter = [FIRModelInterpreter modelInterpreterForRemoteModel:remoteModel];
      } else {
        modelInterpreter = [FIRModelInterpreter modelInterpreterForLocalModel:localModel];
      }
      break;
    case ModelTypeQuantized:
    case ModelTypeInvalid:
      modelInterpreter = [FIRModelInterpreter modelInterpreterForRemoteModel:remoteModel];
      break;
  }

  NSString *newResultsTextString = @"Starting inference...\n";
  if (self.resultsTextView.text) {
    newResultsTextString = [self.resultsTextView.text stringByAppendingString:newResultsTextString];
  }
  [self updateResultsText:newResultsTextString];
  BOOL isQuantized = modelType == ModelTypeQuantized;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSData *imageData = [self scaledImageDataFromImage:image];
    [self
        runInferenceOnImageData:imageData
               modelInterpreter:modelInterpreter
                    isQuantized:isQuantized
                     completion:^(NSArray *_Nullable results, NSError *_Nullable error) {
                       if (!results || results.count == 0) {
                         NSString *errorString =
                             error ? error.localizedDescription : failedToDetectObjectsMessage;
                         errorString =
                             [NSString stringWithFormat:@"Inference error: %@", errorString];
                         NSLog(@"%@", errorString);
                         [self updateResultsText:errorString];
                         self.detectButton.enabled = YES;
                         return;
                       }

                       NSString *inferenceMessageString = @"Inference results using ";
                       if ([self.modelManager isModelDownloaded:remoteModel]) {
                         inferenceMessageString = [inferenceMessageString
                             stringByAppendingFormat:@"`%@` remote model:\n",
                                                     [self remoteModelNameForModelType:modelType]];
                       } else {
                         inferenceMessageString = [inferenceMessageString
                             stringByAppendingFormat:@"`%@` local model:\n",
                                                     [self localModelNameForModelType:modelType]];
                       }
                       [self updateResultsText:
                                 [inferenceMessageString
                                     stringByAppendingString:
                                         [self detectionResultsStringRromResults:results]]];
                       self.detectButton.enabled = YES;
                     }];
  });
}

- (IBAction)openPhotoLibrary:(id)sender {
  self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)openCamera:(id)sender {
  self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)downloadModel:(id)sender {
  [self updateResultsText:nil];
  FIRModelDownloadConditions *conditions = nil;
  switch ([self currentModelType]) {
    case ModelTypeQuantized:
      self.downloadProgressView.hidden = NO;
      if ([self.modelManager isModelDownloaded:[self currentRemoteModel]]) {
        conditions = self.updateConditions;
        [self updateResultsText:
                  @"The remote model has already been downloaded, checking with the Firebase "
                  @"Console to see if a newer version of the model is available for download. This "
                  @"text view will notify you if a newer version was downloaded.\n"];
      } else {
        conditions = self.initialConditions;
        [self updateResultsText:@"The remote model is being downloaded. Follow the progress view "
                                @"to determine when the model download has completed.\n"];
      }
      self.downloadProgressView.observedProgress =
          [self.modelManager downloadModel:[self currentRemoteModel] conditions:conditions];
      break;
    case ModelTypeFloat:
      if ([self.modelManager isModelDownloaded:[self currentRemoteModel]]) {
        [self updateResultsText:
                  @"Deleting the downloaded remote model. Once the model has been deleted, you can "
                  @"always redownload it by pressing the download button.\n"];
        [self.modelManager
            deleteDownloadedModel:[self currentRemoteModel]
                       completion:^(NSError *_Nullable error) {
                         if (error) {
                           NSLog(@"Failed to delete the float model.");
                           return;
                         }
                         [self updateResultsText:
                                   @"The downloaded remote model has been successfully deleted.\n"];
                         self.downloadModelButton.enabled = YES;
                       }];
      } else {
        [self updateResultsText:
                  @"The remote model has not been downloaded yet. Loading the local model so it "
                  @"can be used as a fallback while the remote model is being downloaded. This "
                  @"text view will notify you once the download has completed.\n"];
        [self.modelManager downloadModel:[self currentRemoteModel]
                              conditions:self.initialConditions];
      }
      break;
    case ModelTypeInvalid:
      [self updateResultsText:@"Downloading the current model. This text view will notify you once "
                              @"the download has completed.\n"];
      [self.modelManager downloadModel:[self currentRemoteModel] conditions:self.initialConditions];
      break;
  }
  self.downloadModelButton.enabled = NO;
}

- (IBAction)modelSwitched:(id)sender {
  [self updateResultsText:nil];
  switch ([self currentModelType]) {
    case ModelTypeQuantized:
      self.detectButton.enabled = [self.modelManager isModelDownloaded:[self currentRemoteModel]];
      break;
    case ModelTypeFloat:
    case ModelTypeInvalid:
      self.downloadProgressView.hidden = YES;
      self.detectButton.enabled = YES;
      break;
  }
  self.downloadModelButton.enabled = YES;
}

#pragma mark - Notifications

- (void)remoteModelDownloadDidSucceed:(NSNotification *)notification {
  [self runOnMainThread:^{
    [self updateResultsText:nil];
    self.downloadModelButton.enabled = YES;
    FIRRemoteModel *remotemodel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    if (remotemodel == nil) {
      [self updateResultsText:@"firebaseMLModelDownloadDidSucceed notification posted without a "
                              @"RemoteModel instance."];
      return;
    }
    if ([remotemodel.name isEqualToString:[self currentRemoteModel].name]) {
      self.detectButton.enabled = YES;
    }
    [self updateResultsText:[NSString
                                stringWithFormat:@"Successfully downloaded the remote model with "
                                                 @"name: %@. The model is ready for detection.",
                                                 remotemodel.name]];
  }];
}

- (void)remoteModelDownloadDidFail:(NSNotification *)notification {
  [self runOnMainThread:^{
    [self updateResultsText:nil];
    self.detectButton.enabled = [self currentModelType] == ModelTypeQuantized;
    self.downloadModelButton.enabled = YES;
    FIRRemoteModel *remoteModel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    NSError *error = notification.userInfo[FIRModelDownloadUserInfoKeyError];
    if (error == nil) {
      [self updateResultsText:@"firebaseMLModelDownloadDidFail notification posted without a "
                              @"RemoteModel instance or error."];
      return;
    }
    [self updateResultsText:
              [NSString
                  stringWithFormat:@"Failed to download the remote model with name: %@, error: %@.",
                                   remoteModel, error.localizedDescription]];
  }];
}

#pragma mark - Private

- (void)setUpRemoteModels {
  self.remoteModels = [NSMutableArray arrayWithCapacity:ModelTypeSize()];
  for (int modelType = 0; modelType < ModelTypeSize(); modelType++) {
    [self.remoteModels addObject:[[FIRCustomRemoteModel alloc]
                                     initWithName:[self remoteModelNameForModelType:modelType]]];
  }
}

- (void)setUpLocalModels {
  self.localModels = [NSMutableArray arrayWithCapacity:ModelTypeSize()];
  for (int modelType = 0; modelType < ModelTypeSize(); modelType++) {
    [self.localModels
        addObject:
            [[FIRCustomLocalModel alloc]
                initWithModelPath:[NSBundle.mainBundle
                                      pathForResource:[self localModelNameForModelType:modelType]
                                               ofType:modelExtension]]];
  }
}

/// Returns a string representation of the detection results.
- (NSString *)detectionResultsStringRromResults:(NSArray *)results {
  if (!results) {
    return failedToDetectObjectsMessage;
  }

  NSMutableString *resultString = [NSMutableString new];
  for (NSArray *result in results) {
    [resultString appendFormat:@"%@: %@\n", result[0], ((NSNumber *)result[1]).stringValue];
  }
  return resultString;
}

/// Updates the results text view with the given text. The default is `nil`, so calling
/// `updateResultsText()` will clear the results.
- (void)updateResultsText:(nullable NSString *)text {
  [self runOnMainThread:^{
    self.resultsTextView.text = text;
  }];
}

/// Updates the image view with a scaled version of the given image.
- (void)updateImageViewWithImage:(UIImage *)image {
  UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
  CGFloat imageWidth = image.size.width;
  CGFloat imageHeight = image.size.height;
  if (imageWidth <= FLT_EPSILON || imageHeight <= FLT_EPSILON) {
    self.imageView.image = image;
    NSLog(@"Failed to update image view because image has invalid size: %@",
          NSStringFromCGSize(image.size));
    return;
  }

  CGFloat scaledImageWidth = 0.0;
  CGFloat scaledImageHeight = 0.0;
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationPortraitUpsideDown:
    case UIInterfaceOrientationUnknown:
      scaledImageWidth = self.imageView.bounds.size.width;
      scaledImageHeight = imageHeight * scaledImageWidth / imageWidth;
      break;
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      scaledImageWidth = imageWidth * scaledImageHeight / imageHeight;
      scaledImageHeight = self.imageView.bounds.size.height;
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
    UIImage *scaledImage =
        [image scaledImageWithSize:CGSizeMake(scaledImageWidth, scaledImageHeight)];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.imageView.image = scaledImage ? scaledImage : image;
    });
  });
}

- (NSString *)remoteModelNameForModelType:(ModelType)modelType {
  switch (modelType) {
    case ModelTypeQuantized:
      return quantizedRemoteModelName;
    case ModelTypeFloat:
      return floatRemoteModelName;
    case ModelTypeInvalid:
      return invalidRemoteModelName;
  }
}

- (NSString *)localModelNameForModelType:(ModelType)modelType {
  switch (modelType) {
    case ModelTypeQuantized:
      return quantizedModelFilename;
    case ModelTypeFloat:
      return floatModelFilename;
    case ModelTypeInvalid:
      return invalidModelFilename;
  }
}

- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image {
  return [self scaledImageDataFromImage:image isQuantized:NO];
}

- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image isQuantized:(BOOL)isQuantized {
  return [self scaledImageDataFromImage:image
                               withSize:CGSizeMake(dimensionImageWidth, dimensionImageHeight)
                            isQuantized:(BOOL)isQuantized
                         componentCount:componentCountInt
                              batchSize:batchSizeInt];
}

- (nullable NSData *)scaledImageDataFromImage:(UIImage *)image
                                     withSize:(CGSize)size
                                  isQuantized:(BOOL)isQuantized
                               componentCount:(int)componentCount
                                    batchSize:(int)batchSize {
  NSData *scaledImageData =
      [image scaledDataWithSize:size
                      byteCount:size.width * size.height * componentCount * batchSize
                    isQuantized:isQuantized];
  if (!scaledImageData) {
    NSLog(@"Failed to scale image to size: %@.", NSStringFromCGSize(size));
    return nil;
  }
  return scaledImageData;
}

- (void)runInferenceOnImageData:(NSData *)imageData
               modelInterpreter:(FIRModelInterpreter *)modelInterpreter
                    isQuantized:(BOOL)isQuantized
                     completion:(DetectObjectsCompletion)completion {
  [self runInferenceOnImageData:imageData
               modelInterpreter:modelInterpreter
                    isQuantized:isQuantized
                topResultsCount:topResultsCountInt
                     completion:completion];
}

- (void)runInferenceOnImageData:(NSData *)imageData
               modelInterpreter:(FIRModelInterpreter *)modelInterpreter
                    isQuantized:(BOOL)isQuantized
                topResultsCount:(int)topResultsCount
                     completion:(DetectObjectsCompletion)completion {
  if (!imageData) {
    [self safeDispatchOnMain:completion
                     objects:nil
                       error:[[ModelInterpreterError alloc]
                                 initWithCode:ModelInterpreterErrorCodeInvalidImageData]];
    return;
  }
  FIRModelInputs *inputs = [FIRModelInputs new];
  FIRModelInputOutputOptions *modelInputOutputOptions = [FIRModelInputOutputOptions new];
  FIRModelElementType modelElementType =
      isQuantized ? FIRModelElementTypeUInt8 : FIRModelElementTypeFloat32;
  NSError *error;
  // Add the image data to the model input.
  [inputs addInput:imageData error:&error];

  if (error) {
    NSLog(@"Failed to add the image data input with error: %@", error.localizedDescription);
    [self safeDispatchOnMain:completion objects:nil error:error];
    return;
  }

  NSArray<NSNumber *> *inputDimensions = @[
    [NSNumber numberWithInt:batchSizeInt], [NSNumber numberWithFloat:dimensionImageWidth],
    [NSNumber numberWithFloat:dimensionImageHeight], [NSNumber numberWithInt:componentCountInt]
  ];
  [modelInputOutputOptions setInputFormatForIndex:inputOutputIndex
                                             type:modelElementType
                                       dimensions:inputDimensions
                                            error:&error];
  NSArray<NSNumber *> *outputDimensions =
      @[ [NSNumber numberWithInt:batchSizeInt], [NSNumber numberWithInt:labelsCount] ];
  [modelInputOutputOptions setOutputFormatForIndex:inputOutputIndex
                                              type:modelElementType
                                        dimensions:outputDimensions
                                             error:&error];

  if (error) {
    NSLog(@"Failed to set up the input/output options with error:: %@", error.localizedDescription);
    [self safeDispatchOnMain:completion objects:nil error:error];
    return;
  }

  // Run the interpreter for the model with the given inputs.
  [modelInterpreter runWithInputs:inputs
                          options:modelInputOutputOptions
                       completion:^(FIRModelOutputs *_Nullable outputs, NSError *_Nullable error) {
                         if (error || !outputs) {
                           completion(nil, error);
                           return;
                         }
                         [self process:outputs
                             modelElementType:modelElementType
                              topResultsCount:topResultsCount
                                   completion:completion];
                       }];
}

- (void)process:(FIRModelOutputs *)outputs
    modelElementType:(FIRModelElementType)modelElementType
     topResultsCount:(int)topResultsCount
          completion:(DetectObjectsCompletion)completion {
  // Get the output for the first batch, since `dimensionBatchSize` is 1.
  NSError *error;
  NSArray<NSArray<NSNumber *> *> *outputArrayOfArrays = [outputs outputAtIndex:0 error:&error];
  if (error) {
    NSLog(@"Failed to process detection outputs with error: %@", error.localizedDescription);
    completion(nil, error);
    return;
  }

  // Get the first output from the array of output arrays.
  if (outputArrayOfArrays == nil || outputArrayOfArrays.firstObject == nil ||
      ![outputArrayOfArrays.firstObject isKindOfClass:[NSArray class]] ||
      outputArrayOfArrays.firstObject.firstObject == nil ||
      ![outputArrayOfArrays.firstObject.firstObject isKindOfClass:[NSNumber class]]) {
    NSLog(@"%@", @"Failed to get the results array from output.");
    completion(
        nil, [[ModelInterpreterError alloc] initWithCode:ModelInterpreterErrorCodeInvalidResults]);
    return;
  }

  NSArray<NSNumber *> *firstOutput = outputArrayOfArrays.firstObject;
  NSMutableArray<NSNumber *> *confidences =
      [[NSMutableArray alloc] initWithCapacity:firstOutput.count];

  switch (modelElementType) {
    case FIRModelElementTypeUInt8:
      for (NSNumber *number in firstOutput) {
        [confidences addObject:[NSNumber numberWithFloat:SoftmaxScale *
                                                         (number.intValue - SoftmaxZeroPoint)]];
      }
      firstOutput = confidences;
      break;
    case FIRModelElementTypeFloat32:
      break;
    default:
      completion(nil, [[ModelInterpreterError alloc]
                          initWithCode:ModelInterpreterErrorCodeInvalidModelDataType]);
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
  [zippedResults sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
    float confidenceValue1 = ((NSNumber *)((NSArray *)obj1)[1]).floatValue;
    float confidenceValue2 = ((NSNumber *)((NSArray *)obj2)[1]).floatValue;
    return confidenceValue1 < confidenceValue2;
  }];

  // Resize the sorted results array to match the `topResultsCount`.
  NSArray<NSArray *> *sortedResults =
      [zippedResults subarrayWithRange:NSMakeRange(0, topResultsCount)];

  // Create an array of tuples with the results as [(label: String, confidence: Float)].
  NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:topResultsCount];
  for (NSArray *sortedResult in sortedResults) {
    int labelIndex = ((NSNumber *)sortedResult[0]).intValue;
    [results addObject:@[ self.labels[labelIndex], (NSNumber *)sortedResult[1] ]];
  }
  completion(results, nil);
}

#pragma mark - Constants

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
  [self updateResultsText:nil];
  UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
  if (pickedImage) [self updateImageViewWithImage:pickedImage];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)runOnMainThread:(void (^)(void))functionBlock {
  if (NSThread.isMainThread) {
    functionBlock();
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    functionBlock();
  });
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
