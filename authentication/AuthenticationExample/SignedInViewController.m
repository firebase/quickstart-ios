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

#import "SignedInViewController.h"
#import "UIViewController+Alerts.h"
@import FirebaseAuth;
@import Firebase.Core;

@interface SignedInViewController ()
@property (weak, nonatomic) IBOutlet UILabel *userInfoEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *userInfoDisplayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userInfoUserIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *userInfoProviderListLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userInfoProfileURLImageView;
@end

/*! @var kOKButtonText
 @brief The text of the "OK" button for the Sign In result dialogs.
 */
static NSString *const kOKButtonText = @"OK";

/*! @var kTokenRefreshedAlertTitle
 @brief The title of the "Token Refreshed" alert.
 */
static NSString *const kTokenRefreshedAlertTitle = @"Token";

/*! @var kTokenRefreshErrorAlertTitle
 @brief The title of the "Token Refresh error" alert.
 */
static NSString *const kTokenRefreshErrorAlertTitle = @"Get Token Error";

/** @var kSetDisplayNameTitle
 @brief The title of the "Set Display Name" error dialog.
 */
static NSString *const kSetDisplayNameTitle = @"Set Display Name";

/** @var kUnlinkTitle
 @brief The text of the "Unlink from Provider" error Dialog.
 */
static NSString *const kUnlinkTitle = @"Unlink from Provider";

/** @var kChangeEmailText
 @brief The title of the "Change Email" button.
 */
static NSString *const kChangeEmailText = @"Change Email";

/** @var kChangePasswordText
 @brief The title of the "Change Password" button.
 */
static NSString *const kChangePasswordText = @"Change Password";


@implementation SignedInViewController

- (void)viewDidLoad {
  // Give us a circle for the image view:
  _userInfoProfileURLImageView.layer.cornerRadius =
  _userInfoProfileURLImageView.frame.size.width / 2.0f;
  _userInfoProfileURLImageView.layer.masksToBounds = YES;
  [self updateUserInfo];
}

/** @fn signOut
 @brief Signs the user out.
 */
- (IBAction)didSignOut:(id)sender {
  // [START auth_signout]
  FIRAuth *firebaseAuth = [FIRAuth auth];
  NSError *signOutError;
  BOOL status = [firebaseAuth signOut:&signOutError];
  if (!status) {
    NSLog(@"Error signing out: %@", signOutError);
    return;
  }
  // [END auth_signout]
  [self performSegueWithIdentifier:@"SignOut" sender:nil];
}

/** @fn forceTokenRefresh
 @brief Invoked when the token refresh row is pressed.
 */
- (IBAction)didTokenRefresh:(id)sender {
  FIRAuthTokenCallback action = ^(NSString * _Nullable token, NSError * _Nullable error) {
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

    // Log token refresh event to Scion.
    [FIRAnalytics logEventWithName:@"tokenrefresh" parameters: nil];

    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:kTokenRefreshedAlertTitle
                                        message:token
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
  };
  // [START token_refresh]
  [[FIRAuth auth].currentUser getTokenForcingRefresh:YES callback:action];
  // [END token_refresh]
}

/** @fn setDisplayName
 @brief Changes the display name of the current user.
 */
- (IBAction)didSetDisplayName:(id)sender {
  [self showTextInputPromptWithMessage:@"Display Name:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                         if (!userPressedOK || !userInput.length) {
                           return;
                         }

                         [self showSpinner:^{
                           // [START profile_change]
                           FIRUserProfileChangeRequest *changeRequest =
                           [[FIRAuth auth].currentUser profileChangeRequest];
                           changeRequest.displayName = userInput;
                           [changeRequest commitChangesWithCallback:^(NSError *_Nullable error) {
                             // [END profile_change]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kSetDisplayNameTitle error:error];
                               [self updateUserInfo];
                             }];
                           }];
                         }];
                       }];
}

- (IBAction)didUnlinkFacebook:(id)sender {
  [self unlinkFromProvider:FIRFacebookAuthProviderID];
}

- (IBAction)didUnlinkGoogle:(id)sender {
  [self unlinkFromProvider:FIRGoogleAuthProviderID];
}

/** @fn unlinkFromProvider:
 @brief Unlinks the current user from the provider with the specified provider ID.
 @param provider The provider ID of the provider to unlink the current user's account from.
 */
- (void)unlinkFromProvider:(NSString *)provider {
  // [START unlink_provider]
  [[FIRAuth auth].currentUser unlinkFromProvider:provider
                                        callback:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                                          [self showTypicalUIForUserUpdateResultsWithTitle:kUnlinkTitle error:error];
                                          [self updateUserInfo];
                                        }];
  // [END unlink_provider]
}

/** @fn requestVerifyEmail
 @brief Requests a "verify email" email be sent.
 */
- (IBAction)didRequestVerifyEmail:(id)sender {
  [self showSpinner:^{
    // [START send_verification_email]
    [[FIRAuth auth].currentUser sendEmailVerification:^(NSError * _Nullable error) {
      // [END send_verification_email]
      [self hideSpinner:^{
        if (error) {
          [self showMessagePrompt:error.localizedDescription];
          return;
        }

        [self showMessagePrompt:@"Sent"];
      }];
    }];
  }];
}

/** @fn changeEmail
 @brief Changes the email address of the current user.
 */
- (IBAction)didChangeEmail:(id)sender {
  [self showTextInputPromptWithMessage:@"Email Address:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                         if (!userPressedOK || !userInput.length) {
                           return;
                         }

                         [self showSpinner:^{
                           // [START change_email]
                           [[FIRAuth auth].currentUser updateEmail:userInput callback:^(NSError *_Nullable error) {
                             // [END change_email]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kChangeEmailText error:error];
                               [self updateUserInfo];
                             }];
                           }];
                         }];
                       }];
}

/** @fn changePassword
 @brief Changes the password of the current user.
 */
- (IBAction)didChangePassword:(id)sender {
  [self showTextInputPromptWithMessage:@"New Password:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                         if (!userPressedOK || !userInput.length) {
                           return;
                         }

                         [self showSpinner:^{
                           // [START change_password]
                           [[FIRAuth auth].currentUser updatePassword:userInput callback:^(NSError *_Nullable error) {
                             // [END change_password]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kChangePasswordText error:error];
                               [self updateUserInfo];
                             }];
                           }];
                         }];
                       }];
}

#pragma mark - Helpers

/** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
 @brief Shows a @c UIAlertView if error is non-nil with the localized description of the error.
 @param resultsTitle The title of the @c UIAlertView
 @param error The error details to display if non-nil.
 */
- (void)showTypicalUIForUserUpdateResultsWithTitle:(NSString *)resultsTitle
                                             error:(NSError *)error {
  if (error) {
    NSString *message =
    [NSString stringWithFormat:@"%@ (%ld)\n%@",
     error.domain,
     (long)error.code,
     error.localizedDescription];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:resultsTitle
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:kOKButtonText, nil];
    [alert show];
    return;
  }
}

- (void)updateUserInfo {
  FIRUser *user = [FIRAuth auth].currentUser;
  _userInfoDisplayNameLabel.text = user.displayName;
  _userInfoEmailLabel.text = user.email;
  _userInfoUserIDLabel.text = user.uid;

  NSMutableArray<NSString *> *providerIDs = [NSMutableArray array];
  for (id<FIRUserInfo> userInfo in user.providerData) {
    [providerIDs addObject:userInfo.providerID];
  }
  _userInfoProviderListLabel.text = [providerIDs componentsJoinedByString:@", "];

  NSURL *photoURL = user.photoURL;
  static NSURL *lastPhotoURL = nil;
  lastPhotoURL = photoURL;  // to prevent earlier image overwrites later one.
  if (photoURL) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]];
      dispatch_async(dispatch_get_main_queue(), ^() {
        if (photoURL == lastPhotoURL) {
          _userInfoProfileURLImageView.image = image;
        }
      });
    });
  } else {
    _userInfoProfileURLImageView.image = nil;
  }
}

@end
