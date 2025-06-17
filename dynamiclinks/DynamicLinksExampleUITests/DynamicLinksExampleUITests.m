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

static NSString *const header = @"Dynamic Links Example";
static NSString *const okButton = @"OK";
static NSString *const generateButton = @"Click HERE to Generate Links";
static NSString *const urlToConvert = @"https://google.com/photos/about/";
static NSString *const linkTrait = @"https://";

@interface DynamicLinksExampleUITests : XCTestCase
@end

@implementation DynamicLinksExampleUITests {
  XCUIApplication *_app;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  [_app launch];
  // This is not a system alert, so it can be handled by regular EG means.
  [self dismissAlertIfOpen];
}

- (void)testVerifyLinksGenerated {
  XCTAssertTrue([_app navigationBars][header].exists);

  // Type url to convert.
  XCUIElement *inputText = [[_app textFields] elementBoundByIndex:0];
  FIRWaitForVisible(inputText);
  [inputText tap];
  [inputText typeText:urlToConvert];

  // Navigate to the bottom.
  [inputText swipeUp];

  // Make sure there is no links generated.
  NSPredicate *linkPredicate =
  [NSPredicate predicateWithFormat:@"(label CONTAINS[c] %@)", linkTrait];
  XCTAssertEqual([[[_app staticTexts] matchingPredicate:linkPredicate] count], 0,
                 @"There shouldn't be any links generated.");

  // Generate links.
  [[_app staticTexts][generateButton] tap];

  // The long link appears immediately, while we need to wait for the short link.
  XCUIElement *shortLink =
  [[[_app staticTexts] matchingPredicate:linkPredicate] elementBoundByIndex:1];
  FIRWaitForVisible(shortLink);

  // Make sure both links are present.
  XCTAssertEqual([[[_app staticTexts] matchingPredicate:linkPredicate] count], 2,
                 @"Both links should be generated.");
}

// Dismiss alert by tapping "OK" button.
- (void)dismissAlertIfOpen {
  FIRWaitForVisible(_app.buttons[okButton]);
  if (_app.buttons[okButton].exists) {
    [_app.buttons[okButton] tap];
  }
}

@end
