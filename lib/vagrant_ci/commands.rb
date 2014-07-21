module Vagrant_ci
    class Commands
        attr_accessor :box_name, :localLocation, :remoteLocation, :artifact_path

        def initialize(build_name, localLocation, remoteLocation, artifact_path )
           @box_name = build_name
           @artifact_path = artifact_path
           @localLocation = localLocation
           @remoteLocation = remoteLocation
        end

        def create_box
            p box_name
            Vagrant_ci::Shell::run "vagrant up #{@box_name} --provision"
        end

        def destroy_box
            puts "Destorying: #{@box_name}"
            Vagrant_ci::Shell::run "vagrant destroy -f #{@box_name}"
        end

        def get_artifact_and_destroy
            begin
                get_file_from_vagrant_box
            ensure
                Vagrant_ci::Shell::run "vagrant destroy -f #{@box_name}"
            end
        end

        def execute(command)
            Vagrant_ci::Shell::run "vagrant ssh #{@box_name} --command \"cd #{@remoteLocation} && #{command}\""
        end

        def copy_file_to_vagrant_box
              serverIp = get_ssh_details(/(?<=HostName ).*/, @box_name)
              scp(@localLocation,"vagrant@#{serverIp}:#{@remoteLocation}", @box_name)
        end

        def get_file_from_vagrant_box
            serverIp = get_ssh_details(/(?<=HostName ).*/,@box_name)
            scp("vagrant@#{serverIp}:#{@remoteLocation}" ,@localLocation, @box_name)
        end
private
        def scp(from, to, box_name)
            portNum = get_ssh_details(/(?<=Port ).*/,box_name)
            keyPath = get_ssh_details(/(?<=IdentityFile ).*/,box_name)

            Vagrant_ci::Shell::run "scp -o 'StrictHostKeyChecking no' -i #{keyPath} -P #{portNum} -r #{from} #{to}"
        end

        def get_ssh_details(regex, box_name)
            response = `vagrant ssh-config #{box_name}`
            return response.match(regex)
        end
    end
end
