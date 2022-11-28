#!/usr/bin/env bash

# Copyright 2021 Google
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


# Build the quickstart. If we're running on the main repo (not a fork), we
# also run the tests along with the decoded GoogleService-Info.plist files.

set -euo pipefail

# Set default parameters

# Set have_secrets to true or false.
source scripts/check_secrets.sh

# Get Xcode version
system=$(uname -s)
case "$system" in
  Darwin)
    xcode_version=$(xcodebuild -version | head -n 1)
    xcode_version="${xcode_version/Xcode /}"
    xcode_major="${xcode_version/.*/}"
    ;;
  *)
    xcode_major="0"
    ;;
esac

# Initialize flags
flags=()

# Set project / workspace
WORKSPACE="${SAMPLE}/Legacy${SAMPLE}Quickstart/${SAMPLE}Example.xcworkspace"
flags+=( -workspace "$WORKSPACE" )

# Set scheme
SCHEME="${SAMPLE}Example${SWIFT_SUFFIX:-}"

flags+=( -scheme "$SCHEME" )

# Set destination & derivedDataPath
DESTINATION="platform=iOS,name:Any iOS Device"
DERIVEDDATAPATH="build-for-testing/${SCHEME}"
flags+=( -destination "$DESTINATION" -sdk "iphoneos" -derivedDataPath "$DERIVEDDATAPATH")

# Add extra flags
if [[ "$SAMPLE" == Config ]];then
    flags+=( -configuration Debug )
fi

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
xcb "${flags[@]}"
echo "$message"

# Zip build-for-testing into MyTests.zip
cd build-for-testing/${SCHEME}/Build/Products
zip -r MyTests.zip Debug-iphoneos *.xctestrun
echo "build-for-testing/${SCHEME}/Build/Products zipped into MyTests.zip"