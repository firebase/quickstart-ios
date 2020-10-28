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
#import "FIREGSignInHelper.h"

typedef BOOL (^SystemAlertHandler)(XCUIElement*);
static SystemAlertHandler const alertHandler = ^(XCUIElement* element) {
  if (element.buttons[@"Continue"].exists) {
    [element.buttons[@"Continue"] tap];
  }
  return YES;
};

static NSString *const signInButton = @"Sign in with Google";
static NSString *const welcomeMessage = @"HTTPS Callable functions Quickstart";

@interface FunctionsExampleUITests : XCTestCase
@end

@implementation FunctionsExampleUITests {
  XCUIApplication *_app;
  id<NSObject> signInPermissionMonitor;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  signInPermissionMonitor =
  [self addUIInterruptionMonitorWithDescription:@"Allow Google Sign-In" handler:alertHandler];
  [_app launch];
  if (![self signedIn]) {
    [[_app buttons][signInButton] tap];
    doGoogleSignIn(_app, YES, YES);
    // Make sure main app screen is loaded.
    FIRWaitForVisible([[_app collectionViews] firstMatch]);
  }
}

- (void)tearDown {
  [self removeUIInterruptionMonitor:signInPermissionMonitor];
  [super tearDown];
}

- (void)SKIPtestVerifyAppLaunched {
  // Check that main UI elements are present on the screen.
  XCTAssertTrue([[_app staticTexts][@"Add two numbers"] exists]);
  XCTAssertTrue([[_app staticTexts][@"Sanitize a message"] exists]);
}

- (void)SKIPtestAddTwoNumbers {
  XCUIElement* number1 = [_app textFields][@"Num 1"];
  FIRWaitForVisible(number1);
  [number1 tap];
  [number1 typeText:@"14"];

  XCUIElement* number2 = [_app textFields][@"Num 2"];
  FIRWaitForVisible(number2);
  [number2 doubleTap];
  [number2 typeText:@"51"];

  [[_app buttons][@"Calculate"] tap];
  XCUIElement* result = [_app textFields][@"65"];

  // Wait till network call is completed.
  FIRWaitForVisible(result);
  XCTAssert(result.exists);
}

- (void)SKIPtestChangeMessage {
  NSString* testText = @"hello from cloud functions!";
  XCUIElement* input = [_app textFields][@"Add your message"];
  [input tap];
  [input typeText:testText];

  [[_app buttons][@"Add message"] tap];
  XCUIElement* result = [_app textFields][[testText uppercaseString]];

  // Wait till network call is completed.
  FIRWaitForVisible(result);
  XCTAssert(result.exists);
}

- (BOOL)signedIn {
  FIRWaitForVisible(_app.buttons[signInButton]);
  return !_app.buttons[signInButton].exists;
}

@end
