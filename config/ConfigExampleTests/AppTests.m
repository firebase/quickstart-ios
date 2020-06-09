//
//  Copyright (c) 2016 Google Inc.
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

#import <FirebaseCore/FIRApp.h>
#import <FirebaseRemoteConfig/FIRRemoteConfig.h>

@interface AppTests : XCTestCase
@end

@implementation AppTests

- (void)setUp {
  [super setUp];
  if ([FIRApp defaultApp] == nil) {
    [FIRApp configure];
  }
}

- (void)testRemoteConfig {
  FIRRemoteConfig *remoteConfig = [FIRRemoteConfig remoteConfig];
  XCTAssert([remoteConfig isKindOfClass:[FIRRemoteConfig class]]);
}

@end
