#!/usr/bin/env ruby

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

require 'xcodeproj'
sample = ARGV[0]
project_path = "#{sample}Example.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Add a file to the project in the main group
file_name = 'GoogleService-Info.plist'
file = project.new_file(file_name)

# Add the file to the all targets
project.targets.each do |target|
  target.add_file_references([file])
end

#save project
project.save()
