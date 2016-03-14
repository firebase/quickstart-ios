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
// https://developers.google.com/firebase/docs/remote-config/ios
//

#import "ViewController.h"
#import "FIRRemoteConfig.h"

@implementation ViewController

const long PRICE = 100;
NSString *const PRICE_PREFIX = @"Your price is $";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.remoteConfig = [FIRRemoteConfig remoteConfig];

    // Create Remote Config Setting to enable developer mode.
    // Fetching configs from the server is normally limited to 5 requests per hour.
    // Enabling developer mode allows many more requests to be made per hour, so developers
    // can test different config values during development.
    // [START enable_dev_mode]
    FIRRemoteConfigSettings *remoteConfigSettings = [[FIRRemoteConfigSettings alloc] init];
    remoteConfigSettings.developerModeEnabled = YES;
    self.remoteConfig.configSettings = remoteConfigSettings;
    // [END enable_dev_mode]

    [self fetchConfig];
}

- (void)fetchConfig {
    _priceLabel.text = @"Checking your price...";

    long expirationDuration = 3600;
    // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
    // the server.
    if (self.remoteConfig.configSettings.developerModeEnabled) {
        expirationDuration = 0;
    }

    // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
    // fetched and cached config would be considered expired because it would have been fetched
    // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
    // throttling is in progress. The default expiration duration is 43200 (12 hours).
    // [START fetch_config_with_callback]
    [self.remoteConfig fetchWithExpirationDuration:expirationDuration completionHandler:^(FIRRemoteConfigStatus status, NSError *error) {
        if (status == FIRRemoteConfigStatusSuccess) {
            NSLog(@"Config fetched!");
            [self.remoteConfig activateFetched];
            [self displayPrice];
        } else {
            NSLog(@"Config not fetched");
            NSLog(@"Error %@", error);
            self.priceLabel.text = [NSString stringWithFormat:@"%@%ld", PRICE_PREFIX, PRICE];
        }
    }];
    // [END fetch_config_with_callback]
}

// Display price with discount applied if promotion is on. Otherwise display original price.
- (void)displayPrice {
    if (self.remoteConfig[@"is_promotion_on"].boolValue) {
        // [START get_config_value]
        long discountedPrice = PRICE - self.remoteConfig[@"discount"].numberValue.longValue;
        // [END get_config_value]
        self.priceLabel.text = [NSString stringWithFormat:@"%@%ld", PRICE_PREFIX, discountedPrice];
    } else {
        self.priceLabel.text = [NSString stringWithFormat:@"%@%ld", PRICE_PREFIX, PRICE];
    }
}

- (IBAction)handleFetchTouch:(id)sender {
    [self fetchConfig];
}

@end
