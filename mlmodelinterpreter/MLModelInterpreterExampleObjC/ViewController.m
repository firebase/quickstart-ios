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

// REPLACE THESE CLOUD MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
static NSString *const cloudModelNameFloat = @"imagenet-classification-float-v2";
static NSString *const cloudModelNameQuantized = @"imagenet-classification-quant-v2";
static NSString *const cloudModelNameInvalid = @"invalid_model";

static NSString *const defaultImage = @"grace_hopper.jpg";
static NSString *const cloudModel1DownloadCompletedKey = @"FIRCloudModel1DownloadCompleted";
static NSString *const cloudModel2DownloadCompletedKey = @"FIRCloudModel2DownloadCompleted";
static NSString *const failedToDetectObjectsMessage = @"Failed to detect objects in image.";
static uint const componentsCount = 3;

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

#pragma mark - Properties

/// Model interpreter manager that manages loading models and detecting objects.
@property(nonatomic) ModelInterpreterManager *modelManager;

/// Indicates whether the download cloud model button was selected.
@property(nonatomic) bool downloadCloudModelButtonSelected;

/// An image picker for accessing the photo library or camera.
@property(nonatomic) UIImagePickerController *imagePicker;

#pragma mark - Properties

/// A segmented control for changing models (0 = float, 1 = quantized, 2 = invalid).
@property (weak, nonatomic) IBOutlet UISegmentedControl *modelControl;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *resultsTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadModelButton;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.modelManager = [ModelInterpreterManager new];
  self.downloadCloudModelButtonSelected = NO;
  self.imagePicker = [UIImagePickerController new];
  _imageView.image = [UIImage imageNamed:defaultImage];
  _imagePicker.delegate = self;

  if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
      ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
    [_cameraButton setEnabled:NO];
  }

  [self setUpCloudModel];
  [self setUpLocalModel];
}

#pragma mark - IBActions

- (IBAction)detectObjects:(id)sender {
  [self clearResults];
  UIImage *image = _imageView.image;
  if (!image) {
    _resultsTextView.text = @"Image must not be nil.\n";
    return;
  }

  if (!_downloadCloudModelButtonSelected) {
    _resultsTextView.text = @"Loading the local model...\n";
    if (![_modelManager loadLocalModelWithIsQuantized:[self quantized]]) {
      _resultsTextView.text = @"Failed to load the local model.";
      return;
    }
  }
  NSString *newResultsTextString = @"Starting inference...\n";
  if (_resultsTextView.text) {
    _resultsTextView.text = [_resultsTextView.text stringByAppendingString:newResultsTextString];
  }
  BOOL isQuantized = [self quantized];
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSObject *imageData;
    if (isQuantized) {
      imageData = [self.modelManager scaledImageDataFromImage:image componentsCount:componentsCount];
    } else {
      imageData = [self.modelManager scaledPixelArrayFromImage:image componentsCount:componentsCount isQuantized:isQuantized];
    }
    [self.modelManager detectObjectsInImageData:imageData topResultsCount:nil completion:^(NSArray * _Nullable results, NSError * _Nullable error) {
      if (!results || results.count == 0) {
        NSString *errorString = error ? error.localizedDescription : failedToDetectObjectsMessage;
        errorString = [NSString stringWithFormat:@"Inference error: %@", errorString];
        NSLog(@"%@", errorString);
        self.resultsTextView.text = errorString;
        return;
      }

      NSString *inferenceMessageString;
      if (self.downloadCloudModelButtonSelected) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:[self currentCloudModelKey]];
        inferenceMessageString = [NSString stringWithFormat:@"Inference results using `%@` cloud model:\n", [self currentCloudModelName]];
      } else {
        inferenceMessageString = @"Inference results using the local model:\n";
      }
      self.resultsTextView.text = [inferenceMessageString stringByAppendingString:[self detectionResultsStringRromResults:results]];
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

- (IBAction)downloadCloudModel:(id)sender {
  [self clearResults];
  _downloadCloudModelButtonSelected = true;
  BOOL isCloudModelDownloaded = [NSUserDefaults.standardUserDefaults boolForKey:[self currentCloudModelKey]];
  _resultsTextView.text = isCloudModelDownloaded ?
    @"Cloud model loaded. Select the `Detect` button to start the inference." :
  @"Downloading cloud model. Once the download has completed, select the `Detect` button to start the inference.";
  if (![_modelManager loadCloudModelWithIsQuantized:[self quantized]]) {
    _resultsTextView.text = @"Failed to load the cloud model.";
  }
}

- (IBAction)modelSwitched:(id)sender {
  [self clearResults];
  [self setUpLocalModel];
  [self setUpCloudModel];
}

#pragma mark - Private

  /// Returns the name for the currently selected cloud model.
- (NSString *)currentCloudModelName {
  switch (_modelControl.selectedSegmentIndex) {
    case 0:
    return cloudModelNameFloat;
    case 1:
    return cloudModelNameQuantized;
    case 2:
    return cloudModelNameInvalid;
    default:
    return @"";
  }
}

  /// Returns the name for the currently selected cloud model.
- (NSString *)currentLocalModelName {
  switch (_modelControl.selectedSegmentIndex) {
    case 0:
    return floatModelFilename;
    case 1:
    return quantizedModelFilename;
    case 2:
    return invalidModelFilename;
    default:
    return @"";
  }
}

  /// Returns the key for the currently selected cloud model.
- (NSString *)currentCloudModelKey {
  return (_modelControl.selectedSegmentIndex == 0) ?
    cloudModel1DownloadCompletedKey :
  cloudModel2DownloadCompletedKey;
  }

- (BOOL)quantized {
  return (_modelControl.selectedSegmentIndex == 1);
}

  /// Sets up the currently selected cloud model.
- (void)setUpCloudModel {
  NSString *name = [self currentCloudModelName];
  if (![_modelManager setUpCloudModelWithName:name]) {
    if (_resultsTextView.text) {
      _resultsTextView.text = @"";
    }
    _resultsTextView.text = [NSString stringWithFormat:@"%@\nFailed to set up the `%@` cloud model.", _resultsTextView.text, name];
    }
  }

  /// Sets up the local model.
- (void)setUpLocalModel {
  NSString *name = [self currentLocalModelName];
  NSString *filename = [self currentLocalModelName];
  [self currentLocalModelName];

  if (![_modelManager setUpLocalModelWithName:name filename:filename]) {
    if (_resultsTextView.text) {
      _resultsTextView.text = @"";
    }
    _resultsTextView.text = [_resultsTextView.text stringByAppendingString:@"\nFailed to set up the local model."];
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

  /// Clears the results from the last inference call.
- (void)clearResults {
  _resultsTextView.text = nil;
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
  [self clearResults];

  UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
  if (pickedImage) [self updateImageViewWithImage:pickedImage];
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
