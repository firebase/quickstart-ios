//
//  ConfigExampleUITests.m
//  ConfigExampleUITests
//
//  Created by Ibrahim Ulukaya on 2/13/18.
//  Copyright © 2018 Google Inc. All rights reserved.
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
