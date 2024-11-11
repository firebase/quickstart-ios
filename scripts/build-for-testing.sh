#!/usr/bin/env bash

# Copyright 2022 Google
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script is modified from test.sh. It's possible it into merge into test.sh
# This script build the quickstart artifacts to run tests on Firebase Test Lab. 
# If we're running on the main repo (not a fork), we also run the tests along 
# with the decoded GoogleService-Info.plist files.

set -euo pipefail

# Set default parameters
if [[ -z "${SPM:-}" ]]; then
    SPM=false
    echo "Defaulting to SPM=$SPM"
    if [[ -z "${LEGACY:-}" ]]; then
        LEGACY=false
        echo "Defaulting to LEGACY=$LEGACY"
    fi
fi

# Set have_secrets to true or false.
source scripts/check_secrets.sh

# Initialize flags
flags=()

# Set project / workspace
if [[ "$SPM" == true ]];then
    flags+=( -project "${DIR}/${SAMPLE}Example.xcodeproj" )
else
    if [[ "$LEGACY" == true ]]; then
        WORKSPACE="${SAMPLE}/Legacy${SAMPLE}Quickstart/${SAMPLE}Example.xcworkspace"
    else
        WORKSPACE="${SAMPLE}/${SAMPLE}Example.xcworkspace"
    fi
    flags+=( -workspace "$WORKSPACE" )
fi

# Set scheme
if [[ -z "${SCHEME:-}" ]]; then
    if [[ "$SPM" == true ]];then
        SCHEME="${SAMPLE}Example (${OS})"
    else
        SCHEME="${SAMPLE}Example${SWIFT_SUFFIX:-}"
    fi
fi

flags+=( -scheme "$SCHEME" )

# Set derivedDataPath
DERIVEDDATAPATH="build-for-testing/${SCHEME}"
flags+=( -sdk "iphoneos" -derivedDataPath "$DERIVEDDATAPATH")

# Add extra flags
if [[ "$SAMPLE" == Config ]];then
    flags+=( -configuration Debug )
fi

# NOTE: Add your code signature details here for running tests in Firebase Test Lab
flags+=(
    CODE_SIGN_IDENTITY=""
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
    build-for-testing
)

# Check whether to test on top of building
message="Tests did not run."

function xcb() {
    echo xcodebuild "$@"
    xcodebuild "$@" | xcpretty
}

# Run xcodebuild
sudo xcode-select -s /Applications/Xcode_15.3.app/Contents/Developer
xcb "${flags[@]}"
echo "$message"

# Zip build-for-testing into MyTests.zip
cd "build-for-testing/${SCHEME}/Build/Products"
zip -r MyTests.zip Debug-iphoneos ./*.xctestrun
echo "build-for-testing/${SCHEME}/Build/Products zipped into MyTests.zip"
