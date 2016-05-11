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

#import "PostTableViewCell.h"
@import FirebaseAuth;

@implementation PostTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
  return [super initWithFrame:frame];
}

- (IBAction)didTapStarButton:(id)sender {
  self.postRef = [[[FIRDatabase database] reference] child:@"posts"];
  // [START post_stars_transaction]
  [_postRef runTransactionBlock:^FIRTransactionResult * _Nonnull(FIRMutableData * _Nonnull currentData) {
    NSMutableDictionary *post = currentData.value;
    if (!post) {
      return [FIRTransactionResult successWithValue:currentData];
    }

    NSMutableDictionary *stars = [post objectForKey:@"stars"];
    NSString *uid = [FIRAuth auth].currentUser.uid;
    int starCount = [post[@"starCount"] intValue];
    if ([stars objectForKey:uid]) {
      // Unstar the post and remove self from stars
      starCount--;
      [stars removeObjectForKey:uid];
    } else {
      // Star the post and add self to stars
      starCount++;
      stars[uid] = @YES;
    }
    post[@"starCount"] = [NSNumber numberWithInt:starCount];

    // Set value and report transaction success
    [currentData setValue:post];
    return [FIRTransactionResult successWithValue:currentData];
  } andCompletionBlock:^(NSError * _Nullable error, BOOL committed, FIRDataSnapshot * _Nullable snapshot) {
    // Transaction completed
    NSLog(@"%@", error.localizedDescription);
  }];
  // [END post_stars_transaction]
}

@end
