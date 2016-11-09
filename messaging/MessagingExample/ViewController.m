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

#import "ViewController.h"
@import FirebaseInstanceID;
@import FirebaseMessaging;

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (IBAction)handleLogTokenTouch:(id)sender {
  // [START get_iid_token]
  NSString *token = [[FIRInstanceID instanceID] token];
  NSLog(@"InstanceID token: %@", token);
  // [END get_iid_token]
}

- (IBAction)handleSubscribeTouch:(id)sender {
  // [START subscribe_topic]
  [[FIRMessaging messaging] subscribeToTopic:@"/topics/news"];
  NSLog(@"Subscribed to news topic");
  // [END subscribe_topic]
}

@end
