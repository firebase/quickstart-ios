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
require 'optparse'

options = {}
options[:source_tree] = "SOURCE_ROOT"
options[:file_ext] = "xcframework,framework,dylib"
OptionParser.new do |opt|
  opt.on('--sdk SDK') { |o| options[:sdk] = o }
  opt.on('--target TARGET') { |o| options[:target] = o }
  opt.on('--framework_path FRAMEWORK_PATH') { |o| options[:framework_path] = o }
  opt.on('--source_tree SOURCE_TREE') { |o| options[:source_tree] = o }
  opt.on('--file_ext FILE_EXT') { |o| options[:file_ext] = o}
end.parse!
sdk = options[:sdk]
target_name = options[:target]
framework_path = options[:framework_path]
source_tree = options[:source_tree]
file_ext = options[:file_ext]
project_path = "#{sdk}Example.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Find the target.
target = project.targets.find { |t| t.name == target_name }

# Check if the target exists.
unless target
  STDERR.puts "Error: Target '#{target_name}' not found in project '#{project_path}'."
  exit 1
end

project_framework_group = project.frameworks_group

def add_ref(group, path, source_tree, phase_list)
  ref = group.new_reference("#{path}")
  ref.name = "#{File.basename(path)}"
  ref.source_tree = source_tree
  phase_list.each do |phase|
    build_file = phase.add_file_reference(ref)
    # In Xcode 15+, the following settings should be applied when embedding
    # static frameworks. This will will enable Xcode to strip out the
    # framework's static archive and headers, so that only the framework's
    # resources remain.
    if phase.isa == 'PBXCopyFilesBuildPhase' && phase.name == "Embed Frameworks"
      build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
    end
  end
  puts ref
end

if File.directory?(framework_path)
  if framework_path.end_with?("bundle")
    puts "The following bundle is added to #{target.name}"
    add_ref(project.main_group,
            framework_path,
            source_tree,
            [target.resources_build_phase])
  else
    framework_group = Dir.glob(File.join(framework_path, "*.{#{file_ext}}"))

    framework_set = target.frameworks_build_phase.files.to_set
    puts "The following frameworks are added to #{target.name}"
    embed_frameworks_phase = target.new_copy_files_build_phase("Embed Frameworks")
    embed_frameworks_phase.dst_subfolder_spec = "10" # `Frameworks` directory
    framework_group.each do |framework|
      next if framework_set.size == framework_set.add(framework).size
      add_ref(project_framework_group,
              framework,
              source_tree,
              [target.frameworks_build_phase, embed_frameworks_phase])
    end
  end
else
  puts "The following file is added to #{target.name}"
  add_ref(project_framework_group,
          framework_path,
          source_tree,
          [target.frameworks_build_phase])
end
project.save()
