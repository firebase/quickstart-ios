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


// This ViewController demonstrates logging events leading up to a crash and
// reporting that crash. Crashes are automatically reported.
//
// Events are logged using FCRLog().
//
// Check https://developers.google.com/firebase/console to view and analyze your crash reports.
//
// Check https://developers.google.com/firebase/docs/crash/crash-ios for more on
// Firebase Crash on iOS.


#import "ViewController.h"
#import "Firebase/CrashReporting.h"

@import Firebase;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    // FCRLog provides a boolean that allows you to specify whether or not to include the
    // logged event in the console output. In this case the "View loaded" event will
    // be shown in the console output.
    // [START log_event]
    FCRLog(TRUE, @"View loaded");
    // [END log_event]
}

- (IBAction)initiateCrash:(id)sender {
    // [START log_and_crash]
    FCRLog(FALSE, @"Cause crash button clicked");
    assert(NO);
    // [END log_and_crash]
}

@end
