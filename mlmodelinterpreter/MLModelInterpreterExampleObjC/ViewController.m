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
#import "ModelInterpreterManager.h"
#import "UIImage+TFLite.h"

@import Firebase;

static NSString *const failedToDetectObjectsMessage = @"Failed to detect objects in image.";
static NSString *const defaultImage = @"grace_hopper.jpg";

typedef NS_ENUM(NSInteger, RemoteModelType) {
  RemoteModelTypeQuantized = 0,
  RemoteModelTypeFloat = 1,
  RemoteModelTypeInvalid = 2
};

NSString * const RemoteModelDownloadCompletedKey[] = {
  [RemoteModelTypeQuantized] = @"FIRRemoteModel1DownloadCompleted",
  [RemoteModelTypeFloat] = @"FIRRemoteModel2DownloadCompleted",
  [RemoteModelTypeInvalid] = @"FIRRemoteInvalidModel"
};

// REPLACE THESE REMOTE MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
NSString * const RemoteModelDescription[] = {
  [RemoteModelTypeQuantized] = @"image-classification-quant-v2",
  [RemoteModelTypeFloat] = @"image-classification-float-v2",
  [RemoteModelTypeInvalid] = @"invalid_model"
};

typedef NS_ENUM(NSInteger, LocalModelType) {
  LocalModelTypeQuantized = 0,
  LocalModelTypeFloat = 1,
  LocalModelTypeInvalid = 2
};

NSString * const LocalModelDescription[] = {
  [RemoteModelTypeQuantized] = quantizedModelFilename,
  [RemoteModelTypeFloat] = floatModelFilename,
  [RemoteModelTypeInvalid] = invalidModelFilename
};


@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/// A map of `ModelInterpreterManager` instances where the key is remote+local model name string.
@property(nonatomic) NSMutableDictionary<NSString *, ModelInterpreterManager *> *modelInterpreterManagerMap;

  /// The `ModelInterpreterManager` for the current remote and local models.
@property(nonatomic) ModelInterpreterManager *manager;

/// An image picker for accessing the photo library or camera.
@property(nonatomic) UIImagePickerController *imagePicker;

/// The currently selected remote model type.
@property(nonatomic, readonly) RemoteModelType currentRemoteModelType;

/// The currently selected local model type.
@property(nonatomic, readonly) LocalModelType currentLocalModelType;
@property(nonatomic, readonly) BOOL isQuantizedModel;
@property(nonatomic, readonly) BOOL isRemoteModelDownloaded;
@property(nonatomic, readonly) BOOL isExplicitModelDownload;

/// A segmented control for changing models (0 = float, 1 = quantized, 2 = invalid).
@property (weak, nonatomic) IBOutlet UISegmentedControl *modelControl;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *resultsTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadModelButton;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@property(nonatomic) bool isLocalModelLoaded;

@end

@implementation ViewController

- (RemoteModelType) currentRemoteModelType {
  return _modelControl.selectedSegmentIndex;
}

- (LocalModelType) currentLocalModelType {
  return _modelControl.selectedSegmentIndex;
}

- (BOOL) isRemoteModelDownloaded {
  return [NSUserDefaults.standardUserDefaults boolForKey:RemoteModelDownloadCompletedKey[self.currentRemoteModelType]];
}

- (BOOL) isQuantizedModel {
  return self.isRemoteModelDownloaded ? self.currentRemoteModelType == RemoteModelTypeQuantized : self.currentLocalModelType == LocalModelTypeQuantized;
}

- (BOOL) isExplicitModelDownload {
  return _modelControl.selectedSegmentIndex == 0;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.modelInterpreterManagerMap = [NSMutableDictionary new];
  self.isLocalModelLoaded = NO;
  self.imagePicker = [UIImagePickerController new];
  _imageView.image = [UIImage imageNamed:defaultImage];
  _imagePicker.delegate = self;
  if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
      ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
    [_cameraButton setEnabled:NO];
  }
  [self updateModelInterpreterManager];
  [self setUpRemoteModel];
  [self setUpLocalModel];
  self.downloadModelButton.enabled = !self.isRemoteModelDownloaded;
}

#pragma mark - IBActions

- (IBAction)detectObjects:(id)sender {
  [self updateResultsText:nil];
  UIImage *image = _imageView.image;
  if (!image) {
    [self updateResultsText:@"Image must not be nil.\n"];
    return;
  }
  if (self.isRemoteModelDownloaded) {
    [self updateResultsText:@"Loading the  model...\n"];
    [self loadRemoteModel];
  } else {
    [self updateResultsText:@"Loading the local model...\n"];
    if (![_manager loadLocalModelWithIsQuantizedModel:self.isQuantizedModel]) {
      [self updateResultsText:@"Failed to load the local model."];
      return;
    }
    _isLocalModelLoaded = YES;
  }
  NSString *newResultsTextString = @"Starting inference...\n";
  if (_resultsTextView.text) {
    newResultsTextString = [_resultsTextView.text stringByAppendingString:newResultsTextString];
  }
  [self updateResultsText:newResultsTextString];
  RemoteModelType remotemodel = self.currentRemoteModelType;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSData *imageData = [self.manager scaledImageDataFromImage:image];
    [self.manager detectObjectsInImageData:imageData topResultsCount:nil completion:^(NSArray * _Nullable results, NSError * _Nullable error) {
      if (!results || results.count == 0) {
        NSString *errorString = error ? error.localizedDescription : failedToDetectObjectsMessage;
        errorString = [NSString stringWithFormat:@"Inference error: %@", errorString];
        NSLog(@"%@", errorString);
        [self updateResultsText:errorString];
        return;
      }
      
      NSString *inferenceMessageString = @"Inference results using ";
      if (self.isRemoteModelDownloaded) {
        inferenceMessageString = [inferenceMessageString stringByAppendingFormat:@"`%@` remote model:\n", RemoteModelDescription[remotemodel]];
      } else {
        inferenceMessageString = [inferenceMessageString stringByAppendingFormat:@"`%@` local model:\n", LocalModelDescription[self.currentLocalModelType]];;
      }
      [self updateResultsText:[inferenceMessageString stringByAppendingString:[self detectionResultsStringRromResults:results]]];
    }];
  });
}

- (IBAction)openPhotoLibrary:(id)sender {
  _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (IBAction)openCamera:(id)sender {
  _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (IBAction)downloadModel:(id)sender {
  [self updateResultsText:nil];
  self.downloadModelButton.enabled = self.isRemoteModelDownloaded;
  self.detectButton.enabled = NO;
  self.downloadProgressView.hidden = !self.isQuantizedModel || self.isRemoteModelDownloaded;
  self.resultsTextView.text = self.isRemoteModelDownloaded ?
  @"Remote model loaded. Select the `Detect` button to start the inference." :
  @"Downloading remote model. Once the download has completed, select the `Detect` button to start the inference.";
  [self downloadRemoteModel];
}

- (IBAction)modelSwitched:(id)sender {
  [self updateResultsText:nil];
  [self updateModelInterpreterManager];
  [self setUpLocalModel];
  [self setUpRemoteModel];
  self.downloadModelButton.enabled = !self.isRemoteModelDownloaded;
  self.downloadProgressView.hidden = !self.isExplicitModelDownload || self.isRemoteModelDownloaded;
}

#pragma mark - Notifications

- (void)remoteModelDownloadDidSucceed:(NSNotification *)notification {
  [self runOnMainThread:^{
    [self updateResultsText:nil];
    FIRRemoteModel *remotemodel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    if (remotemodel == nil) {
      [self updateResultsText:@"firebaseMLModelDownloadDidSucceed notification posted without a RemoteModel instance."];
      return;
    }
    [self updateUserDefaultsForRemoteModel:remotemodel];
    if ([remotemodel.name isEqualToString:RemoteModelDescription[self.currentRemoteModelType]]) {
      self.detectButton.enabled = YES;
      self.downloadModelButton.enabled = NO;
      if (self.isExplicitModelDownload) {
        [self loadRemoteModel];
      }
    }
    [self updateResultsText:[NSString stringWithFormat:@"Successfully downloaded the remote model with name: %@. The model is ready for detection.", remotemodel.name]];
   }];
}

- (void)remoteModelDownloadDidFail:(NSNotification *)notification {
  [self runOnMainThread:^{
    [self updateResultsText:nil];
    self.detectButton.enabled = YES;
    self.downloadModelButton.enabled = YES;
    FIRRemoteModel *remoteModel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    NSError *error = notification.userInfo[FIRModelDownloadUserInfoKeyError];
    if (error == nil) {
      [self updateResultsText:@"firebaseMLModelDownloadDidFail notification posted without a RemoteModel instance or error."];
      return;
    }
    [self updateResultsText:[NSString stringWithFormat:@"Failed to download the remote model with name: %@, error: %@.", remoteModel, error.localizedDescription]];
  }];
}

#pragma mark - Private

/// Updates the `ModelInterpreterManager` instance based on the current remote and local models.
- (void)updateModelInterpreterManager {
  NSString *key = [NSString stringWithFormat:@"%@%ld%@%ld", RemoteModelDescription[self.currentRemoteModelType],
                    self.currentRemoteModelType,
                    LocalModelDescription[self.currentLocalModelType],
                    self.currentLocalModelType
                   ];
  _manager = _modelInterpreterManagerMap[key];
  if (_manager == nil) {
    _manager = [ModelInterpreterManager new];
  }
  _modelInterpreterManagerMap[key] = _manager;
}

- (void)setUpRemoteModel {
  NSString *modelName = RemoteModelDescription[self.currentRemoteModelType];
  if (![_manager setUpRemoteModelWithName:modelName]) {
    [self updateResultsText:[NSString stringWithFormat:@"%@\nFailed to set up the `%@` remote model.", _resultsTextView.text, modelName]];
  }
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(remoteModelDownloadDidSucceed:) name:FIRModelDownloadDidSucceedNotification object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(remoteModelDownloadDidFail:) name:FIRModelDownloadDidFailNotification object:nil];
}

- (void)setUpLocalModel {
  NSString *localModelName = LocalModelDescription[self.currentLocalModelType];
  if (![_manager setUpLocalModelWithName:localModelName filename:localModelName]) {
    NSString *newResultsText = @"";
    if (_resultsTextView.text) {
      newResultsText = _resultsTextView.text;
    }
    [self updateResultsText:[newResultsText stringByAppendingString:@"\nFailed to set up the local model."]];
  }
}

/// Downloads the currently selected remote model from the server either by explicitly invoking
// the `ModelManager`'s `download(_:)` method or by implicitly invoking download via the
// `ModelInterpreterManager`'s `loadRemoteModel(isQuantizedModel:)` method.
- (void)downloadRemoteModel {
  if (!self.isExplicitModelDownload) {
    [self loadRemoteModel];
    return;
  }
  NSString *name = RemoteModelDescription[self.currentRemoteModelType];
  FIRModelManager *modelManager = [FIRModelManager modelManager];
  FIRRemoteModel *remoteModel = [modelManager remoteModelWithName:name];
  if (remoteModel == nil) {
    [self updateResultsText:[NSString stringWithFormat:@"Failed to download remote model with name: %@ because the model was not registered with the Model Manager.", name]];
    return;
  }
  _downloadProgressView.observedProgress = [modelManager downloadRemoteModel:remoteModel];
}

- (void)loadRemoteModel {
  if (![self.manager loadRemoteModelWithIsQuantizedModel:self.isQuantizedModel]) {
    [self updateResultsText:@"Failed to load the remote model."];
  }
}

/// Updates the `downloadCompletedKey` in the User Defaults to true for the given remote model.
- (void)updateUserDefaultsForRemoteModel:(FIRRemoteModel *)remoteModel {
  NSString *key;
  for (int i = 0; i < 3; i++) {
    if ([remoteModel.name isEqualToString:RemoteModelDescription[i]]) {
      key = RemoteModelDownloadCompletedKey[i];
      break;
    }
  }
  [NSUserDefaults.standardUserDefaults setBool:YES forKey:key];
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
  UIInterfaceOrientation orientation =  UIApplication.sharedApplication.statusBarOrientation;
  CGFloat imageWidth = image.size.width;
  CGFloat imageHeight = image.size.height;
  if (imageWidth <= FLT_EPSILON || imageHeight <= FLT_EPSILON) {
    _imageView.image = image;
    NSLog(@"Failed to update image view because image has invalid size: %@", NSStringFromCGSize(image.size));
    return;
  }
  
  CGFloat scaledImageWidth = 0.0;
  CGFloat scaledImageHeight = 0.0;
  switch (orientation) {
      case UIInterfaceOrientationPortrait:
      case UIInterfaceOrientationPortraitUpsideDown:
      case UIInterfaceOrientationUnknown:
      scaledImageWidth = _imageView.bounds.size.width;
      scaledImageHeight = imageHeight * scaledImageWidth / imageWidth;
      break;
      case UIInterfaceOrientationLandscapeLeft:
      case UIInterfaceOrientationLandscapeRight:
      scaledImageWidth = imageWidth * scaledImageHeight / imageHeight;
      scaledImageHeight = _imageView.bounds.size.height;
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
    UIImage *scaledImage = [image scaledImageWithSize:CGSizeMake(scaledImageWidth, scaledImageHeight)];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.imageView.image = scaledImage ? scaledImage : image;
    });
  });
}

#pragma mark - Constants

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
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

@end
