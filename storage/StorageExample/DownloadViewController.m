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

#import "DownloadViewController.h"
@import FirebaseStorage;

@interface DownloadViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;
@property (strong, nonatomic) FIRStorageReference *storageRef;
@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  self.storageRef = [[FIRStorage storage] reference];

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [NSString stringWithFormat:@"file:%@/myimage.jpg", documentsDirectory];
  NSString *storagePath = [[NSUserDefaults standardUserDefaults] objectForKey:@"storagePath"];

  // [START downloadimage]
  [[_storageRef child:storagePath]
          writeToFile:[NSURL URLWithString:filePath] completion:^(NSURL * _Nullable URL,
                                                                  NSError * _Nullable error) {
            if (error) {
              NSLog(@"Error downloading: %@", error);
              _statusTextView.text = @"Download Failed";
              return;
            }
            _statusTextView.text = @"Download Succeeded!";
            _imageView.image = [UIImage imageWithContentsOfFile:filePath];
          }];
  // [END downloadimage]
}
@end
