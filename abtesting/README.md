A/B Testing
========

Firebase A/B Testing leverages Remote Config to automatically trial new app
behaviors and exports the experiment results into Firebase Analytics. This
sample demonstrates using an A/B test to test multiple color schemes within
an app.

## Create Experiment

In Firebase Console's A/B Testing section, click the `Create experiment` button
and select the `Remote Config` option. For Basics, provide a name for the experiment
and optionally a description. For Targeting, select your app using the drop-down
and increase the 'Exposure' to 100%. For Goals, feel free to choose any metric from
the drop-down, such as `Crash-free users`. For Variants, click `Choose or create new`
underneath 'Parameter', type `color_scheme`, and click the `Create parameter`
drop-down presented. Under 'Baseline', provide a value of `light` to `color_scheme`.
Under 'Variant A', provide a value of `dark` to `color_scheme`. Finally, press the
`Review` button.

## Test on Device

In the Firebase Console's A/B Testing section, click on your experiment. Under
'Experiment overview', click on the details (vertical dots / ellipsis) to manage your
experiment, then press 'Manage test devices'. Run the sample and copy the printed
installation auth token from Xcode's console into the text field, select 'Variant A'
from the 'Variant' drop-down, and click the 'Add' button. After making changes
to the A/B test device configuration on the Firebase Console, tap the Refresh
button to update the UI, or alternatively on iOS 15 pull down on the screen until
the refresh icon starts rotating.

## Published Experiment

Make sure the experiment is running at a high percentage and reinstall the app until your app
instance is in the A/B test by chance.
