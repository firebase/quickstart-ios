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

#import "Post.h"
#import "PostDetailTableViewController.h"
#import "PostTableViewCell.h"

@import Firebase;

static const int kSectionComments = 2;
static const int kSectionSend = 1;
static const int kSectionPost = 0;

@interface PostDetailTableViewController ()
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *comments;
@property (strong, nonatomic) UITextField *commentField;
@property (strong, nonatomic) Post *post;
@property (strong, nonatomic) FIRDatabaseReference *postRef;
@property (strong, nonatomic) FIRDatabaseReference *commentsRef;
@end

@implementation PostDetailTableViewController

  FIRDatabaseHandle _refHandle;

// UITextViewDelegate protocol method
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  FIRDatabaseReference *ref = [FIRDatabase database].reference;
  self.postRef = [[ref child:@"posts"] child:_postKey];
  self.commentsRef = [[ref child:@"post-comments"] child:_postKey];
  self.comments = [[NSMutableArray alloc] init];
  self.post = [[Post alloc] init];
  UINib *nib = [UINib nibWithNibName:@"PostTableViewCell" bundle:nil];
  [self.tableView registerNib:nib forCellReuseIdentifier:@"post"];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.comments removeAllObjects];
  // [START child_event_listener]
  // Listen for new comments in the Firebase database
  [_commentsRef
                observeEventType:FIRDataEventTypeChildAdded
                withBlock:^(FIRDataSnapshot *snapshot) {
                  [self.comments addObject:snapshot];
                  [self.tableView insertRowsAtIndexPaths:@[
                    [NSIndexPath indexPathForRow:self.comments.count - 1 inSection:kSectionComments]
                  ]
                                        withRowAnimation:UITableViewRowAnimationAutomatic];
                }];
  // Listen for deleted comments in the Firebase database
  [_commentsRef
   observeEventType:FIRDataEventTypeChildRemoved
   withBlock:^(FIRDataSnapshot *snapshot) {
     int index = [self indexOfMessage:snapshot];
     [self.comments removeObjectAtIndex:index];
     [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:kSectionComments]]
                           withRowAnimation:UITableViewRowAnimationAutomatic];
   }];
  // [END child_event_listener]

  // [START post_value_event_listener]
  _refHandle = [_postRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
    NSDictionary *postDict = snapshot.value;
    // [START_EXCLUDE]
    [self.post setValuesForKeysWithDictionary:postDict];
    [self.tableView reloadData];
    self.navigationItem.title = self.post.title;
    // [END_EXCLUDE]
  }];
  // [END post_value_event_listener]
}

- (int) indexOfMessage:(FIRDataSnapshot *)snapshot {
  int index = 0;
  for (FIRDataSnapshot *comment in _comments) {
    if ([snapshot.key isEqualToString:comment.key]) {
      return index;
    }
    ++index;
  }
  return -1;
}
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.postRef removeObserverWithHandle:_refHandle];
  [self.commentsRef removeAllObservers];
  [[[[FIRDatabase database].reference child:@"users"] child:[FIRAuth auth].currentUser.uid] removeAllObservers];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == kSectionPost || section == kSectionSend ) {
    return 1;
  } else if (section == kSectionComments) {
    return _comments.count;
  }
  NSAssert(NO, @"Unexpected section");
  return 0;
}
- (IBAction)didTapSend:(UIButton *)sender {
  [self textFieldShouldReturn:_commentField];
  _commentField.enabled = NO;
  sender.enabled = NO;
  NSString *uid = [FIRAuth auth].currentUser.uid;
  [[[[FIRDatabase database].reference child:@"users"] child:uid]
   observeSingleEventOfType:FIRDataEventTypeValue
   withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
      NSDictionary *user = snapshot.value;
      NSString *username = user[@"username"];
      NSDictionary *comment = @{@"uid": uid,
                                @"author": username,
                                @"text": self.commentField.text};
      [[self.commentsRef childByAutoId] setValue:comment];
      self.commentField.text = @"";
      self.commentField.enabled = YES;
      sender.enabled = YES;
  }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  if (indexPath.section == kSectionPost) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"post" forIndexPath: indexPath];
    PostTableViewCell *postcell = (PostTableViewCell *)cell;
    postcell.authorLabel.text = _post.author;
    postcell.postTitle.text = _post.title;
    postcell.postBody.text = _post.body;
    NSString *imageName = _post.stars[[self getUid]] ? @"ic_star" : @"ic_star_border";
    [postcell.starButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    postcell.numStarsLabel.text = [NSString stringWithFormat:@"%d", _post.starCount];
    postcell.postKey = _postKey;

  } else if (indexPath.section == kSectionComments) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"comment" forIndexPath: indexPath];
    NSDictionary *comment = _comments[indexPath.row].value;
    cell.textLabel.text = comment[@"author"];
    cell.detailTextLabel.text = comment[@"text"];
  } else if (indexPath.section == kSectionSend) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"send" forIndexPath: indexPath];
    _commentField = [(UITextField *) cell viewWithTag:7];
  } else {
      [NSException raise:NSInternalInconsistencyException format:@"Wrong section %ld", (long)indexPath.section];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == kSectionPost) {
    return 160;
  }
  return 56;
}

- (NSString *) getUid {
  return [FIRAuth auth].currentUser.uid;
}

@end
