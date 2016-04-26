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

#import "TwitterLoginViewController.h"
#import "UIViewController+Alerts.h"
@import TwitterKit;
@import FirebaseAuth;

@implementation TwitterLoginViewController
- (void)viewDidLoad {
  [super viewDidLoad];

  TWTRLogInButton* logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession* session, NSError* error) {
    if (session) {
      // [START headless_twitter_auth]
      FIRAuthCredential *credential = [FIRTwitterAuthProvider credentialWithToken:session.authToken secret:session.authTokenSecret];
      // [START_EXCLUDE]
      [self showSpinner:^{
        // [END_EXCLUDE]
        [[FIRAuth auth] signInWithCredential:credential
                                  completion:^(FIRUser *user, NSError *error) {
                                      // [END headless_twitter_auth]
                                      [self hideSpinner:^{
                                        if (error) {
                                          [self showMessagePrompt:error.localizedDescription];
                                          return;
                                        }
                                        [self performSegueWithIdentifier:@"TwitterLogin" sender:nil];
                                      }];
                                    }];
      }];
    } else {
      NSLog(@"error: %@", error.localizedDescription);
    }
  }];
  logInButton.center = self.view.center;
  [self.view addSubview:logInButton];
}
@end
