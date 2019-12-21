# Copyright 2019 Google
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

# Set up secrets to get the GoogleService-Info.plist files.

# This does not work for pull requests from forks. See
# https://docs.travis-ci.com/user/pull-requests#pull-requests-and-security-restrictions
if [[ ! -z $encrypted_d6a88994a5ab_key ]]; then
  openssl aes-256-cbc -K $encrypted_2858fa01aa14_key -iv $encrypted_2858fa01aa14_iv \
  -in scripts/Secrets.tar.enc -out scripts/Secrets.tar -d

  tar xvf scripts/Secrets.tar
  cd Secrets/quickstart-ios
  for dir in *; do
    cp $dir/GoogleService-Info.plist ../../$dir
  done
fi
