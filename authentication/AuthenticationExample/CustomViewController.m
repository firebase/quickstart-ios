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

#import "CustomViewController.h"
#import "UIViewController+Alerts.h"

// [START usermanagement_view_import]
@import FirebaseAuth;
@import Firebase.Core;
// [END usermanagement_view_import]


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


@interface CustomViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextView *tokenField;
@end
@implementation CustomViewController

- (IBAction)didTapEmailLogin:(id)sender {
  // [START headless_email_auth]
  [[FIRAuth auth] signInWithEmail:_emailField.text
                         password:_passwordField.text
                         callback:^(FIRUser *user, NSError *error) {
                           // [END headless_email_auth]
                           if (error) {
                             [self showMessagePrompt:error.localizedDescription];
                             return;
                           }

                           [self performSegueWithIdentifier:@"EmailSignIn" sender:self];
                         }];
}

- (IBAction)didTapCustomTokenLogin:(id)sender {
  NSString *customToken = _tokenField.text;
  // [START signinwithcustomtoken]
  [[FIRAuth auth] signInWithCustomToken:customToken callback:^(FIRUser * _Nullable user,
                                                     NSError * _Nullable error) {
    if (error) {
      [self showMessagePrompt:error.localizedDescription];
      return;
    }

    [self performSegueWithIdentifier:@"EmailSignIn" sender:self];
  }];
  // [END signinwithcustomtoken]
}


/** @fn requestPasswordReset
 @brief Requests a "password reset" email be sent.
 */
- (IBAction)didRequestPasswordReset:(id)sender {
  [self showTextInputPromptWithMessage:@"Email:"
      completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
        if (!userPressedOK || !userInput.length) {
          return;
        }

        [self showSpinner:^{
          // [START password_reset]
          [[FIRAuth auth] sendPasswordResetWithEmail:userInput
              callback:^(NSError * _Nullable error) {
                // [END password_reset]
                [self hideSpinner:^{
                  if (error) {
                    [self showMessagePrompt:error.localizedDescription];
                    return;
                  }

                  [self showMessagePrompt:@"Sent"];
                }];
              }];
            }];
          }];
}

/** @fn getProvidersForEmail
 @brief Prompts the user for an email address, calls @c FIRAuth.getProvidersForEmail:callback:
 and displays the result.
 */
- (IBAction)didGetProvidersForEmail:(id)sender {
  [self showTextInputPromptWithMessage:@"Email:"
      completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
        if (!userPressedOK || !userInput.length) {
          return;
        }

        [self showSpinner:^{
          // [START get_providers]
          [[FIRAuth auth] getProvidersForEmail:userInput
              callback:^(NSArray<NSString *> *_Nullable providers, NSError *_Nullable error) {
                // [END get_providers]
                [self hideSpinner:^{
                  if (error) {
                    [self showMessagePrompt:error.localizedDescription];
                    return;
                  }

                  [self showMessagePrompt:[providers componentsJoinedByString:@", "]];
                }];
              }];
        }];
    }];
}

- (IBAction)didCreateAccount:(id)sender {
  [self showTextInputPromptWithMessage:@"Email:"
      completionBlock:^(BOOL userPressedOK, NSString *_Nullable email) {
        if (!userPressedOK || !email.length) {
          return;
        }

        [self showTextInputPromptWithMessage:@"Password:"
            completionBlock:^(BOOL userPressedOK, NSString *_Nullable password) {
              if (!userPressedOK || !password.length) {
                return;
              }

              [self showSpinner:^{
                // [START create_user]
                [[FIRAuth auth] createUserWithEmail:email password:password
                    callback:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                      // [END create_user]
                      [self hideSpinner:^{
                        if (error) {
                          [self showMessagePrompt:error.localizedDescription];
                            return;
                        }

                        [self showMessagePrompt:user.email];
                      }];
                    }];
              }];
            }];
    }];
}

@end