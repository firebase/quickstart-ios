#!/bin/sh

# Copyright 2020 Google
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


# Check if secrets are available for multiple CI's. It may have be already
# set when this script is called from the firebase-ios-sdk's CI.

check_secrets()
{
  if [[ "${have_secrets:-}" != true ]]; then
    have_secrets=false

    # GitHub Actions: Secrets are available if we're not running on a fork
    # or in a pull request context.
    # https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-environment-variables
    if [[ -n "${secrets_passphrase:-}" ]]; then
      have_secrets=true
    fi
  fi
}
check_secrets
