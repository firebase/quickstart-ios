//
//  Copyright (c) 2018 Google Inc.
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
@import Firebase;
@import Crashlytics;

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Log that the view did load, CLSNSLog is used here so the log message will be
  // shown in the console output. If CLSLog is used the message is not shown in
  // the console output.
  CLSNSLog(@"View loaded");

  [CrashlyticsKit setIntValue:3 forKey:@"current_level"];
  [CrashlyticsKit setObjectValue:@"logged_in" forKey:@"last_UI_action"];
  [CrashlyticsKit setUserIdentifier:@"123456789"];

  NSDictionary *userInfo = @{
                             NSLocalizedDescriptionKey: NSLocalizedString(@"The request failed.", nil),
                             NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The response returned a 404.", nil),
                             NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Does this page exist?", nil),
                             @"ProductID": @"123456",
                             @"UserID": @"Jane Smith"
                             };
  NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                       code:-1001
                                   userInfo:userInfo];
  [CrashlyticsKit recordError:error];
}

- (IBAction)initiateCrash:(id)sender {
  // CLSLog is used here to indicate that the log message
  // will not be shown in the console output. Use CLSNSLog to have the
  // log message show in the console output.
  // [START log_and_crash]
  CLSLog(@"Cause Crash button clicked");
  [Crashlytics.sharedInstance crash];
    // [END log_and_crash]
}

@end
