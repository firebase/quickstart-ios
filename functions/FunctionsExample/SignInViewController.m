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

#import "SignInViewController.h"
#import "AppDelegate.h"
#import "FAuthPickerViewController.h"

@import Firebase;
@import FirebaseUI;

@interface SignInViewController ()

@end

@implementation SignInViewController

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([FIRAuth auth].currentUser) {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main"
                                                                           bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [self dismissViewControllerAnimated:YES completion:nil];
    return;
  }
  FUIAuth *authUI = [FUIAuth defaultAuthUI];
  authUI.delegate = self;
  authUI.TOSURL = [NSURL URLWithString:@"https://firebase.google.com/terms/"];
  authUI.providers = @[[[FUIGoogleAuth alloc] init]];
  UINavigationController *authViewController = authUI.authViewController;
  authViewController.navigationBar.hidden = true;
  [self presentViewController:authViewController animated:true completion:nil];
}

- (void)authUI:(FUIAuth *)authUI didSignInWithAuthDataResult:(FIRAuthDataResult *)authDataResult error:(NSError *)error {
  if (error) {
    if (error.code == FUIAuthErrorCodeUserCancelledSignIn) {
      NSLog(@"User cancelled sign-in");
    } else {
      NSError *detailedError = error.userInfo[NSUnderlyingErrorKey];
      if (!detailedError) {
        detailedError = error;
      }
      NSLog(@"Login error: %@", detailedError.localizedDescription);
    }
    return;
  }
  [self signedIn:authDataResult.user];
}

- (FUIAuthPickerViewController *)authPickerViewControllerForAuthUI:(FUIAuth *)authUI {
  return [[FAuthPickerViewController alloc] initWithNibName:@"FAuthPickerViewController"
                                                     bundle:[NSBundle mainBundle]
                                                     authUI:authUI];
}

- (void)signedIn:(FIRUser *)user {
  AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
  appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main"
                                                                         bundle:[NSBundle mainBundle]] instantiateInitialViewController];
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
