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

#import "FBLoginViewController.h"
#import "UIViewController+Alerts.h"

@import FirebaseAuth;
@import FBSDKCoreKit;
@import FBSDKLoginKit;

@interface FBLoginViewController ()<FBSDKLoginButtonDelegate>
//@property (weak, nonatomic) IBOutlet FBSDKLoginButton *facebookLoginButton;
@end

@implementation FBLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
  loginButton.center = self.view.center;
  loginButton.delegate = self;
  [self.view addSubview:loginButton];
}

- (void)loginButton:(FBSDKLoginButton *)loginButton
    didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
  if (error == nil) {
    // [START headless_facebook_auth]
    FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                     credentialWithAccessToken: [FBSDKAccessToken currentAccessToken].tokenString];
    // [START_EXCLUDE]
    [self showSpinner:^{
      // [END_EXCLUDE]
      [[FIRAuth auth] signInWithCredential:credential
                                completion:^(FIRUser *user, NSError *error) {
                                    // [END headless_facebook_auth]
                                    [self hideSpinner:^{
                                      if (error) {
                                        [self showMessagePrompt:error.localizedDescription];
                                        return;
                                      }
                                      [self performSegueWithIdentifier:@"FBLogin" sender:nil];
                                    }];
                                  }];
    }];

  } else {
    NSLog(@"%@", error.localizedDescription);
  }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
  [self showMessagePrompt:@"User logged out!"];
}


@end
