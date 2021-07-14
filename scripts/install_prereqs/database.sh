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

while test $# -gt 0; do
  case "$1" in
    --build-only)
      export BUILD_ONLY=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

IMPORT_DUMMY_PLIST=$BUILD_ONLY \
DIRECTORY=database \
PROJECT=Database \
. ../scripts/prereq_core.sh
