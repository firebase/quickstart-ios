#!/usr/bin/env ruby

# Copyright 2020 Google LLC
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
require 'set'
sdk = ARGV[0]
target = ARGV[1]
framework_dir = ARGV[2]
project_path = "#{sdk}Example.xcodeproj"
project = Xcodeproj::Project.open(project_path)
framework_group = Dir.glob(File.join(framework_dir ,"*{framework,dylib}"))

project.targets.each do |project_target|
  next unless project_target.name == target
  project_framework_group = project.frameworks_group
  framework_build_phase = project_target.frameworks_build_phase
  framework_set = project_target.frameworks_build_phase.files.to_set
	puts "The following frameworks are added to #{project_target}"
  framework_group.each do |framework|
    next if framework_set.size == framework_set.add(framework).size
    ref = project_framework_group.new_reference("#{framework}")
    ref.name = "#{File.basename(framework)}"
    ref.source_tree = "SOURCE_ROOT"
    framework_build_phase.add_file_reference(ref)
    puts ref
  end
end
project.save()
