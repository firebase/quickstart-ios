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

#import "ViewController.h"
#import "FirebaseStorage.h"

@import Firebase.Auth;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *signinButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *takePicButton;
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;

@property (strong, nonatomic) FIRStorage *storageRef;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self updateUIForUser:[FIRAuth auth].currentUser];

  // [START configurestorage]
  FIRFirebaseApp *app = [FIRFirebaseApp app];
  // Configure manually with a storage bucket.
  NSString *bucket = @"YOUR_PROJECT.storage.firebase.com";
  self.storageRef = [[FIRStorage alloc] initWithApp:app bucketName:bucket];
  // [END configurestorage]
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

  UIImage *image = info[UIImagePickerControllerOriginalImage];
  NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
  _urlTextView.text = @"Beginning Upload";

  // [START uploadimage]
  FIRStorageMetadata *metadata = [FIRStorageMetadata new];
  metadata.contentType = @"image/jpeg";
  FIRStorageUploadTask *upload = [[_storageRef childByAppendingString:@"myimage.jpg"]
                                  putData:imageData
                                  metadata:metadata];


  // [END uploadimage]

  // [START oncomplete]
  [upload observeStatus:FIRTaskStatusComplete
      withCallback:^(FIRStorageUploadTask *task) {
        _urlTextView.text = @"Upload Succeeded!";
        [self onSuccesfulUpload];
      }];
  // [END oncomplete]

  // [START onfailure]
  [upload observeStatus:FIRTaskStatusFailure
      withErrorCallback:^(FIRStorageUploadTask *task, NSError *error) {
        if (error) {
          NSLog(@"Error uploading: %@", error);
        }
        _urlTextView.text = @"Upload Failed";
      }];
  // [END onfailure]
}

- (void)onSuccesfulUpload {
  NSLog(@"Retrieving metadata");
  _urlTextView.text = @"Fetching Metadata";
  // [START getmetadata]
  [[_storageRef childByAppendingString:@"myimage.jpg"]
      metadataWithCompletion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error) {
          NSLog(@"Error retrieving metadata: %@", error);
          _urlTextView.text = @"Error Fetching Metadata";
          return;
        }
        // Get first download URL to display.
        _urlTextView.text = [metadata.downloadURLs[0] absoluteString];
        NSLog(@"Retrieved metadata: %@", metadata);
      }];
  // [END getmetadata]
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

# pragma mark - Sign In

- (void)updateUIForUser:(FIRUser *)user {
  if (user) {
    _emailField.enabled = NO;
    _passwordField.enabled = NO;
    _emailField.text = _passwordField.text = @"";
    [_signinButton setTitle:@"Sign Out" forState:UIControlStateNormal];
    _signUpButton.enabled = NO;
    _takePicButton.enabled = YES;
    _urlTextView.text = @"";
  } else {
    _emailField.enabled = YES;
    _passwordField.enabled = YES;
    [_signinButton setTitle:@"Sign In" forState:UIControlStateNormal];
    _signUpButton.enabled = YES;
    _takePicButton.enabled = NO;
    _urlTextView.text = @"";
  }
}

- (IBAction)didTapSignIn:(id)sender {
  if ([FIRAuth auth].currentUser) {
    // Sign Out.
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    if (!error) {
      [self updateUIForUser:nil];
    }
    return;
  }
  // Sign In with credentials.
  NSString *email = _emailField.text;
  NSString *password = _passwordField.text;
  [[FIRAuth auth] signInWithEmail:email
                         password:password
                         callback:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                           if (error) {
                             _urlTextView.text = error.description;
                           }
                           [self updateUIForUser:user];
  }];
}

- (IBAction)didTapSignUp:(id)sender {
  NSString *email = _emailField.text;
  NSString *password = _passwordField.text;
  [[FIRAuth auth] createUserWithEmail:email
                         password:password
                         callback:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                           [self updateUIForUser:user];
                         }];
}

@end
