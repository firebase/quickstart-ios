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

@interface PerformanceExampleUITests : XCTestCase

@end

@implementation PerformanceExampleUITests{
  XCUIApplication *_app;
}

- (void)setUp {
  [super setUp];
  _app = [[XCUIApplication alloc] init];
  [_app launch];
}

- (void)testVerifyAppLaunched {
    // Verify that Performance Example app launched successfully and its title is visible.
    XCTAssertTrue([_app navigationBars][@"Firebase Performance Example"].exists);

    // Make sure Google logo is loaded.
    XCTAssertTrue([[[_app images] elementBoundByIndex:0] exists]);
}

@end
