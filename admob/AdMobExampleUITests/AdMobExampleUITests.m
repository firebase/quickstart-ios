//
// Copyright (c) 2019 Google Inc.
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
static NSString *const header = @"AdMob Example";
static NSString *const bannerButtonLabel = @"SHOW INTERSTITIAL AD";
static NSString *const closeButtonLabel = @"Close Advertisement";

@interface AdMobExampleUITests : XCTestCase
@end

@implementation AdMobExampleUITests {
  XCUIApplication *_app;
  XCUIElement *adMobBanner;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  [_app launch];

  adMobBanner = [_app staticTexts][@"Test Ad"];

  // Wait till banner is loaded.
  NSPredicate *bannerIsLoaded = [NSPredicate predicateWithFormat:@"isHittable == true"];
  FIRWaitForPredicateWithTimeout(bannerIsLoaded, adMobBanner, 30);
}

 // Verify that Ad Banner is displayed.
- (void)testVerifyAdBanner {
  // Make sure app is in foreground.
  [self checkAppInForeground];

  // Verify that Ad Banner is Hittable.
  XCTAssertTrue(adMobBanner.isHittable);

}

// Verify that user is taken to web view if they tap on the banner button.
- (void)testVerifyButton {
  // Make sure header is visible.
  XCUIElement *appHeader = [_app navigationBars][header];
  XCTAssertTrue(appHeader.exists);

  // Make sure the button is visible.
  XCUIElement *bannerButton = [_app buttons][bannerButtonLabel];
  XCTAssertTrue(bannerButton.isHittable);

  [bannerButton tap];
  // Make sure some web views are loaded.
  XCTAssertTrue([[_app webViews] count] > 0);
}

- (void)checkAppInForeground {
  NSPredicate *appInForeground =
      [NSPredicate predicateWithFormat:@"state == %d", XCUIApplicationStateRunningForeground];
  FIRWaitForPredicate(appInForeground, _app);
  XCTAssertEqual(_app.state, XCUIApplicationStateRunningForeground, @"App should be in foreground");
}

- (void)checkAppInBackground {
  NSPredicate *appInBackground = [NSPredicate
      predicateWithFormat:@"state == %d", XCUIApplicationStateRunningBackgroundSuspended];
  FIRWaitForPredicate(appInBackground, _app);
  XCTAssertEqual(_app.state, XCUIApplicationStateRunningBackgroundSuspended,
                 @"App should be in background");
}

static void FIRWaitForPredicate(NSPredicate *predicate, XCUIElement *element) {
  FIRWaitForPredicateWithTimeout(predicate, element, defaultTimeout);
}

static void FIRWaitForPredicateWithTimeout(NSPredicate *predicate, XCUIElement *element,
                                    NSUInteger timeout) {
  XCTestExpectation *expectation =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:element];
  NSArray *expectationArray = @[ expectation ];
  (void)[XCTWaiter waitForExpectations:expectationArray timeout:timeout];
}

@end
