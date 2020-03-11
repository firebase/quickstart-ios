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

#import "FIREGSignInHelper.h"

#import "FIREGHelper.h"
#import "FIREGSignInInfo.h"

// Google Sign-In constants.
static NSString *const switchAccount = @"Use another account";
static NSString *const loginField = @"Email or phone";
static NSString *const passwordField = @"Enter your password";
static NSString *const nextButton = @"Next";

// Test credentials.
static NSString *const testAccount = TESTACCOUNT;
static NSString *const testPassword = TESTPASSWORD;
static NSString *const wrongTestPassword = @"123testing!";

void doGoogleSignIn(XCUIApplication *app, BOOL correctPassword, BOOL withAlert) {
  // Google Sign-In permission request handling if needed.
  if (withAlert) {
    FIRWaitTillAlertPresent(10);
    // Required for triggering SystemAlertHandler logic.
    [app tap];
  }

  // WebView with Google Sign-In should be loaded. All further user interactions happen on WebViews.
  // Enter account.
  XCUIElementQuery *webView = app.webViews;
  XCUIElement *login = webView.textFields[loginField];
  FIRWaitForVisible(login);
  [login tap];
  FIRWaitForVisible(app.keyboards.firstMatch);
  [login typeText:testAccount];

  // This is to hide keyboards after testAccount filled in.
  [app tap];
  FIRWaitForVisible(webView.buttons[nextButton]);
  [webView.buttons[nextButton] tap];

  // Enter password.
  XCUIElement *password = app.webViews.secureTextFields[passwordField];
  FIRWaitForVisible(password);
  [password tap];
  [password typeText:testPassword];
  [app tap];
  [webView.buttons[nextButton] tap];

  // It could take some time to do authentication.
  NSPredicate* gone = [NSPredicate predicateWithFormat:@"exists == false"];
  FIRWaitForPredicateWithTimeout(gone, password, 30);
  FIRDumpUIHierarchy(app);
}
