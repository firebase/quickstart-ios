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

static NSString *const subscribeButton = @"Subscribe To Weather";
static NSString *const logButton = @"Log Token";

@interface MessagingExampleUITests : XCTestCase
@end

@implementation MessagingExampleUITests {
  XCUIApplication *_app;
  id<NSObject> notificationPermissionMonitor;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  notificationPermissionMonitor =
      [self addUIInterruptionMonitorWithDescription:@"Allow Notifications" handler:alertHandler];
  [_app launch];
}

- (void)tearDown {
  [self removeUIInterruptionMonitor:notificationPermissionMonitor];
  [super tearDown];
}

- (void)testVerifyAppLaunched {
  FIRWaitTillAlertPresent(defaultTimeout);
  // Remove the permission request and make sure it's gone.
  [[[_app navigationBars] element] tap];
  FIRWaitTillAlertGone(defaultTimeout);

  // Verify that Messaging Example app launched successfully and its title is visible.
  XCTAssertTrue(_app.buttons[subscribeButton].exists);

  // Make sure FCM token has been received. It's index 1 after the title at index 0.
  XCTAssertTrue(
      [[[[_app staticTexts] elementBoundByIndex:1] label] containsString:@"Received FCM token"]);

  // Tap on "Subscribe to News" button.
  [_app.buttons[subscribeButton] tap];

  // Tap on "Log Token" button.
  [_app.buttons[logButton] tap];

  // Make sure app is still in foreground (i.e. not crashed).
  XCTAssertTrue(_app.buttons[subscribeButton].exists);

  // Wait till network call is finished.
  NSPredicate *gone = [NSPredicate predicateWithFormat:@"exists == false"];
  FIRWaitForPredicateWithTimeout(gone, [_app staticTexts][@"No InstanceID token"], 20);

  // Make sure [FIRMessaging messaging].FCMToken returns FCM token.
  XCTAssertTrue(
      [[[[_app staticTexts] elementBoundByIndex:1] label] containsString:@"Logged FCM token"]);
  // Make sure [FIRInstanceID instanceID] instanceIDWithHandler: returns FCM token.
  XCTAssertTrue([[[[_app staticTexts] elementBoundByIndex:2] label]
      containsString:@"Remote InstanceID token"]);
}

@end
