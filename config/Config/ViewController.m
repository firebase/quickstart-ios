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
#import <Firebase/Config.h>

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  GCSDefaultConfigCompletion completion = ^void(GCSConfig *config, GCSConfigStatus status, NSError *error) {
    if (error) {
      // There has been an error fetching the config
      NSLog(@"Error fetching config: %@", error.localizedDescription);
    } else {
      BOOL isPromo = config[@"is-promotion-on"].boolValue;
      NSNumber* discount = config[@"discount"].numberValue;
      NSLog(@"isPromo: %d", isPromo);
      NSLog(@"discount: %@", discount);
    }
  };

  NSDictionary *customVariables = @{@"build":@"dev"};
  // 43200 secs = 12 hours
  [GCSConfig fetchDefaultConfigWithExpirationDuration:43200
                                      customVariables:customVariables
                                    completionHandler:completion];
}

@end
