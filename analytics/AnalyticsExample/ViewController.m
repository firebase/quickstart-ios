//
//  Copyright (c) 2015 Google Inc.
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

//
// For more information on setting up and running this sample code, see
// https://firebase.google.com/docs/analytics/ios/start
//

#import "ViewController.h"

@import Firebase;

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [self recordScreenView];

  // [START custom_event_objc]
  [FIRAnalytics logEventWithName:kFIREventSelectContent
                      parameters:@{
                                   kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", self.title],
                                   kFIRParameterItemName:self.title,
                                   kFIRParameterContentType:@"image"
                                   }];
  // [END custom_event_objc]
}

// Manually record "screen views" as user selects tabs.
- (void)recordScreenView {
  // These strings must be <= 36 characters long in order for setScreenName:screenClass: to succeed.
  NSString *screenName = self.title;
  NSString *screenClass = [self.classForCoder description];

  // [START set_current_screen]
  [FIRAnalytics setScreenName:screenName screenClass:screenClass];
  // [END set_current_screen]
}

@end
