require 'xcodeproj'

# Class that contains methods for pre-processing xcode project files.
#
class XCodeProjProcessor

  CID = 'CLIENT_ID'.freeze
  RCID = 'REVERSED_CLIENT_ID'.freeze
  DOMAIN_PLACEHODLER = 'YOUR_DYNAMIC_LINK_DOMAIN'.freeze
  G_PLIST = /GoogleService-Info.plist/.freeze

    # Class constructor.
    # @param  [Array<String>] args
    #         Arguments passed to the script.
    #
  def initialize(args)
    if !args.key?('project')
      abort("Project flag should be set!")
    end

    @args = args
    @project_path = args['project']
    @files_to_add = args['files']&.split(',') || []
    @frameworks_to_add = args['frameworks']&.split(',') || []
    @resources_to_add = args['resources']&.split(',') || []
    @project =  Xcodeproj::Project.open(@project_path)
    @target_name = args['target'] || ""
    @new_file_group = @project.new_group('Files-'+ @target_name)
    @extra_flags =  args['extras']&.split(',') || []
  end

    # Returns whether unit tests should be disabled.
  def disable_init_tests?
    @args.key?("disable_unit_tests")
  end

    # Returns whether ui tests should be disabled.
  def disable_ui_tests?
    @args.key?("disable_ui_tests")
  end

    # Disables certain type of targets.
    # @param  [Symbol] type
    #         The type of the target expressed as a symbol.
    #
  def disable_tests_by_type(type)
     @project.targets.find_all do |target|
       target.symbol_type == type
     end.each(&:remove_from_project)
  end

    # Returns whether frameworks are specified.
  def has_frameworks?
    !@frameworks_to_add.empty?
  end

   # Returns whether resources are specified.
  def has_resources?
    !@resources_to_add.empty?
  end

    # Saves current project.
  def save
    @project.save(@project_path)
  end

    # Adds REVERSED_CLIENT_ID to the list of known URL Schemes.
    # This is a standard step for various Firebase SDKs.
    # @param  [#to_s] source
    #         The absolute path to the REVERSED_CLIENT_ID provider.
    #
    # @param  [#to_s] target
    #         The absolute path to the Info.plist.
    #
  def self.add_reverse_client_id(source, target)
    source_hsh =  Xcodeproj::Plist.read_from_path(source)
    rcid = source_hsh[RCID]
    abort("Can't find #{RCID} in file #{source}") unless rcid

    target_hsh =  Xcodeproj::Plist.read_from_path(target)
    url_types = {'CFBundleURLTypes' => [{'CFBundleTypeRole' => 'Editor',
                                         'CFBundleURLName' => 'Client',
                                         'CFBundleURLSchemes' =>  [rcid]}]}
    Xcodeproj::Plist.write_to_path(target_hsh.merge(url_types), target)
  end

    # Dumps important properties of Xcodeproj::Project.
  def dump_configuration
    puts <<-EOT
----------- FILES -----------
#{@project.files.map(&:path)}
----------- BUILD CONFIGURATIONS -----------
#{@project.build_configurations.map(&:pretty_print)}
----------- TARGET CONFIGURATIONS -----------
#{@project.targets.map { |target| {target.name =>
target.build_configuration_list
.build_configurations.map(&:build_settings)}}}
----------- FRAMEWORKS -----------
#{@project.targets.map { |target| {target.name =>
target.frameworks_build_phase.files_references.map(&:pretty_print)}}}
----------- RESOURCES -----------
#{@project.targets.map { |target| {target.name =>
target.resources_build_phase.files_references.map(&:pretty_print)}}}
EOT
  end

    # Adds files to current project (passed as arguments to the script).
  def add_files_to_project(files = @files_to_add)
    files.each do |file_path|
      file_to_add = @new_file_group.new_file(file_path)
      @project.native_targets.each do |target|
        # If the name of the target contains the target flag, we'll add the file.
        # If no target flag was passed, it will be added to all targets.
        if target.name[@target_name]
          target.add_file_references([file_to_add])
        end
      end
    end
  end

    # Adds frameworks to current project (passed as arguments to the script).
    # @param  [Boolean] test_targets
    #         Whether or not scrypt adds frameworks to test targets.
    #
  def add_frameworks_to_project(test_targets=false)
    return unless has_frameworks?
    add_files_to_project(@frameworks_to_add)
    @frameworks_to_add.each do |file_path|
      file_to_add = @new_file_group.new_file(file_path)
      @project.native_targets.each do |target|
        if test_targets || !target.test_target_type?
          target.frameworks_build_phases.add_file_reference(file_to_add)
        end
      end
    end
  end

    # Adds resources to current project (passed as arguments to the script).
    # @param  [Boolean] test_targets
    #         Whether or not scrypt adds resources to test targets.
    #
  def add_resources_to_project(test_targets=false)
    return unless has_resources?
    add_files_to_project(@resources_to_add)
    @resources_to_add.each do |file_path|
      file_to_add = @new_file_group.new_file(file_path)
      @project.native_targets.each do |target|
        if test_targets || !target.test_target_type?
          target.resources_build_phase.add_file_reference(file_to_add)
        end
      end
    end
  end

    # Add information taken from GoogleService-Info.plist.
  def modify_info_plist
    gplist = @files_to_add.find{ |pl|  pl =~ G_PLIST }
    return unless gplist
    abs_project_path = File.dirname(@project_path)
    # Add REVERSED_CLIENT_ID to Info.plist
    info_plist = File.join(abs_project_path,  @project.targets.first.to_s, 'Info.plist')
    if @extra_flags.include?('add_reversed_client_id') && File.exist?(info_plist)
      XCodeProjProcessor.add_reverse_client_id(gplist, info_plist)
    end
  end

   # Remove GoogleService-Info.plist from the resources to build.
  def remove_existing_google_plist
    to_remove = @project.files.find { |file|  file.path =~ G_PLIST}
    @project.targets.each do |target|
      target.resources_build_phase.remove_file_reference(to_remove)
    end if to_remove
  end
end

# Parse the arguments into a hash map.
args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
xcproject = XCodeProjProcessor.new(args)

# Main body of the script.
if xcproject.disable_init_tests?
  xcproject.disable_tests_by_type(:unit_test_bundle)
elsif xcproject.disable_ui_tests?
  xcproject.disable_tests_by_type(:ui_test_bundle)
else
  xcproject.remove_existing_google_plist
  xcproject.add_files_to_project
  xcproject.add_frameworks_to_project
  xcproject.add_resources_to_project
  xcproject.modify_info_plist
end

xcproject.dump_configuration
xcproject.save

