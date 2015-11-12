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
@import Firebase.Config;

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // [START completion_handler]
  GCSDefaultConfigCompletion completion = ^void(GCSConfig *config, GCSConfigStatus status, NSError *error) {
    if (error) {
      // There has been an error fetching the config
      NSLog(@"Error fetching config: %@", error.localizedDescription);
    } else {
      // Parse your config data
      // [START_EXCLUDE]
      // [START read_data]
      BOOL isPromo = config[@"is_promotion_on"].boolValue;
      NSNumber *discount = config[@"discount"].numberValue;
      // [END read_data]
      double price = 100.00;
      if(isPromo) {
        price = (price / 100) * (price - [discount doubleValue]);
      }
      NSString *priceMsg = [NSString stringWithFormat:@"Your price is $%.02f", price];
      _priceLabel.text = priceMsg;
      BOOL isDevBuild = [config boolForKey:@"dev_features_on" defaultValue:NO];
      if (isDevBuild) {
        NSString *debugMsg = [NSString stringWithFormat:@"Config set size: %ld", (long)config.count];
        _debugLabel.text = debugMsg;
      }
      // [END_EXCLUDE]
    }
  };
  // [END completion_handler]

  // [START fetch_config]
  NSDictionary *customVariables = @{@"build":@"dev"};
  // 43200 secs = 12 hours
  [GCSConfig fetchDefaultConfigWithExpirationDuration:43200
                                      customVariables:customVariables
                                    completionHandler:completion];
  // [END fetch_config]
}

@end
