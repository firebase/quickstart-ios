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

// [START usermanagement_view_import]
#import "FirebaseAuth/FIRAuth.h"
#import "FirebaseAuth/FIRAuthUI.h"
#import "FirebaseAuth/FIRGoogleSignInAuthProvider.h"
#import "FirebaseAuth/FIRUser.h"
#import "Firebase/Core.h"
// [END usermanagement_view_import]

/*! @var kSignInButtonText
 @brief The text of the "Sign In" button.
 */
static NSString *const kSignInButtonText = @"Sign In";

/*! @var kSignedInAlertTitle
 @brief The text of the "Sign In Succeeded" alert.
 */
static NSString *const kSignedInAlertTitle = @"Signed In";

/*! @var kSignInErrorAlertTitle
 @brief The text of the "Sign In Encountered an Error" alert.
 */
static NSString *const kSignInErrorAlertTitle = @"Sign-In Error";

/*! @var kOKButtonText
 @brief The text of the "OK" button for the Sign In result dialogs.
 */
static NSString *const kOKButtonText = @"OK";

/*! @var kSignInButtonWidth
 @brief The width of the "Sign In" button.
 */
static const CGFloat kSignInButtonWidth = 200;

/*! @var kSignInButtonHeight
 @brief The height of the "Sign In" button.
 */
static const CGFloat kSignInButtonHeight = 30;

@interface ViewController () <FIRAuthUIDelegate>
@end
@implementation ViewController

- (void)loadView {
  [super loadView];
  self.view.backgroundColor = [UIColor whiteColor];
  [self loadSignInButton];
}

/*! @fn loadSignInButton
 @brief Loads the sign in button.
 */
- (void)loadSignInButton {
  UIButton *signInButton = [UIButton buttonWithType:UIButtonTypeSystem];
  signInButton.frame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight);
  [signInButton setTitle:kSignInButtonText forState:UIControlStateNormal];
  [signInButton addTarget:self
                   action:@selector(signInPressed:)
         forControlEvents:UIControlEventTouchUpInside];

  signInButton.center =
  CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));

  signInButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
  | UIViewAutoresizingFlexibleRightMargin
  | UIViewAutoresizingFlexibleBottomMargin
  | UIViewAutoresizingFlexibleLeftMargin;

  [self.view addSubview:signInButton];
}

/*! @fn signInPressed:
 @brief Invoked when the sign in button is pressed.
 @param sender The sign in button.
 */
- (void)signInPressed:(UIButton *)sender {
  // [START usermanagement_config]
  FIRAuth *firebaseAuth = [FIRAuth auth];
  FIRAuthUIOptions *firebaseAuthUIOptions = [[FIRAuthUIOptions alloc] init];
  FIRGoogleSignInAuthProvider *googleSignIn =
  [[FIRGoogleSignInAuthProvider alloc] initWithClientId:
      [FIRContext sharedInstance].serviceInfo.clientID];
  [firebaseAuthUIOptions addProvider:googleSignIn];
  // [END usermanagement_config]

  FIRAuthUI *firebaseAuthUI =
  [FIRAuthUI authUIWithAuth:firebaseAuth options:firebaseAuthUIOptions delegate:self];
  [firebaseAuthUI presentSignInWithCallback:^(FIRUser *_Nullable user,
                                              NSError *_Nullable error) {
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:kOKButtonText
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                 NSLog(kOKButtonText);
                               }];
    if (error) {
      UIAlertController *alertController = [UIAlertController
                                            alertControllerWithTitle:kSignInErrorAlertTitle
                                            message:error.localizedDescription
                                            preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:okAction];
      [self presentViewController:alertController
                         animated:YES
                       completion:nil];
      return;
    }

    // Log sign in event to Scion.
    [GMRAppMeasurement logEventWithName:kGMREventLogin parameters:nil];

    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:kSignedInAlertTitle
                                          message:user.displayName
                                          preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [self presentViewController:alertController 
                       animated:YES 
                     completion:nil];
  }];
}

@end
