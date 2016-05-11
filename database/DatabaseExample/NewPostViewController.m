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

#import "NewPostViewController.h"
#import "User.h"
#import "Post.h"
@import Firebase;

@implementation NewPostViewController {
  __weak IBOutlet UITextView *bodyTextView;
  __weak IBOutlet UITextField *titleTextField;
}

#pragma mark - UIViewController lifecycle methods
- (void)viewDidLoad {
  [super viewDidLoad];

  // [START create_database_reference]
  self.ref = [[FIRDatabase database] reference];
  // [END create_database_reference]
}

- (IBAction)didTapShare:(id)sender {
  // [START single_value_read]
  NSString *userID = [FIRAuth auth].currentUser.uid;
  [[[_ref child:@"users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
    // Get user value
    User *user = [[User alloc] initWithUsername:snapshot.value[@"username"]];

    // [START_EXCLUDE]
    // Write new post
    [self writeNewPost:userID username:user.username title:titleTextField.text body:bodyTextView.text];
    // Finish this Activity, back to the stream
    [[self navigationController] popViewControllerAnimated:YES];
    // [END_EXCLUDE]
  } withCancelBlock:^(NSError * _Nonnull error) {
    NSLog(@"%@", error.localizedDescription);
  }];
  // [END single_value_read]
}

- (void)writeNewPost:(NSString *)userID username:(NSString *)username title:(NSString *)title body:(NSString *)body {
  // Create new post at /user-posts/$userid/$postid and at
  // /posts/$postid simultaneously
  // [START write_fan_out]
  NSString *key = [[_ref child:@"posts"] childByAutoId].key;
  NSDictionary *post = @{@"uid": userID,
                         @"author": username,
                         @"title": title,
                         @"body": body};
  NSDictionary *childUpdates = @{[@"/posts/" stringByAppendingString:key]: post,
                                 [NSString stringWithFormat:@"/user-posts/%@/", key]: post};
  [_ref updateChildValues:childUpdates];
  // [END write_fan_out]
}



@end
