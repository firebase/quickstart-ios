#!/usr/bin/env bash

set -eo pipefail

EXIT_STATUS=0

if [[ ! -z $encrypted_2858fa01aa14_key ]]; then
    (xcodebuild \
      -workspace ${SAMPLE}/${SAMPLE}Example.xcworkspace \
      -scheme ${SAMPLE}Example${SWIFT_SUFFIX} \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 11' \
      build \
      test \
      ONLY_ACTIVE_ARCH=YES \
      | xcpretty) || EXIT_STATUS=$?
else
    # Skip running tests if GoogleService-Info.plist's weren't decoded.
    (xcodebuild \
      -workspace ${SAMPLE}/${SAMPLE}Example.xcworkspace \
      -scheme ${SAMPLE}Example${SWIFT_SUFFIX} \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 11' \
      build \
      ONLY_ACTIVE_ARCH=YES \
      | xcpretty) || EXIT_STATUS=$?

  exit $EXIT_STATUS
