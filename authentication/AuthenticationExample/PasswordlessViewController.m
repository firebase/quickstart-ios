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
  [self showSpinner:^{
    // [START signin_emaillink]
    [[FIRAuth auth] signInWithEmail:_emailField.text
                               link:_link
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
  [NSUserDefaults.standardUserDefaults setObject:_emailField.text forKey:@"Email"];
  [self showSpinner:^{
    // [START send_signin_link]
    FIRActionCodeSettings *actionCodeSettings = [[FIRActionCodeSettings alloc] init];
    // The sign-in operation has to always be completed in the app.
    actionCodeSettings.handleCodeInApp = YES;
    // Passing the email in the URL and using it on the sign-in step is discouraged
    // as this flow should complete on the same device it started
    [actionCodeSettings setURL:[NSURL URLWithString:@"https://www.example.com"]];
    [actionCodeSettings setIOSBundleID:[[NSBundle mainBundle] bundleIdentifier]];
    [actionCodeSettings setAndroidPackageName:@"com.example.android"
                        installIfNotAvailable:NO
                               minimumVersion:@"12"];
    [[FIRAuth auth] sendSignInLinkToEmail:_emailField.text
                       actionCodeSettings:actionCodeSettings
                               completion:^(NSError *_Nullable error) {
      // [START_EXCLUDE]
      [self hideSpinner:^{
        if (error) {
          [self showMessagePrompt:error.localizedDescription];
           return;
        }
        [self showMessagePrompt:@"Check your email for link"];
      }];
      // [END_EXCLUDE]
    }];
    // [END send_signin_link]
  }];
}

@end
