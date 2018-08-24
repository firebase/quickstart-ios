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
@import AVFoundation;
@import CoreVideo;
@import Firebase;

static NSString *const alertControllerTitle = @"Vision Detectors";
static NSString *const alertControllerMessage = @"Select a detector";
static NSString *const cancelActionTitleText = @"Cancel";
static NSString *const videoDataOutputQueueLabel = @"com.google.firebaseml.visiondetector.VideoDataOutputQueue";
static NSString *const sessionQueueLabel = @"com.google.firebaseml.visiondetector.SessionQueue";
static NSString *const noResultsMessage = @"No Results";
static const CGFloat FIRSmallDotRadius = 4.0;
static const CGFloat FIRBigDotRadius = 10.0;

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

typedef NS_ENUM(NSInteger, Detector) {
  DetectorOnDeviceFace,
  DetectorOnDeviceText
};

@property (nonatomic) NSArray *detectors;
@property (nonatomic) Detector currentDetector;
@property (nonatomic) bool isUsingFrontCamera;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, nonnull) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) FIRVision *vision;
@property (nonatomic) UIView *annotationOverlayView;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@end

@implementation CameraViewController

- (NSString *)stringForDetector:(Detector)detector {
  switch (detector) {
    case DetectorOnDeviceFace:
      return @"On-Device Face";
    case DetectorOnDeviceText:
      return @"On-Device Text";
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _detectors = @[[NSNumber numberWithInt:DetectorOnDeviceFace], [NSNumber numberWithInt:DetectorOnDeviceText]];
  _currentDetector = DetectorOnDeviceFace;
  _isUsingFrontCamera = YES;
  _captureSession = [[AVCaptureSession alloc] init];
  _sessionQueue = dispatch_queue_create(sessionQueueLabel.UTF8String, nil);
  _vision = [FIRVision vision];

  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
  [_cameraView.layer addSublayer:_previewLayer];
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

#pragma mark - On-Device Detection

- (void)detectFacesOnDeviceInImage:(FIRVisionImage *)image width:(CGFloat) width height:(CGFloat)height {
  FIRVisionFaceDetectorOptions *options = [[FIRVisionFaceDetectorOptions alloc] init];
  // When performing latency tests to determine ideal detection settings,
  // run the app in 'release' mode to get accurate performance metrics
  options.performanceMode = FIRVisionFaceDetectorPerformanceModeFast;
  options.contourMode = FIRVisionFaceDetectorContourModeAll;
  options.landmarkMode = FIRVisionFaceDetectorLandmarkModeNone;
  options.classificationMode = FIRVisionFaceDetectorClassificationModeNone;
  options.minFaceSize = 0.1;
  options.trackingEnabled = YES;

  FIRVisionFaceDetector *faceDetector = [_vision faceDetectorWithOptions:options];
  [faceDetector detectInImage:image completion:^(NSArray<FIRVisionFace *> * _Nullable faces, NSError * _Nullable error) {
    if (!faces || faces.count == 0) {
      [self removeDetectionAnnotations];
      NSLog(@"%@", @"On-Device face detector returned no results.");
      return;
    }
    [self removeDetectionAnnotations];
    for (FIRVisionFace *face in faces) {
      CGRect normalizedRect = CGRectMake(face.frame.origin.x / width, face.frame.origin.y / height, face.frame.size.width / width, face.frame.size.height / height);
      CGRect standardizedRect = CGRectStandardize([self->_previewLayer rectForMetadataOutputRectOfInterest:normalizedRect]);
      [UIUtilities addRectangle:standardizedRect toView:self->_annotationOverlayView color:UIColor.greenColor];
      [self addContoursFromVisionFace:face width:width height:height];
    }
  }];
}

- (void)addContoursFromVisionFace:(FIRVisionFace *)face
                            width:(size_t)imageWidth
                           height:(size_t)imageHeight {
  // Face
  FIRVisionFaceContour *faceContour = [face contourOfType:FIRFaceContourTypeFace];
  for (FIRVisionPoint *point in faceContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }

  // Eyebrows
  FIRVisionFaceContour *leftEyebrowTopContour =
  [face contourOfType:FIRFaceContourTypeLeftEyebrowTop];
  for (FIRVisionPoint *point in leftEyebrowTopContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *leftEyebrowBottomContour =
  [face contourOfType:FIRFaceContourTypeLeftEyebrowBottom];
  for (FIRVisionPoint *point in leftEyebrowBottomContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *rightEyebrowTopContour =
  [face contourOfType:FIRFaceContourTypeRightEyebrowTop];
  for (FIRVisionPoint *point in rightEyebrowTopContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *rightEyebrowBottomContour =
  [face contourOfType:FIRFaceContourTypeRightEyebrowBottom];
  for (FIRVisionPoint *point in rightEyebrowBottomContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }

  // Eyes
  FIRVisionFaceContour *leftEyeContour = [face contourOfType:FIRFaceContourTypeLeftEye];
  for (FIRVisionPoint *point in leftEyeContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *rightEyeContour = [face contourOfType:FIRFaceContourTypeRightEye];
  for (FIRVisionPoint *point in rightEyeContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }

  // Lips
  FIRVisionFaceContour *upperLipTopContour = [face contourOfType:FIRFaceContourTypeUpperLipTop];
  for (FIRVisionPoint *point in upperLipTopContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *upperLipBottomContour =
  [face contourOfType:FIRFaceContourTypeUpperLipBottom];
  for (FIRVisionPoint *point in upperLipBottomContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *lowerLipTopContour = [face contourOfType:FIRFaceContourTypeLowerLipTop];
  for (FIRVisionPoint *point in lowerLipTopContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *lowerLipBottomContour =
  [face contourOfType:FIRFaceContourTypeLowerLipBottom];
  for (FIRVisionPoint *point in lowerLipBottomContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }

  // Nose
  FIRVisionFaceContour *noseBridgeContour = [face contourOfType:FIRFaceContourTypeNoseBridge];
  for (FIRVisionPoint *point in noseBridgeContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
  FIRVisionFaceContour *noseBottomContour = [face contourOfType:FIRFaceContourTypeNoseBottom];
  for (FIRVisionPoint *point in noseBottomContour.points) {
    CGPoint cgPoint =
        [self normalizedPointFromVisionPoint:point width:imageWidth height:imageHeight];
    [UIUtilities addCircleAtPoint:cgPoint
                           toView:self->_annotationOverlayView
                            color:UIColor.greenColor
                           radius:FIRSmallDotRadius];
  }
}

- (void)recognizeTextOnDeviceInImage:(FIRVisionImage *)image width:(CGFloat) width height:(CGFloat)height {
  FIRVisionTextRecognizer *textRecognizer = [_vision onDeviceTextRecognizer];
  [textRecognizer processImage:image completion:^(FIRVisionText * _Nullable text, NSError * _Nullable error) {
    [self removeDetectionAnnotations];
    if (text == nil) {
      NSLog(@"On-Device text recognizer error: %@", error ? error.localizedDescription : noResultsMessage);
      return;
    }
    // Blocks.
    for (FIRVisionTextBlock *block in text.blocks) {
      NSArray<NSValue *> *points = [self convertedPointsFromPoints:block.cornerPoints width:width height:height];
      [UIUtilities addShapeWithPoints:points toView:self->_annotationOverlayView color:UIColor.purpleColor];

      // Lines.
      for (FIRVisionTextLine *line in block.lines) {
        NSArray<NSValue *> *points = [self  convertedPointsFromPoints:line.cornerPoints width:width height:height];
        [UIUtilities addShapeWithPoints:points toView:self->_annotationOverlayView color:UIColor.purpleColor];

        // Elements.
        for (FIRVisionTextElement *element in line.elements) {
          CGRect normalizedRect = CGRectMake(element.frame.origin.x / width, element.frame.origin.y / height, element.frame.size.width / width, element.frame.size.height / height);
          CGRect convertedRect = [self->_previewLayer rectForMetadataOutputRectOfInterest:normalizedRect];
          [UIUtilities addRectangle:convertedRect toView:self->_annotationOverlayView color:UIColor.greenColor];
          UILabel *label = [[UILabel alloc] initWithFrame:convertedRect];
          label.text = element.text;
          label.adjustsFontSizeToFitWidth = YES;
          [self.annotationOverlayView addSubview:label];
        }
      }
    }
  }];
}

#pragma mark - Private

- (void)setUpCaptureSessionOutput {
  dispatch_async(_sessionQueue, ^{
    [self->_captureSession beginConfiguration];
    // When performing latency tests to determine ideal capture settings,
    // run the app in 'release' mode to get accurate performance metrics
    self->_captureSession.sessionPreset = AVCaptureSessionPresetMedium;

    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
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
    AVCaptureDevicePosition cameraPosition = self.isUsingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self captureDeviceForPosition:cameraPosition];
    if (device) {
      NSArray<AVCaptureInput *> *currentInputs = self.captureSession.inputs;
      for (AVCaptureInput *input in currentInputs) {
        [self.captureSession removeInput:input];
      }
      NSError *error;
      AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
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

- (void)setUpAnnotationOverlayView {
  _annotationOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
  _annotationOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
  [_cameraView addSubview:_annotationOverlayView];
  [NSLayoutConstraint activateConstraints:@[
                                            [_annotationOverlayView.topAnchor constraintEqualToAnchor:_cameraView.topAnchor],
                                            [_annotationOverlayView.leadingAnchor constraintEqualToAnchor:_cameraView.leadingAnchor],
                                            [_annotationOverlayView.trailingAnchor constraintEqualToAnchor:_cameraView.trailingAnchor],
                                            [_annotationOverlayView.bottomAnchor constraintEqualToAnchor:_cameraView.bottomAnchor]
                                            ]];
}

- (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position  {
  AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                                                             mediaType:AVMediaTypeVideo
                                                                                                              position:AVCaptureDevicePositionUnspecified];
  for (AVCaptureDevice *device in discoverySession.devices) {
    if (device.position == position) {
      return device;
    }
  }
  return nil;
}

- (void)presentDetectorsAlertController {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertControllerTitle message:alertControllerMessage preferredStyle:UIAlertControllerStyleAlert];
  for (NSNumber *detectorType in _detectors) {
    NSInteger detector = detectorType.integerValue;
    UIAlertAction *action = [UIAlertAction actionWithTitle:[self stringForDetector:detector]
                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                       self.currentDetector = detector;
                                                       [self removeDetectionAnnotations];
                                                     }];
    if (detector == _currentDetector) {
      [action setEnabled:NO];
    }
    [alertController addAction:action];
  }
  [alertController addAction:[UIAlertAction actionWithTitle:cancelActionTitleText
                                                      style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)removeDetectionAnnotations {
  for (UIView *annotationView in _annotationOverlayView.subviews) {
    [annotationView removeFromSuperview];
  }
}

- (NSArray <NSValue *>*)convertedPointsFromPoints:(NSArray<NSValue *> *)points
                                            width:(CGFloat)width
                                           height:(CGFloat)height {
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:points.count];
  for (NSValue *point in points) {
    CGPoint cgPointValue = point.CGPointValue;
    CGPoint normalizedPoint = CGPointMake(cgPointValue.x / width, cgPointValue.y / height);
    CGPoint cgPoint = [_previewLayer pointForCaptureDevicePointOfInterest:normalizedPoint];
    [result addObject: [NSValue valueWithCGPoint:cgPoint]];
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

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (imageBuffer) {
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithBuffer:sampleBuffer];
    FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
    UIImageOrientation orientation = [UIUtilities imageOrientationFromDevicePosition:_isUsingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
    FIRVisionDetectorImageOrientation visionOrientation = [UIUtilities visionImageOrientationFromImageOrientation:orientation];
    metadata.orientation = visionOrientation;
    visionImage.metadata = metadata;
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    switch (_currentDetector) {
      case DetectorOnDeviceFace:
        [self detectFacesOnDeviceInImage:visionImage width:imageWidth height:imageHeight];
        break;
      case DetectorOnDeviceText:
        [self recognizeTextOnDeviceInImage:visionImage width:imageWidth height:imageHeight];
        break;
    }
  } else {
    NSLog(@"%@", @"Failed to get image buffer from sample buffer.");
  }
}

@end
