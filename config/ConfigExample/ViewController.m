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
@import Firebase;

@implementation ViewController

NSString *const kWelcomeMessageConfigKey = @"welcome_message";
NSString *const kWelcomeMessageCapsConfigKey = @"welcome_message_caps";
NSString *const kLoadingPhraseConfigKey = @"loading_phrase";

- (void)viewDidLoad {
  [super viewDidLoad];
  // [START get_remote_config_instance]
  self.remoteConfig = [FIRRemoteConfig remoteConfig];
  // [END get_remote_config_instance]

  // Create a Remote Config Setting to enable developer mode, which you can use to increase
  // the number of fetches available per hour during development. See Best Practices in the
  // README for more information.
  // [START enable_dev_mode]
  FIRRemoteConfigSettings *remoteConfigSettings = [[FIRRemoteConfigSettings alloc] initWithDeveloperModeEnabled:YES];
  self.remoteConfig.configSettings = remoteConfigSettings;
  // [END enable_dev_mode]

  // Set default Remote Config parameter values. An app uses the in-app default values until you
  // update any values that you want to change in the Firebase console. See Best Practices in the
  // README for more information.
  // [START set_default_values]
  [self.remoteConfig setDefaultsFromPlistFileName:@"RemoteConfigDefaults"];
  // [END set_default_values]

  [self fetchConfig];
  [super viewDidLoad];
}

- (void)fetchConfig {
    self.welcomeLabel.text = self.remoteConfig[kLoadingPhraseConfigKey].stringValue;

    long expirationDuration = 3600;
    // If your app is using developer mode, expirationDuration is set to 0, so each fetch will
    // retrieve values from the Remote Config service.
    if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
        expirationDuration = 0;
    }

    // [START fetch_config_with_callback]
    // TimeInterval is set to expirationDuration here, indicating the next fetch request will use
    // data fetched from the Remote Config service, rather than cached parameter values, if cached
    // parameter values are more than expirationDuration seconds old. See Best Practices in the
    // README for more information.
    [self.remoteConfig fetchWithExpirationDuration:expirationDuration completionHandler:^(FIRRemoteConfigFetchStatus status, NSError *error) {
        if (status == FIRRemoteConfigFetchStatusSuccess) {
            NSLog(@"Config fetched!");
            [self.remoteConfig activateFetched];
        } else {
            NSLog(@"Config not fetched");
            NSLog(@"Error %@", error.localizedDescription);
        }
        [self displayWelcome];
    }];
    // [END fetch_config_with_callback]
}

// Display welcome message in all caps if welcome_message_caps is set to true. Otherwise
// display welcome message as fetched from welcome_message.
- (void)displayWelcome {
    // [START get_config_value]
    NSString *welcomeMessage = self.remoteConfig[kWelcomeMessageConfigKey].stringValue;
    // [END get_config_value]
    if (self.remoteConfig[kWelcomeMessageCapsConfigKey].boolValue) {
        welcomeMessage = [welcomeMessage uppercaseString];
    }
    self.welcomeLabel.text = welcomeMessage;
}

- (IBAction)handleFetchTouch:(id)sender {
    [self fetchConfig];
}

@end
