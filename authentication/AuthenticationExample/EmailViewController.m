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

#import "EmailViewController.h"
#import "UIViewController+Alerts.h"

@import Firebase;

@interface EmailViewController ()
@property(weak, nonatomic) IBOutlet UITextField *emailField;
@property(weak, nonatomic) IBOutlet UITextField *passwordField;
@end

@implementation EmailViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self.view endEditing:YES];
}

- (IBAction)didTapEmailLogin:(id)sender {
  [self showSpinner:^{
    // [START headless_email_auth]
    [[FIRAuth auth] signInWithEmail:self->_emailField.text
                           password:self->_passwordField.text
                         completion:^(FIRAuthDataResult * _Nullable authResult,
                                      NSError * _Nullable error) {
      // [START_EXCLUDE]
      [self hideSpinner:^{
        if (error && error.code == FIRAuthErrorCodeSecondFactorRequired) {
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
                NSLog(@"Multi factor start sign in failed. Error: %@", error.description);
              } else {
                [self showTextInputPromptWithMessage:[NSString stringWithFormat:@"Verification code for %@", selectedHint.displayName]
                                     completionBlock:^(BOOL userPressedOK, NSString *_Nullable verificationCode) {
                 FIRPhoneAuthCredential *credential =
                     [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID
                                                                  verificationCode:verificationCode];
                 FIRMultiFactorAssertion *assertion = [FIRPhoneMultiFactorGenerator assertionWithCredential:credential];
                 [resolver resolveSignInWithAssertion:assertion completion:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable error) {
                   if (error) {
                     NSLog(@"Multi factor finanlize sign in failed. Error: %@", error.description);
                   } else {
                     [self.navigationController popViewControllerAnimated:YES];
                   }
                 }];
               }];
              }
            }];
         }];
        } else if (error) {
          [self showMessagePrompt:error.localizedDescription];
          return;
        }
        [self.navigationController popViewControllerAnimated:YES];
      }];
      // [END_EXCLUDE]
    }];
    // [END headless_email_auth]
  }];
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
      [[FIRAuth auth] sendPasswordResetWithEmail:userInput completion:^(NSError *_Nullable error) {
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
      // [END password_reset]
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
      // [START get_methods]
      [[FIRAuth auth] fetchSignInMethodsForEmail:userInput
                                      completion:^(NSArray<NSString *> *_Nullable providers,
                                                   NSError *_Nullable error) {
        // [START_EXCLUDE]
        [self hideSpinner:^{
          if (error) {
            [self showMessagePrompt:error.localizedDescription];
            return;
          }

          [self showMessagePrompt:[providers componentsJoinedByString:@", "]];
        }];
        // [END_EXCLUDE]
      }];
      // [END get_methods]
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
        [[FIRAuth auth] createUserWithEmail:email
                                   password:password
                                 completion:^(FIRAuthDataResult * _Nullable authResult,
                                              NSError * _Nullable error) {
          // [START_EXCLUDE]
          [self hideSpinner:^{
            if (error) {
              [self showMessagePrompt: error.localizedDescription];
              return;
            }
            NSLog(@"%@ created", authResult.user.email);
            [self.navigationController popViewControllerAnimated:YES];
          }];
          // [END_EXCLUDE]
        }];
        // [END create_user]
      }];
    }];
  }];
}

@end
