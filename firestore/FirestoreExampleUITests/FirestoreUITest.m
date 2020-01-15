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

static NSString *const starRating = @"No rating";

// Test credentials.
static NSString *const testEmail = @"test@google.com";
static NSString *const testName = @"test google";
static NSString *const testPassword = @"Test123";

@interface FirestoreUITest : XCTestCase
@end

@implementation FirestoreUITest {
  XCUIApplication *_app;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  [_app launch];
  if (![self isSignedIn]) {
    [self doSignIn];
  }
  // The next two navigations are to give the restaurants time to load.  Is there a better way?

  // Navigate to the filter screen.
  [_app.buttons[@"Filter"] tap];

  // Navigate back.
  [_app.buttons[@"Done"] tap];

  // Make sure table with restaurants has loaded.
  NSUInteger allRestaurants = [self restaurantsCount];
  XCTAssertEqual(allRestaurants, 50, @"50 restaurants are loaded.");
}

- (void)testVerifyAppLaunched {
  [self checkMainScreenIsDisplayed];

  // Make sure table with restaurants is not empty.
  XCTAssertGreaterThan([self restaurantsCount], 0, @"Restaurants should be loaded.");
}

- (void)testAddComment {
  // Navigate to the first restaurant in the list.
  FIRWaitForVisible(_app.navigationBars[@"Friendly Eats"]);
  XCUIElement *firstRestaurant = [_app.cells firstMatch];
  [firstRestaurant tap];

  // Navigate to the review section.
  FIRWaitForVisible(_app.buttons[@"Add"]);
  [_app.buttons[@"Add"] tap];
  FIRWaitForVisible(_app.navigationBars[@"Write a Review"]);

  // If we have 5 stars in the Imageview, the last, 5th star will be somewhere between 80% and 100%
  // of image width, so 90% is just the horizontal middle of it.
  XCUIElement *stars = _app.otherElements[starRating];
  [[stars coordinateWithNormalizedOffset:(CGVectorMake(0.9, 0.5))] tap];

  // Type the comment into text field.
  XCUIElement *textField = [[_app textFields] firstMatch];
  [textField tap];
  [textField typeText:@"The food was delicious!"];

  // Navigate back to main screen.
  NSArray *backButtons = @[ @"Done", @"Friendly Eats" ];
  for (id button in backButtons) {
    FIRWaitForVisible(_app.buttons[button]);
    [_app.buttons[button] tap];
    FIRWaitForVisible([[_app tables] firstMatch]);
  }
  [self checkMainScreenIsDisplayed];
}

// TODO(b/147740878): reenable this test once we've figured out how to make it deterministic
- (void)xtestApplyFilter {
  // Navigate to the filter screen.
  [_app.buttons[@"Filter"] tap];

  // Filter by category.
  FIRWaitForVisible(_app.textFields[@"Category"]);
  [_app.textFields[@"Category"] tap];

  // Intract with wheel picker and apply the filter,
  [[[_app pickerWheels] element] adjustToPickerWheelValue:@"Deli"];
  [[_app buttons][@"Done"] tap];

  [self checkMainScreenIsDisplayed];
  // Check that filter is applied.
  NSUInteger filteredRestaurants = [self restaurantsCount];
  XCTAssertEqual(filteredRestaurants, 5, @"5 restaurants should pass the filter.");
}

- (NSUInteger)restaurantsCount {
  return [[[[_app tables] firstMatch] cells] count];
}

- (void)doSignIn {
  XCUIElementQuery *buttons = [_app buttons];
  [buttons [@"Sign in with email"] tap];
  // Type test email.
  XCUIElement *email = _app.textFields[@"Enter your email"];
  [email tap];
  [email typeText:testEmail];
  [[buttons [@"Next"] firstMatch] tap];

  XCUIElement *name =_app.textFields[@"First & last name"];
  // This account does not exist before. First & last name is required.
  if (name.exists) {
    [name tap];
    [name typeText:testName];
    // Type test password.
    XCUIElement *password = _app.secureTextFields[@"Choose password"];

    [password tap];
    [password typeText:testPassword];
    [[buttons [@"Save"] firstMatch] tap];
  }
  // This account existed and only password required.
  else{
    // Type test password.
    XCUIElement *password = _app.secureTextFields[@"Enter your password"];

    [password tap];
    [password typeText:testPassword];
    [[buttons [@"Sign in"] firstMatch] tap];

  }


  // Wait till list with restaurants is loaded.
  FIRWaitForVisible([[_app cells] firstMatch]);
}

- (BOOL)isSignedIn {
  return ![_app buttons][@"Sign in with email"].exists;
}

- (void)checkMainScreenIsDisplayed {
  // Check that navigation bar contains all the required items.
  NSArray<NSString *> *navBar = @[ @"Populate", @"Filter" ];
  for (NSString *button in navBar) {
    XCTAssertTrue(_app.buttons[button].exists);
  }
}

@end
