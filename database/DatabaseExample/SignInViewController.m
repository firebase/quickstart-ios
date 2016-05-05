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

#import "SignInViewController.h"
@import FirebaseAuth;

@interface SignInViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@end

@implementation SignInViewController

- (IBAction)didTapSignUp:(id)sender {
  [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
      return;
    }
    self.ref = [FIRDatabase database].reference;
    [[[_ref child:@"users"] child:user.uid] setValue:@{@"username": _emailField.text}];
    [self performSegueWithIdentifier:@"signIn" sender:nil];
  }];
}

#pragma mark - UITextFieldDelegate protocol methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self didTapSignUp:nil];
  return YES;
}

@end
