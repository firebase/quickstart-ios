//
//  Copyright (c) 2018 Google Inc.
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

#import "PasswordlessViewController.h"
#import "UIViewController+Alerts.h"

@import Firebase;

@interface PasswordlessViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property(strong, nonatomic) NSString *link;
@end

@implementation PasswordlessViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  _emailField.text = [NSUserDefaults.standardUserDefaults valueForKey:@"Email"];
  self.link = [NSUserDefaults.standardUserDefaults valueForKey:@"Link"];
  if (_link) {
    _signInButton.enabled = YES;
  }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self.view endEditing:YES];
}

- (IBAction)didTapSignInWithEmailLink:(id)sender {
  NSString *email = _emailField.text;
  NSString *link = _link;
  [self showSpinner:^{
    // [START signin_emaillink]
    [[FIRAuth auth] signInWithEmail:email
                               link:link
                         completion:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable error) {
      // [START_EXCLUDE]
      [self hideSpinner:^{
        if (error) {
          [self showMessagePrompt:error.localizedDescription];
          return;
        }
        [self.navigationController popViewControllerAnimated:YES];
      }];
    // [END_EXCLUDE]
    }];
    // [END signin_emaillink]
  }];
}

- (IBAction)didTapSendSignInLink:(id)sender {
  NSString *email = _emailField.text;
  [self showSpinner:^{
    // [START action_code_settings]
    FIRActionCodeSettings *actionCodeSettings = [[FIRActionCodeSettings alloc] init];
    [actionCodeSettings setURL:[NSURL URLWithString:@"https://www.example.com"]];
    // The sign-in operation has to always be completed in the app.
    actionCodeSettings.handleCodeInApp = YES;
    [actionCodeSettings setIOSBundleID:[[NSBundle mainBundle] bundleIdentifier]];
    [actionCodeSettings setAndroidPackageName:@"com.example.android"
                        installIfNotAvailable:NO
                               minimumVersion:@"12"];
    // [END action_code_settings]
    // [START send_signin_link]
    [[FIRAuth auth] sendSignInLinkToEmail:email
                       actionCodeSettings:actionCodeSettings
                               completion:^(NSError *_Nullable error) {
      // [START_EXCLUDE]
      [self hideSpinner:^{
        // [END_EXCLUDE]
        if (error) {
          [self showMessagePrompt:error.localizedDescription];
           return;
        }
        // The link was successfully sent. Inform the user.
        // Save the email locally so you don't need to ask the user for it again
        // if they open the link on the same device.
        [NSUserDefaults.standardUserDefaults setObject:email forKey:@"Email"];
        [self showMessagePrompt:@"Check your email for link"];
        // [START_EXCLUDE]
      }];
      // [END_EXCLUDE]
    }];
    // [END send_signin_link]
  }];
}

@end
