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
#import "UIImage+VisionDetection.h"
#import "UIUtilities.h"

@import Firebase;

NS_ASSUME_NONNULL_BEGIN

static NSArray *images;

static NSString *const detectionNoResultsMessage = @"No results returned.";
static NSString *const sparseTextModelName = @"Sparse";
static NSString *const denseTextModelName = @"Dense";

static CGColorRef lineColor;
static CGColorRef fillColor;

static int const rowsCount = 5;
static int const componentsCount = 1;

/**
 * @enum DetectorPickerRow
 * Defines the Firebase ML SDK vision detector types.
 */
typedef NS_ENUM(NSInteger, DetectorPickerRow) {
  /** Cloud vision text vision detector (Sparse). */
  DetectorPickerRowDetectTextInCloudSparse,
  /** Cloud vision text vision detector (Dense). */
  DetectorPickerRowDetectTextInCloudDense,
  /** Cloud vision document text vision detector. */
  DetectorPickerRowDetectDocumentTextInCloud,
  /** Cloud vision label vision detector. */
  DetectorPickerRowDetectImageLabelsInCloud,
  /** Cloud vision landmark vision detector. */
  DetectorPickerRowDetectLandmarkInCloud
};

@interface ViewController () <UINavigationControllerDelegate,
                              UIPickerViewDelegate,
                              UIPickerViewDataSource,
                              UIImagePickerControllerDelegate>

@property(nonatomic) FIRVision *vision;

/** A string holding current results from detection. */
@property(nonatomic) NSMutableString *resultsText;

/** An overlay view that displays detection annotations. */
@property(nonatomic) UIView *annotationOverlayView;

/** An image picker for accessing the photo library or camera. */
@property(nonatomic) UIImagePickerController *imagePicker;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;

// Image counter.
@property(nonatomic) NSUInteger currentImage;

@property(weak, nonatomic) IBOutlet UIPickerView *detectorPicker;
@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *photoCameraButton;

@end

@implementation ViewController

- (NSString *)stringForDetectorPickerRow:(DetectorPickerRow)detectorPickerRow {
  switch (detectorPickerRow) {
    case DetectorPickerRowDetectTextInCloudSparse:
      return @"Text in Cloud (Sparse)";
    case DetectorPickerRowDetectTextInCloudDense:
      return @"Text in Cloud (Dense)";
    case DetectorPickerRowDetectDocumentTextInCloud:
      return @"Document Text in Cloud";
    case DetectorPickerRowDetectImageLabelsInCloud:
      return @"Image Labeling in Cloud";
    case DetectorPickerRowDetectLandmarkInCloud:
      return @"Landmarks in Cloud";
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];

  images = @[
    @"grace_hopper.jpg", @"beach.jpg", @"image_has_text.jpg",
    @"liberty.jpg"
  ];
  lineColor = UIColor.yellowColor.CGColor;
  fillColor = UIColor.clearColor.CGColor;

  // [START init_vision]
  self.vision = [FIRVision vision];
  // [END init_vision]

  self.imagePicker = [UIImagePickerController new];
  self.resultsText = [NSMutableString new];
  _currentImage = 0;
  _imageView.image = [UIImage imageNamed:images[_currentImage]];
  _annotationOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
  _annotationOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
  [_imageView addSubview:_annotationOverlayView];
  [NSLayoutConstraint activateConstraints:@[
    [_annotationOverlayView.topAnchor constraintEqualToAnchor:_imageView.topAnchor],
    [_annotationOverlayView.leadingAnchor constraintEqualToAnchor:_imageView.leadingAnchor],
    [_annotationOverlayView.trailingAnchor constraintEqualToAnchor:_imageView.trailingAnchor],
    [_annotationOverlayView.bottomAnchor constraintEqualToAnchor:_imageView.bottomAnchor]
  ]];
  _imagePicker.delegate = self;
  _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

  _detectorPicker.delegate = self;
  _detectorPicker.dataSource = self;

  BOOL isCameraAvailable =
      [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
      [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
  if (!isCameraAvailable) {
    [_photoCameraButton setEnabled:NO];
  }

  int defaultRow = (rowsCount / 2) - 1;
  [_detectorPicker selectRow:defaultRow inComponent:0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.navigationController.navigationBar setHidden:NO];
}

- (IBAction)detect:(id)sender {
  [self clearResults];
  NSInteger rowIndex = [_detectorPicker selectedRowInComponent:0];
  switch (rowIndex) {
    case DetectorPickerRowDetectTextInCloudSparse:
      [self detectTextInCloudInImage:_imageView.image withOptions:nil];
      break;
    case DetectorPickerRowDetectTextInCloudDense: {
      FIRVisionCloudTextRecognizerOptions *options = [FIRVisionCloudTextRecognizerOptions new];
      options.modelType = FIRVisionCloudTextModelTypeDense;
      [self detectTextInCloudInImage:_imageView.image withOptions:options];
      break;
    }
    case DetectorPickerRowDetectDocumentTextInCloud:
      [self detectDocumentTextInCloudInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectImageLabelsInCloud:
      [self detectCloudLabelsInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectLandmarkInCloud:
      [self detectCloudLandmarksInImage:_imageView.image];
      break;
  }
}

- (IBAction)openPhotoLibrary:(id)sender {
  _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (IBAction)openCamera:(id)sender {
  if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] &&
      ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
    return;
  }
  _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (IBAction)changeImage:(id)sender {
  [self clearResults];
  self.currentImage = (_currentImage + 1) % images.count;
  _imageView.image = [UIImage imageNamed:images[_currentImage]];
}

/// Removes the detection annotations from the annotation overlay view.
- (void)removeDetectionAnnotations {
  for (UIView *annotationView in _annotationOverlayView.subviews) {
    [annotationView removeFromSuperview];
  }
}

/// Clears the results text view and removes any frames that are visible.
- (void)clearResults {
  [self removeDetectionAnnotations];
  self.resultsText = [NSMutableString new];
}

- (void)showResults {
  UIAlertController *resultsAlertController =
      [UIAlertController alertControllerWithTitle:@"Detection Results"
                                          message:nil
                                   preferredStyle:UIAlertControllerStyleActionSheet];
  [resultsAlertController
      addAction:[UIAlertAction actionWithTitle:@"OK"
                                         style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction *_Nonnull action) {
                                         [resultsAlertController dismissViewControllerAnimated:YES
                                                                                    completion:nil];
                                       }]];
  resultsAlertController.message = _resultsText;
  resultsAlertController.popoverPresentationController.barButtonItem = _detectButton;
  resultsAlertController.popoverPresentationController.sourceView = self.view;
  [self presentViewController:resultsAlertController animated:YES completion:nil];
  NSLog(@"%@", _resultsText);
}

/// Updates the image view with a scaled version of the given image.
- (void)updateImageViewWithImage:(UIImage *)image {
  CGFloat scaledImageWidth = 0.0;
  CGFloat scaledImageHeight = 0.0;
  switch (UIApplication.sharedApplication.statusBarOrientation) {
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationPortraitUpsideDown:
    case UIInterfaceOrientationUnknown:
      scaledImageWidth = _imageView.bounds.size.width;
      scaledImageHeight = image.size.height * scaledImageWidth / image.size.width;
      break;
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      scaledImageWidth = image.size.width * scaledImageHeight / image.size.height;
      scaledImageHeight = _imageView.bounds.size.height;
      break;
  }

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
    UIImage *scaledImage =
        [image scaledImageWithSize:CGSizeMake(scaledImageWidth, scaledImageHeight)];
    if (!scaledImage) {
      scaledImage = image;
    }
    if (!scaledImage) {
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_imageView.image = scaledImage;
    });
  });
}

- (CGAffineTransform)transformMatrix {
  UIImage *image = _imageView.image;
  if (!image) {
    return CGAffineTransformMake(0, 0, 0, 0, 0, 0);
  }
  CGFloat imageViewWidth = _imageView.frame.size.width;
  CGFloat imageViewHeight = _imageView.frame.size.height;
  CGFloat imageWidth = image.size.width;
  CGFloat imageHeight = image.size.height;

  CGFloat imageViewAspectRatio = imageViewWidth / imageViewHeight;
  CGFloat imageAspectRatio = imageWidth / imageHeight;
  CGFloat scale = (imageViewAspectRatio > imageAspectRatio) ? imageViewHeight / imageHeight
                                                            : imageViewWidth / imageWidth;

  // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
  // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
  CGFloat scaledImageWidth = imageWidth * scale;
  CGFloat scaledImageHeight = imageHeight * scale;
  CGFloat xValue = (imageViewWidth - scaledImageWidth) / 2.0;
  CGFloat yValue = (imageViewHeight - scaledImageHeight) / 2.0;

  CGAffineTransform transform =
      CGAffineTransformTranslate(CGAffineTransformIdentity, xValue, yValue);
  return CGAffineTransformScale(transform, scale, scale);
}

- (void)process:(FIRVisionImage *)visionImage
    withTextRecognizer:(FIRVisionTextRecognizer *)textRecognizer {
  // [START recognize_text]
  [textRecognizer
      processImage:visionImage
        completion:^(FIRVisionText *_Nullable text, NSError *_Nullable error) {
          if (text == nil) {
            // [START_EXCLUDE]
            self.resultsText = [NSMutableString
                stringWithFormat:@"Text recognizer failed with error: %@",
                                 error ? error.localizedDescription : detectionNoResultsMessage];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }

          // [START_EXCLUDE]
          // Blocks.
          for (FIRVisionTextBlock *block in text.blocks) {
            CGRect transformedRect =
                CGRectApplyAffineTransform(block.frame, [self transformMatrix]);
            [UIUtilities addRectangle:transformedRect
                               toView:self.annotationOverlayView
                                color:UIColor.purpleColor];

            // Lines.
            for (FIRVisionTextLine *line in block.lines) {
              CGRect transformedRect =
                  CGRectApplyAffineTransform(line.frame, [self transformMatrix]);
              [UIUtilities addRectangle:transformedRect
                                 toView:self.annotationOverlayView
                                  color:UIColor.orangeColor];

              // Elements.
              for (FIRVisionTextElement *element in line.elements) {
                CGRect transformedRect =
                    CGRectApplyAffineTransform(element.frame, [self transformMatrix]);
                [UIUtilities addRectangle:transformedRect
                                   toView:self.annotationOverlayView
                                    color:UIColor.greenColor];
                UILabel *label = [[UILabel alloc] initWithFrame:transformedRect];
                label.text = element.text;
                label.adjustsFontSizeToFitWidth = YES;
                [self.annotationOverlayView addSubview:label];
              }
            }
          }
          [self.resultsText appendFormat:@"%@\n", text.text];
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END recognize_text]
}

- (void)process:(FIRVisionImage *)visionImage
    withDocumentTextRecognizer:(FIRVisionDocumentTextRecognizer *)documentTextRecognizer {
  // [START recognize_document_text]
  [documentTextRecognizer
      processImage:visionImage
        completion:^(FIRVisionDocumentText *_Nullable text, NSError *_Nullable error) {
          if (text == nil) {
            // [START_EXCLUDE]
            self.resultsText = [NSMutableString
                stringWithFormat:@"Document text recognizer failed with error: %@",
                                 error ? error.localizedDescription : detectionNoResultsMessage];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }
          // [START_EXCLUDE]
          // Blocks.
          for (FIRVisionDocumentTextBlock *block in text.blocks) {
            CGRect transformedRect =
                CGRectApplyAffineTransform(block.frame, [self transformMatrix]);
            [UIUtilities addRectangle:transformedRect
                               toView:self.annotationOverlayView
                                color:UIColor.purpleColor];

            // Paragraphs.
            for (FIRVisionDocumentTextParagraph *paragraph in block.paragraphs) {
              CGRect transformedRect =
                  CGRectApplyAffineTransform(paragraph.frame, [self transformMatrix]);
              [UIUtilities addRectangle:transformedRect
                                 toView:self.annotationOverlayView
                                  color:UIColor.orangeColor];

              // Words.
              for (FIRVisionDocumentTextWord *word in paragraph.words) {
                CGRect transformedRect =
                    CGRectApplyAffineTransform(word.frame, [self transformMatrix]);
                [UIUtilities addRectangle:transformedRect
                                   toView:self.annotationOverlayView
                                    color:UIColor.greenColor];

                // Symbols.
                for (FIRVisionDocumentTextSymbol *symbol in word.symbols) {
                  CGRect transformedRect =
                      CGRectApplyAffineTransform(symbol.frame, [self transformMatrix]);
                  [UIUtilities addRectangle:transformedRect
                                     toView:self.annotationOverlayView
                                      color:UIColor.cyanColor];
                  UILabel *label = [[UILabel alloc] initWithFrame:transformedRect];
                  label.text = symbol.text;
                  label.adjustsFontSizeToFitWidth = YES;
                  [self.annotationOverlayView addSubview:label];
                }
              }
            }
          }
          [self.resultsText appendFormat:@"%@\n", text.text];
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END recognize_document_text]
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
  return componentsCount;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView
    numberOfRowsInComponent:(NSInteger)component {
  return rowsCount;
}

#pragma mark - UIPickerViewDelegate

- (nullable NSString *)pickerView:(UIPickerView *)pickerView
                      titleForRow:(NSInteger)row
                     forComponent:(NSInteger)component {
  return [self stringForDetectorPickerRow:row];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  [self clearResults];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
  [self clearResults];
  UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
  if (pickedImage) {
    [self updateImageViewWithImage:pickedImage];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Vision Cloud Detection

/// Detects text on the specified image and draws a frame around the recognized text using the
/// Cloud text recognizer.
///
/// - Parameter image: The image.
- (void)detectTextInCloudInImage:(UIImage *)image
                     withOptions:(nullable FIRVisionCloudTextRecognizerOptions *)options {
  if (!image) {
    return;
  }

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  FIRVisionTextRecognizer *cloudTextRecognizer;
  NSString *modelTypeString = sparseTextModelName;
  if (options != nil) {
    modelTypeString = (options.modelType == FIRVisionCloudTextModelTypeDense) ? denseTextModelName
                                                                              : modelTypeString;
    // [START init_text_cloud]
    cloudTextRecognizer = [_vision cloudTextRecognizerWithOptions:options];
    // [END init_text_cloud]
  } else {
    cloudTextRecognizer = [_vision cloudTextRecognizer];
  }

  [_resultsText
      appendString:[NSString stringWithFormat:@"Running Cloud Text Recognition (%@ model)...\n",
                                              modelTypeString]];
  [self process:visionImage withTextRecognizer:cloudTextRecognizer];
}

/// Detects document text on the specified image and draws a frame around the recognized text
/// using the Cloud document text recognizer.
///
/// - Parameter image: The image.
- (void)detectDocumentTextInCloudInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // [START init_document_text_cloud]
  FIRVisionDocumentTextRecognizer *cloudDocumentTextRecognizer =
      [_vision cloudDocumentTextRecognizer];
  // [END init_document_text_cloud]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  [_resultsText appendString:@"Running Cloud Document Text Recognition...\n"];
  [self process:visionImage withDocumentTextRecognizer:cloudDocumentTextRecognizer];
}

/// Detects landmarks on the specified image and draws a frame around the detected landmarks using
/// cloud landmark API.
///
/// - Parameter image: The image.
- (void)detectCloudLandmarksInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // Create a landmark detector.
  // [START config_landmark_cloud]
  FIRVisionCloudDetectorOptions *options = [FIRVisionCloudDetectorOptions new];
  options.modelType = FIRVisionCloudModelTypeLatest;
  options.maxResults = 20;
  // [END config_landmark_cloud]

  // [START init_landmark_cloud]
  FIRVisionCloudLandmarkDetector *cloudDetector =
      [_vision cloudLandmarkDetectorWithOptions:options];
  // Or, to use the default settings:
  // FIRVisionCloudLandmarkDetector *cloudDetector = [_vision cloudLandmarkDetector];
  // [END init_landmark_cloud]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_landmarks_cloud]
  [cloudDetector
      detectInImage:visionImage
         completion:^(NSArray<FIRVisionCloudLandmark *> *_Nullable landmarks,
                      NSError *_Nullable error) {
           if (!landmarks || landmarks.count == 0) {
             // [START_EXCLUDE]
             NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
             self.resultsText = [NSMutableString
                 stringWithFormat:@"Cloud landmark detection failed with error: %@", errorString];
             [self showResults];
             // [END_EXCLUDE]
             return;
           }

           // Recognized landmarks
           // [START_EXCLUDE]
           [self.resultsText setString:@""];
           for (FIRVisionCloudLandmark *landmark in landmarks) {
             CGAffineTransform transform = [self transformMatrix];
             CGRect transformedRect = CGRectApplyAffineTransform(landmark.frame, transform);
             [UIUtilities addRectangle:transformedRect
                                toView:self.annotationOverlayView
                                 color:UIColor.greenColor];
             [self.resultsText
                 appendFormat:@"Landmark: %@, Confidence: %@, EntityID: %@, Frame: %@\n",
                              landmark.landmark, landmark.confidence, landmark.entityId,
                              NSStringFromCGRect(landmark.frame)];
           }
           [self showResults];
           // [END_EXCLUDE]
         }];
  // [END detect_landmarks_cloud]
}

/// Detects labels on the specified image using cloud label API.
///
/// - Parameter image: The image.
- (void)detectCloudLabelsInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // [START init_label_cloud]
  FIRVisionImageLabeler *cloudLabeler = [_vision cloudImageLabeler];
  // Or, to change the default settings:
  // FIRVisionImageLabeler *cloudLabeler = [_vision cloudImageLabelerWithOptions:options];
  // [END init_label_cloud]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_label_cloud]
  [cloudLabeler
      processImage:visionImage
        completion:^(NSArray<FIRVisionImageLabel *> *_Nullable labels, NSError *_Nullable error) {
          if (!labels || labels.count == 0) {
            // [START_EXCLUDE]
            NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
            self.resultsText = [NSMutableString
                stringWithFormat:@"Cloud label detection failed with error: %@", errorString];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }

          // Labeled image
          // [START_EXCLUDE]
          [self.resultsText setString:@""];
          for (FIRVisionImageLabel *label in labels) {
            [self.resultsText appendFormat:@"Label: %@, Confidence: %@, EntityID: %@\n", label.text,
                                           label.confidence, label.entityID];
          }
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END detect_label_cloud]
}
@end

NS_ASSUME_NONNULL_END
