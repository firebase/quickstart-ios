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

typedef BOOL (^SystemAlertHandler)(XCUIElement *);
static SystemAlertHandler const alertHandler = ^(XCUIElement *element) {
  if (element.buttons[@"Continue"].exists) {
    [element.buttons[@"Continue"] tap];
  }

  if (element.buttons[@"WLAN Only"].exists) {
    [element.buttons[@"WLAN Only"] tap];
  }
  return YES;
};

static NSString *const header = @"Authentication Example";
static NSString *const signInButton = @"Sign In";
static NSString *const createButton = @"Create";
static NSString *const signOutButton = @"Sign Out";
static NSString *const linkButton = @"Link";
static NSString *const optionsHeader = @"Select Provider";
static NSString *const emailPlaceholder = @"Email";
static NSString *const passwordPlaceholder = @"Password";
static NSString *const okButton = @"OK";
static NSString *const backButton = @"Back";
static NSString *const googleProvider = @"Google";
static NSString *const tokenRefreshButton = @"Token Refresh";
static NSString *const requestVerifyEmail = @"Request Verify Email";
static NSString *const cancelButton = @"Cancel";
static NSString *const errorMessage =
    @"Wrong password. Try again or click Forgot password to reset it.";
static NSString *const alertMessage = @"The user canceled the sign-in flow.";

// Test account credentials.
static NSString *const testEmail = @"test@test.com";
static NSString *const testPassword = @"test12";

@interface AuthenticationExampleUITests : XCTestCase
@property NSArray *signInOptions;
@end

@implementation AuthenticationExampleUITests {
  XCUIApplication *_app;
  id<NSObject> signInPermissionMonitor;
}

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
  _app = [[XCUIApplication alloc] init];
  signInPermissionMonitor =
      [self addUIInterruptionMonitorWithDescription:@"Allow Google Sign-In" handler:alertHandler];
  _signInOptions = @[ @"Email", @"Anonymous", @"Google", @"Facebook" ];
  [_app launch];

  if ([self signedIn]) {
    [self signOut];
  }
  FIRWaitForVisible(_app.buttons[signInButton]);
}

- (void)tearDown {
  [self removeUIInterruptionMonitor:signInPermissionMonitor];
  [super tearDown];
}

- (void)testAuth {
  // Verify that Auth Example app launched successfully and its title is visible.
  XCTAssertTrue(_app.navigationBars[header].exists);
}

- (void)testAuthOptions {
  [_app.buttons[signInButton] tap];
  FIRWaitForVisible(_app.alerts[optionsHeader]);

  // Make sure various authentication options are present.
  for (NSString *option in _signInOptions) {
    XCTAssertTrue(_app.buttons[option].exists);
  }
}

- (void)testAuthAnonymously {
  // Verify that user is able to authenticate anonymously.
  [self signInWith:@"Anonymous"];

  FIRWaitForVisible(_app.buttons[signOutButton]);
  XCTAssertTrue(_app.buttons[linkButton].exists);
  [self signOut];
}

- (void)testAuthExistingAccount {
  [self signInWith:@"Email"];
  FIRWaitForVisible(_app.buttons[createButton]);

  XCUIElement *inputText = [[_app textFields] elementBoundByIndex:0];
  FIRWaitForVisible(inputText);
  [inputText tap];
  [inputText typeText:testEmail];

  XCUIElement *password = [[_app secureTextFields] elementBoundByIndex:0];
  FIRWaitForVisible(password);
  [password tap];
  [password typeText:testPassword];

  [[_app buttons][signInButton] tap];
  FIRWaitForVisible(_app.buttons[signOutButton]);
  XCTAssertTrue([self signedIn], @"User should be able to sign-in with existing credentials");
  [self signOut];
}

- (void)testAuthExistingAccountWrongPassword {
  [self signInWith:@"Email"];
  FIRWaitForVisible(_app.buttons[createButton]);

  XCUIElement *inputText = [[_app textFields] elementBoundByIndex:0];
  FIRWaitForVisible(inputText);
  [inputText tap];
  [inputText typeText:testEmail];

  XCUIElement *password = [[_app secureTextFields] elementBoundByIndex:0];
  FIRWaitForVisible(password);
  [password tap];
  [password typeText:@"wrong password"];

  [[_app buttons][signInButton] tap];
  XCUIElement *error =
      _app.alerts.staticTexts[@"The password is invalid or the user does not have a password."];
  FIRWaitForVisible(error);
  XCTAssertTrue(error.exists);

  [self dismissAlertIfOpen];
  [self goBack];

  XCTAssertFalse([self signedIn], @"User shouldn't be able to sign-in with wrong credentials");
}

- (void)testCreateAccountBadPassword {
  [self signInWith:@"Email"];
  FIRWaitForVisible(_app.buttons[createButton]);

  // 5 characters is not long enough, user should see an error.
  [self createLogin:testEmail withPassword:randomString(5)];

  XCUIElement *error = _app.alerts.staticTexts[@"The password must be 6 characters long or more."];
  FIRWaitForVisible(error);
  XCTAssertTrue(error.exists);

  [self dismissAlertIfOpen];
  [self goBack];
  XCTAssertFalse([self signedIn], @"User shouldn't be signed in with a weak password");
}

- (void)testCreateAlreadyExistingAccount {
  [self signInWith:@"Email"];
  FIRWaitForVisible(_app.buttons[createButton]);

  // This account is already created.
  [self createLogin:testEmail withPassword:testPassword];

  XCUIElement *error =
      _app.alerts.staticTexts[@"The email address is already in use by another account."];
  FIRWaitForVisible(error);
  XCTAssertTrue(error.exists);

  [self dismissAlertIfOpen];
  [self goBack];
  XCTAssertFalse([self signedIn], @"User shouldn't be able to create an already existing account");
}

- (void)testCreateAccountCorrectPassword {
  [self signInWith:@"Email"];
  FIRWaitForVisible(_app.buttons[createButton]);

  // These are valid credentials.
  NSString *newEmail = [timestamp() stringByAppendingString:@"_test@test.com"];
  NSString *newPassword = randomString(10);
  [self createLogin:newEmail withPassword:newPassword];

  FIRWaitForVisible(_app.buttons[signOutButton]);
  XCTAssertTrue([self signedIn], @"User should be signed in with newly created credentials");
  [self signOut];
}

// TODO(b/140411106): Fix the GoogleSignIn breakage.
- (void)FAILING_testGoogleSignInAndLinkAccount {
  [self signInWith:@"Google"];

  // User can be signed in right away, without following Google Sign-In flow.
  if (![self signedIn]) {
    doGoogleSignIn(_app, YES, YES);
    // Wait till all alerts and spinners are gone.
    FIRWaitForVisible(_app.buttons[signOutButton]);
  }
  // Make sure user is signed in.
  XCTAssertTrue([self signedIn], @"User should be able to sign-in with existing credentials");

  // Make sure all the required UI elements are present.
  XCTAssertTrue(_app.buttons[tokenRefreshButton].exists);
  XCTAssertTrue(_app.buttons[requestVerifyEmail].exists);
  XCTAssertTrue(_app.buttons[linkButton].exists);

  // Sign out from this Google account.
  [self signOut];
  XCTAssertFalse([self signedIn], @"User should be signed out");

  // Sign in anonymously.
  [self signInWith:@"Anonymous"];
  XCTAssertTrue([self signedIn], @"User should be able to sign-in anonymously");

  // Try to link anonymous accout with exisiting Google account.
  FIRWaitForVisible(_app.buttons[linkButton]);
  [_app.buttons[linkButton] tap];
  FIRWaitForVisible(_app.buttons[@"Google"]);
  [_app.buttons[@"Google"] tap];

  XCUIElement *error =
      _app.alerts
          .staticTexts[@"This credential is already associated with a different user account."];
  FIRWaitForVisible(error);
  XCTAssertTrue(error.exists);

  // Dismiss the alert.
  [self dismissAlertIfOpen];

  [self signOut];
}

// TODO(b/140411106): Fix the GoogleSignIn breakage.
- (void)FAILING_testGoogleSignInWrongPasswordAndCancelFlow {
  [self signInWith:@"Google"];
  if (![self signedIn]) {
    // Try to sign in with invalid credentials.
    doGoogleSignIn(_app, NO, YES);

    XCUIElement *error = _app.staticTexts[errorMessage];
    XCTAssertTrue([error exists], @"Error message should be present.");

    // Close Safari ViewController.
    [_app.buttons[cancelButton] tap];

    // Make sure the correct alert message appears.
    FIRWaitForVisible(_app.alerts.staticTexts[alertMessage]);

    // Dismiss the alert.
    [self dismissAlertIfOpen];
  }
}

#pragma mark - Helpers

- (void)signInWith:(NSString *)provider {
  FIRWaitForVisible(_app.buttons[signInButton]);
  [_app.buttons[signInButton] tap];
  FIRWaitForVisible(_app.buttons[provider]);
  [_app.buttons[provider] tap];
}

- (void)signOut {
  FIRWaitForVisible(_app.buttons[signOutButton]);
  [_app.buttons[signOutButton] tap];
  XCTAssertTrue(_app.buttons[signInButton].exists);
}

- (BOOL)signedIn {
  FIRWaitForVisible(_app.buttons[signOutButton]);
  return _app.buttons[signOutButton].exists;
}

// Navigate back using Navigation Controller (back button could different on different OS,
// so both options are checked).
- (void)goBack {
  FIRWaitForVisible(_app.buttons[backButton]);
  if (_app.buttons[backButton].exists) {
    [_app.buttons[backButton] tap];
  } else {
    [[_app.navigationBars.buttons firstMatch] tap];
  }
}

// Dismiss alert by tapping "OK" button.
- (void)dismissAlertIfOpen {
  XCUIElement *button = _app.buttons[okButton];
  FIRWaitForVisible(button);
  if (button.exists) {
    [button tap];
  }
}

- (void)createLogin:(NSString *)login withPassword:(NSString *)password {
  FIRWaitForVisible(_app.buttons[createButton]);
  [_app.buttons[createButton] tap];

  XCUIElement *inputText = [[[_app alerts] textFields] elementBoundByIndex:0];
  FIRWaitForVisible(inputText);
  [inputText typeText:login];
  [[_app buttons][okButton] tap];

  XCUIElement *passwordField = [[[_app alerts] textFields] elementBoundByIndex:0];
  FIRWaitForVisible(passwordField);
  [passwordField typeText:password];
  [[_app buttons][okButton] tap];
}

@end
