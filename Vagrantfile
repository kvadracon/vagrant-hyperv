NETWORK = "192.168.0.0"
GW = "192.168.0.1"
PREF = "24"
DNS = "1.1.1.1"

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

# Require YAML module
require 'yaml'

# Read YAML file with box details
servers = YAML.load_file('servers.yaml')

# Create boxes
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "hyperv" do |h, override|
    h.enable_virtualization_extensions = true
    h.linked_clone = true
    override.vm.synced_folder ".", "/vagrant", disabled: true
  end
  # Iterate through entries in YAML file
  servers.each do |servers|
    config.vm.define servers["name"] do |srv|
      srv.vm.box = servers["box"]
      vhostname = servers["name"]
      # First connect to Default Switch network
      vm_exists = system("powershell.exe", "-Command", "Get-VM -VMNAME vhostname -ErrorAction SilentlyContinue | out-null")
      if !vm_exists
        srv.vm.network "private_network", bridge: "Default Switch"
      end
      srv.vm.provider "hyperv" do |hv|
        hv.memory = servers["ram"]
        hv.cpus = servers["cpu"]
        hv.vmname = servers["name"]
      end
      # Configure static ip script
      srv.vm.provision "shell" do |sh|
        sh.path = "./.scripts/configure-static-ip.sh"
        sh.args = [servers["ip"], GW, PREF, DNS]
      end
      # Install apps script
      srv.vm.provision :shell, path: servers["script"]  
      # Change connect to NATSwitch static IP network
      srv.trigger.after :reload, :up do |trigger| 
        trigger.info = "Setting Hyper-V switch to 'NATSwitch' to allow for static IP..."
        trigger.run = {
          privileged: "true", 
          powershell_elevated_interactive: "true", 
          path: "./.scripts/set-hyperv-switch.ps1", 
          args: [servers["name"], servers["ip"]]
      }
      end
    end
  end
  # Create static network switch before start VMs
  config.trigger.before :up do |trigger|
    trigger.info = "Creating SWITCHNAME Hyper-V switch if it does not exist..."
    trigger.run = {
      privileged: "true", 
      powershell_elevated_interactive: "true", 
      path: "./.scripts/create-nat-hyperv-switch.ps1", 
      args: [GW, NETWORK, PREF]
    }
  end
end


