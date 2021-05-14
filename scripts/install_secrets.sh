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

# Secret keys do not work for pull requests from forks. See
# https://docs.github.com/en/actions/reference/encrypted-secrets#limits-for-secrets

if [[ ! -z "$secrets_passphrase" ]]; then
  # --batch to prevent interactive command
  # --yes to assume "yes" for questions
  gpg --quiet --batch --yes --decrypt --passphrase="$secrets_passphrase" \
    --output ../scripts/Secrets.tar ../scripts/Secrets.tar.gpg

  tar xvf ../scripts/Secrets.tar
fi
