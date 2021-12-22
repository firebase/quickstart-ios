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

@import Photos;
#import "ViewController.h"
#import "DownloadViewController.h"

@import FirebaseAuth;
@import FirebaseStorage;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *takePicButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadPicButton;
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;

@property (strong, nonatomic) FIRStorage *storage;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // [START configurestorage]
  self.storage = [FIRStorage storage];
  // [END configurestorage]

  // [START storageauth]
  // Using Cloud Storage for Firebase requires the user be authenticated. Here we are using
  // anonymous authentication.
  if (![FIRAuth auth].currentUser) {
    [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRAuthDataResult * _Nullable authResult,
                                                      NSError * _Nullable error) {
      if (error) {
        self->_urlTextView.text = error.description;
        self->_takePicButton.enabled = NO;
      } else {
        self->_takePicButton.enabled = YES;
        self->_urlTextView.text = @"";
      }
    }];
  }
  // [END storageauth]
}

# pragma mark - Image Picker

- (IBAction)didTapTakePicture:(id)sender {
  UIImagePickerController * picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  }

  [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [picker dismissViewControllerAnimated:YES completion:NULL];

  _urlTextView.text = @"Beginning Upload";
  NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
  // if it's a photo from the library, not an image from the camera
  if (referenceUrl) {
    PHFetchResult* assets = [PHAsset fetchAssetsWithALAssetURLs:@[referenceUrl] options:nil];
    PHAsset *asset = assets.firstObject;
    [asset requestContentEditingInputWithOptions:nil
                               completionHandler:^(PHContentEditingInput *contentEditingInput,
                                                   NSDictionary *info) {
                                 NSURL *imageFile = contentEditingInput.fullSizeImageURL;
                                 NSString *filePath =
                                     [NSString stringWithFormat:@"%@/%lld/%@",
                                         [FIRAuth auth].currentUser.uid,
                                         (long long)([NSDate date].timeIntervalSince1970 * 1000.0),
                                         imageFile.lastPathComponent];
                                 FIRStorageReference *storageRef = [self->_storage referenceWithPath:filePath];
                                 // [START uploadimage]
                                 [storageRef putFile:imageFile
                                            metadata:nil
                                          completion:^(FIRStorageMetadata *metadata, NSError *error) {
                                    if (error) {
                                      NSLog(@"Error uploading: %@", error);
                                      self->_urlTextView.text = @"Upload Failed";
                                      return;
                                    }
                                    [self uploadSuccess:storageRef storagePath:filePath];
                                  }];
                                 // [END uploadimage]
                               }];

  } else {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    NSString *imagePath =
    [NSString stringWithFormat:@"%@/%lld.jpg",
     [FIRAuth auth].currentUser.uid,
     (long long)([NSDate date].timeIntervalSince1970 * 1000.0)];
    FIRStorageMetadata *metadata = [FIRStorageMetadata new];
    metadata.contentType = @"image/jpeg";
    FIRStorageReference *storageRef = [_storage referenceWithPath:imagePath];
    [storageRef putData:imageData
               metadata:metadata
             completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
          if (error) {
            NSLog(@"Error uploading: %@", error);
            self->_urlTextView.text = @"Upload Failed";
            return;
          }
          [self uploadSuccess:storageRef storagePath:imagePath];
        }];
  }
}

- (void)uploadSuccess:(FIRStorageReference *) storageRef storagePath: (NSString *) storagePath {
  NSLog(@"Upload Succeeded!");
  [storageRef downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
    if (error) {
      NSLog(@"Error getting download URL: %@", error);
      self->_urlTextView.text = @"Can't get download URL";
      return;
    }
    self->_urlTextView.text = URL.absoluteString;
    [[NSUserDefaults standardUserDefaults] setObject:storagePath forKey:@"storagePath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self->_downloadPicButton.enabled = YES;
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}


@end
