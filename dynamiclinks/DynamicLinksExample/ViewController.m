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
#import "HeaderCell.h"
#import "ParamTableViewCell.h"
@import Firebase;

static NSString *const Link = @"Link Value";
static NSString *const Domain = @"App Domain";
static NSString *const Source = @"Source";
static NSString *const Medium = @"Medium";
static NSString *const Campaign = @"Campaign";
static NSString *const Term = @"Term";
static NSString *const Content = @"Content";
static NSString *const BundleID = @"App Bundle ID";
static NSString *const FallbackURL = @"Fallback URL";
static NSString *const MinimumAppVersion = @"Minimum App Version";
static NSString *const CustomScheme = @"Custom Scheme";
static NSString *const IPadBundleID = @"iPad Bundle ID";
static NSString *const IPadFallbackURL = @"iPad Fallback URL";
static NSString *const AppStoreID = @"AppStore ID";
static NSString *const AffiliateToken = @"Affiliate Token";
static NSString *const CampaignToken = @"Campaign Token";
static NSString *const ProviderToken = @"Provider Token";
static NSString *const PackageName = @"Package Name";
static NSString *const AndroidFallbackURL = @"Android Fallback URL";
static NSString *const MinimumVersion = @"Minimum Version";
static NSString *const Title = @"Title";
static NSString *const DescriptionText = @"Description Text";
static NSString *const ImageURL = @"Image URL";
static NSString *const OtherFallbackURL = @"Other Platform Fallback URL";

static NSInteger const NumberParams = 24;

static NSString *const GoogleAnalytics = @"Google Analytics";
static NSString *const IOS = @"iOS";
static NSString *const ITunes = @"iTunes Connect Analytics";
static NSString *const Android = @"Android";
static NSString *const Social = @"Social Meta Tag";
static NSString *const Other = @"Other Platform";

static NSString *const DOMAIN_URI_PREFIX = @"YOUR_DOMAIN_URI_PREFIX";

@interface Section:NSObject
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSArray<NSString *> *items;
@property(nonatomic) BOOL collapsed;
@end

@implementation Section
- (instancetype)initWithName:(NSString *)name withItems:(NSArray<NSString *> *)items {
  self = [super init];
  if (self) {
    self.name = name;
    self.items = items;
    self.collapsed = YES;
  }
  return self;
}
@end

@interface ViewController()<UIGestureRecognizerDelegate>
@property(nonatomic, strong) NSArray<Section *> *sections;
@property(nonatomic, strong) NSMutableDictionary<NSString *, UITextField *> *dictionary;
@property(nonatomic, strong) NSURL *longLink;
@property(nonatomic, strong) NSURL *shortLink;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.dictionary = [[NSMutableDictionary alloc] initWithCapacity:NumberParams];


  self.sections = @[[[Section alloc]initWithName:GoogleAnalytics withItems:@[Source, Medium, Campaign, Term, Content]],
                    [[Section alloc]initWithName:IOS withItems:@[BundleID, FallbackURL, MinimumAppVersion, CustomScheme, IPadBundleID, IPadFallbackURL, AppStoreID]],
                    [[Section alloc]initWithName:ITunes withItems:@[AffiliateToken, CampaignToken, ProviderToken]],
                    [[Section alloc]initWithName:Android withItems:@[PackageName, AndroidFallbackURL, MinimumVersion]],
                    [[Section alloc]initWithName:Social withItems:@[Title, DescriptionText, ImageURL]],
                    [[Section alloc]initWithName:Other withItems:@[OtherFallbackURL]]
                  ];
}

- (void)buildFDLLink {
  if ([DOMAIN_URI_PREFIX  isEqual: @"YOUR_DOMAIN_URI_PREFIX"]) {
    [NSException raise:@"DOMAIN_URI_PREFIX"
                format:@"%@",
     @"Please update DOMAIN_URI_PREFIX constant in your code from Firebase Console!"];
  }
  // [START buildFDLLink]
  // general link params
  if (_dictionary[Link].text == nil) {
    NSLog(@"%@", @"Link can not be empty!");
    return;
  }

  NSURL *link = [NSURL URLWithString:_dictionary[Link].text];
  FIRDynamicLinkComponents *components =
  [FIRDynamicLinkComponents componentsWithLink:link domainURIPrefix:DOMAIN_URI_PREFIX];

  // analytics params
  FIRDynamicLinkGoogleAnalyticsParameters *analyticsParams =
  [FIRDynamicLinkGoogleAnalyticsParameters parametersWithSource:_dictionary[Source].text
                                                         medium:_dictionary[Medium].text
                                                       campaign:_dictionary[Campaign].text];
  analyticsParams.term = _dictionary[Term].text;
  analyticsParams.content = _dictionary[Content].text;
  components.analyticsParameters = analyticsParams;

  if (_dictionary[BundleID].text) {
    // iOS params
    FIRDynamicLinkIOSParameters *iOSParams = [FIRDynamicLinkIOSParameters parametersWithBundleID:_dictionary[BundleID].text];
    iOSParams.fallbackURL = [NSURL URLWithString:_dictionary[FallbackURL].text];
    iOSParams.minimumAppVersion = _dictionary[MinimumAppVersion].text;
    iOSParams.customScheme = _dictionary[CustomScheme].text;
    iOSParams.iPadBundleID = _dictionary[IPadBundleID].text;
    iOSParams.iPadFallbackURL = [NSURL URLWithString:_dictionary[IPadFallbackURL].text];
    iOSParams.appStoreID = _dictionary[AppStoreID].text;
    components.iOSParameters = iOSParams;

    // iTunesConnect params
    FIRDynamicLinkItunesConnectAnalyticsParameters *appStoreParams = [FIRDynamicLinkItunesConnectAnalyticsParameters parameters];
    appStoreParams.affiliateToken = _dictionary[AffiliateToken].text;
    appStoreParams.campaignToken = _dictionary[CampaignToken].text;
    appStoreParams.providerToken = _dictionary[ProviderToken].text;
    components.iTunesConnectParameters = appStoreParams;
  }

  if (_dictionary[PackageName].text) {
    // Android params
    FIRDynamicLinkAndroidParameters *androidParams = [FIRDynamicLinkAndroidParameters parametersWithPackageName: _dictionary[PackageName].text];
    androidParams.fallbackURL = [NSURL URLWithString:_dictionary[FallbackURL].text];
    androidParams.minimumVersion = (_dictionary[MinimumVersion].text).integerValue;
    components.androidParameters = androidParams;
  }

  // social tag params
  FIRDynamicLinkSocialMetaTagParameters *socialParams = [FIRDynamicLinkSocialMetaTagParameters parameters];
  socialParams.title = _dictionary[Title].text;
  socialParams.descriptionText = _dictionary[DescriptionText].text;
  socialParams.imageURL = [NSURL URLWithString:_dictionary[ImageURL].text];
  components.socialMetaTagParameters = socialParams;

  // OtherPlatform params
  FIRDynamicLinkOtherPlatformParameters *otherPlatformParams =
  [FIRDynamicLinkOtherPlatformParameters parameters];
  otherPlatformParams.fallbackUrl = [NSURL URLWithString:_dictionary[OtherFallbackURL].text];
  components.otherPlatformParameters = otherPlatformParams;

  _longLink = components.url;
  NSLog(@"Long URL: %@", _longLink.absoluteString);
  // [END buildFDLLink]

  // Handle longURL.
  [self.tableView reloadRowsAtIndexPaths:@[
                                           [NSIndexPath indexPathForRow:0 inSection:2]
                                           ]
                        withRowAnimation:UITableViewRowAnimationNone];

  // [START shortLinkOptions]
  FIRDynamicLinkComponentsOptions *options = [FIRDynamicLinkComponentsOptions options];
  options.pathLength = FIRShortDynamicLinkPathLengthUnguessable;
  components.options = options;
  // [END shortLinkOptions]

  // [START shortenLink]
  [components shortenWithCompletion:^(NSURL *_Nullable shortURL,
                                      NSArray *_Nullable warnings,
                                      NSError *_Nullable error) {
    // Handle shortURL or error.
    if (error) {
      NSLog(@"Error generating short link: %@", error.description);
      return;
    }
    NSLog(@"Short URL: %@", shortURL.absoluteString);
    // [START_EXCLUDE]
    self->_shortLink = shortURL;
    [self.tableView reloadRowsAtIndexPaths:@[
                                             [NSIndexPath indexPathForRow:1 inSection:2]
                                             ]
                          withRowAnimation:UITableViewRowAnimationNone];
    // [END_EXCLUDE]
  }];
  // [END shortenLink]
}

#pragma mark - View Controller DataSource and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case 0: return @"Components";
    case 1: return @"Optional Parameters";
    case 2: return @"Click HERE to Generate Links";
    default: return @"";
  }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
  if (section == 2) {
    view.subviews[0].backgroundColor = UIColor.yellowColor;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buildFDLLink)];
    tapRecognizer.delegate = self;
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tapRecognizer];
  }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: return 1;
    case 2: return 2;
    default: {
      // For section 1, the total count is items count plus the number of headers
      long count = _sections.count;
      for (Section *section in _sections) {
        count += section.items.count;
      }
      return count;
    }
  }
}

// Cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case 0: {
      ParamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"param" forIndexPath:indexPath];
      cell.paramLabel.text = Link;
      _dictionary[Link] = cell.paramTextField;
      return cell;
    }
    case 2: {
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"generate" forIndexPath:indexPath];
      if (indexPath.row == 0) {
        cell.textLabel.text = @"Long Link";
        cell.detailTextLabel.text = _longLink.absoluteString;
      } else {
        cell.textLabel.text = @"Short Link";
        cell.detailTextLabel.text = _shortLink.absoluteString;
      }
      return cell;
    }
    default: {
      // Calculate the real section index and row index
      NSInteger section = [self getSectionIndex:indexPath.row];
      NSInteger row = [self getRowIndex:indexPath.row];

      if (row == 0) {
        HeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"header" forIndexPath:indexPath];
        cell.titleLabel.text = _sections[section].name;
        cell.toggleButton.tag = section;
        [cell.toggleButton setTitle:_sections[section].collapsed ? @"+" : @"-" forState:UIControlStateNormal];
        [cell.toggleButton addTarget:self action:@selector(toggleCollapse:) forControlEvents: UIControlEventTouchUpInside];
        return cell;
      } else {
        ParamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"param" forIndexPath:indexPath];
        cell.paramLabel.text = _sections[section].items[row - 1];
        if ([cell.paramLabel.text isEqualToString:BundleID]) {
          cell.paramTextField.text = [NSBundle mainBundle].bundleIdentifier;
        } else if ([cell.paramLabel.text isEqualToString:MinimumAppVersion]) {
          cell.paramTextField.text = @"1.0";
        } else {
          cell.paramTextField.text = nil;    
        }

        _dictionary[cell.paramLabel.text] = cell.paramTextField;
        return cell;
      }
    }
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case 0: return 80.0;
    case 2: return 44.0;
    default: {
      if ([self getRowIndex:indexPath.row] == 0) {
        // Header has fixed height
        return 44.0;
      } else {
        // Calculate the real section index
        NSInteger section = [self getSectionIndex:indexPath.row];
        return _sections[section].collapsed ? 0 : 80.0;
      }
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 2) {
    if (indexPath.row == 0) {
      // copy long link
      if (_longLink) {
        [UIPasteboard generalPasteboard].string = _longLink.absoluteString;
        NSLog(@"Long Link copied to Clipboard");
      } else {
        NSLog(@"Long Link is empty");
      }
    } else {
      // copy short link
      if (_shortLink) {
        [UIPasteboard generalPasteboard].string = _shortLink.absoluteString;
        NSLog(@"Short Link copied to Clipboard");
      } else {
        NSLog(@"Short Link is empty");
      }
    }
  }
}


#pragma mark - Event Handlers

- (void)toggleCollapse:(UIButton *)sender  {
  NSInteger section = sender.tag;
  BOOL collapsed = _sections[section].collapsed;

  // Toggle collapse
  _sections[section].collapsed = !collapsed;

  NSArray<NSNumber *> *indices = [self getHeaderIndices];

  NSInteger start = indices[section].integerValue;
  NSInteger end = start + _sections[section].items.count;

  [self.tableView beginUpdates];

  for (NSInteger i = start; i <= end; i++) {
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  [self.tableView endUpdates];
}

#pragma mark - Helper Functions

- (NSInteger)getSectionIndex:(NSInteger)row {
  NSArray<NSNumber *> *indices = [self getHeaderIndices];

  for (NSInteger i = 0; i < indices.count; i++) {
    if (i == indices.count - 1 || row < indices[i + 1].integerValue) {
      return i;
    }
  }

  return -1;
}

- (NSInteger)getRowIndex:(NSInteger)row {
  NSInteger index = row;
  NSArray<NSNumber *> *indices = [self getHeaderIndices];

  for (NSInteger i = 0; i < indices.count; i++) {
    if (i == indices.count - 1 || row < indices[i + 1].integerValue) {
      index -= indices[i].integerValue;
      break;
    }
  }

  return index;
}

- (NSArray<NSNumber *> *)getHeaderIndices {
  NSInteger index = 0;
  NSMutableArray<NSNumber *> *indices = [[NSMutableArray alloc] initWithCapacity:_sections.count];

  for (Section *section in _sections) {
    [indices addObject:@(index)];
    index += section.items.count + 1;
  }

  return indices;
}



@end
