require 'vagrant_commands'

module Vagrant_ci
    class Runner
        attr_accessor :build_name

        def initialize(build_name)
            @build_name = build_name
        end

        def run(task_list)
            begin
                heartbeat = Vagrant_ci::Jenkins::heartbeat

                puts "Creating Vagrantbox for Process ID: #{Process.pid}"

                vagrant_commands = Vagrant_ci::Commands.new(@build_name, project_location, remoteLocation, artifact_path)

                vagrant_commands.create_box
                vagrant_commands.copy_file_to_vagrant_box

                task_list.each { |task| vagrant_commands.execute(task) }
            ensure
                vagrant_commands.get_artifact_and_destroy
                heartbeat.terminate
            end
        end

        def config_vagrant(vm_image_location, vagrant_file_path, provider = "vmware", version = 0 )
            begin
                heartbeat = Vagrant_ci::Jenkins::heartbeat

                box_name = File.basename(vm_image_location, ".*" )

                box = Boxes::VagrantBox.new(box_name, provider, version, vm_image_location)
                Boxes::install_box_if_missing(box)

                insert_build_config_into_vagrantfile(vagrant_file_path, box_name, vm_image_location)
            ensure
                heartbeat.terminate
            end
        end
private

        def insert_build_config_into_vagrantfile(vagrant_file_path, vm_name, box_url)

            check_or_generate_vagrantfile(vagrant_file_path, vm_name, box_url)

            unless File.read(vagrant_file_path).include? @build_name
                File.open(vagrant_file_path, 'r+') do |f|
                    f.seek(-4,IO::SEEK_END)
                    f.puts Vagrant_ci::Vagrantfile::box_config(vm_name, box_url, @build_name)
                    f.puts 'end'
                end
            end
        end

        def check_or_generate_vagrantfile(vagrant_file_path, vm_name, box_url)
            unless File.exist?(vagrant_file_path)
                show_gui = ENV['VAGRANT_GUI'] || false
                vagrant_template = Vagrant_ci::Vagrantfile.new(vm_name, box_url, @build_name)
                File.open(vagrant_file_path, 'w') {|file| file.puts vagrant_template.render }
            end
        end

        def remoteLocation
            ENV['VAGANT_REMOTE_DEST'] || 'vagrant_build'
        end

        def artifact_path
            ENV['ARTIFACT_PATH'] || 'ci-artifacts'
        end

        def project_location
            ENV['PROJECT_LOCATION'] || './'
        end
    end
end