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

#import "MainViewController.h"
#import "UIViewController+Alerts.h"
@import FBSDKCoreKit;
@import FBSDKLoginKit;
@import TwitterKit;

static const int kSectionToken = 3;
static const int kSectionProviders = 2;
static const int kSectionUser = 1;
static const int kSectionSignIn = 0;

typedef enum : NSUInteger {
  AuthEmail,
  AuthAnonymous,
  AuthFacebook,
  AuthGoogle,
  AuthTwitter,
  AuthCustom,
  AuthPhone,
  AuthPasswordless
} AuthProvider;

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

/** @var kUpdatePhoneNumberText
 @brief The title of the "Update Phone Number" button.
 */
static NSString *const kUpdatePhoneNumberText = @"Update Phone Number";

@interface MainViewController ()
@property(strong, nonatomic) FIRAuthStateDidChangeListenerHandle handle;
@end

@implementation MainViewController

- (void)firebaseLoginWithCredential:(FIRAuthCredential *)credential {
  [self showSpinner:^{
    if ([FIRAuth auth].currentUser) {
      // [START link_credential]
      [[FIRAuth auth]
       .currentUser linkWithCredential:credential
       completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
         // [START_EXCLUDE]
         [self hideSpinner:^{
           if (error) {
             [self showMessagePrompt:error.localizedDescription];
             return;
           }
           [self.tableView reloadData];
         }];
         // [END_EXCLUDE]
       }];
       // [END link_credential]
     } else {
       // [START signin_credential]
       [[FIRAuth auth] signInWithCredential:credential
                                 completion:^(FIRUser *user, NSError *error) {
         // [START_EXCLUDE silent]
         [self hideSpinner:^{
         // [END_EXCLUDE]
         if (error) {
           // [START_EXCLUDE]
           [self showMessagePrompt:error.localizedDescription];
           // [END_EXCLUDE]
           return;
         }
         // User successfully signed in. Get user data from the FIRUser object
         // [START_EXCLUDE]
         }];
         // [END_EXCLUDE]
       }];
       // [END signin_credential]
    }
  }];
}

- (void)showAuthPicker: (NSArray<NSNumber *>*) providers {
  UIAlertController *picker =
      [UIAlertController alertControllerWithTitle:@"Select Provider"
                                          message:nil
                                   preferredStyle:UIAlertControllerStyleAlert];

  for (NSNumber *provider in providers) {
    UIAlertAction *action;
    switch (provider.unsignedIntegerValue) {
      case AuthEmail:
      {
        action = [UIAlertAction actionWithTitle:@"Email"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          [self performSegueWithIdentifier:@"email" sender:nil];
        }];
      }
        break;
      case AuthPasswordless:
      {
        action = [UIAlertAction actionWithTitle:@"Passwordless"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
                                          [self performSegueWithIdentifier:@"passwordless" sender:nil];
                                        }];
      }
      break;
      case AuthCustom:
      {
        action = [UIAlertAction actionWithTitle:@"Custom"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          [self performSegueWithIdentifier:@"customToken" sender:nil];
        }];
      }
        break;
      case AuthTwitter:
      {
        action = [UIAlertAction actionWithTitle:@"Twitter"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
            if (session) {
              // [START headless_twitter_auth]
              FIRAuthCredential *credential =
                  [FIRTwitterAuthProvider credentialWithToken:session.authToken
                                                       secret:session.authTokenSecret];
              // [END headless_twitter_auth]
              [self firebaseLoginWithCredential:credential];
            } else {
              [self showMessagePrompt:error.localizedDescription];
            }
          }];
        }];
      }
        break;
      case AuthFacebook: {
        action = [UIAlertAction actionWithTitle:@"Facebook"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
          [loginManager logInWithReadPermissions:@[ @"public_profile", @"email" ]
                              fromViewController:self
                                         handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error) {
              [self showMessagePrompt:error.localizedDescription];
            } else if (result.isCancelled) {
              NSLog(@"FBLogin cancelled");
            } else {
              // [START headless_facebook_auth]
              FIRAuthCredential *credential = [FIRFacebookAuthProvider
                  credentialWithAccessToken:[FBSDKAccessToken currentAccessToken].tokenString];
               // [END headless_facebook_auth]
               [self firebaseLoginWithCredential:credential];
             }
           }];
        }];
      }
        break;
      case AuthGoogle: {
        action = [UIAlertAction actionWithTitle:@"Google"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          // [START setup_gid_uidelegate]
          [GIDSignIn sharedInstance].uiDelegate = self;
          [[GIDSignIn sharedInstance] signIn];
          // [END setup_gid_uidelegate]
        }];
      }
        break;
      case AuthPhone: {
        action = [UIAlertAction actionWithTitle:@"Phone"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          [self showTextInputPromptWithMessage:@"Phone Number:"
                               completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
             if (!userPressedOK || !userInput.length) {
               return;
             }

             [self showSpinner:^{
               // [START phone_auth]
               [[FIRPhoneAuthProvider provider] verifyPhoneNumber:userInput
                                                       UIDelegate:nil
                                                       completion:^(NSString * _Nullable verificationID, NSError * _Nullable error) {
                // [START_EXCLUDE silent]
                [self hideSpinner:^{
                // [END_EXCLUDE]
                 if (error) {
                   [self showMessagePrompt:error.localizedDescription];
                   return;
                 }
                 // Sign in using the verificationID and the code sent to the user
                 // [START_EXCLUDE]
                 [self showTextInputPromptWithMessage:@"Verification Code:"
                                      completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                   if (!userPressedOK || !userInput.length) {
                     return;
                   }

                   // [START get_phone_cred]
                   FIRAuthCredential *credential = [[FIRPhoneAuthProvider provider]
                       credentialWithVerificationID:verificationID
                                   verificationCode:userInput];
                   // [END get_phone_cred]
                   [self firebaseLoginWithCredential:credential];
                 }];
                }];
                // [END_EXCLUDE]
               }];
               // [END phone_auth]
             }];
           }];
        }];
      }
        break;
      case AuthAnonymous: {
        action = [UIAlertAction actionWithTitle:@"Anonymous"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          [self showSpinner:^{
            // [START firebase_auth_anonymous]
            [[FIRAuth auth]
             signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
               // [START_EXCLUDE]
               [self hideSpinner:^{
                 if (error) {
                   [self showMessagePrompt:error.localizedDescription];
                   return;
                 }
               }];
               // [END_EXCLUDE]
             }];
            // [END firebase_auth_anonymous]
          }];
        }];
        }
        break;
    }

    [picker addAction:action];
  }


  UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil];
  [picker addAction:cancel];

  [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)didTapSignIn:(id)sender {
  [self showAuthPicker:@[@(AuthEmail),
                         @(AuthAnonymous),
                         @(AuthGoogle),
                         @(AuthFacebook),
                         @(AuthTwitter),
                         @(AuthPhone),
                         @(AuthCustom),
                         @(AuthPasswordless)]];
}

- (IBAction)didTapLink:(id)sender {
  NSMutableArray *providers = [@[@(AuthGoogle),
                                 @(AuthFacebook),
                                 @(AuthTwitter),
                                 @(AuthPhone)] mutableCopy];

  // Remove any existing providers. Note that this is not a complete list of
  // providers, so always check the documentation for a complete reference:
  // https://firebase.google.com/docs/auth
  for (id<FIRUserInfo> userInfo in [FIRAuth auth].currentUser.providerData) {
    if ([userInfo.providerID isEqualToString:FIRFacebookAuthProviderID]) {
      [providers removeObject:@(AuthFacebook)];
    } else if ([userInfo.providerID isEqualToString:FIRGoogleAuthProviderID]) {
      [providers removeObject:@(AuthGoogle)];
    } else if ([userInfo.providerID isEqualToString:FIRTwitterAuthProviderID]) {
      [providers removeObject:@(AuthTwitter)];
    } else if ([userInfo.providerID isEqualToString:FIRPhoneAuthProviderID]) {
      [providers removeObject:@(AuthPhone)];
    }
  }
  [self showAuthPicker:providers];
}

- (IBAction)didTapSignOut:(id)sender {
  // [START signout]
  NSError *signOutError;
  BOOL status = [[FIRAuth auth] signOut:&signOutError];
  if (!status) {
    NSLog(@"Error signing out: %@", signOutError);
    return;
  }
  // [END signout]
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // [START auth_listener]
  self.handle = [[FIRAuth auth]
      addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        // [START_EXCLUDE]
        [self setTitleDisplay:user];
        [self.tableView reloadData];
        // [END_EXCLUDE]
      }];
  // [END auth_listener]
}

- (void)setTitleDisplay: (FIRUser *)user {
  if (user.displayName) {
    self.navigationItem.title = [NSString stringWithFormat:@"Welcome %@", user.displayName];
  } else {
    self.navigationItem.title = @"Authentication Example";
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  // [START remove_auth_listener]
  [[FIRAuth auth] removeAuthStateDidChangeListener:_handle];
  // [END remove_auth_listener]
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == kSectionSignIn) {
    return 1;
  } else if (section == kSectionUser || section == kSectionToken) {
    if ([FIRAuth auth].currentUser) {
      return 1;
    } else {
      return 0;
    }
  } else if (section == kSectionProviders) {
    return [[FIRAuth auth].currentUser.providerData count];
  }
  NSAssert(NO, @"Unexpected section");
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  if (indexPath.section == kSectionSignIn) {
    // [START current_user]
    if ([FIRAuth auth].currentUser) {
      // User is signed in.
      // [START_EXCLUDE]
      cell = [tableView dequeueReusableCellWithIdentifier:@"SignOut"];
      // [END_EXCLUDE]
    } else {
      // No user is signed in.
      // [START_EXCLUDE]
      cell = [tableView dequeueReusableCellWithIdentifier:@"SignIn"];
      // [END_EXCLUDE]
    }
    // [END current_user]
  } else if (indexPath.section == kSectionUser) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Profile"];
    // [START get_user_profile]
    FIRUser *user = [FIRAuth auth].currentUser;
    // [END get_user_profile]
    // [START user_profile]
    if (user) {
      // The user's ID, unique to the Firebase project.
      // Do NOT use this value to authenticate with your backend server,
      // if you have one. Use getTokenWithCompletion:completion: instead.
      NSString *uid = user.uid;
      NSString *email = user.email;
      NSURL *photoURL = user.photoURL;
      // [START_EXCLUDE]
      UILabel *emailLabel = [(UILabel *)cell viewWithTag:1];
      UILabel *userIDLabel = [(UILabel *)cell viewWithTag:2];
      UIImageView *profileImageView = [(UIImageView *)cell viewWithTag:3];
      emailLabel.text = email;
      userIDLabel.text = uid;

      static NSURL *lastPhotoURL = nil;
      lastPhotoURL = photoURL;  // to prevent earlier image overwrites later one.
      if (photoURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
          UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]];
          dispatch_async(dispatch_get_main_queue(), ^() {
            if (photoURL == lastPhotoURL) {
              profileImageView.image = image;
            }
          });
        });
      } else {
        profileImageView.image = [UIImage imageNamed:@"ic_account_circle"];
      }
      // [END_EXCLUDE]
    }
    // [END user_profile]
  } else if (indexPath.section == kSectionProviders) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Provider"];
    // [START provider_data]
    id<FIRUserInfo> userInfo = [FIRAuth auth].currentUser.providerData[indexPath.row];
    cell.textLabel.text = [userInfo providerID];
    // Provider-specific UID
    cell.detailTextLabel.text = [userInfo uid];
    // [END provider_data]
  } else if (indexPath.section == kSectionToken) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Token"];
    UIButton *requestEmailButton = [(UIButton *)cell viewWithTag:4];
    requestEmailButton.enabled = [FIRAuth auth].currentUser.email ? YES : NO;
  }
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  return @"Unlink";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
    editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == kSectionProviders) {
    return UITableViewCellEditingStyleDelete;
  }
  return UITableViewCellEditingStyleNone;
}

// Swipe to delete.
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSString *providerID = [[FIRAuth auth].currentUser.providerData[indexPath.row] providerID];
    [self showSpinner:^{
      // [START unlink_provider]
      [[FIRAuth auth].currentUser unlinkFromProvider:providerID
                                          completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
        // [START_EXCLUDE]
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self.tableView reloadData];
        }];
        // [END_EXCLUDE]
      }];
      // [END unlink_provider]
    }];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == kSectionUser) {
    return 200;
  }
  return 44;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 4;
}

- (IBAction)didTokenRefresh:(id)sender {
  FIRAuthTokenCallback action = ^(NSString *_Nullable token, NSError *_Nullable error) {
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

    // Log token refresh event to Analytics.
    [FIRAnalytics logEventWithName:@"tokenrefresh" parameters:nil];

    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:kTokenRefreshedAlertTitle
                                            message:token
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
  };
  // [START token_refresh]
  [[FIRAuth auth].currentUser getIDTokenForcingRefresh:YES completion:action];
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
      FIRUserProfileChangeRequest *changeRequest = [[FIRAuth auth].currentUser profileChangeRequest];
      changeRequest.displayName = userInput;
      [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        // [START_EXCLUDE]
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kSetDisplayNameTitle error:error];
          [self setTitleDisplay:[FIRAuth auth].currentUser];
        }];
        // [END_EXCLUDE]
      }];
      // [END profile_change]
    }];
  }];
}

/** @fn requestVerifyEmail
 @brief Requests a "verify email" email be sent.
 */
- (IBAction)didRequestVerifyEmail:(id)sender {
  [self showSpinner:^{
    // [START send_verification_email]
    [[FIRAuth auth].currentUser sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
      // [START_EXCLUDE]
      [self hideSpinner:^{
        if (error) {
          [self showMessagePrompt:error.localizedDescription];
          return;
        }

        [self showMessagePrompt:@"Sent"];
      }];
      // [END_EXCLUDE]
    }];
    // [END send_verification_email]
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
      [[FIRAuth auth].currentUser updateEmail:userInput completion:^(NSError *_Nullable error) {
        // [START_EXCLUDE]
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kChangeEmailText error:error];
        }];
        // [END_EXCLUDE]
      }];
      // [END change_email]
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
      [[FIRAuth auth].currentUser updatePassword:userInput completion:^(NSError *_Nullable error) {
        // [START_EXCLUDE]
        [self hideSpinner:^{
          [self showTypicalUIForUserUpdateResultsWithTitle:kChangePasswordText error:error];
        }];
      // [END_EXCLUDE]
      }];
    // [END change_password]
    }];
  }];
}

/** @fn updatePhoneNumber
 @brief Updates the phone number of the current user.
 */
- (IBAction)didUpdatePhoneNumber:(id)sender {
  [self showTextInputPromptWithMessage:@"New Phone Number:"
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
    if (!userPressedOK || !userInput.length) {
      return;
    }

    [self showSpinner:^{
      // [START update_phone]
      [[FIRPhoneAuthProvider provider] verifyPhoneNumber:userInput
                                              UIDelegate:nil
                                              completion:^(NSString * _Nullable verificationID,
                                                           NSError * _Nullable error) {
        // [START_EXCLUDE]
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self showTextInputPromptWithMessage:@"Verification Code:"
                               completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
            if (!userPressedOK || !userInput.length) {
              return;
            }

            [self showSpinner:^{
              // [END_EXCLUDE]
              FIRPhoneAuthCredential *credential = [[FIRPhoneAuthProvider provider]
                  credentialWithVerificationID:verificationID
                              verificationCode:userInput];
              [[FIRAuth auth].currentUser updatePhoneNumberCredential:credential
                                                           completion:^(NSError * _Nullable error) {
                // [END update_phone]
                [self hideSpinner:^{
                  [self showTypicalUIForUserUpdateResultsWithTitle:kUpdatePhoneNumberText
                                                             error:error];
                }];
              }];
            }];
          }];
        }];
      }];
    }];
  }];
}

/** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
 @brief Shows a @c UIAlertView if error is non-nil with the localized description of the error.
 @param resultsTitle The title of the @c UIAlertView
 @param error The error details to display if non-nil.
 */
- (void)showTypicalUIForUserUpdateResultsWithTitle:(NSString *)resultsTitle error:(NSError *)error {
  if (error) {
    NSString *message = [NSString stringWithFormat:@"%@ (%ld)\n%@", error.domain, (long)error.code,
                         error.localizedDescription];
    if ([UIAlertController class]) {
      UIAlertAction *okAction = [UIAlertAction actionWithTitle:kOKButtonText
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                         NSLog(@"OK");
                                                       }];

      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:resultsTitle
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:okAction];
      [self presentViewController:alertController
                                                   animated:YES
                                                 completion:nil];
    } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:resultsTitle
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:kOKButtonText, nil];
      [alert show];
      return;
    }
  }
  [self.tableView reloadData];
}

@end
