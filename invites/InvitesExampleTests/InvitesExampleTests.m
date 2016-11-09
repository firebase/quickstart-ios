//
//  Copyright (c) Google Inc.
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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Firebase/AppInvite.h>

@interface AppInvitesExampleTests : XCTestCase

@end

@implementation AppInvitesExampleTests

- (void)testAppWasConfigured {
  // Check that the FIR context matches what we read from the file.
  FIRContext* context = [FIRContext sharedInstance];
  NSDictionary *configPlist =
      [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                 pathForResource:@"GoogleService-Info"
                                          ofType:@"plist"]];
  NSError* configureError = nil;
  [context configure: &configureError];

  // Check the client ID is configured for iOS target app.
  NSString* actual = context.serviceInfo.clientID;
  NSString* expected = [configPlist objectForKey:@"CLIENT_ID"];

  XCTAssertEqualObjects(actual, expected);
}

@end
