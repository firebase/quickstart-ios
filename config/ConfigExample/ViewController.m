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
@import FirebaseRemoteConfig;

@implementation ViewController

NSString *const kWelcomeMessageConfigKey = @"welcome_message";
NSString *const kWelcomeMessageCapsConfigKey = @"welcome_message_caps";
NSString *const kLoadingPhraseConfigKey = @"loading_phrase";

- (void)viewDidLoad {
  [super viewDidLoad];
  // [START get_remote_config_instance]
  self.remoteConfig = [FIRRemoteConfig remoteConfig];
  // [END get_remote_config_instance]

  // Create Remote Config Setting to enable developer mode.
  // Fetching configs from the server is normally limited to 5 requests per hour.
  // Enabling developer mode allows many more requests to be made per hour, so developers
  // can test different config values during development.
  // [START enable_dev_mode]
  FIRRemoteConfigSettings *remoteConfigSettings = [[FIRRemoteConfigSettings alloc] initWithDeveloperModeEnabled:YES];
  self.remoteConfig.configSettings = remoteConfigSettings;
  // [END enable_dev_mode]

  // Set default Remote Config values. In general you should have in-app defaults for all
  // values that you may configure using Remote Config later on. The idea is that you
  // use the in-app defaults and when you need to adjust those defaults, you set an updated
  // value in the App Manager console. The next time that your application fetches values
  // from the server, the new values you set in the Firebase console are cached. After you
  // activate these values, they are used in your app instead of the in-app defaults. You
  // can set default values using a plist file, as shown here, or you can set defaults
  // inline by using one of the other setDefaults methods.
  // [START set_default_values]
  [self.remoteConfig setDefaultsFromPlistFileName:@"RemoteConfigDefaults"];
  // [END set_default_values]

  [self fetchConfig];
  [super viewDidLoad];
}

- (void)fetchConfig {
    self.welcomeLabel.text = self.remoteConfig[kLoadingPhraseConfigKey].stringValue;

    long expirationDuration = 3600;
    // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
    // the server.
    if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
        expirationDuration = 0;
    }

    // [START fetch_config_with_callback]
    // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
    // fetched and cached config would be considered expired because it would have been fetched
    // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
    // throttling is in progress. The default expiration duration is 43200 (12 hours).
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
