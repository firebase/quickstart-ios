//
//  Copyright (c) 2019 Google Inc.
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

#import <XCTest/XCTest.h>

#import "FIREGHelper.h"

typedef BOOL (^SystemAlertHandler)(XCUIElement *);
static SystemAlertHandler const alertHandler = ^(XCUIElement *element) {
  if (element.buttons[@"OK"].exists) {
    [element.buttons[@"OK"] tap];
  }
  if (element.buttons[@"Allow"].exists) {
    [element.buttons[@"Allow"] tap];
  }
  return YES;
};
static NSString *const header = @"Cloud Storage for Firebase Example";
static NSString *const downloadHeader = @"Photos";
static NSString *const takePictureButton = @"Take Picture";
static NSString *const downloadPictureButton = @"Download Picture";
static NSString *const cancelButton = @"Cancel";
static NSString *const momentsHeader = @"Moments";
static NSString *const uploadStartedTrait = @"Beginning upload";

@interface StorageExampleUITests : XCTestCase
@end

@implementation StorageExampleUITests {
  XCUIApplication *_app;
  id<NSObject> cameraPermissionMonitor;
}

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
  _app = [[XCUIApplication alloc] init];
  cameraPermissionMonitor =
      [self addUIInterruptionMonitorWithDescription:@"Allow camera or photos" handler:alertHandler];
  [_app launch];
}

- (void)tearDown {
  [self removeUIInterruptionMonitor:cameraPermissionMonitor];
  [super tearDown];
}

- (void)SKIP_testNavigateToDownloadViewAndBack_simulator {
  // Verify that Storage Example app launched successfully and its title is visible.
  [self checkHeaderIsPresent:header];

  // Verify that user can open and then dismiss DownloadViewController.
  [_app.buttons[takePictureButton] tap];

  FIRWaitForVisible(_app.navigationBars[downloadHeader]);
  XCTAssertTrue(_app.navigationBars[downloadHeader].exists);

  // Navigate back.
  [_app.navigationBars.buttons[cancelButton] tap];

  // Make sure user is taken back.
  [self checkHeaderIsPresent:header];
}

// The Photos UI changed in Xcode 12 and this function needs to be updated.
- (void)SKIP_testUploadFromPhotoLibraryAndDownload_simulator {
  // Try to select an existing image.
  [self selectImageFromLibrary];

  // Request for permission could appear here.
  FIRWaitTillAlertPresent(10);

  // If permission request appears - we need to remove it and select image once again.
  if (FIRSystemAlertShown()) {
    // Required for triggering SystemAlertHandler logic.
    [_app tap];
    // Select the image one more time, see b/74081132
    [self selectImageFromLibrary];
  }
  // Make sure main screen is present.
  [self checkHeaderIsPresent:header];

  // Wait till upload is finished.
  XCUIElement *downloadButton = _app.buttons[downloadPictureButton];
  NSPredicate *hittable = [NSPredicate predicateWithFormat:@"hittable == true"];
  FIRWaitForPredicateWithTimeout(hittable, downloadButton, 20);

  // Navigate to image screen.
  [_app.buttons[downloadPictureButton] tap];

  // Check that image downloaded.
  FIRWaitForVisibleWithTimeout(_app.textViews[@"Download Succeeded!"], 30);
  XCTAssertTrue(_app.textViews[@"Download Succeeded!"].exists);
}

#pragma mark - Helpers

// Common way to detect what screen is displayed now.
- (void)checkHeaderIsPresent:(NSString *)header {
  FIRWaitForVisible(_app.navigationBars[header]);
  XCTAssertTrue(_app.navigationBars[header].exists);
}

// Select an image from existing photo library.
- (void)selectImageFromLibrary {
  FIRWaitForVisible(_app.buttons[takePictureButton]);
  [_app.buttons[takePictureButton] tap];

  // Select the "Moments" folder.
  XCUIElement *momentsLink = [[[[_app tables] cells] matchingIdentifier:momentsHeader] element];
  FIRWaitForVisible(momentsLink);
  [momentsLink tap];

  // Wait till UIImagePickerController has loaded photo library.
  XCUIElement *momentsTitle = [_app navigationBars][momentsHeader];
  FIRWaitForVisible(momentsTitle);

  // Select some image from the list of images.
  XCUIElement *image = [[_app cells] elementBoundByIndex:1];
  [image tap];
}

@end
