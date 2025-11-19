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

static NSTimeInterval const defaultTimeout = 10;

@interface AnalyticsUITest : XCTestCase
@end

@implementation AnalyticsUITest {
  XCUIApplication *_app;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  [_app launch];
}

- (void)testVerifyAppLaunched {
  NSArray *tapArray = @[ @"A", @"B", @"C", @"D" ];

  FIRWaitForVisible(_app.staticTexts[@"Pick Your Favorite Food!"]);
  [[_app.pickerWheels firstMatch] adjustToPickerWheelValue:@"Pizza"];

  // Tap on each tab
  for (NSString *tap_label in tapArray) {
    [_app.buttons[tap_label] tap];
  }

  // Share
  [_app.buttons[@"Share"] tap];
  FIRWaitForVisible([_app.alerts firstMatch]);
  XCTAssertTrue(_app.alerts[@"Share: D"].exists);
}

static void FIRWaitForVisibleWithTimeout(XCUIElement *element, NSUInteger timeout) {
  NSPredicate *visible = [NSPredicate predicateWithFormat:@"exists == true"];
  FIRWaitForPredicateWithTimeout(visible, element, timeout);
}

static void FIRWaitForVisible(XCUIElement *element) {
  FIRWaitForVisibleWithTimeout(element, defaultTimeout);
}

static void FIRWaitForPredicateWithTimeout(NSPredicate *predicate, XCUIElement *element,
                                    NSUInteger timeout) {
  XCTestExpectation *expectation =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:element];
  NSArray *expectationArray = @[ expectation ];
  (void)[XCTWaiter waitForExpectations:expectationArray timeout:timeout];
}

@end
