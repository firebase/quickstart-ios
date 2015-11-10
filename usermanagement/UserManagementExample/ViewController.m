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

/*! @var kTokenRefreshButtonText
 @brief The text of the "Refresh Token" button.
 */
static NSString *const kTokenRefreshButtonText = @"Get Token";

/*! @var kTokenRefreshedAlertTitle
 @brief The title of the "Token Refreshed" alert.
 */
static NSString *const kTokenRefreshedAlertTitle = @"Token";

/*! @var kTokenRefreshErrorAlertTitle
 @brief The title of the "Token Refresh error" alert.
 */
static NSString *const kTokenRefreshErrorAlertTitle = @"Get Token Error";

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

/*! @var kSignOutButtonText
 @brief The text of the "Sign Out" button.
 */
static NSString *const kSignOutButtonText = @"Sign Out";

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

/*! @var kUserEmailLabelHeight
 @brief The height of the user's email address label.
 */
static const CGFloat kUserEmailLabelHeight = 20;

@interface ViewController ()<FIRAuthUIDelegate>
@end
@implementation ViewController {
  __weak UILabel *_userEmailLabel;
}

- (void)loadView {
  [super loadView];
  self.view.backgroundColor = [UIColor whiteColor];
  [self loadSignInButton];
  [self loadTokenRefreshButton];
  [self loadSignOutButton];
  [self loadUserEmailLabel];
  _userEmailLabel.text = [FIRAuth auth].currentUser.email;
}

/*! @fn loadSignOutButton
 @brief Loads the "sign out" button.
 */
- (void)loadSignOutButton {
  UIButton *signOutButton = [UIButton buttonWithType:UIButtonTypeSystem];
  signOutButton.frame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight);
  [signOutButton setTitle:kSignOutButtonText forState:UIControlStateNormal];
  [signOutButton addTarget:self
                    action:@selector(signOutPressed:)
          forControlEvents:UIControlEventTouchUpInside];

  signOutButton.center =
  CGPointMake(CGRectGetMidX(self.view.bounds),
              CGRectGetMidY(self.view.bounds) - kSignInButtonHeight);

  signOutButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
  | UIViewAutoresizingFlexibleRightMargin
  | UIViewAutoresizingFlexibleBottomMargin
  | UIViewAutoresizingFlexibleLeftMargin;

  [self.view addSubview:signOutButton];
}

/*! @fn loadUserEmailLabel
 @brief Loads the label which displays the user's email address.
 */
- (void)loadUserEmailLabel {
  CGRect userEmailLabelFrame =
  CGRectMake(0, 0, self.view.bounds.size.width, kUserEmailLabelHeight);
  UILabel *userEmailLabel = [[UILabel alloc] initWithFrame:userEmailLabelFrame];
  userEmailLabel.textAlignment = NSTextAlignmentCenter;
  userEmailLabel.center = self.view.center;
  userEmailLabel.center =
  CGPointMake(self.view.center.x, self.view.center.y + (kSignInButtonHeight * 2));
  [self.view addSubview:userEmailLabel];
  _userEmailLabel = userEmailLabel;
}

/*! @fn loadTokenRefreshButton
 @brief Loads the "refresh token" button.
 */
- (void)loadTokenRefreshButton {
  UIButton *tokenRefreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
  tokenRefreshButton.frame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight);
  [tokenRefreshButton setTitle:kTokenRefreshButtonText forState:UIControlStateNormal];
  [tokenRefreshButton addTarget:self
                         action:@selector(refreshTokenPressed:)
               forControlEvents:UIControlEventTouchUpInside];

  tokenRefreshButton.center =
  CGPointMake(CGRectGetMidX(self.view.bounds),
              CGRectGetMidY(self.view.bounds) + kSignInButtonHeight);

  tokenRefreshButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
  | UIViewAutoresizingFlexibleRightMargin
  | UIViewAutoresizingFlexibleBottomMargin
  | UIViewAutoresizingFlexibleLeftMargin;

  [self.view addSubview:tokenRefreshButton];
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

#pragma mark - Actions

/*! @fn signInPressed:
 @brief Invoked when the sign in button is pressed.
 @param sender The sign in button.
 */
- (void)signInPressed:(UIButton *)sender {
  FIRAuth *firebaseAuth = [FIRAuth auth];
  FIRAuthUI *firebaseAuthUI =
  [FIRAuthUI authUIWithAuth:firebaseAuth delegate:self];
  [firebaseAuthUI presentSignInWithCallback:^(FIRUser *_Nullable user,
                                              NSError *_Nullable error) {

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

    _userEmailLabel.text = [FIRAuth auth].currentUser.email;
    [GMRAppMeasurement logEventWithName:kGMREventLogin parameters:nil];

    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:kSignedInAlertTitle
                                        message:user.displayName
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
  }];
}

- (void)signOutPressed:(UIButton *)sender {
  FIRAuth *firebaseAuth = [FIRAuth auth];
  [firebaseAuth signOut];
  _userEmailLabel.text = firebaseAuth.currentUser.email;
}

/*! @fn refreshTokenPressed:
 @brief Invoked when the token refresh button is pressed.
 @param sender The token refresh button.
 */
- (void)refreshTokenPressed:(UIButton *)sender {
  [[FIRAuth auth] getTokenForcingRefresh:NO
                            withCallback:^(NSString * _Nullable token, NSError * _Nullable error) {

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:kOKButtonText
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       NSLog(kOKButtonText);
                                                     }];
    if (error) {
      UIAlertController *alertController =
          [UIAlertController alertControllerWithTitle:kTokenRefreshErrorAlertTitle
                                              message:error.localizedDescription
                                       preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:okAction];
      [self presentViewController:alertController animated:YES completion:nil];
      return;
    }

    [GMRAppMeasurement logEventWithName:@"tokenrefresh" parameters:nil];

    UIAlertController *alertController =
       [UIAlertController alertControllerWithTitle:kTokenRefreshedAlertTitle
                                           message:token
                                    preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
  }];
}

@end