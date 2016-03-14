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

//
// For more information on setting up and running this sample code, see
// https://developers.google.com/firebase/docs/auth/ios/user-auth
//

#import "GoogleSignInViewController.h"
#import "UIViewController+Alerts.h"

#import <GoogleSignIn/GIDSignIn.h>
#import <GoogleSignIn/GIDSignInButton.h>
#import <GoogleSignIn/GIDGoogleUser.h>
#import <GoogleSignIn/GIDAuthentication.h>

@import FirebaseAuth;
@import Firebase.Core;

@interface GoogleSignInViewController ()<GIDSignInDelegate, GIDSignInUIDelegate>
@property (weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
@end

@implementation GoogleSignInViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [GIDSignIn sharedInstance].clientID = [FIRContext sharedInstance].serviceInfo.clientID;
  [GIDSignIn sharedInstance].uiDelegate = self;

  // TODO(developer): Configure the sign-in button look/feel
  [GIDSignIn sharedInstance].delegate = self;
}

// [START headless_google_auth]
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
  if (error == nil) {
    GIDAuthentication *authentication = user.authentication;
    FIRAuthCredential *credential =
    [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken accessToken:authentication.accessToken];

    // [START_EXCLUDE]
    [self showSpinner:^{
      // [END_EXCLUDE]
      [[FIRAuth auth] signInWithCredential:credential
                                  callback:^(FIRUser *user, NSError *error) {
                                    // [END headless_google_auth]
                                    [self hideSpinner:^{
                                      if (error) {
                                        [self showMessagePrompt:error.localizedDescription];
                                        return;
                                      }
                                      [self performSegueWithIdentifier:@"GoogleSignIn" sender:nil];
                                    }];
                                  }];
                                }];
  } else {
    NSLog(@"%@", error.localizedDescription);
  }
}

@end
