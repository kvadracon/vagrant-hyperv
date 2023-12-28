param (
    [parameter (Mandatory=$true)]
    [string]$vmName,
    [parameter (Mandatory=$true)]
    [string]$staticIP
)

$restartRequired = 0
$startTimeout = 20
$stopTimeout = 10

if (Get-VM -VMName $vmName -ErrorAction SilentlyContinue) {
  if (Get-VM -VMNAME $vmName | Where-Object {$_.State -eq "Running"}) {
    $vagrantIP = (Get-VM -VMName $vmName | Get-VMNetworkAdapter).IpAddresses | Select -first 1

    Write-Host "Validate IP configuration"
    # Set fixed IP inside the VM
    if ($vagrantIP -And $vagrantIP -ne "$staticIP") {

      # If the private key is owned by anyone other then current user, ssh will not accept it
      Write-Host "IP configuration of network adapter eth0 incorrect... Restart required"
      $restartRequired = 1
    }

    Write-Host "Validate Switch configuration"
    if ("VagrantSwitch" -in (Get-VM -Name $vmName | Get-VMNetworkAdapter | Select-Object -ExpandProperty SwitchName) -eq $FALSE) {
      Write-Host "Switch configuration is incorrect... Restart required"
      $restartRequired = 1
    }

    # Restart if needed
    if ($restartRequired) {
      Write-Host "Restarting VM $vmName to finalize static ip configuration"
      
      # Stop
      Stop-VM -Name $vmName
      Write-Host "Stopping VM $vmName"
      For ($i=0; $i -le $stopTimeout; $i++) { 
        if (Get-VM -VMNAME $vmName | Where-Object {$_.State -eq "off"}) { sleep 1 } else { break } 
      }      
      
      # Switch switch :) when the vm is stopped, otherwise stop action takes a long time
      Write-Host "Associate VM $vmName with switch NATSwitch"
      Get-VM -VMNAME $vmName | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "NATSwitch"
      
      # Start
      Start-VM -Name $vmName
      Write-Host "Starting VM $vmName"
      For ($i=0; $i -le $startTimeout; $i++) { 
        if (Get-VM -VMNAME $vmName | Where-Object {$_.State -eq "Running"}) { sleep 1 } 
        else { break } 
      }
      Write-Host "VM IP address $staticIP"
    } else {
      Write-Host "VM has already a fixed IP: $staticIP"
    }
    #
  } else {
    throw "ERROR: VM needs to be running to set a fixed IP."
  }
}