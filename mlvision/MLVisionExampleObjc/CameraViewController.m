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

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

typedef NS_ENUM(NSInteger, Detector) {
  DetectorOnDeviceFace,
  DetectorOnDeviceText
};

@property (nonatomic) NSArray *detectors;
@property (nonatomic) Detector currentDetector;
@property (nonatomic) bool isUsingFrontCamera;
@property (nonatomic, nonnull) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) FIRVision *vision;
@property (nonatomic) UIView *annotationOverlayView;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@end

@implementation CameraViewController

- (NSString *)stringForDetector:(Detector)detector {
  switch (detector) {
    case DetectorOnDeviceFace:
    return @"On-Device Face Detection";
    case DetectorOnDeviceText:
    return @"On-Device Text Recognition";
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
  options.contourMode = FIRVisionFaceDetectorContourModeAll;
  options.trackingEnabled = YES;

  FIRVisionFaceDetector *faceDetector = [_vision faceDetectorWithOptions:options];
  NSError *error;
  NSArray<FIRVisionFace *> *faces = [faceDetector resultsInImage:image error:&error];
  if (error != nil) {
    NSLog(@"Failed to detect faces with error: %@", error.localizedDescription);
    return;
  }
  if (faces.count == 0) {
    NSLog(@"%@", @"On-Device face detector returned no results.");
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self removeDetectionAnnotations];
    });
    return;
  }

  dispatch_sync(dispatch_get_main_queue(), ^{
    [self removeDetectionAnnotations];
    for (FIRVisionFace *face in faces) {
      CGRect normalizedRect = CGRectMake(face.frame.origin.x / width, face.frame.origin.y / height, face.frame.size.width / width, face.frame.size.height / height);
      CGRect standardizedRect = CGRectStandardize([self->_previewLayer rectForMetadataOutputRectOfInterest:normalizedRect]);
      [UIUtilities addRectangle:standardizedRect toView:self->_annotationOverlayView color:UIColor.greenColor];
    }
  });
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
