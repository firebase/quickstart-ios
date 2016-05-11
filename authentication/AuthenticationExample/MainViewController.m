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
@import Firebase;
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
  AuthCustom
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
         }];
         // [END_EXCLUDE]
       }];
      // [END link_credential]
    } else {
      // [START signin_credential]
      [[FIRAuth auth] signInWithCredential:credential
                                completion:^(FIRUser *user, NSError *error) {
                                  // [START_EXCLUDE]
                                  [self hideSpinner:^{
                                    if (error) {
                                      [self showMessagePrompt:error.localizedDescription];
                                      return;
                                    }
                                  }];
                                  // [END_EXCLUDE]
                                }];
      // [END signin_credential]
    }
  }];
}

- (void)showAuthPicker: (NSArray<NSNumber *>*) providers {
  UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"Select Provider"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

  for (NSNumber *provider in providers) {
    UIAlertAction *action;
    switch (provider.unsignedIntegerValue) {
      case AuthEmail:
      {
        action = [UIAlertAction actionWithTitle:@"Email" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          [self performSegueWithIdentifier:@"email" sender:nil];
        }];
      }
        break;
      case AuthCustom:
      {
        action = [UIAlertAction actionWithTitle:@"Custom" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          [self performSegueWithIdentifier:@"customToken" sender:nil];
        }];
      }
        break;
      case AuthTwitter:
      {
        action = [UIAlertAction actionWithTitle:@"Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
        action = [UIAlertAction actionWithTitle:@"Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
          [loginManager
           logInWithReadPermissions:@[ @"public_profile", @"email" ]
           fromViewController:self
           handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
             if (error) {
               [self showMessagePrompt:error.localizedDescription];
             } else if (result.isCancelled) {
               NSLog(@"FBLogin cancelled");
             } else {
               // [START headless_facebook_auth]
               FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                                credentialWithAccessToken:[FBSDKAccessToken currentAccessToken]
                                                .tokenString];
               // [END headless_facebook_auth]
               [self firebaseLoginWithCredential:credential];
             }
           }];

        }];
      }
        break;
      case AuthGoogle: {
        action = [UIAlertAction actionWithTitle:@"Google" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          [GIDSignIn sharedInstance].clientID = [FIRApp defaultApp].options.clientID;
          [GIDSignIn sharedInstance].uiDelegate = self;
          [GIDSignIn sharedInstance].delegate = self;
          [[GIDSignIn sharedInstance] signIn];

        }];
      }
        break;
      case AuthAnonymous: {
        action = [UIAlertAction actionWithTitle:@"Anonymous" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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


  UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  [picker addAction:cancel];

  [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)didTapSignIn:(id)sender {
  [self showAuthPicker:@[@(AuthEmail),
                         @(AuthAnonymous),
                         @(AuthGoogle),
                         @(AuthFacebook),
                         @(AuthTwitter),
                         @(AuthCustom)]];
}

- (IBAction)didTapLink:(id)sender {
  NSMutableArray *providers = [@[@(AuthEmail),
                                @(AuthGoogle),
                                @(AuthFacebook),
                                @(AuthTwitter)] mutableCopy];

  // Remove any existing providers. Note that this is not a complete list of
  // providers, so always check the documentation for a complete reference:
  // https://firebase.google.com/docs/auth
  for (id<FIRUserInfo> userInfo in [FIRAuth auth].currentUser.providerData) {
    if ([userInfo.providerID isEqualToString:FIREmailPasswordAuthProviderID]) {
        [providers removeObject:@(AuthEmail)];
    } else if ([userInfo.providerID isEqualToString:FIRFacebookAuthProviderID]) {
      [providers removeObject:@(AuthFacebook)];
    } else if ([userInfo.providerID isEqualToString:FIRGoogleAuthProviderID]) {
      [providers removeObject:@(AuthGoogle)];
    } else if ([userInfo.providerID isEqualToString:FIRTwitterAuthProviderID]) {
      [providers removeObject:@(AuthTwitter)];
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

// [START headless_google_auth]
- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
  if (error == nil) {
    GIDAuthentication *authentication = user.authentication;
    FIRAuthCredential *credential =
    [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken
                                     accessToken:authentication.accessToken];
    // [START_EXCLUDE]
    [self firebaseLoginWithCredential:credential];
    // [END_EXCLUDE]
  } else
    // [START_EXCLUDE]
    [self showMessagePrompt:error.localizedDescription];
  // [END_EXCLUDE]
}
// [END headless_google_auth]

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.handle = [[FIRAuth auth]
      addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        [self setTitleDisplay:user];
        [self.tableView reloadData];
      }];
}

- (void)setTitleDisplay: (FIRUser *)user {
  if (user) {
    self.navigationItem.title = [NSString stringWithFormat:@"Welcome %@", user.displayName];
  } else {
    self.navigationItem.title = @"Authentication Example";
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[FIRAuth auth] removeAuthStateDidChangeListener:_handle];
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
    if ([FIRAuth auth].currentUser) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"SignOut"];
    } else {
      cell = [tableView dequeueReusableCellWithIdentifier:@"SignIn"];
    }
  } else if (indexPath.section == kSectionUser) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Profile"];
    FIRUser *user = [FIRAuth auth].currentUser;
    UILabel *emailLabel = [(UILabel *)cell viewWithTag:1];
    UILabel *userIDLabel = [(UILabel *)cell viewWithTag:2];
    UIImageView *profileImageView = [(UIImageView *)cell viewWithTag:3];
    emailLabel.text = user.email;
    userIDLabel.text = user.uid;

    NSURL *photoURL = user.photoURL;
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
  } else if (indexPath.section == kSectionProviders) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Provider"];
    id<FIRUserInfo> userInfo = [FIRAuth auth].currentUser.providerData[indexPath.row];
    cell.textLabel.text = [userInfo providerID];
    cell.detailTextLabel.text = [userInfo uid];
  } else if (indexPath.section == kSectionToken) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Token"];
  }
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  return @"Unlink";
}

// Swipe to delete.
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSString *providerID = [[FIRAuth auth].currentUser.providerData[indexPath.row] providerID];
    [self showSpinner:^{
      // [START unlink_provider]
      [[FIRAuth auth]
              .currentUser unlinkFromProvider:providerID
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
  [[FIRAuth auth].currentUser getTokenForcingRefresh:YES completion:action];
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
                           [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
                             // [START_EXCLUDE]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kSetDisplayNameTitle
                                                                          error:error];
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
    [[FIRAuth auth]
            .currentUser sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
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
                           [[FIRAuth auth]
                                   .currentUser
                               updateEmail:userInput
                                completion:^(NSError *_Nullable error) {
                                  // [START_EXCLUDE]
                                  [self hideSpinner:^{
                                    [self
                                        showTypicalUIForUserUpdateResultsWithTitle:kChangeEmailText
                                                                             error:error];

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
                           [[FIRAuth auth]
                                   .currentUser
                               updatePassword:userInput
                                   completion:^(NSError *_Nullable error) {
                                     // [START_EXCLUDE]
                                     [self hideSpinner:^{
                                       [self showTypicalUIForUserUpdateResultsWithTitle:
                                                 kChangePasswordText
                                                                                  error:error];
                                     }];
                                     // [END_EXCLUDE]
                                   }];
                           // [END change_password]
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:resultsTitle
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:kOKButtonText, nil];
    [alert show];
    return;
  }
  [self.tableView reloadData];
}

@end
