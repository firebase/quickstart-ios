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

#import "FIREGHelper.h"

// Google Sign-In constants.
static NSString *const switchAccount = @"Use another account";
static NSString *const loginField = @"Email or phone";
static NSString *const passwordField = @"Enter your password";
static NSString *const nextButton = @"Next";

// Test credentials.
static NSString *const testAccount = @"fb.engprod7@gmail.com";
static NSString *const testPassword = @"123testing";
static NSString *const wrongTestPassword = @"123testing!";

void tapNext(XCUIApplication *app) {
  // Dismiss the keyboard, on small screens "Next" button could be hidden.
  [[[app toolbars] buttons][@"Done"] tap];
  if (app.buttons[nextButton.uppercaseString].exists) {
    FIRTapSafely(app, app.buttons[nextButton.uppercaseString]);
  } else {
    FIRTapSafely(app, app.webViews.buttons[nextButton]);
  }
}

void doGoogleSignIn(XCUIApplication *app, BOOL correctPassword, BOOL withAlert) {
  // Google Sign-In permission request handling if needed.
  if (withAlert) {
    FIRWaitTillAlertPresent(10);
    // Required for triggering SystemAlertHandler logic.
    // Tap on status bar is always safe while [app tap] is not safe.
    [[[app statusBars] element] tap];
  }

  // WebView with Google Sign-In should be loaded. All further user interactions happen on WebViews.
  XCUIElement *switchButton = app.webViews.links[switchAccount];
  FIRWaitForVisible(switchButton);

  // Even though some account could be saved and suggested, we'd like to enter the test
  // account credentials. This simplifies the test logic.
  if ([switchButton exists]) {
    FIRTapSafely(app, switchButton);
  }

  // Enter account.
  XCUIElement *login = app.webViews.textFields[loginField];
  FIRWaitForVisible(login);
  FIRTapSafely(app, login);

  // Make sure login is focused.
  NSPredicate *focused = [NSPredicate predicateWithFormat:@"hasKeyboardFocus == true"];
  FIRWaitForPredicate(focused, login);
  [login typeText:testAccount];

  tapNext(app);

  // Enter password.
  XCUIElement *password = app.webViews.secureTextFields[passwordField];
  FIRWaitForVisible(password);
  FIRTapSafely(app, password);

  FIRWaitForPredicate(focused, password);
  [password typeText:testPassword];
  tapNext(app);

  // It could take some time to do authentication.
  NSPredicate* gone = [NSPredicate predicateWithFormat:@"exists == false"];
  FIRWaitForPredicateWithTimeout(gone, password, 30);
  FIRDumpUIHierarchy(app);
}
