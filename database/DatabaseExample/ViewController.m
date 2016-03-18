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

#import "ViewController.h"
@import Firebase.Core;

@implementation ViewController {
  FirebaseHandle _refHandle;
  UInt32 _userInt;
}

#pragma mark - UIViewController lifecycle methods
- (void)viewDidLoad {
  [super viewDidLoad];

  // [START create_database_reference]
  self.ref = [FIRDatabase database].reference;
  // [END create_database_reference]

  _userInt = arc4random();
  self.messages = [[NSMutableArray alloc] init];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
  [self.messages removeAllObjects];
  // Listen for new messages in the Firebase database
  _refHandle = [[self.ref childByAppendingPath:@"messages"]
      observeEventType:FIRDataEventTypeChildAdded
             withBlock:^(FIRDataSnapshot *snapshot) {
               [self.messages addObject:snapshot];
               [self.tableView insertRowsAtIndexPaths:@[
                 [NSIndexPath indexPathForRow:[self.messages count] - 1 inSection:0]
               ] withRowAnimation:UITableViewRowAnimationAutomatic];
             }];
}

- (void)viewDidDisappear:(BOOL)animated {
  [self.ref removeObserverWithHandle:_refHandle];
}

#pragma mark - UITableViewDataSource protocol methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // Dequeue cell
  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"tableViewCell" forIndexPath:indexPath];

  // Unpack message from Firebase DataSnapshot
  FIRDataSnapshot *snapshot = self.messages[indexPath.row];
  NSString *name = snapshot.value[@"name"];
  NSString *text = snapshot.value[@"text"];
  cell.textLabel.text = [NSString stringWithFormat:@"%@ says %@", name, text];

  return cell;
}

#pragma mark - UITableViewDataSource protocol methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // Push data to Firebase Database
  [[[self.ref childByAppendingPath:@"messages"] childByAutoId] setValue:@{
    @"name" : [NSString stringWithFormat:@"User %d", _userInt],
    @"text" : textField.text
  }];
  textField.text = @"";
  return YES;
}

@end
