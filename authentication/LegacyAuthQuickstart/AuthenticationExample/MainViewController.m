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

#import <CommonCrypto/CommonDigest.h>
#import <GameKit/GameKit.h>

@import AuthenticationServices;
@import FBSDKCoreKit;
@import FBSDKLoginKit;

static const int kSectionMultiFactor = 4;
static const int kSectionToken = 3;
static const int kSectionProviders = 2;
static const int kSectionUser = 1;
static const int kSectionSignIn = 0;

typedef enum : NSUInteger {
  AuthEmail,
  AuthAnonymous,
  AuthApple,
  AuthFacebook,
  AuthGoogle,
  AuthTwitter,
  AuthGitHub,
  AuthCustom,
  AuthPhone,
  AuthPasswordless,
  AuthGameCenter,
  AuthMicrosoft,
  AuthEmailMFA,
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

static BOOL isMFAEnabled = NO;

@interface MainViewController ()
@property(strong, nonatomic) FIRAuthStateDidChangeListenerHandle handle;
@property(strong, nonatomic) FIROAuthProvider *microsoftProvider;
@property(strong, nonatomic) FIROAuthProvider *twitterProvider;
@property(strong, nonatomic) FIROAuthProvider *gitHubProvider;
@end

@interface MainViewController (SignInWithApple) <ASAuthorizationControllerDelegate,
                                                 ASAuthorizationControllerPresentationContextProviding>

@property(nonatomic, readwrite, nullable) NSString *currentNonce;

- (void)startSignInWithAppleFlow API_AVAILABLE(ios(13.0));

- (void)startSignInWithGoogleFlow;

@end

@implementation MainViewController {
  NSString *_currentNonce;
}

- (void)firebaseLoginWithCredential:(FIRAuthCredential *)credential {
  [self showSpinner:^{
    if ([FIRAuth auth].currentUser) {
      // [START link_credential]
      [[FIRAuth auth].currentUser linkWithCredential:credential
          completion:^(FIRAuthDataResult *result, NSError *_Nullable error) {
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
                                completion:^(FIRAuthDataResult * _Nullable authResult,
                                             NSError * _Nullable error) {
        // [START_EXCLUDE silent]
        [self hideSpinner:^{
        // [END_EXCLUDE]
          if (isMFAEnabled && error && error.code == FIRAuthErrorCodeSecondFactorRequired) {
            FIRMultiFactorResolver *resolver = error.userInfo[FIRAuthErrorUserInfoMultiFactorResolverKey];
            NSMutableString *displayNameString = [NSMutableString string];
            for (FIRMultiFactorInfo *tmpFactorInfo in resolver.hints) {
              [displayNameString appendString:tmpFactorInfo.displayName];
              [displayNameString appendString:@" "];
            }
            [self showTextInputPromptWithMessage:[NSString stringWithFormat:@"Select factor to sign in\n%@", displayNameString]
                                 completionBlock:^(BOOL userPressedOK, NSString *_Nullable displayName) {
             FIRPhoneMultiFactorInfo* selectedHint;
             for (FIRMultiFactorInfo *tmpFactorInfo in resolver.hints) {
               if ([displayName isEqualToString:tmpFactorInfo.displayName]) {
                 selectedHint = (FIRPhoneMultiFactorInfo *)tmpFactorInfo;
               }
             }
             [FIRPhoneAuthProvider.provider
              verifyPhoneNumberWithMultiFactorInfo:selectedHint
              UIDelegate:nil
              multiFactorSession:resolver.session
              completion:^(NSString * _Nullable verificationID, NSError * _Nullable error) {
                if (error) {
                  [self showMessagePrompt:error.localizedDescription];
                } else {
                  [self showTextInputPromptWithMessage:[NSString stringWithFormat:@"Verification code for %@", selectedHint.displayName]
                                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable verificationCode) {
                   FIRPhoneAuthCredential *credential =
                       [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID
                                                                    verificationCode:verificationCode];
                   FIRMultiFactorAssertion *assertion = [FIRPhoneMultiFactorGenerator assertionWithCredential:credential];
                   [resolver resolveSignInWithAssertion:assertion completion:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable error) {
                     if (error) {
                       [self showMessagePrompt:error.localizedDescription];
                     } else {
                       NSLog(@"Multi factor finanlize sign in succeeded.");
                     }
                   }];
                 }];
                }
              }];
           }];
          }
        else if (error) {
          // [START_EXCLUDE]
          [self showMessagePrompt:error.localizedDescription];
          // [END_EXCLUDE]
          return;
        }
        // User successfully signed in. Get user data from the FIRUser object
        if (authResult == nil) { return; }
        FIRUser *user = authResult.user;
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
      case AuthEmailMFA:
      {
        action = [UIAlertAction actionWithTitle:@"Email with MFA"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          isMFAEnabled = YES;
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
      case AuthApple:
      {
        if (@available(iOS 13, *)) {
          action = [UIAlertAction actionWithTitle:@"Apple"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
            [self startSignInWithAppleFlow];
          }];
        } else {
          continue;
        }
      }
        break;
      case AuthTwitter:
      {
        action = [UIAlertAction actionWithTitle:@"Twitter"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
            // [START firebase_auth_twitter]
            [self.twitterProvider getCredentialWithUIDelegate:nil
                completion:^(FIRAuthCredential *_Nullable credential, NSError *_Nullable error) {
              [self showSpinner:^{
                 if (error) {
                   [self hideSpinner:^{
                     [self showMessagePrompt:error.localizedDescription];
                     return;
                   }];
                 }
                if (credential) {
                  [[FIRAuth auth] signInWithCredential:credential
                                            completion:^(FIRAuthDataResult *_Nullable authResult,
                                                         NSError *_Nullable error) {
                    [self hideSpinner:^{
                      if (error) {
                        [self showMessagePrompt:error.localizedDescription];
                        return;
                      }
                    }];
                  }];
                }
              }];
            }];
            // [END firebase_auth_twitter]
         }];
      }
        break;
      case AuthGitHub:
      {
        action = [UIAlertAction actionWithTitle:@"GitHub"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
            // [START firebase_auth_github]
            [self.gitHubProvider getCredentialWithUIDelegate:nil
                completion:^(FIRAuthCredential *_Nullable credential, NSError *_Nullable error) {
              [self showSpinner:^{
                 if (error) {
                   [self hideSpinner:^{
                     [self showMessagePrompt:error.localizedDescription];
                     return;
                   }];
                 }
                if (credential) {
                  [[FIRAuth auth] signInWithCredential:credential
                                            completion:^(FIRAuthDataResult *_Nullable authResult,
                                                         NSError *_Nullable error) {
                    [self hideSpinner:^{
                      if (error) {
                        [self showMessagePrompt:error.localizedDescription];
                        return;
                      }
                    }];
                  }];
                }
              }];
            }];
            // [END firebase_auth_github]
         }];
      }
        break;
      case AuthFacebook: {
        action = [UIAlertAction actionWithTitle:@"Facebook"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
          FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
          [loginManager logInWithPermissions:@[ @"public_profile", @"email" ]
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
          [self startSignInWithGoogleFlow];
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
            [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRAuthDataResult * _Nullable authResult,
                                                              NSError * _Nullable error) {
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
      case AuthGameCenter: {
        action = [UIAlertAction actionWithTitle:@"Game Center"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
            // [START firebase_auth_gamecenter]
            [FIRGameCenterAuthProvider
             getCredentialWithCompletion:^(FIRAuthCredential * _Nullable credential,
                                           NSError * _Nullable error) {
               [self showSpinner:^{
                 if (error) {
                   [self hideSpinner:^{
                     [self showMessagePrompt:error.localizedDescription];
                     return;
                   }];
                 }
                 if (credential) {
                   [[FIRAuth auth] signInWithCredential:credential
                                             completion:^(FIRAuthDataResult * _Nullable authResult,
                                                          NSError * _Nullable error) {
                     [self hideSpinner:^{
                       if (error) {
                         [self showMessagePrompt:error.localizedDescription];
                         return;
                       }
                     }];
                   }];
                 }
               }];
             }];
            // [END firebase_auth_gamecenter]
          }];
        };
        break;
      case AuthMicrosoft: {
        action = [UIAlertAction actionWithTitle:@"Microsoft"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
            // [START firebase_auth_microsoft]
            [self.microsoftProvider getCredentialWithUIDelegate:nil
                completion:^(FIRAuthCredential *_Nullable credential, NSError *_Nullable error) {
              [self showSpinner:^{
                 if (error) {
                   [self hideSpinner:^{
                     [self showMessagePrompt:error.localizedDescription];
                     return;
                   }];
                 }
                if (credential) {
                  [[FIRAuth auth] signInWithCredential:credential
                                            completion:^(FIRAuthDataResult *_Nullable authResult,
                                                         NSError *_Nullable error) {
                    [self hideSpinner:^{
                      if (error) {
                        [self showMessagePrompt:error.localizedDescription];
                        return;
                      }
                    }];
                  }];
                }
              }];
            }];
            // [END firebase_auth_microsoft]
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
                         @(AuthEmailMFA),
                         @(AuthAnonymous),
                         @(AuthApple),
                         @(AuthGoogle),
                         @(AuthFacebook),
                         @(AuthTwitter),
                         @(AuthGitHub),
                         @(AuthPhone),
                         @(AuthCustom),
                         @(AuthPasswordless),
                         @(AuthGameCenter),
                         @(AuthMicrosoft)]];
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

- (void)authenticateGameCenterLocalPlayer {
  __weak GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
  localPlayer.authenticateHandler = ^(UIViewController *gcAuthViewController,
                                      NSError *error) {
    if (gcAuthViewController != nil) {
      // Pause any activities that require user interaction, then present the
      // gcAuthViewController to the player.
      [self presentViewController:gcAuthViewController animated:YES completion:nil];
    } else if (localPlayer.isAuthenticated) {
      // Local player is logged in to Game Center.
    } else {
      // Error
      if (error) {
        [self showMessagePrompt:error.localizedDescription];
        return;
      }
    }
  };
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

  self.microsoftProvider = [FIROAuthProvider providerWithProviderID:@"microsoft.com"];
  self.twitterProvider = [FIROAuthProvider providerWithProviderID:@"twitter.com"];
  self.gitHubProvider = [FIROAuthProvider providerWithProviderID:@"github.com"];

  // Authenticate Game Center Local Player
  // Uncomment to sign in with Game Center
  // [self authenticateGameCenterLocalPlayer];
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
  } else if (section == kSectionUser || section == kSectionToken || section == kSectionMultiFactor) {
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
      NSString *email = user.email;
      NSString *uid = user.uid;
      NSMutableString *multiFactorString = [NSMutableString stringWithFormat:@"MultiFactor: "];
      for (FIRMultiFactorInfo *info in user.multiFactor.enrolledFactors) {
        [multiFactorString appendString:info.displayName];
        [multiFactorString appendString:@" "];
      }
      NSURL *photoURL = user.photoURL;
      // [START_EXCLUDE]
      UILabel *emailLabel = [(UILabel *)cell viewWithTag:1];
      UILabel *userIDLabel = [(UILabel *)cell viewWithTag:2];
      UIImageView *profileImageView = [(UIImageView *)cell viewWithTag:3];
      UILabel *multiFactorLabel = [(UILabel *)cell viewWithTag:4];
      emailLabel.text = email;
      userIDLabel.text = uid;
      multiFactorLabel.text = multiFactorString;
      if (isMFAEnabled) {
        multiFactorLabel.hidden = NO;
      } else {
        multiFactorLabel.hidden = YES;
      }
      
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
  } else if (indexPath.section == kSectionMultiFactor) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"MultiFactor"];
  } else {
    [NSException raise:NSInternalInconsistencyException format:@"Unexpected state"];
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
  if (isMFAEnabled) {
    return 5;
  } else {
    return 4;
  }
}

- (IBAction)didMultiFactorEnroll:(id)sender {
  FIRUser *user = FIRAuth.auth.currentUser;
  if (!user) {
    NSLog(@"Please sign in first.");
  } else {
    [self showTextInputPromptWithMessage:@"Phone Number"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable phoneNumber) {
     [user.multiFactor
      getSessionWithCompletion:^(FIRMultiFactorSession *_Nullable session, NSError *_Nullable error) {
        [FIRPhoneAuthProvider.provider verifyPhoneNumber:phoneNumber
                                              UIDelegate:nil
                                      multiFactorSession:session
                                              completion:^(NSString * _Nullable verificationID,
                                                           NSError * _Nullable error) {
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
          } else {
            [self showTextInputPromptWithMessage:@"Verification code"
                                 completionBlock:^(BOOL userPressedOK,
                                                   NSString *_Nullable verificationCode) {
             FIRPhoneAuthCredential *credential =
             [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID
                                                          verificationCode:verificationCode];
             FIRMultiFactorAssertion *assertion =
             [FIRPhoneMultiFactorGenerator assertionWithCredential:credential];
             [self showTextInputPromptWithMessage:@"Display name"
                                  completionBlock:^(BOOL userPressedOK,
                                                    NSString *_Nullable displayName) {
              [user.multiFactor enrollWithAssertion:assertion
                                        displayName:displayName
                                         completion:^(NSError *_Nullable error) {
               if (error) {
                 [self showMessagePrompt:error.localizedDescription];
               } else {
                 NSLog(@"Multi factor finanlize enroll succeeded.");
                 [self showTypicalUIForUserUpdateResultsWithTitle:@"Multi Factor" error:error];
               }
             }];
            }];
           }];
          }
        }];
      }];
   }];
  }
}

- (IBAction)didMultiFactorUnenroll:(id)sender {
  NSMutableString *displayNameString = [NSMutableString string];
  for (FIRMultiFactorInfo *tmpFactorInfo in FIRAuth.auth.currentUser.multiFactor.enrolledFactors) {
    [displayNameString appendString:tmpFactorInfo.displayName];
    [displayNameString appendString:@" "];
  }
  [self showTextInputPromptWithMessage:[NSString stringWithFormat:@"Multifactor Unenroll\n%@", displayNameString]
                       completionBlock:^(BOOL userPressedOK, NSString *_Nullable displayName) {
   FIRMultiFactorInfo *factorInfo;
   for (FIRMultiFactorInfo *tmpFactorInfo in FIRAuth.auth.currentUser.multiFactor.enrolledFactors) {
     if ([displayName isEqualToString:tmpFactorInfo.displayName]) {
       factorInfo = tmpFactorInfo;
     }
   }
   [FIRAuth.auth.currentUser.multiFactor unenrollWithInfo:factorInfo
                                               completion:^(NSError * _Nullable error) {
     if (error) {
       [self showMessagePrompt:error.localizedDescription];
     } else {
       NSLog(@"Multi factor finanlize unenroll succeeded.");
       [self showTypicalUIForUserUpdateResultsWithTitle:@"Multi Factor" error:error];
     }
   }];
 }];
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

#pragma mark - Sign in with Apple

@implementation MainViewController (SignInWithApple)

- (void)startSignInWithAppleFlow {
  NSString *nonce = [self randomNonce:32];
  self.currentNonce = nonce;
  ASAuthorizationAppleIDProvider *appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
  ASAuthorizationAppleIDRequest *request = [appleIDProvider createRequest];
  request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
  request.nonce = [self stringBySha256HashingString:nonce];

  ASAuthorizationController *authorizationController =
      [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
  authorizationController.delegate = self;
  authorizationController.presentationContextProvider = self;
  [authorizationController performRequests];
}

- (NSString *)randomNonce:(NSInteger)length {
  NSAssert(length > 0, @"Expected nonce to have positive length");
  NSString *characterSet = @"0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._";
  NSMutableString *result = [NSMutableString string];
  NSInteger remainingLength = length;

  while (remainingLength > 0) {
    NSMutableArray *randoms = [NSMutableArray arrayWithCapacity:16];
    for (NSInteger i = 0; i < 16; i++) {
      uint8_t random = 0;
      int errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random);
      NSAssert(errorCode == errSecSuccess, @"Unable to generate nonce: OSStatus %i", errorCode);

      [randoms addObject:@(random)];
    }

    for (NSNumber *random in randoms) {
      if (remainingLength == 0) {
        break;
      }

      if (random.unsignedIntValue < characterSet.length) {
        unichar character = [characterSet characterAtIndex:random.unsignedIntValue];
        [result appendFormat:@"%C", character];
        remainingLength--;
      }
    }
  }

  return [result copy];
}

- (NSString *)stringBySha256HashingString:(NSString *)input {
  const char *string = [input UTF8String];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(string, (CC_LONG)strlen(string), result);

  NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (NSInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    [hashed appendFormat:@"%02x", result[i]];
  }
  return hashed;
}

- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization API_AVAILABLE(ios(13.0)) {
  if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
    ASAuthorizationAppleIDCredential *appleIDCredential = authorization.credential;
    NSString *rawNonce = self.currentNonce;
    NSAssert(rawNonce != nil, @"Invalid state: A login callback was received, but no login request was sent.");

    if (appleIDCredential.identityToken == nil) {
      NSLog(@"Unable to fetch identity token.");
      return;
    }

    NSString *idToken = [[NSString alloc] initWithData:appleIDCredential.identityToken
                                              encoding:NSUTF8StringEncoding];
    if (idToken == nil) {
      NSLog(@"Unable to serialize id token from data: %@", appleIDCredential.identityToken);
    }

    // Initialize a Firebase credential.
    FIROAuthCredential *credential = [FIROAuthProvider credentialWithProviderID:@"apple.com"
                                                                        IDToken:idToken
                                                                       rawNonce:rawNonce];

    // Sign in with Firebase.
    [self firebaseLoginWithCredential:credential];
  }
}

- (void)authorizationController:(ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
  NSLog(@"Sign in with Apple errored: %@", error);
}

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller API_AVAILABLE(ios(13.0)) {
  return self.view.window;
}

- (void)setCurrentNonce:(NSString *)currentNonce {
  _currentNonce = [currentNonce copy];
}

- (NSString *)currentNonce {
  return [_currentNonce copy];
}

#pragma mark - Sign in with Google

- (void)startSignInWithGoogleFlow {
  // [START headless_google_auth]
  GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:[FIRApp defaultApp].options.clientID];

  __weak __auto_type weakSelf = self;
  [GIDSignIn.sharedInstance signInWithConfiguration:config presentingViewController:self callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
    __auto_type strongSelf = weakSelf;
    if (strongSelf == nil) { return; }

    if (error == nil) {
      // [START google_credential]
      GIDAuthentication *authentication = user.authentication;
      FIRAuthCredential *credential =
      [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken
                                       accessToken:authentication.accessToken];
      // [END google_credential]
      // [START_EXCLUDE]
      [strongSelf firebaseLoginWithCredential:credential];
      // [END_EXCLUDE]
    } else {
      // [START_EXCLUDE]
      [strongSelf showMessagePrompt:error.localizedDescription];
      // [END_EXCLUDE]
    }
  }];

  // [END headless_google_auth]
}

@end
