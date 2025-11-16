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

@interface ConfigUITest : XCTestCase
@end

@implementation ConfigUITest {
  XCUIApplication *_app;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  [_app launch];
}

- (void)testRemoteConfig {
  // Verify that Remote Config Example app is launched successfully and its title is visible.
  XCTAssertTrue([_app navigationBars][@"Remote Config Example"].exists);

  // Tap on 'Fetch Remote Config' button.
  [_app.buttons[@"Fetch Remote Config"] tap];

  // Verify that the Remote Config value is visible.
  XCUIElement* config = [_app staticTexts][@"WELCOME TO MY AWESOME APP!"];
  FIRWaitForVisibleWithTimeout(config, 20);
  XCTAssertTrue(config.exists);
}

@end
