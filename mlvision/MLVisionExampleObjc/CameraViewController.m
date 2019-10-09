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

#import "CameraViewController.h"
#import "UIUtilities.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

@import Firebase;

NS_ASSUME_NONNULL_BEGIN

static NSString *const alertControllerTitle = @"Vision Detectors";
static NSString *const alertControllerMessage = @"Select a detector";
static NSString *const cancelActionTitleText = @"Cancel";
static NSString *const videoDataOutputQueueLabel =
    @"com.google.firebaseml.visiondetector.VideoDataOutputQueue";
static NSString *const sessionQueueLabel = @"com.google.firebaseml.visiondetector.SessionQueue";
static NSString *const noResultsMessage = @"No Results";

/** Name of the remote AutoML model. */
static NSString *const FIRRemoteAutoMLModelName = @"remote_automl_model";

/** Filename of AutoML local model manifest in the main resource bundle. */
static NSString *const FIRAutoMLLocalModelManifestFilename = @"automl_labeler_manifest";

/** File type of AutoML local model manifest in the main resource bundle. */
static NSString *const FIRAutoMLManifestFileType = @"json";

static float const labelConfidenceThreshold = 0.75;
static const CGFloat FIRSmallDotRadius = 4.0;
static const CGFloat FIRconstantScale = 1.0;
static const CGFloat padding = 10.0;
static const CGFloat resultsLabelHeight = 200.0;
static const int resultsLabelLines = 5;

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

typedef NS_ENUM(NSInteger, Detector) {
  DetectorOnDeviceAutoMLImageLabeler,
  DetectorOnDeviceBarcode,
  DetectorOnDeviceFace,
  DetectorOnDeviceText,
  DetectorOnDeviceObjectProminentNoClassifier,
  DetectorOnDeviceObjectProminentWithClassifier,
  DetectorOnDeviceObjectMultipleNoClassifier,
  DetectorOnDeviceObjectMultipleWithClassifier
};

@property(nonatomic) NSArray *detectors;
@property(nonatomic) Detector currentDetector;
@property(nonatomic) bool isUsingFrontCamera;
@property(nonatomic, nonnull) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic) AVCaptureSession *captureSession;
@property(nonatomic) dispatch_queue_t sessionQueue;
@property(nonatomic) FIRVision *vision;
@property(nonatomic) UIView *annotationOverlayView;
@property(nonatomic) UIImageView *previewOverlayView;
@property(weak, nonatomic) IBOutlet UIView *cameraView;
@property(nonatomic) CMSampleBufferRef lastFrame;
@property(nonatomic) FIRModelManager *modelManager;

@property(strong, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@end

@implementation CameraViewController

- (NSString *)stringForDetector:(Detector)detector {
  switch (detector) {
    case DetectorOnDeviceAutoMLImageLabeler:
      return @"On-Device AutoML Image Labeler";
    case DetectorOnDeviceBarcode:
      return @"On-Device Barcode detector";
    case DetectorOnDeviceFace:
      return @"On-Device Face Detection";
    case DetectorOnDeviceText:
      return @"On-Device Text Recognition";
    case DetectorOnDeviceObjectProminentNoClassifier:
      return @"ODT for prominent object, only tracking";
    case DetectorOnDeviceObjectProminentWithClassifier:
      return @"ODT for prominent object with classification";
    case DetectorOnDeviceObjectMultipleNoClassifier:
      return @"ODT for multiple objects, only tracking";
    case DetectorOnDeviceObjectMultipleWithClassifier:
      return @"ODT for multiple objects with classification";
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _detectors = @[
    @(DetectorOnDeviceAutoMLImageLabeler), @(DetectorOnDeviceBarcode), @(DetectorOnDeviceFace),
    @(DetectorOnDeviceText), @(DetectorOnDeviceObjectProminentNoClassifier),
    @(DetectorOnDeviceObjectProminentWithClassifier), @(DetectorOnDeviceObjectMultipleNoClassifier),
    @(DetectorOnDeviceObjectMultipleWithClassifier)
  ];
  _currentDetector = DetectorOnDeviceFace;
  _isUsingFrontCamera = YES;
  _captureSession = [[AVCaptureSession alloc] init];
  _sessionQueue = dispatch_queue_create(sessionQueueLabel.UTF8String, nil);
  _vision = [FIRVision vision];
  _modelManager = [FIRModelManager modelManager];
  _previewOverlayView = [[UIImageView alloc] initWithFrame:CGRectZero];
  _previewOverlayView.contentMode = UIViewContentModeScaleAspectFill;
  _previewOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
  _annotationOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
  _annotationOverlayView.translatesAutoresizingMaskIntoConstraints = NO;

  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
  [self setUpPreviewOverlayView];
  [self setUpAnnotationOverlayView];
  [self setUpCaptureSessionOutput];
  [self setUpCaptureSessionInput];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self startSession];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self stopSession];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  _previewLayer.frame = _cameraView.frame;
}

- (IBAction)selectDetector:(id)sender {
  [self presentDetectorsAlertController];
}

- (IBAction)switchCamera:(id)sender {
  self.isUsingFrontCamera = !_isUsingFrontCamera;
  [self removeDetectionAnnotations];
  [self setUpCaptureSessionInput];
}

#pragma mark - On-Device AutoML Detection

/// Detects labels on the specified image using AutoML On-Device label API.
///
/// - Parameter image: The image.
- (void)detectImageLabelsAutoMLOnDeviceInImage:(FIRVisionImage *)image
                                         width:(CGFloat)width
                                        height:(CGFloat)height {
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
      NSLog(@"Failed to find AutoML local model manifest file: %@",
            FIRAutoMLLocalModelManifestFilename);
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

  dispatch_group_t group = dispatch_group_create();
  dispatch_group_enter(group);

  // [START detect_automl_label]
  [onDeviceAutoMLLabeler
      processImage:image
        completion:^(NSArray<FIRVisionImageLabel *> *_Nullable labels, NSError *_Nullable error) {
          // [START_EXCLUDE]
          [self updatePreviewOverlayView];
          [self removeDetectionAnnotations];
          // [END_EXCLUDE]
          if (error != nil) {
            // [START_EXCLUDE]
            NSLog(@"Failed to detect labels with error: %@.", error.localizedDescription);
            dispatch_group_leave(group);
            // [END_EXCLUDE]
            return;
          }

          if (!labels || labels.count == 0) {
            // [START_EXCLUDE]
            dispatch_group_leave(group);
            // [END_EXCLUDE]
            return;
          }

          // [START_EXCLUDE]
          CGRect annotationFrame = self.annotationOverlayView.frame;
          CGRect resultsRect =
              CGRectMake(annotationFrame.origin.x + padding,
                         annotationFrame.size.height - padding - resultsLabelHeight,
                         annotationFrame.size.width - 2 * padding, resultsLabelHeight);
          UILabel *resultsLabel = [[UILabel alloc] initWithFrame:resultsRect];
          resultsLabel.textColor = UIColor.yellowColor;
          NSMutableArray *labelStrings = [NSMutableArray arrayWithCapacity:labels.count];
          for (FIRVisionImageLabel *label in labels) {
            [labelStrings addObject:[NSString stringWithFormat:@"Label: %@, Confidence: %@",
                                                               label.text, label.confidence]];
          }
          resultsLabel.text = [labelStrings componentsJoinedByString:@"\n"];
          resultsLabel.adjustsFontSizeToFitWidth = YES;
          resultsLabel.numberOfLines = resultsLabelLines;
          [self.annotationOverlayView addSubview:resultsLabel];
          dispatch_group_leave(group);
          // [END_EXCLUDE]
        }];
  // [END detect_automl_label]
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
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
    self.downloadProgressView.observedProgress =
        [self.modelManager downloadModel:remoteModel conditions:conditions];
    NSLog(@"Start downloading AutoML remote model.");
  });
}

#pragma mark - Notifications

- (void)remoteModelDownloadDidSucceed:(NSNotification *)notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.downloadProgressView.hidden = YES;
    FIRRemoteModel *remotemodel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    if (remotemodel == nil) {
      NSLog(
          @"firebaseMLModelDownloadDidSucceed notification posted without a RemoteModel instance.");
      return;
    }
    NSLog(@"Successfully downloaded the remote model with name: %@. The model is ready for "
          @"detection.",
          remotemodel.name);
  });
}

- (void)remoteModelDownloadDidFail:(NSNotification *)notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.downloadProgressView.hidden = YES;
    FIRRemoteModel *remoteModel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
    NSError *error = notification.userInfo[FIRModelDownloadUserInfoKeyError];
    if (error == nil) {
      NSLog(@"firebaseMLModelDownloadDidFail notification posted without a RemoteModel instance or "
            @"error.");
      return;
    }
    NSLog(@"Failed to download the remote model with name: %@, error: %@.", remoteModel,
          error.localizedDescription);
  });
}

#pragma mark - Other On-Device Detections

- (void)detectFacesOnDeviceInImage:(FIRVisionImage *)image
                             width:(CGFloat)width
                            height:(CGFloat)height {
  FIRVisionFaceDetectorOptions *options = [[FIRVisionFaceDetectorOptions alloc] init];
  // When performing latency tests to determine ideal detection settings,
  // run the app in 'release' mode to get accurate performance metrics
  options.performanceMode = FIRVisionFaceDetectorPerformanceModeFast;
  options.contourMode = FIRVisionFaceDetectorContourModeAll;
  options.landmarkMode = FIRVisionFaceDetectorLandmarkModeNone;
  options.classificationMode = FIRVisionFaceDetectorClassificationModeNone;

  FIRVisionFaceDetector *faceDetector = [_vision faceDetectorWithOptions:options];
  NSError *error;
  NSArray<FIRVisionFace *> *faces = [faceDetector resultsInImage:image error:&error];
  if (error != nil) {
    NSLog(@"Failed to detect faces with error: %@", error.localizedDescription);
    return;
  }
  if (faces.count == 0) {
    NSLog(@"On-Device face detector returned no results.");
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self updatePreviewOverlayView];
      [self removeDetectionAnnotations];
    });
    return;
  }

  dispatch_sync(dispatch_get_main_queue(), ^{
    [self updatePreviewOverlayView];
    [self removeDetectionAnnotations];
    for (FIRVisionFace *face in faces) {
      CGRect normalizedRect =
          CGRectMake(face.frame.origin.x / width, face.frame.origin.y / height,
                     face.frame.size.width / width, face.frame.size.height / height);
      CGRect standardizedRect = CGRectStandardize(
          [self->_previewLayer rectForMetadataOutputRectOfInterest:normalizedRect]);
      [UIUtilities addRectangle:standardizedRect
                         toView:self->_annotationOverlayView
                          color:UIColor.greenColor];
      [self addContoursForFace:face width:width height:height];
    }
  });
}

- (void)recognizeTextOnDeviceInImage:(FIRVisionImage *)image
                               width:(CGFloat)width
                              height:(CGFloat)height {
  FIRVisionTextRecognizer *textRecognizer = [_vision onDeviceTextRecognizer];
  dispatch_group_t group = dispatch_group_create();
  dispatch_group_enter(group);
  [textRecognizer
      processImage:image
        completion:^(FIRVisionText *_Nullable text, NSError *_Nullable error) {
          [self removeDetectionAnnotations];
          [self updatePreviewOverlayView];
          if (text == nil) {
            NSLog(@"On-Device text recognizer error: %@",
                  error ? error.localizedDescription : noResultsMessage);
            dispatch_group_leave(group);
            return;
          }
          // Blocks.
          for (FIRVisionTextBlock *block in text.blocks) {
            NSArray<NSValue *> *points = [self convertedPointsFromPoints:block.cornerPoints
                                                                   width:width
                                                                  height:height];
            [UIUtilities addShapeWithPoints:points
                                     toView:self->_annotationOverlayView
                                      color:UIColor.purpleColor];

            // Lines.
            for (FIRVisionTextLine *line in block.lines) {
              NSArray<NSValue *> *points = [self convertedPointsFromPoints:line.cornerPoints
                                                                     width:width
                                                                    height:height];
              [UIUtilities addShapeWithPoints:points
                                       toView:self->_annotationOverlayView
                                        color:UIColor.purpleColor];

              // Elements.
              for (FIRVisionTextElement *element in line.elements) {
                CGRect normalizedRect = CGRectMake(
                    element.frame.origin.x / width, element.frame.origin.y / height,
                    element.frame.size.width / width, element.frame.size.height / height);
                CGRect convertedRect =
                    [self->_previewLayer rectForMetadataOutputRectOfInterest:normalizedRect];
                [UIUtilities addRectangle:convertedRect
                                   toView:self->_annotationOverlayView
                                    color:UIColor.greenColor];
                UILabel *label = [[UILabel alloc] initWithFrame:convertedRect];
                label.text = element.text;
                label.adjustsFontSizeToFitWidth = YES;
                [self.annotationOverlayView addSubview:label];
              }
            }
          }
          dispatch_group_leave(group);
        }];
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)detectBarcodesOnDeviceInImage:(FIRVisionImage *)image
                                width:(CGFloat)width
                               height:(CGFloat)height
                              options:(FIRVisionBarcodeDetectorOptions *)options {
  FIRVisionBarcodeDetector *detector = [_vision barcodeDetectorWithOptions:options];
  dispatch_group_t group = dispatch_group_create();
  dispatch_group_enter(group);

  [detector detectInImage:image
               completion:^(NSArray<FIRVisionBarcode *> *barcodes, NSError *error) {
                 if (error != nil) {
                   NSLog(@"Failed to detect barcodes with error: %@", error.localizedDescription);
                   [self updatePreviewOverlayView];
                   [self removeDetectionAnnotations];
                   dispatch_group_leave(group);
                   return;
                 }
                 if (barcodes.count == 0) {
                   NSLog(@"On-Device barcode detector returned no results.");
                   [self updatePreviewOverlayView];
                   [self removeDetectionAnnotations];
                   dispatch_group_leave(group);
                   return;
                 }

                 [self updatePreviewOverlayView];
                 [self removeDetectionAnnotations];
                 for (FIRVisionBarcode *barcode in barcodes) {
                   CGRect normalizedRect =
                       CGRectMake(barcode.frame.origin.x / width,       // X
                                  barcode.frame.origin.y / height,      // Y
                                  barcode.frame.size.width / width,     // Width
                                  barcode.frame.size.height / height);  // Height
                   CGRect standardizedRect = CGRectStandardize(
                       [self.previewLayer rectForMetadataOutputRectOfInterest:normalizedRect]);
                   [UIUtilities addRectangle:standardizedRect
                                      toView:self.annotationOverlayView
                                       color:UIColor.greenColor];
                   UILabel *label = [[UILabel alloc] initWithFrame:standardizedRect];
                   label.numberOfLines = 0;
                   NSMutableString *description = [NSMutableString new];
                   [description appendString:barcode.rawValue];
                   label.text = description;

                   label.adjustsFontSizeToFitWidth = YES;
                   [self.annotationOverlayView addSubview:label];
                 }
                 dispatch_group_leave(group);
               }];
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

#pragma mark - Object Detection

- (void)detectObjectsOnDeviceInImage:(FIRVisionImage *)image
                               width:(CGFloat)width
                              height:(CGFloat)height
                             options:(FIRVisionObjectDetectorOptions *)options {
  FIRVisionObjectDetector *detector = [_vision objectDetectorWithOptions:options];

  NSError *error;
  NSArray *objects = [detector resultsInImage:image error:&error];
  if (error != nil) {
    NSLog(@"Failed to detect object with error: %@", error.localizedDescription);
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self updatePreviewOverlayView];
      [self removeDetectionAnnotations];
    });
    return;
  }

  if (!objects || objects.count == 0) {
    NSLog(@"On-Device object detector returned no results.");
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self updatePreviewOverlayView];
      [self removeDetectionAnnotations];
    });
    return;
  }

  dispatch_sync(dispatch_get_main_queue(), ^{
    [self updatePreviewOverlayView];
    [self removeDetectionAnnotations];
    for (FIRVisionObject *object in objects) {
      CGRect normalizedRect =
          CGRectMake(object.frame.origin.x / width, object.frame.origin.y / height,
                     object.frame.size.width / width, object.frame.size.height / height);
      CGRect standardizedRect =
          CGRectStandardize([self.previewLayer rectForMetadataOutputRectOfInterest:normalizedRect]);
      [UIUtilities addRectangle:standardizedRect
                         toView:self.annotationOverlayView
                          color:UIColor.greenColor];
      UILabel *label = [[UILabel alloc] initWithFrame:standardizedRect];
      label.numberOfLines = 2;
      NSMutableString *description = [NSMutableString new];
      if (object.trackingID != nil) {
        [description appendFormat:@"ID: %@\n", object.trackingID];
      }
      NSString *categoryString =
          [NSString stringWithFormat:@"Class: %lu", object.classificationCategory];
      [description appendString:categoryString];
      label.text = description;

      label.adjustsFontSizeToFitWidth = YES;
      [self.annotationOverlayView addSubview:label];
    }
  });
}

#pragma mark - Private

- (void)setUpCaptureSessionOutput {
  dispatch_async(_sessionQueue, ^{
    [self->_captureSession beginConfiguration];
    // When performing latency tests to determine ideal capture settings,
    // run the app in 'release' mode to get accurate performance metrics
    self->_captureSession.sessionPreset = AVCaptureSessionPresetMedium;

    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{
      (id)
      kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
    };
    dispatch_queue_t outputQueue = dispatch_queue_create(videoDataOutputQueueLabel.UTF8String, nil);
    [output setSampleBufferDelegate:self queue:outputQueue];
    if ([self.captureSession canAddOutput:output]) {
      [self.captureSession addOutput:output];
      [self.captureSession commitConfiguration];
    } else {
      NSLog(@"%@", @"Failed to add capture session output.");
    }
  });
}

- (void)setUpCaptureSessionInput {
  dispatch_async(_sessionQueue, ^{
    AVCaptureDevicePosition cameraPosition =
        self.isUsingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self captureDeviceForPosition:cameraPosition];
    if (device) {
      [self->_captureSession beginConfiguration];
      NSArray<AVCaptureInput *> *currentInputs = self.captureSession.inputs;
      for (AVCaptureInput *input in currentInputs) {
        [self.captureSession removeInput:input];
      }
      NSError *error;
      AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                          error:&error];
      if (error) {
        NSLog(@"Failed to create capture device input: %@", error.localizedDescription);
        return;
      } else {
        if ([self.captureSession canAddInput:input]) {
          [self.captureSession addInput:input];
        } else {
          NSLog(@"%@", @"Failed to add capture session input.");
        }
      }
      [self.captureSession commitConfiguration];
    } else {
      NSLog(@"Failed to get capture device for camera position: %ld", cameraPosition);
    }
  });
}

- (void)startSession {
  dispatch_async(_sessionQueue, ^{
    [self->_captureSession startRunning];
  });
}

- (void)stopSession {
  dispatch_async(_sessionQueue, ^{
    [self->_captureSession stopRunning];
  });
}

- (void)setUpPreviewOverlayView {
  [_cameraView addSubview:_previewOverlayView];
  [NSLayoutConstraint activateConstraints:@[
    [_previewOverlayView.centerYAnchor constraintEqualToAnchor:_cameraView.centerYAnchor],
    [_previewOverlayView.centerXAnchor constraintEqualToAnchor:_cameraView.centerXAnchor],
    [_previewOverlayView.leadingAnchor constraintEqualToAnchor:_cameraView.leadingAnchor],
    [_previewOverlayView.trailingAnchor constraintEqualToAnchor:_cameraView.trailingAnchor]
  ]];
}
- (void)setUpAnnotationOverlayView {
  [_cameraView addSubview:_annotationOverlayView];
  [NSLayoutConstraint activateConstraints:@[
    [_annotationOverlayView.topAnchor constraintEqualToAnchor:_cameraView.topAnchor],
    [_annotationOverlayView.leadingAnchor constraintEqualToAnchor:_cameraView.leadingAnchor],
    [_annotationOverlayView.trailingAnchor constraintEqualToAnchor:_cameraView.trailingAnchor],
    [_annotationOverlayView.bottomAnchor constraintEqualToAnchor:_cameraView.bottomAnchor]
  ]];
}

- (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position {
  if (@available(iOS 10, *)) {
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
        discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                              mediaType:AVMediaTypeVideo
                               position:AVCaptureDevicePositionUnspecified];
    for (AVCaptureDevice *device in discoverySession.devices) {
      if (device.position == position) {
        return device;
      }
    }
  }
  return nil;
}

- (void)presentDetectorsAlertController {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:alertControllerTitle
                                          message:alertControllerMessage
                                   preferredStyle:UIAlertControllerStyleAlert];
  for (NSNumber *detectorType in _detectors) {
    NSInteger detector = detectorType.integerValue;
    UIAlertAction *action = [UIAlertAction actionWithTitle:[self stringForDetector:detector]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *_Nonnull action) {
                                                     self.currentDetector = detector;
                                                     [self removeDetectionAnnotations];
                                                   }];
    if (detector == _currentDetector) {
      [action setEnabled:NO];
    }
    [alertController addAction:action];
  }
  [alertController addAction:[UIAlertAction actionWithTitle:cancelActionTitleText
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)removeDetectionAnnotations {
  for (UIView *annotationView in _annotationOverlayView.subviews) {
    [annotationView removeFromSuperview];
  }
}

- (void)updatePreviewOverlayView {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(_lastFrame);
  if (imageBuffer == nil) {
    return;
  }
  CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
  CIContext *context = [[CIContext alloc] initWithOptions:nil];
  CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
  if (cgImage == nil) {
    return;
  }
  UIImage *rotatedImage = [UIImage imageWithCGImage:cgImage
                                              scale:FIRconstantScale
                                        orientation:UIImageOrientationRight];
  if (_isUsingFrontCamera) {
    CGImageRef rotatedCGImage = rotatedImage.CGImage;
    if (rotatedCGImage == nil) {
      return;
    }
    UIImage *mirroredImage = [UIImage imageWithCGImage:rotatedCGImage
                                                 scale:FIRconstantScale
                                           orientation:UIImageOrientationLeftMirrored];
    _previewOverlayView.image = mirroredImage;
  } else {
    _previewOverlayView.image = rotatedImage;
  }
  CGImageRelease(cgImage);
}

- (NSArray<NSValue *> *)convertedPointsFromPoints:(NSArray<NSValue *> *)points
                                            width:(CGFloat)width
                                           height:(CGFloat)height {
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:points.count];
  for (NSValue *point in points) {
    CGPoint cgPointValue = point.CGPointValue;
    CGPoint normalizedPoint = CGPointMake(cgPointValue.x / width, cgPointValue.y / height);
    CGPoint cgPoint = [_previewLayer pointForCaptureDevicePointOfInterest:normalizedPoint];
    [result addObject:[NSValue valueWithCGPoint:cgPoint]];
  }
  return result;
}

- (CGPoint)normalizedPointFromVisionPoint:(FIRVisionPoint *)point
                                    width:(CGFloat)width
                                   height:(CGFloat)height {
  CGPoint cgPointValue = CGPointMake(point.x.floatValue, point.y.floatValue);
  CGPoint normalizedPoint = CGPointMake(cgPointValue.x / width, cgPointValue.y / height);
  CGPoint cgPoint = [_previewLayer pointForCaptureDevicePointOfInterest:normalizedPoint];
  return cgPoint;
}

- (void)addContoursForFace:(FIRVisionFace *)face width:(CGFloat)width height:(CGFloat)height {
  // Face
  FIRVisionFaceContour *faceContour = [face contourOfType:FIRFaceContourTypeFace];
  for (FIRVisionPoint *point in faceContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.blueColor
                           radius:FIRSmallDotRadius];
  }

  // Eyebrows
  FIRVisionFaceContour *leftEyebrowTopContour =
      [face contourOfType:FIRFaceContourTypeLeftEyebrowTop];
  for (FIRVisionPoint *point in leftEyebrowTopContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.orangeColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *leftEyebrowBottomContour =
      [face contourOfType:FIRFaceContourTypeLeftEyebrowBottom];
  for (FIRVisionPoint *point in leftEyebrowBottomContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.orangeColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *rightEyebrowTopContour =
      [face contourOfType:FIRFaceContourTypeRightEyebrowTop];
  for (FIRVisionPoint *point in rightEyebrowTopContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.orangeColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *rightEyebrowBottomContour =
      [face contourOfType:FIRFaceContourTypeRightEyebrowBottom];
  for (FIRVisionPoint *point in rightEyebrowBottomContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.orangeColor
                           radius:FIRSmallDotRadius];
  }

  // Eyes
  FIRVisionFaceContour *leftEyeContour = [face contourOfType:FIRFaceContourTypeLeftEye];
  for (FIRVisionPoint *point in leftEyeContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.cyanColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *rightEyeContour = [face contourOfType:FIRFaceContourTypeRightEye];
  for (FIRVisionPoint *point in rightEyeContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.cyanColor
                           radius:FIRSmallDotRadius];
  }

  // Lips
  FIRVisionFaceContour *upperLipTopContour = [face contourOfType:FIRFaceContourTypeUpperLipTop];
  for (FIRVisionPoint *point in upperLipTopContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.redColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *upperLipBottomContour =
      [face contourOfType:FIRFaceContourTypeUpperLipBottom];
  for (FIRVisionPoint *point in upperLipBottomContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.redColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *lowerLipTopContour = [face contourOfType:FIRFaceContourTypeLowerLipTop];
  for (FIRVisionPoint *point in lowerLipTopContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.redColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *lowerLipBottomContour =
      [face contourOfType:FIRFaceContourTypeLowerLipBottom];
  for (FIRVisionPoint *point in lowerLipBottomContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.redColor
                           radius:FIRSmallDotRadius];
  }

  // Nose
  FIRVisionFaceContour *noseBridgeContour = [face contourOfType:FIRFaceContourTypeNoseBridge];
  for (FIRVisionPoint *point in noseBridgeContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.yellowColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *noseBottomContour = [face contourOfType:FIRFaceContourTypeNoseBottom];
  for (FIRVisionPoint *point in noseBottomContour.points) {
    CGPoint cgPoint = [self normalizedPointFromVisionPoint:point width:width height:height];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.yellowColor
                           radius:FIRSmallDotRadius];
  }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (imageBuffer) {
    _lastFrame = sampleBuffer;
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithBuffer:sampleBuffer];
    FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
    UIImageOrientation orientation = [UIUtilities
        imageOrientationFromDevicePosition:_isUsingFrontCamera ? AVCaptureDevicePositionFront
                                                               : AVCaptureDevicePositionBack];

    FIRVisionDetectorImageOrientation visionOrientation =
        [UIUtilities visionImageOrientationFromImageOrientation:orientation];
    metadata.orientation = visionOrientation;
    visionImage.metadata = metadata;
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    BOOL shouldEnableClassification = NO;
    BOOL shouldEnableMultipleObjects = NO;
    switch (_currentDetector) {
      case DetectorOnDeviceObjectProminentWithClassifier:
      case DetectorOnDeviceObjectMultipleWithClassifier:
        shouldEnableClassification = YES;
      default:
        break;
    }
    switch (_currentDetector) {
      case DetectorOnDeviceObjectMultipleNoClassifier:
      case DetectorOnDeviceObjectMultipleWithClassifier:
        shouldEnableMultipleObjects = YES;
      default:
        break;
    }

    switch (_currentDetector) {
      case DetectorOnDeviceAutoMLImageLabeler:
        [self detectImageLabelsAutoMLOnDeviceInImage:visionImage
                                               width:imageWidth
                                              height:imageHeight];
        break;
      case DetectorOnDeviceBarcode: {
        FIRVisionBarcodeDetectorOptions *options = [[FIRVisionBarcodeDetectorOptions alloc] init];
        [self detectBarcodesOnDeviceInImage:visionImage
                                      width:imageWidth
                                     height:imageHeight
                                    options:options];
        break;
      }
      case DetectorOnDeviceFace:
        [self detectFacesOnDeviceInImage:visionImage width:imageWidth height:imageHeight];
        break;
      case DetectorOnDeviceText:
        [self recognizeTextOnDeviceInImage:visionImage width:imageWidth height:imageHeight];
        break;
      case DetectorOnDeviceObjectProminentNoClassifier:
      case DetectorOnDeviceObjectProminentWithClassifier:
      case DetectorOnDeviceObjectMultipleNoClassifier:
      case DetectorOnDeviceObjectMultipleWithClassifier: {
        FIRVisionObjectDetectorOptions *options = [FIRVisionObjectDetectorOptions new];
        options.shouldEnableClassification = shouldEnableClassification;
        options.shouldEnableMultipleObjects = shouldEnableMultipleObjects;
        [self detectObjectsOnDeviceInImage:visionImage
                                     width:imageWidth
                                    height:imageHeight
                                   options:options];
        break;
      }
    }
  } else {
    NSLog(@"%@", @"Failed to get image buffer from sample buffer.");
  }
}

@end

NS_ASSUME_NONNULL_END
