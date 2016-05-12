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

#import <UIKit/UIKit.h>
@import Firebase;

@interface PostTableViewCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UIImageView *authorImage;
@property(weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UIButton *starButton;
@property(weak, nonatomic) IBOutlet UILabel *numStarsLabel;
@property(weak, nonatomic) IBOutlet UILabel *postTitle;
@property(weak, nonatomic) IBOutlet UITextView *postBody;
@property(weak, nonatomic) NSString *postKey;
@end
