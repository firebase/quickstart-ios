# Firebase A/B Testing Quickstart

## Firebase A/B Testing

Firebase A/B Testing leverages Remote Config to automatically trial new app behaviors and exports 
the experiment results into Firebase Analytics. This sample demonstrates using an A/B test to test 
multiple color schemes within an app.

See [OUTLINE.md](OUTLINE.md) for information on the design of the app, screenshots, and symbol 
references.

To view the older Objective-C and Swift quickstarts, view the 
[LegacyABTestingQuickstart](LegacyABTestingQuickstart) directory.

## Getting Started

- [Add Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup)
- [Create Firebase Remote Config Experiment with A/B Testing
](https://firebase.google.com/docs/ab-testing/abtest-config)
- Run the sample on your device or simulator.
    - If your build fails due to package errors, try resetting package caches (File > Swift 
    Packages > Reset Package Caches).
    - On macOS, running the sample can prompt you for your password to allow Keychain access, 
    which will enable Installations to work properly and thus allow you to follow the instructions
    of the [Test on Device](#test-on-device) section. Otherwise, refer to the [Published Experiment
    ](#published-experiment) section below. This prompt appears because the project is signed to 
    run locally, but if you use a proper Signing Certificate then your end users should not see 
    that prompt.
    - On Mac Catalyst, Firebase Installations is not installed, so you won't be able to manage it 
    as a test device. Instead, refer to the [Published Experiment](#published-experiment) section 
    below.

## Create Experiment

In Firebase Console's A/B Testing section, click the `Create experiment` button and select the 
`Remote Config` option. For Basics, provide a name for the experiment and optionally a description.
 For Targeting, select your app using the drop-down and increase the 'Exposure' to 100%. For Goals,
 feel free to choose any metric from the drop-down, such as `Crash-free users`. For Variants, click
 `Choose or create new` underneath 'Parameter', type `color_scheme`, and click the 
`Create parameter` drop-down presented. Under 'Baseline', provide a value of `light` to 
`color_scheme`. Under 'Variant A', provide a value of `dark` to `color_scheme`. Finally, press the 
`Review` button.

## Test on Device

In the Firebase Console's A/B Testing section, click on your experiment. Under 
'Experiment overview', click on the details (vertical dots / ellipsis) to manage your experiment, 
then press 'Manage test devices'. Run the sample and copy the printed installation auth token from 
Xcode's console into the text field, select 'Variant A' from the 'Variant' drop-down, and click the
 'Add' button. After making changes to the A/B test device configuration on the Firebase Console, 
tap the Refresh button to update the UI, or alternatively on iOS 15 pull down on the screen until 
the refresh icon starts rotating.

## Published Experiment

Make sure the experiment is running at a high percentage and reinstall the app until your app 
instance is in the A/B test by chance.

## Support

- [Firebase Support](https://firebase.google.com/support/)

## License

Copyright 2021 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.