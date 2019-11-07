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
static NSString *const ModelExtension = @"tflite";
static NSString *const quantizedModelFilename = @"mobilenet_quant_v1_224";

static NSString *const detectionNoResultsMessage = @"No results returned.";
static NSString *const failedToDetectObjectsMessage = @"Failed to detect objects in image.";
static NSString *const sparseTextModelName = @"Sparse";
static NSString *const denseTextModelName = @"Dense";

/** Name of the local AutoML model. */
static NSString *const FIRLocalAutoMLModelName = @"local_automl_model";

/** Name of the remote AutoML model. */
static NSString *const FIRRemoteAutoMLModelName = @"remote_automl_model";

/** Filename of AutoML local model manifest in the main resource bundle. */
static NSString *const FIRAutoMLLocalModelManifestFilename = @"automl_labeler_manifest";

/** File type of AutoML local model manifest in the main resource bundle. */
static NSString *const FIRAutoMLManifestFileType = @"json";

static float const labelConfidenceThreshold = 0.75;
static CGFloat const smallDotRadius = 5.0;
static CGFloat const largeDotRadius = 10.0;
static CGColorRef lineColor;
static CGColorRef fillColor;

static int const rowsCount = 14;
static int const componentsCount = 1;

/**
 * @enum DetectorPickerRow
 * Defines the Firebase ML SDK vision detector types.
 */
typedef NS_ENUM(NSInteger, DetectorPickerRow) {
  /** On-Device vision face vision detector. */
  DetectorPickerRowDetectFaceOnDevice,
  /** On-Device vision text vision detector. */
  DetectorPickerRowDetectTextOnDevice,
  /** On-Device vision barcode vision detector. */
  DetectorPickerRowDetectBarcodeOnDevice,
  /** On-Device vision image label detector. */
  DetectorPickerRowDetectImageLabelsOnDevice,
  /** On-Device vision AutoML image label detector. */
  DetectorPickerRowDetectImageLabelsAutoMLOnDevice,
  /** On-Device vision object detector, prominent, only tracking. */
  DetectorPickerRowDetectObjectsProminentNoClassifier,
  /** On-Device vision object detector, prominent, with classification. */
  DetectorPickerRowDetectObjectsProminentWithClassifier,
  /** On-Device vision object detector, multiple, only tracking. */
  DetectorPickerRowDetectObjectsMultipleNoClassifier,
  /** On-Device vision object detector, multiple, with classification. */
  DetectorPickerRowDetectObjectsMultipleWithClassifier,
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

@property(nonatomic) FIRModelManager *modelManager;

/** A string holding current results from detection. */
@property(nonatomic) NSMutableString *resultsText;

/** An overlay view that displays detection annotations. */
@property(nonatomic) UIView *annotationOverlayView;

/** An image picker for accessing the photo library or camera. */
@property(nonatomic) UIImagePickerController *imagePicker;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;
@property(strong, nonatomic) IBOutlet UIProgressView *downloadProgressView;

// Image counter.
@property(nonatomic) NSUInteger currentImage;

@property(weak, nonatomic) IBOutlet UIPickerView *detectorPicker;
@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *photoCameraButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *videoCameraButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *downloadOrDeleteModelButton;

@end

@implementation ViewController

- (NSString *)stringForDetectorPickerRow:(DetectorPickerRow)detectorPickerRow {
  switch (detectorPickerRow) {
    case DetectorPickerRowDetectFaceOnDevice:
      return @"Face On-Device";
    case DetectorPickerRowDetectTextOnDevice:
      return @"Text On-Device";
    case DetectorPickerRowDetectBarcodeOnDevice:
      return @"Barcode On-Device";
    case DetectorPickerRowDetectImageLabelsOnDevice:
      return @"Image Labeling On-Device";
    case DetectorPickerRowDetectImageLabelsAutoMLOnDevice:
      return @"AutoML Image Labeling On-Device";
    case DetectorPickerRowDetectObjectsProminentNoClassifier:
      return @"ODT, prominent, only tracking";
    case DetectorPickerRowDetectObjectsProminentWithClassifier:
      return @"ODT, prominent, with classification";
    case DetectorPickerRowDetectObjectsMultipleNoClassifier:
      return @"ODT, multiple, only tracking";
    case DetectorPickerRowDetectObjectsMultipleWithClassifier:
      return @"ODT, multiple, with classification";
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
    @"grace_hopper.jpg", @"barcode_128.png", @"qr_code.jpg", @"beach.jpg", @"image_has_text.jpg",
    @"liberty.jpg"
  ];
  lineColor = UIColor.yellowColor.CGColor;
  fillColor = UIColor.clearColor.CGColor;

  // [START init_vision]
  self.vision = [FIRVision vision];
  // [END init_vision]

  _modelManager = [FIRModelManager modelManager];
  FIRAutoMLRemoteModel *remoteModel =
      [[FIRAutoMLRemoteModel alloc] initWithName:FIRRemoteAutoMLModelName];
  NSString *buttonImage =
      [self.modelManager isModelDownloaded:remoteModel] ? @"delete" : @"cloud_download";
  self.downloadOrDeleteModelButton.image = [UIImage imageNamed:buttonImage];

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
  if (isCameraAvailable) {
    // `CameraViewController` uses `AVCaptureDeviceDiscoverySession` which is only supported for
    // iOS 10 or newer.
    if (@available(iOS 10, *)) {
      [_videoCameraButton setEnabled:YES];
    }
  } else {
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
    case DetectorPickerRowDetectFaceOnDevice:
      [self detectFacesInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectTextOnDevice:
      [self detectTextOnDeviceInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectBarcodeOnDevice:
      [self detectBarcodesInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectImageLabelsOnDevice:
      [self detectLabelsInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectImageLabelsAutoMLOnDevice:
      [self detectImageLabelsAutoMLInImage:_imageView.image];
      break;
    case DetectorPickerRowDetectObjectsProminentNoClassifier:
    case DetectorPickerRowDetectObjectsProminentWithClassifier:
    case DetectorPickerRowDetectObjectsMultipleNoClassifier:
    case DetectorPickerRowDetectObjectsMultipleWithClassifier: {
      BOOL shouldEnableClassification =
          (rowIndex == DetectorPickerRowDetectObjectsProminentWithClassifier) ||
          (rowIndex == DetectorPickerRowDetectObjectsMultipleWithClassifier);
      BOOL shouldEnableMultipleObjects =
          (rowIndex == DetectorPickerRowDetectObjectsMultipleNoClassifier) ||
          (rowIndex == DetectorPickerRowDetectObjectsMultipleWithClassifier);
      FIRVisionObjectDetectorOptions *options = [FIRVisionObjectDetectorOptions new];
      options.shouldEnableClassification = shouldEnableClassification;
      options.shouldEnableMultipleObjects = shouldEnableMultipleObjects;
      options.detectorMode = FIRVisionObjectDetectorModeSingleImage;
      [self detectObjectsOnDeviceInImage:_imageView.image withOptions:options];
      break;
    }
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

- (IBAction)downloadOrDeleteModel:(id)sender {
  [self clearResults];
  FIRAutoMLRemoteModel *remoteModel =
      [[FIRAutoMLRemoteModel alloc] initWithName:FIRRemoteAutoMLModelName];
  if ([self.modelManager isModelDownloaded:remoteModel]) {
    [self.modelManager
        deleteDownloadedModel:remoteModel
                   completion:^(NSError *_Nullable error) {
                     if (error) {
                       NSLog(@"Failed to delete the AutoML model.");
                       return;
                     }
                     NSLog(@"The downloaded remote model has been successfully deleted.");
                     self.downloadOrDeleteModelButton.image =
                         [UIImage imageNamed:@"cloud_download"];
                   }];
  }
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

- (CGPoint)pointFromVisionPoint:(FIRVisionPoint *)visionPoint {
  return CGPointMake(visionPoint.x.floatValue, visionPoint.y.floatValue);
}

- (void)addContoursForFace:(FIRVisionFace *)face transform:(CGAffineTransform)transform {
  // Face
  FIRVisionFaceContour *faceContour = [face contourOfType:FIRFaceContourTypeFace];
  for (FIRVisionPoint *visionPoint in faceContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }

  // Eyebrows
  FIRVisionFaceContour *leftEyebrowTopContour =
      [face contourOfType:FIRFaceContourTypeLeftEyebrowTop];
  for (FIRVisionPoint *visionPoint in leftEyebrowTopContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *leftEyebrowBottomContour =
      [face contourOfType:FIRFaceContourTypeLeftEyebrowBottom];
  for (FIRVisionPoint *visionPoint in leftEyebrowBottomContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *rightEyebrowTopContour =
      [face contourOfType:FIRFaceContourTypeRightEyebrowTop];
  for (FIRVisionPoint *visionPoint in rightEyebrowTopContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *rightEyebrowBottomContour =
      [face contourOfType:FIRFaceContourTypeRightEyebrowBottom];
  for (FIRVisionPoint *visionPoint in rightEyebrowBottomContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }

  // Eyes
  FIRVisionFaceContour *leftEyeContour = [face contourOfType:FIRFaceContourTypeLeftEye];
  for (FIRVisionPoint *visionPoint in leftEyeContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *rightEyeContour = [face contourOfType:FIRFaceContourTypeRightEye];
  for (FIRVisionPoint *visionPoint in rightEyeContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }

  // Lips
  FIRVisionFaceContour *upperLipTopContour = [face contourOfType:FIRFaceContourTypeUpperLipTop];
  for (FIRVisionPoint *visionPoint in upperLipTopContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *upperLipBottomContour =
      [face contourOfType:FIRFaceContourTypeUpperLipBottom];
  for (FIRVisionPoint *visionPoint in upperLipBottomContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *lowerLipTopContour = [face contourOfType:FIRFaceContourTypeLowerLipTop];
  for (FIRVisionPoint *visionPoint in lowerLipTopContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *lowerLipBottomContour =
      [face contourOfType:FIRFaceContourTypeLowerLipBottom];
  for (FIRVisionPoint *visionPoint in lowerLipBottomContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }

  // Nose
  FIRVisionFaceContour *noseBridgeContour = [face contourOfType:FIRFaceContourTypeNoseBridge];
  for (FIRVisionPoint *visionPoint in noseBridgeContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
  FIRVisionFaceContour *noseBottomContour = [face contourOfType:FIRFaceContourTypeNoseBottom];
  for (FIRVisionPoint *visionPoint in noseBottomContour.points) {
    CGPoint point = [self pointFromVisionPoint:visionPoint];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:smallDotRadius];
  }
}

- (void)addLandmarksForFace:(FIRVisionFace *)face transform:(CGAffineTransform)transform {
  // Mouth
  FIRVisionFaceLandmark *bottomMouthLandmark = [face landmarkOfType:FIRFaceLandmarkTypeMouthBottom];
  if (bottomMouthLandmark) {
    CGPoint point = [self pointFromVisionPoint:bottomMouthLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.redColor
                           radius:largeDotRadius];
  }
  FIRVisionFaceLandmark *leftMouthLandmark = [face landmarkOfType:FIRFaceLandmarkTypeMouthLeft];
  if (leftMouthLandmark) {
    CGPoint point = [self pointFromVisionPoint:leftMouthLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.redColor
                           radius:largeDotRadius];
  }
  FIRVisionFaceLandmark *rightMouthLandmark = [face landmarkOfType:FIRFaceLandmarkTypeMouthLeft];
  if (rightMouthLandmark) {
    CGPoint point = [self pointFromVisionPoint:rightMouthLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.redColor
                           radius:largeDotRadius];
  }

  // Nose
  FIRVisionFaceLandmark *noseBaseLandmark = [face landmarkOfType:FIRFaceLandmarkTypeNoseBase];
  if (noseBaseLandmark) {
    CGPoint point = [self pointFromVisionPoint:noseBaseLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.yellowColor
                           radius:largeDotRadius];
  }

  // Eyes
  FIRVisionFaceLandmark *leftEyeLandmark = [face landmarkOfType:FIRFaceLandmarkTypeLeftEye];
  if (leftEyeLandmark) {
    CGPoint point = [self pointFromVisionPoint:leftEyeLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.cyanColor
                           radius:largeDotRadius];
  }
  FIRVisionFaceLandmark *rightEyeLandmark = [face landmarkOfType:FIRFaceLandmarkTypeRightEye];
  if (rightEyeLandmark) {
    CGPoint point = [self pointFromVisionPoint:rightEyeLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.cyanColor
                           radius:largeDotRadius];
  }

  // Ears
  FIRVisionFaceLandmark *leftEarLandmark = [face landmarkOfType:FIRFaceLandmarkTypeLeftEye];
  if (leftEarLandmark) {
    CGPoint point = [self pointFromVisionPoint:leftEarLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.purpleColor
                           radius:largeDotRadius];
  }
  FIRVisionFaceLandmark *rightEarLandmark = [face landmarkOfType:FIRFaceLandmarkTypeRightEye];
  if (rightEarLandmark) {
    CGPoint point = [self pointFromVisionPoint:rightEarLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.purpleColor
                           radius:largeDotRadius];
  }

  // Cheeks
  FIRVisionFaceLandmark *leftCheekLandmark = [face landmarkOfType:FIRFaceLandmarkTypeLeftEye];
  if (leftCheekLandmark) {
    CGPoint point = [self pointFromVisionPoint:leftCheekLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.orangeColor
                           radius:largeDotRadius];
  }
  FIRVisionFaceLandmark *rightCheekLandmark = [face landmarkOfType:FIRFaceLandmarkTypeRightEye];
  if (rightCheekLandmark) {
    CGPoint point = [self pointFromVisionPoint:rightCheekLandmark.position];
    CGPoint transformedPoint = CGPointApplyAffineTransform(point, transform);
    [UIUtilities addCircleAtPoint:transformedPoint
                           toView:_annotationOverlayView
                            color:UIColor.orangeColor
                           radius:largeDotRadius];
  }
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
  self.downloadOrDeleteModelButton.enabled =
      row == DetectorPickerRowDetectImageLabelsAutoMLOnDevice;
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

#pragma mark - Vision On-Device Detection

/// Detects faces on the specified image and draws a frame around the detected faces using
/// On-Device face API.
///
/// - Parameter image: The image.
- (void)detectFacesInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // Create a face detector with options.
  // [START config_face]
  FIRVisionFaceDetectorOptions *options = [FIRVisionFaceDetectorOptions new];
  options.landmarkMode = FIRVisionFaceDetectorLandmarkModeAll;
  options.contourMode = FIRVisionFaceDetectorContourModeAll;
  options.classificationMode = FIRVisionFaceDetectorClassificationModeAll;
  options.performanceMode = FIRVisionFaceDetectorPerformanceModeAccurate;
  // [END config_face]

  // [START init_face]
  FIRVisionFaceDetector *faceDetector = [_vision faceDetectorWithOptions:options];
  // [END init_face]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_faces]
  [faceDetector
      processImage:visionImage
        completion:^(NSArray<FIRVisionFace *> *_Nullable faces, NSError *_Nullable error) {
          if (!faces || faces.count == 0) {
            // [START_EXCLUDE]
            NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
            self.resultsText = [NSMutableString
                stringWithFormat:@"On-Device face detection failed with error: %@", errorString];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }

          // Faces detected
          // [START_EXCLUDE]
          [self.resultsText setString:@""];
          for (FIRVisionFace *face in faces) {
            CGAffineTransform transform = [self transformMatrix];
            CGRect transformedRect = CGRectApplyAffineTransform(face.frame, transform);
            [UIUtilities addRectangle:transformedRect
                               toView:self.annotationOverlayView
                                color:UIColor.greenColor];
            [self addLandmarksForFace:face transform:transform];
            [self addContoursForFace:face transform:transform];
            [self.resultsText appendFormat:@"Frame: %@\n", NSStringFromCGRect(face.frame)];
            NSString *headEulerAngleY =
                face.hasHeadEulerAngleY ? [NSString stringWithFormat:@"%.2f", face.headEulerAngleY]
                                        : @"NA";
            NSString *headEulerAngleZ =
                face.hasHeadEulerAngleZ ? [NSString stringWithFormat:@"%.2f", face.headEulerAngleZ]
                                        : @"NA";
            NSString *leftEyeOpenProbability =
                face.hasLeftEyeOpenProbability
                    ? [NSString stringWithFormat:@"%.2f", face.leftEyeOpenProbability]
                    : @"NA";
            NSString *rightEyeOpenProbability =
                face.hasRightEyeOpenProbability
                    ? [NSString stringWithFormat:@"%.2f", face.rightEyeOpenProbability]
                    : @"NA";
            NSString *smilingProbability =
                face.hasSmilingProbability
                    ? [NSString stringWithFormat:@"%.2f", face.smilingProbability]
                    : @"NA";
            [self.resultsText appendFormat:@"Head Euler Angle Y: %@\n", headEulerAngleY];
            [self.resultsText appendFormat:@"Head Euler Angle Z: %@\n", headEulerAngleZ];
            [self.resultsText
                appendFormat:@"Left Eye Open Probability: %@\n", leftEyeOpenProbability];
            [self.resultsText
                appendFormat:@"Right Eye Open Probability: %@\n", rightEyeOpenProbability];
            [self.resultsText appendFormat:@"Smiling Probability: %@\n", smilingProbability];
          }
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END detect_faces]
}

/// Detects barcodes on the specified image and draws a frame around the detected barcodes using
/// On-Device barcode API.
///
/// - Parameter image: The image.
- (void)detectBarcodesInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // Define the options for a barcode detector.
  // [START config_barcode]
  FIRVisionBarcodeFormat format = FIRVisionBarcodeFormatAll;
  FIRVisionBarcodeDetectorOptions *barcodeOptions =
      [[FIRVisionBarcodeDetectorOptions alloc] initWithFormats:format];
  // [END config_barcode]

  // Create a barcode detector.
  // [START init_barcode]
  FIRVisionBarcodeDetector *barcodeDetector = [_vision barcodeDetectorWithOptions:barcodeOptions];
  // [END init_barcode]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_barcodes]
  [barcodeDetector
      detectInImage:visionImage
         completion:^(NSArray<FIRVisionBarcode *> *_Nullable barcodes, NSError *_Nullable error) {
           if (!barcodes || barcodes.count == 0) {
             // [START_EXCLUDE]
             NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
             self.resultsText = [NSMutableString
                 stringWithFormat:@"On-Device barcode detection failed with error: %@",
                                  errorString];
             [self showResults];
             // [END_EXCLUDE]
             return;
           }

           // [START_EXCLUDE]
           [self.resultsText setString:@""];
           for (FIRVisionBarcode *barcode in barcodes) {
             CGAffineTransform transform = [self transformMatrix];
             CGRect transformedRect = CGRectApplyAffineTransform(barcode.frame, transform);
             [UIUtilities addRectangle:transformedRect
                                toView:self.annotationOverlayView
                                 color:UIColor.greenColor];
             [self.resultsText appendFormat:@"DisplayValue: %@, RawValue: %@, Frame: %@\n",
                                            barcode.displayValue, barcode.rawValue,
                                            NSStringFromCGRect(barcode.frame)];
           }
           [self showResults];
           // [END_EXCLUDE]
         }];
  // [END detect_barcodes]
}

/// Detects labels on the specified image using On-Device label API.
///
/// - Parameter image: The image.
- (void)detectLabelsInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // [START config_label]
  FIRVisionOnDeviceImageLabelerOptions *options = [FIRVisionOnDeviceImageLabelerOptions new];
  options.confidenceThreshold = labelConfidenceThreshold;
  // [END config_label]

  // [START init_label]
  FIRVisionImageLabeler *onDeviceLabeler = [_vision onDeviceImageLabelerWithOptions:options];
  // [END init_label]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_label]
  [onDeviceLabeler
      processImage:visionImage
        completion:^(NSArray<FIRVisionImageLabel *> *_Nullable labels, NSError *_Nullable error) {
          if (!labels || labels.count == 0) {
            // [START_EXCLUDE]
            NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
            [self.resultsText
                appendFormat:@"On-Device label detection failed with error: %@", errorString];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }

          // [START_EXCLUDE]
          [self.resultsText setString:@""];
          for (FIRVisionImageLabel *label in labels) {
            [self.resultsText appendFormat:@"Label: %@, Confidence: %@, EntityID: %@\n", label.text,
                                           label.confidence, label.entityID];
          }
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END detect_label]
}

/// Detects labels on the specified image using AutoML On-Device label API.
///
/// - Parameter image: The image.
- (void)detectImageLabelsAutoMLInImage:(UIImage *)image {
  if (!image) {
    return;
  }
  [self requestAutoMLRemoteModelIfNeeded];

  // [START config_automl_label]
  FIRVisionOnDeviceAutoMLImageLabelerOptions *options;
  FIRAutoMLRemoteModel *remoteModel =
      [[FIRAutoMLRemoteModel alloc] initWithName:FIRRemoteAutoMLModelName];
  if ([self.modelManager isModelDownloaded:remoteModel]) {
    NSLog(@"Use AutoML remote model.");
    options = [[FIRVisionOnDeviceAutoMLImageLabelerOptions alloc] initWithRemoteModel:remoteModel];
  } else {
    NSLog(@"Use AutoML local model.");
    NSString *localModelFilePath =
        [[NSBundle mainBundle] pathForResource:FIRAutoMLLocalModelManifestFilename
                                        ofType:FIRAutoMLManifestFileType];
    if (localModelFilePath == nil) {
      self.resultsText =
          [NSMutableString stringWithFormat:@"Failed to find AutoML local model manifest file: %@",
                                            FIRAutoMLLocalModelManifestFilename];
      [self showResults];
      return;
    }
    FIRAutoMLLocalModel *localModel =
        [[FIRAutoMLLocalModel alloc] initWithManifestPath:localModelFilePath];
    options = [[FIRVisionOnDeviceAutoMLImageLabelerOptions alloc] initWithLocalModel:localModel];
  }
  options.confidenceThreshold = labelConfidenceThreshold;
  // [END config_automl_label]

  // [START init_automl_label]
  FIRVisionImageLabeler *onDeviceAutoMLLabeler =
      [self.vision onDeviceAutoMLImageLabelerWithOptions:options];
  // [END init_automl_label]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_automl_label]
  [onDeviceAutoMLLabeler
      processImage:visionImage
        completion:^(NSArray<FIRVisionImageLabel *> *_Nullable labels, NSError *_Nullable error) {
          if (!labels || labels.count == 0) {
            // [START_EXCLUDE]
            NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
            [self.resultsText
                appendFormat:@"AutoML On-Device label detection failed with error: %@",
                             errorString];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }

          // [START_EXCLUDE]
          [self.resultsText setString:@""];
          for (FIRVisionImageLabel *label in labels) {
            [self.resultsText
                appendFormat:@"Label: %@, Confidence: %@\n", label.text, label.confidence];
          }
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END detect_automl_label]
}

/// Detects text on the specified image and draws a frame around the recognized text using the
/// On-Device text recognizer.
///
/// - Parameter image: The image.
- (void)detectTextOnDeviceInImage:(UIImage *)image {
  if (!image) {
    return;
  }

  // [START init_text]
  FIRVisionTextRecognizer *onDeviceTextRecognizer = [_vision onDeviceTextRecognizer];
  // [END init_text]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  [self.resultsText appendString:@"Running On-Device Text Recognition...\n"];
  [self process:visionImage withTextRecognizer:onDeviceTextRecognizer];
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

/// Detects objects on the specified image and draws a frame around them.
///
/// - Parameter image: The image.
/// - Parameter options: The options for object detector.
- (void)detectObjectsOnDeviceInImage:(UIImage *)image
                         withOptions:(FIRVisionObjectDetectorOptions *)options {
  if (!image) {
    return;
  }

  // [START init_object_detector]
  // Create an objects detector with options.
  FIRVisionObjectDetector *detector = [_vision objectDetectorWithOptions:options];
  // [END init_object_detector]

  // Define the metadata for the image.
  FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
  imageMetadata.orientation =
      [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];

  // Initialize a VisionImage object with the given UIImage.
  FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
  visionImage.metadata = imageMetadata;

  // [START detect_object]
  [detector
      processImage:visionImage
        completion:^(NSArray<FIRVisionObject *> *_Nullable objects, NSError *_Nullable error) {
          if (error != nil) {
            // [START_EXCLUDE]
            NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
            self.resultsText = [NSMutableString
                stringWithFormat:@"Object detection failed with error: %@", errorString];
            [self showResults];
            // [END_EXCLUDE]
          }
          if (!objects || objects.count == 0) {
            // [START_EXCLUDE]
            self.resultsText = [@"On-Device object detector returned no results." mutableCopy];
            [self showResults];
            // [END_EXCLUDE]
            return;
          }

          // [START_EXCLUDE]
          [self.resultsText setString:@""];
          for (FIRVisionObject *object in objects) {
            CGAffineTransform transform = [self transformMatrix];
            CGRect transformedRect = CGRectApplyAffineTransform(object.frame, transform);
            [UIUtilities addRectangle:transformedRect
                               toView:self.annotationOverlayView
                                color:UIColor.greenColor];
            [self.resultsText appendFormat:@"Class: %lu, frame: %@, ID: %@\n",
                                           object.classificationCategory,
                                           NSStringFromCGRect(object.frame), object.trackingID];
          }
          [self showResults];
          // [END_EXCLUDE]
        }];
  // [END detect_object]
}

- (void)requestAutoMLRemoteModelIfNeeded {
  FIRAutoMLRemoteModel *remoteModel =
      [[FIRAutoMLRemoteModel alloc] initWithName:FIRRemoteAutoMLModelName];
  if ([self.modelManager isModelDownloaded:remoteModel]) {
    return;
  }
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(remoteModelDownloadDidSucceed:)
                                             name:FIRModelDownloadDidSucceedNotification
                                           object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(remoteModelDownloadDidFail:)
                                             name:FIRModelDownloadDidFailNotification
                                           object:nil];

  dispatch_async(dispatch_get_main_queue(), ^{
    self.downloadProgressView.hidden = NO;
    FIRModelDownloadConditions *conditions =
        [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:YES
                                             allowsBackgroundDownloading:YES];
    self.downloadProgressView.observedProgress = [self.modelManager downloadModel:remoteModel
                                                                       conditions:conditions];
    NSLog(@"Start downloading AutoML remote model.");
  });
}

#pragma mark - Notifications

- (void)remoteModelDownloadDidSucceed:(NSNotification *)notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.downloadProgressView.hidden = YES;
    self.downloadOrDeleteModelButton.image = [UIImage imageNamed:@"delete"];
    FIRRemoteModel *remotemodel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    if (remotemodel == nil) {
      [self.resultsText appendString:@"firebaseMLModelDownloadDidSucceed notification posted "
                                     @"without a RemoteModel instance."];
      return;
    }
    [self.resultsText appendFormat:@"Successfully downloaded the remote model with name: %@. The "
                                   @"model is ready for detection.",
                                   remotemodel.name];
    NSLog(@"Successfully downloaded AutoML remote model.");
  });
}

- (void)remoteModelDownloadDidFail:(NSNotification *)notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.downloadProgressView.hidden = YES;
    FIRRemoteModel *remoteModel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    NSError *error = notification.userInfo[FIRModelDownloadUserInfoKeyError];
    if (error == nil) {
      [self.resultsText appendString:@"firebaseMLModelDownloadDidFail notification posted without "
                                     @"a RemoteModel instance or error."];
      return;
    }
    [self.resultsText appendFormat:@"Failed to download the remote model with name: %@, error: %@.",
                                   remoteModel, error.localizedDescription];
    NSLog(@"Failed to download AutoML remote model.");
  });
}

@end

NS_ASSUME_NONNULL_END
