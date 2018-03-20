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
#import "CloudAddCell.h"
#import "CommentCell.h"
@import Firebase;
@import MaterialComponents;

@interface MainViewController ()
@property(strong, nonatomic) MDCTextInputControllerUnderline *controller1;
@property(strong, nonatomic) MDCTextInputControllerUnderline *controller2;
@property(strong, nonatomic) MDCTextInputControllerUnderline *controller3;
@end

@implementation MainViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  self.styler.cellStyle = MDCCollectionViewCellStyleCard;
  self.styler.cellLayoutType = MDCCollectionViewCellLayoutTypeList;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView cellHeightAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    return 181;
  }
  return 230;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    CloudAddCell *addCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"add" forIndexPath:indexPath];
    addCell.number1Field.delegate = self;
    _controller1 = [[MDCTextInputControllerUnderline alloc] initWithTextInput:addCell.number1Field];
    addCell.number2Field.delegate = self;
    _controller2 = [[MDCTextInputControllerUnderline alloc] initWithTextInput:addCell.number2Field];


    [addCell.button setElevation:MDCShadowElevationRaisedButtonResting forState:UIControlStateNormal];
    [addCell.button setElevation:MDCShadowElevationRaisedButtonPressed forState:UIControlStateHighlighted];
    return addCell;
  } else {
    CommentCell *commentCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"message" forIndexPath:indexPath];
    commentCell.inputField.delegate = self;
    _controller3 = [[MDCTextInputControllerUnderline alloc] initWithTextInput:commentCell.inputField];

    [commentCell.button setElevation:MDCShadowElevationRaisedButtonResting forState:UIControlStateNormal];
    [commentCell.button setElevation:MDCShadowElevationRaisedButtonPressed forState:UIControlStateHighlighted];
    return commentCell;
  }
}

@end
