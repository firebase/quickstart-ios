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

@interface DatabaseExampleUITests : XCTestCase

@end

static NSString *const signInButton = @"Sign In";
static NSString *const signOutButton = @"Sign Out";
static NSString *const createButton = @"Create";
static NSString *const okButton = @"OK";
static NSString *const emailPlaceholder = @"Email";
static NSString *const passwordPlaceholder = @"Password";
static NSString *const defaultUsername = @"user";
static NSString *const appLoginHeader = @"Database Example";
static NSString *const appMainHeader = @"Messages";
static NSString *const starBorder = @"ic_star_border";
static NSString *const starFull = @"ic_star";
static NSString *const accountLogo = @"ic_account_circle";
static NSString *const emailSuffix = @"_test@test.com";
static NSString *const noStars = @"0";
static NSString *const oneStar = @"1";

// Existing test credentials.
static NSString *const testEmail = @"1522698402_test@test.com";
static NSString *const testPassword = @"8261108117";


@implementation DatabaseExampleUITests {
  XCUIApplication *_app;
}

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
  _app = [[XCUIApplication alloc] init];
  [_app launch];

  // If user is signed in for some reason (for example, because previous test failed),
  // we need to explicitly sign them out.
  if (FIRSignedIn(_app)) {
    [self signOut];
  }
}

- (void)testVerifyAppLaunchedAndRelaunched {
  // Make sure app is launched.
  FIRWaitForVisible(_app.navigationBars[appLoginHeader]);
  XCTAssertTrue(_app.navigationBars[appLoginHeader].exists);
  [_app terminate];
  [_app launch];

  // Make sure app is relaunched.
  FIRWaitForVisible(_app.navigationBars[appLoginHeader]);
  XCTAssertTrue(_app.navigationBars[appLoginHeader].exists);
}

- (void)testLoginWithEmptyAccountCredentials {
  [self signInWithEmail:@"" password:@""];

  XCUIElement *errorMessage =
      _app.staticTexts[@"The password is invalid or the user does not have a password."];
  FIRWaitForVisible(errorMessage);
  XCTAssertTrue(errorMessage.exists);
  FIRDismissAlertIfOpen(_app);
}

- (void)testAccountCreationWithInvalidEmail {
  [self createLoginWithEmail:@"thisEmailHasNoProvider" password:@"aaaaaa"];

  XCUIElement *errorMessage = _app.staticTexts[@"The email address is badly formatted."];
  FIRWaitForVisible(errorMessage);
  XCTAssertTrue(errorMessage.exists);
  FIRDismissAlertIfOpen(_app);
}

- (void)testAccountCreationWithWeakPassword {
  NSString *newEmail = [timestamp() stringByAppendingString:emailSuffix];
  [self createLoginWithEmail:newEmail password:@"aaa"];

  XCUIElement *errorMessage = _app.staticTexts[@"The password must be 6 characters long or more."];
  FIRWaitForVisible(errorMessage);
  XCTAssertTrue(errorMessage.exists);
  FIRDismissAlertIfOpen(_app);
}

- (void)testAccountCreationWithCorrectCredentials {
  NSString *newEmail = [timestamp() stringByAppendingString:emailSuffix];
  NSString *newPassword = randomString(10);
  [self createLoginWithEmail:newEmail password:newPassword];

  [self assertIsLoggedIn];
  [self assertMainScreenIsVisible];
  [self signOut];
}

- (void)testSignOut {
  [self signInWithEmail:testEmail password:testPassword];
  [self assertIsLoggedIn];
  [self signOut];
}

- (void)testSignUpWithDuplicateAccount {
  [self createLoginWithEmail:testEmail password:testPassword];

  XCUIElement *errorMessage =
      _app.staticTexts[@"The email address is already in use by another account."];
  FIRWaitForVisible(errorMessage);
  XCTAssertTrue(errorMessage.exists);
  FIRDismissAlertIfOpen(_app);
}

- (void)testCreateAndReloginWithCorrectPassword {
  NSString *newEmail = [timestamp() stringByAppendingString:emailSuffix];
  NSString *newPassword = randomString(10);
  [self createLoginWithEmail:newEmail password:newPassword];
  [self assertIsLoggedIn];
  [self signOut];

  [self signInWithEmail:newEmail password:newPassword];
  [self assertIsLoggedIn];
  [self signOut];
}

- (void)testLoginWithWrongPassword {
  NSString *newEmail = [timestamp() stringByAppendingString:emailSuffix];
  NSString *newPassword = randomString(10);
  [self createLoginWithEmail:newEmail password:newPassword];
  [self assertIsLoggedIn];
  [self signOut];

  [self signInWithEmail:newEmail password:@"wrongPassword"];
  XCUIElement *errorMessage =
      _app.staticTexts[@"The password is invalid or the user does not have a password."];
  FIRWaitForVisible(errorMessage);
  XCTAssertTrue(errorMessage.exists);
  FIRDismissAlertIfOpen(_app);
}

- (void)testCreateNewValidPost {
  [self signInWithEmail:testEmail password:testPassword];
  [self assertIsLoggedIn];

  // Navigate to the new post screen.
  FIRWaitForVisible(_app.buttons[@"Add"]);
  [_app.buttons[@"Add"] tap];

  // Post some unique text.
  NSString *uniqueMessage = [NSString stringWithFormat:@"My test message %@", timestamp()];
  XCUIElement *inputField = [[_app textFields] firstMatch];
  [inputField tap];
  [inputField typeText:uniqueMessage];
  [[_app buttons][@"Done"] tap];
  [[_app buttons][@"Post"] tap];

  // Navigate back.
  [self assertMainScreenIsVisible];
  [self signOut];

  // Relaunch the app in order to clean cache.
  [_app terminate];
  [_app launch];

  // Sign in with the same credentials.
  [self signInWithEmail:testEmail password:testPassword];
  [self assertIsLoggedIn];

  // Navigate to "My posts" tab.
  [[_app buttons][@"My Posts"] tap];

  [self deleteAllMessages];

  // Make sure posted message is deleted.
  XCUIElement *postedMessage = [_app staticTexts][uniqueMessage];
  XCTAssertFalse([postedMessage exists]);
  [self signOut];
}

#pragma mark - Helpers

- (void)assertIsLoggedOut {
  // Check that "Sign In" button is present, i.e. user is not signed in yet.
  XCTAssertFalse(FIRSignedIn(_app), @"User shouldn't be signed in now");
}

- (void)assertIsLoggedIn {
  // Check that "Sign In" button is not present, i.e. user is signed in.
  XCTAssertTrue(FIRSignedIn(_app), @"User should be signed in now");
}

- (void)signInWithEmail:(NSString *)email password:(NSString *)password {
  // Type email.
  [[[_app textFields] firstMatch] tap];
  [[[_app textFields] firstMatch] typeText:email];

  // Type password.
  [[[_app secureTextFields] firstMatch] tap];
  [[[_app secureTextFields] firstMatch] typeText:password];
  FIRWaitForVisible(_app.buttons[signInButton]);
  [_app.buttons[signInButton] tap];
}

- (void)createLoginWithEmail:(NSString *)login password:(NSString *)password {
  FIRWaitForVisible(_app.buttons[createButton]);
  [_app.buttons[createButton] tap];
  XCUIElement *visibleTextField = [[[_app alerts] textFields] firstMatch];

  // Type login, password and username.
  NSArray *inputTexts = @[ login, password, defaultUsername ];
  for (id text in inputTexts) {
    [visibleTextField tap];
    [visibleTextField typeText:text];
    [[_app buttons][okButton] tap];
  }
}

- (void)assertMainScreenIsVisible {
  FIRWaitForVisible([_app navigationBars][appMainHeader]);

  // Itetate through all application tabs.
  NSArray *tabs = @[ @"Recent", @"My Posts", @"My Top Posts" ];
  for (id tab in tabs) {
    FIRWaitForVisible(_app.buttons[tab]);
    XCTAssertTrue(_app.buttons[tab]);
  }
}

- (void)signOut {
  FIRWaitForVisible(_app.buttons[signOutButton]);
  [_app.buttons[signOutButton] tap];

  FIRWaitForVisible([_app navigationBars][appLoginHeader]);
  [self assertIsLoggedOut];
}

- (void)deleteMessageWithText:(NSString *)label {
  FIRWaitForVisible(_app.staticTexts[label]);

  // Perform left swipe in order to remove this item.
  [[_app staticTexts][label] swipeLeft];
  XCUIElement *deleteButton = [_app buttons][@"Delete"];
  FIRWaitForVisible(deleteButton);
  [deleteButton tap];
}

- (void)deleteAllMessages {
  NSPredicate *messagePredicate =
      [NSPredicate predicateWithFormat:@"(label BEGINSWITH[c] %@)", @"My test message"];
  NSArray<XCUIElement *> *messages =
      [[[_app staticTexts] containingPredicate:messagePredicate] allElementsBoundByIndex];
  NSArray<NSString *> *labels = [messages valueForKey:@"label"];

  // Iterate over all messages and delete them all.
  for (NSString *label in labels) {
    [self deleteMessageWithText:label];
  }
}

@end
