require 'erb'

BOX_ERB = %q{
    c.vm.define '<%=build_name%>' do |con|
        con.vm.box = '<%=vm_name%>'
        con.vm.box_url = '<%=box_url%>'
        con.vm.hostname = '<%=build_name%>.vagrantup.com'
    end
}

VAGRANT_TEMPLATE = %q{
    VAGRANTFILE_API_VERSION = "2"

    Vagrant.configure(VAGRANTFILE_API_VERSION) do |c|
        c.ssh.forward_agent = true
        c.vm.synced_folder ".", "/vagrant", :disabled => true
        c.vm.provider "vmware_fusion" do |p|
            p.gui = <%= gui_enabled %>
        end
        <%= build_configs%>
    end
}

module Vagrant_ci
    class Vagrantfile

        attr_accessor :build_configs, :gui_enabled

        def initialize(vm_name, box_url, build_name)
            @gui_enabled = false
            @build_configs = Vagrant_ci::Vagrantfile::box_config(build_name, vm_name, box_url)
        end

        def render
            ERB.new(VAGRANT_TEMPLATE).result(binding)
        end

        def self.box_config(build_name, vm_name, box_url)
            ERB.new(BOX_ERB).result(binding)
        end
    end
end