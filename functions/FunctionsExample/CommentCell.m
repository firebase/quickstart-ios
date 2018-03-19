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

#import "CommentCell.h"

@import Firebase;


@interface CommentCell ()
@property(weak, nonatomic) IBOutlet MDCTextField *resultField;
@end

@implementation CommentCell

- (IBAction)didTapAddMessage:(id)sender {
  // [START function_add_message]
  [[[FIRFunctions functions] HTTPSCallableWithName:@"addMessage"] callWithObject:@{@"text": _inputField.text} completion:^(FIRHTTPSCallableResult * _Nullable result, NSError * _Nullable error) {
    // [START_EXCLUDE]
    if (error) {
      NSLog(@"%@", error.localizedDescription);
      return;
    }
    // [END_EXCLUDE]
    _resultField.text = result.data[@"text"];
  }];
  // [END function_add_message]
}

@end
