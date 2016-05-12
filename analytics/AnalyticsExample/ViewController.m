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

@import FirebaseAnalytics;

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSString *name = [NSString stringWithFormat:@"Pattern~%@", self.title];
  NSString *text = [NSString stringWithFormat:@"I'd love you to hear about %@", name];

  // [START custom_event_objc]
  [FIRAnalytics logEventWithName:@"share_image"
                           parameters:@{
                                        @"name": name,
                                        @"full_text": text
                                        }];
  // [END custom_event_objc]
}

@end
