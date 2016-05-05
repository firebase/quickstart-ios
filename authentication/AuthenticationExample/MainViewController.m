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
@property (strong, nonatomic) FIRAuthStateDidChangeListenerHandle handle;
@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) UIPickerView *providerPickerView;
@property (strong, nonatomic) UIToolbar *providerToolbar;
@property (nonatomic) long selectedRow;
@property (strong, nonatomic) NSArray<NSString *> *pickerData;
@end

@implementation MainViewController

- (void) createPickerView {
  _selectedRow = 0;
  _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
  [_maskView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];

  [self.view addSubview:_maskView];
  _providerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 344, self.view.bounds.size.width, 44)];

  UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissActionSheet:)];
  _providerToolbar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], done];
  _providerToolbar.barStyle = UIBarStyleBlackOpaque;
  [self.view addSubview:_providerToolbar];

  _providerPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 300, 0, 0)];
  _providerPickerView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
  _providerPickerView.showsSelectionIndicator = YES;
  _providerPickerView.dataSource = self;
  _providerPickerView.delegate = self;

  [self.view addSubview:_providerPickerView];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
  return _pickerData.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
  return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return _pickerData[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  _selectedRow = row;
}

- (IBAction)didTapSignIn:(id)sender {
  self.pickerData = @[@"Email", FIRFacebookAuthProviderID, FIRGoogleAuthProviderID, FIRTwitterAuthProviderID, @"Guest", @"CustomToken"];
  [self createPickerView];
}

- (IBAction)didTapLink:(id)sender {
  NSMutableArray *pickerData = [@[FIRFacebookAuthProviderID, FIRGoogleAuthProviderID, FIRTwitterAuthProviderID] mutableCopy];
  for (id<FIRUserInfo> userInfo in [FIRAuth auth].currentUser.providerData) {
    [pickerData removeObject:userInfo.providerID];
  }
  self.pickerData = pickerData;
  [self createPickerView];
}

- (void)dismissActionSheet:(id)sender {
  [_maskView removeFromSuperview];
  [_providerPickerView removeFromSuperview];
  [_providerToolbar removeFromSuperview];
  NSString *selectedProvider = _pickerData[_selectedRow];
  if ([selectedProvider isEqualToString:@"Email"]) {
    [self performSegueWithIdentifier:@"email" sender:nil];
  } else if ([selectedProvider isEqualToString:FIRFacebookAuthProviderID]) {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"public_profile", @"email"]
                        fromViewController:self
                                   handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                     if (error) {
                                       [self showMessagePrompt:error.localizedDescription];
                                     } else if (result.isCancelled) {
                                       NSLog(@"FBLogin cancelled");
                                     } else {
                                       // [START headless_facebook_auth]
                                       FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                                                        credentialWithAccessToken: [FBSDKAccessToken currentAccessToken].tokenString];
                                       // [END headless_facebook_auth]
                                       [self firebaseLoginWithCredential:credential];
                                     }
                                   }];
  } else if ([selectedProvider isEqualToString:FIRGoogleAuthProviderID]) {
    [GIDSignIn sharedInstance].clientID = [FIRApp defaultApp].options.clientID;
    [GIDSignIn sharedInstance].uiDelegate = self;
    [GIDSignIn sharedInstance].delegate = self;
    [[GIDSignIn sharedInstance] signIn];
  } else if ([selectedProvider isEqualToString:FIRTwitterAuthProviderID]) {
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession* session, NSError* error) {
      if (session) {
        // [START headless_twitter_auth]
        FIRAuthCredential *credential = [FIRTwitterAuthProvider credentialWithToken:session.authToken secret:session.authTokenSecret];
        // [END headless_twitter_auth]
        [self firebaseLoginWithCredential:credential];
      } else {
        [self showMessagePrompt:error.localizedDescription];
      }
    }];
  } else if ([selectedProvider isEqualToString:@"CustomToken"]) {
    [self performSegueWithIdentifier:@"customToken" sender:nil];
  } else if ([selectedProvider isEqualToString:@"Guest"]) {
    [self showSpinner:^{
      // [START firebase_auth_anonymous]
      [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user,
                                                        NSError *_Nullable error) {
        // [END firebase_auth_anonymous]
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
        }];
      }];
    }];
  }
}

- (void)firebaseLoginWithCredential:(FIRAuthCredential *)credential {
  [self showSpinner:^{
    if ([FIRAuth auth].currentUser) {
      // [START link_credential]
      [[FIRAuth auth].currentUser linkWithCredential:credential completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        // [END link_credential]
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
        }];
      }];
    } else {
      // [START signin_credential]
      [[FIRAuth auth] signInWithCredential:credential
                                completion:^(FIRUser *user, NSError *error) {
                                  // [END signin_credential]
                                  [self hideSpinner:^{
                                    if (error) {
                                      [self showMessagePrompt:error.localizedDescription];
                                      return;
                                    }
                                  }];
                                }];
    }
  }];
}

// [START headless_google_auth]
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
  if (error == nil) {
    GIDAuthentication *authentication = user.authentication;
    FIRAuthCredential *credential =
    [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken accessToken:authentication.accessToken];
    // [END headless_google_auth]
    [self firebaseLoginWithCredential:credential];
  } else
    [self showMessagePrompt:error.localizedDescription];
}

- (IBAction)didTapSignOut:(id)sender {
  // [START signout]
  NSError *signOutError;
  BOOL status = [[FIRAuth auth] signOut:&signOutError];
  if (!status) {
    NSLog(@"Error signing out: %@", signOutError);
    return;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.handle =[[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth * _Nonnull auth, FIRUser * _Nullable user) {
    if (user) {
      self.navigationItem.title = user.displayName;
    } else {
      self.navigationItem.title = @"Sign In";
    }
    [self.tableView reloadData];
  }];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  if (indexPath.section == kSectionSignIn) {
    if ([FIRAuth auth].currentUser) {
      cell = [tableView dequeueReusableCellWithIdentifier:@"SignOut"];
    } else {
      cell =[tableView dequeueReusableCellWithIdentifier:@"SignIn"];
    }
  } else if (indexPath.section == kSectionUser) {
    cell =[tableView dequeueReusableCellWithIdentifier:@"Profile"];
    FIRUser *user = [FIRAuth auth].currentUser;
    UILabel *emailLabel = [(UILabel *) cell viewWithTag:1];
    UILabel *userIDLabel = [(UILabel *) cell viewWithTag:2];
    UIImageView *profileImageView = [(UIImageView *) cell viewWithTag:3];
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
    cell =[tableView dequeueReusableCellWithIdentifier:@"Provider"];
    id<FIRUserInfo> userInfo = [FIRAuth auth].currentUser.providerData[indexPath.row];
    cell.textLabel.text = [userInfo providerID];
    cell.detailTextLabel.text = [userInfo uid];
  } else if (indexPath.section == kSectionToken) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"Token"];
  }
  return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return @"Unlink";
}

// Swipe to delete.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSString *providerID = [[FIRAuth auth].currentUser.providerData[indexPath.row] providerID];
    [self showSpinner:^{
      // [START unlink_provider]
      [[FIRAuth auth].currentUser unlinkFromProvider:providerID completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        // [END unlink_provider]
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }
          [self.tableView reloadData];
        }];
      }];
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

    // Log token refresh event to Analytics.
    [FIRAnalytics logEventWithName:@"tokenrefresh" parameters: nil];

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
                             // [END profile_change]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kSetDisplayNameTitle error:error];
                               self.navigationItem.title = [FIRAuth auth].currentUser.displayName;
                             }];
                           }];
                         }];
                       }];
}

/** @fn requestVerifyEmail
 @brief Requests a "verify email" email be sent.
 */
- (IBAction)didRequestVerifyEmail:(id)sender {
  [self showSpinner:^{
    // [START send_verification_email]
    [[FIRAuth auth].currentUser sendEmailVerificationWithCompletion:^(NSError * _Nullable error) {
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
                           [[FIRAuth auth].currentUser updateEmail:userInput completion:^(NSError *_Nullable error) {
                             // [END change_email]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kChangeEmailText error:error];

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
                           [[FIRAuth auth].currentUser updatePassword:userInput completion:^(NSError *_Nullable error) {
                             // [END change_password]
                             [self hideSpinner:^{
                               [self showTypicalUIForUserUpdateResultsWithTitle:kChangePasswordText error:error];
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
  [self.tableView reloadData];
}

@end
