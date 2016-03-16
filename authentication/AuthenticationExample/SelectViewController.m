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

#import "SelectViewController.h"

@import FirebaseAuth;
@import FirebaseAuthUI;
@import Firebase.Core;

/*! @var kOKButtonText
 @brief The text of the "OK" button for the Sign In result dialogs.
 */
static NSString *const kOKButtonText = @"OK";

/*! @var kSignedInAlertTitle
 @brief The text of the "Sign In Succeeded" alert.
 */
static NSString *const kSignedInAlertTitle = @"Signed In";

/*! @var kSignInErrorAlertTitle
 @brief The text of the "Sign In Encountered an Error" alert.
 */
static NSString *const kSignInErrorAlertTitle = @"Sign-In Error";


@interface SelectViewController ()
@end

@implementation SelectViewController

- (IBAction)didUISignIn:(UIButton *)sender {
  // [START firebase_auth_ui]
  FIRAuth *firebaseAuth = [FIRAuth auth];
  FIRAuthUI *firebaseAuthUI = [FIRAuthUI authUIForApp:firebaseAuth.app];
  [firebaseAuthUI presentSignInWithViewController:self callback:^(FIRUser *_Nullable user,
                                                                  NSError *_Nullable error) {
    // [END firebase_auth_ui]
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:kOKButtonText
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       NSLog(kOKButtonText);
                                                     }];
    if (error) {
      UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:kSignInErrorAlertTitle
                                          message:error.localizedDescription
                                   preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:okAction];
      [self presentViewController:alertController animated:YES completion:nil];
      return;
    }

    // Log sign in event to Firebase Analytics.
    [FIRAnalytics logEventWithName:kFIREventLogin parameters:nil];

    [self performSegueWithIdentifier:@"UISignIn" sender:nil];
  }];
}

- (IBAction)didTapGuestSignIn:(id)sender {
  // [START firebase_auth_anonymous]
  [[FIRAuth auth] signInAnonymouslyWithCallback:^(FIRUser *_Nullable user,
                                                  NSError *_Nullable error) {
    // [END firebase_auth_anonymous]
    if (error) {
      NSLog(@"%@", error.localizedDescription);
      return;
    }
    [self performSegueWithIdentifier:@"UISignIn" sender:nil];
  }];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

@end
