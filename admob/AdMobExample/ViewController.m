//
// Copyright (c) 2015 Google Inc.
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
//  ViewController.m
//  AdMobExample
//

// [START firebase_banner_example]
#import "ViewController.h"
@import GoogleMobileAds;

/**
 * AdMob ad unit IDs are not currently stored inside the google-services.plist file. Developers
 * using AdMob can store them as custom values in another plist, or simply use constants. Note that
 * these ad units are configured to return only test ads, and should not be used outside this sample.
 */
static NSString *const kBannerAdUnitID = @"ca-app-pub-3940256099942544/2934735716";
static NSString *const kInterstitialAdUnitID = @"ca-app-pub-3940256099942544/4411468910";

@interface ViewController () <GADFullScreenContentDelegate>

/**
 * @property
 * A UIView subclass that displays ads capable of responding to user touch.
 */
@property(nonatomic, weak) IBOutlet GADBannerView *bannerView;

/**
 * @property
 * A UIView subclass that displays ads capable of responding to user touch.
 */
@property(nonatomic, strong, nullable) GADInterstitialAd *interstitial;

@property (weak, nonatomic) IBOutlet UIButton *interstitialButton;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.bannerView.adUnitID = kBannerAdUnitID;
  self.bannerView.rootViewController = self;
  [self.bannerView loadRequest:[GADRequest request]];
  // [END firebase_banner_example]

  // [START firebase_interstitial_example]
  [self createAndLoadInterstitial];
}

- (void)createAndLoadInterstitial {
  [GADInterstitialAd loadWithAdUnitID:kInterstitialAdUnitID
                              request:[GADRequest request]
                    completionHandler:^(GADInterstitialAd *ad, NSError *error) {
    if (error != nil) {
      // For more fine-grained error handling, take a look at the values in GADErrorCode.
      NSLog(@"Error loading ad: %@", error);
    }
    self.interstitial = ad;
    self.interstitialButton.enabled = YES;
  }];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
  self.interstitialButton.enabled = NO;
  [self createAndLoadInterstitial];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad
didFailToPresentFullScreenContentWithError:(NSError *)error {
  NSLog(@"Error presenting ad: %@", ad);
}

- (IBAction)didTapInterstitialButton:(id)sender {
  if (self.interstitial != nil) {
    [self.interstitial presentFromRootViewController:self];
  }
}

@end
// [END firebase_interstitial_example]
