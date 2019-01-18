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

#import "MainViewController.h"
#import "CommentCell.h"
@import Firebase;
@import MaterialComponents;

@interface MainViewController ()
@property(strong, nonatomic) MDCTextInputControllerUnderline *controller;
@end

@implementation MainViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  self.styler.cellStyle = MDCCollectionViewCellStyleCard;
  self.styler.cellLayoutType = MDCCollectionViewCellLayoutTypeList;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView cellHeightAtIndexPath:(NSIndexPath *)indexPath {
  return 181;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CommentCell *commentCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"message" forIndexPath:indexPath];
    commentCell.inputField.delegate = self;
    _controller = [[MDCTextInputControllerUnderline alloc] initWithTextInput:commentCell.inputField];

    [commentCell.button setElevation:MDCShadowElevationRaisedButtonResting forState:UIControlStateNormal];
    [commentCell.button setElevation:MDCShadowElevationRaisedButtonPressed forState:UIControlStateHighlighted];
    return commentCell;
  }
}

@end
