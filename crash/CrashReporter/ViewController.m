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

#import "ViewController.h"
@import FirebaseCrash;


@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Log that the view did load, FIRCrashNSLog is used here so the log message will be
  // shown in the console output. If FIRCrashLog is used the message is not shown in
  // the console output.
  FIRCrashNSLog(@"View loaded");
}

- (IBAction)initiateCrash:(id)sender {
    // FIRCrashLog is used here to indicate that the log message
    // will not be shown in the console output. Use FIRCrashNSLog to have the
    // log message show in the console output.
    // [START log_and_crash]
    FIRCrashLog(@"Cause Crash button clicked");
    assert(NO);
    // [END log_and_crash]
}

@end
