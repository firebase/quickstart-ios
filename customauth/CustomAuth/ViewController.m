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

#import "ViewController.h"
// [START customauth_headers]
#import <FirebaseApp/FirebaseApp.h>
#import <FirebaseAuth/FirebaseAuth.h>

@import Firebase.Core;
// [END customauth_headers]
@import FirebaseDatabase;

@interface ViewController()
@property (weak, nonatomic) IBOutlet UILabel *signInStatus;
@property (weak, nonatomic) IBOutlet UITextView *tokenField;
@property (strong, nonatomic) Firebase *ref;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // [START init_app]
  FIRFirebaseOptions *opts = [[FIRFirebaseOptions alloc] init];
  opts.APIKey = [FIRContext sharedInstance].serviceInfo.apiKey;
  opts.authWidgetURL = [NSURL URLWithString:@"https://gitkitmobile.appspot.com/gitkit.jsp"];
  FIRFirebaseApp *app =
      [FIRFirebaseApp initializedAppWithAppId:[FIRContext sharedInstance].serviceInfo.googleAppID
                                      options:opts];
  [FIRAuth authForApp:app];
  // [END init_app]
}

- (void)viewWillAppear:(BOOL)animated {
  if ([FIRAuth auth].currentUser) {
    [self isSignedIn];
  } else {
    [self isSignedOut];
  }
}

- (IBAction)didTapSignIn:(id)sender {
  FIRAuth *auth = [FIRAuth auth];
  if (auth.currentUser) {
    [auth signOut];
    [self isSignedOut];
    return;
  }

  NSString *customtoken = _tokenField.text;
  // [START signinwithcustomtoken]
  [auth signInWithCustomToken:customtoken callback:^(FIRUser * _Nullable user,
                                                NSError * _Nullable error) {
    if (error) {
      NSLog(@"Sign in failed: %@", error);
      // [START_EXCLUDE silent]
      [self isSignedOut];
      // [END_EXCLUDE]
      return;
    }

    NSLog(@"%@ Signed In", user.userID);
    // [START_EXCLUDE]
    [self isSignedIn];
    // Query the DB - we are now automatically authenticated.
    self.ref = [[Firebase alloc] initWithUrl:[FIRContext sharedInstance].serviceInfo.databaseURL];
    // Note that if there are security rules on this path, the query must be issues after the
    // authentication has been established, or it will fail and the query will be cancelled.
    [_ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
      NSLog(@"%@ -> %@", snapshot.key, snapshot.value);
    }];
    // [END_EXCLUDE]
  }];
  // [END signinwithcustomtoken]
}

- (void)isSignedOut {
  _signInStatus.text = @"Not Signed In";
  [_signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
}

- (void)isSignedIn {
  _signInStatus.text = @"Signed In";
  [_signInButton setTitle:@"Sign Out" forState:UIControlStateNormal];
  [_signInButton setNeedsLayout];
}


@end
