A/B Testing
========

Firebase A/B Testing leverages Remote Config to automatically trial new app
behaviors and exports the experiment results into Firebase Analytics. This
sample demonstrates using an A/B test to test mutiple color schemes within
an app.

## Quickstart Setup

In Firebase Console, create a new A/B test with any name. In step two under
'Variants', click the 'Add Parameter' button and create a parameter named
`color_scheme`. Set its default value in the control group to `default` and
its value in 'Variant A' to `dark`. In the third step, select any goal metric.

At this point, you can either run the sample and copy the printed Instance ID
token from Xcode's console into the 'Test Device' section in Firebase Console,
or simply run the experiment at a high percentage and reinstall the app
until your app instance is in the A/B test.
