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

#import "PostDataSource.h"

@import Firebase;

@implementation PostDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [[self refForIndex:indexPath.row] removeValue];
  }
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if ([self count] != 0) {
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.backgroundView   =  nil;
  }
  return [self count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  UILabel *noDataLabel         = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, tableView.bounds.size.height)];
  noDataLabel.text             = @"No posts yet - why not add one?";
  noDataLabel.textColor        = [UIColor blackColor];
  noDataLabel.textAlignment    = NSTextAlignmentCenter;
  tableView.backgroundView = noDataLabel;
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  return 1;
}

@end
