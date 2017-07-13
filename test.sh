#!/usr/bin/env bash

set -eo pipefail

EXIT_STATUS=0

(xcodebuild \
  -workspace FirebaseUI.xcworkspace \
  -scheme FirebaseUI \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=10.3.1,name=iPhone 7' \
  build \
  test \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_REQUIRED=NO \
  | xcpretty) || EXIT_STATUS=$?
  
  exit $EXIT_STATUS
