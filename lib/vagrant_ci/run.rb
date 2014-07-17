require 'vagrant_commands'

module Vagrant_ci
    module Provider
        VMWARE="vmware"
        VIRTUALBOX="virtualbox"
    end

    def self.config_vagrant(build_name, name, provider, version, vm_image_location, vagrant_file_path)
        begin
            heartbeat = Vagrant_ci::Jenkins::heartbeat

            box = Boxes::VagrantBox.new(name, provider, version, vm_image_location)
            Boxes::install_box_if_missing(box)

            check_or_generate_vagrantfile(build_name, name, vagrant_file_path)
            insert_build_config_into_vagrantfile(build_name, name, vagrant_file_path)
        ensure
            heartbeat.terminate
        end
    end

    def self.run(build_name, task_list)
        begin
            heartbeat = Vagrant_ci::Jenkins::heartbeat

            puts "Creating Vagrantbox for Process ID: #{Process.pid}"

            vagrant_commands = Vagrant_ci::Commands.new(build_name, project_location, remoteLocation, artifact_path)

            vagrant_commands.create_box
            vagrant_commands.copy_file_to_guest

            task_list.each { |task| vagrant_commands.execute(task) }
        ensure
            vagrant_commands.get_artifact_and_destroy
            heartbeat.terminate
        end
    end

    def self.check_or_generate_vagrantfile(build_name, vagrant_file_path)
        unless File.exist?(vagrant_file_path)
            show_gui = ENV['VAGRANT_GUI'] || false
            vagrant_template = Vagrant_ci::Vagrantfile.new()
            File.open(vagrant_file_path, 'w') {|file| file.puts vagrant_template.render }
        end
    end

    def self.insert_build_config_into_vagrantfile(build_name, vm_name, box_url)
        unless File.read(vagrant_file_path).include? "#{build_name}"
            File.open(vagrant_file_path, 'r+') do |f|
                f.seek(-4,IO::SEEK_END)
                f.puts Vagrant_ci::Vagrantfile::box_config(build_name, vm_name, box_url)
                f.puts 'end'
            end
        end
    end

    private

    def self.remoteLocation
        ENV['VAGANT_REMOTE_DEST'] || 'vagrant_build'
    end

    def self.artifact_path
        ENV['ARTIFACT_PATH'] || 'ci-artifacts'
    end

    def self.project_location
        ENV['PROJECT_LOCATION'] || './'
    end
end