param (
    [parameter (Mandatory=$true)]
    [string]$IPAddress,
    [parameter (Mandatory=$true)]
    [string]$NATNetwork,
    [parameter (Mandatory=$true)]
    [string]$PrefLen
)

If ("NATSwitch" -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    Write-Host "Creating Internal-only switch named NATSwitch on Windows Hyper-V host..."

    New-VMSwitch -SwitchName "NATSwitch" -SwitchType Internal

    New-NetIPAddress -IPAddress "$IPAddress" -PrefixLength "$PrefLen" -InterfaceAlias "vEthernet (NATSwitch)"

    New-NetNAT -Name "NATSwitch" -InternalIPInterfaceAddressPrefix "$NATNetwork/$PrefLen"
}
else {
    Write-Host "NATSwitch for static IP $IPAddress configuration already exists; skipping"
}

If ("$IPAddress" -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress) -eq $FALSE) {
    Write-Host "Registering new IP $IPAddress address on Windows Hyper-V host..."

    New-NetIPAddress -IPAddress "$IPAddress" -PrefixLength "$PrefLen" -InterfaceAlias "vEthernet (NATSwitch)"
}
else {
    Write-Host "Address $IPAddress for static IP configuration already registered; skipping"
}

If ("$NATNetwork/$PrefLen" -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix) -eq $FALSE) {
    Write-Host "Registering new NAT adapter for ($NATNetwork/$PrefLen) on Windows Hyper-V host..."

    New-NetNAT -Name "NATSwitch" -InternalIPInterfaceAddressPrefix "$NATNetwork/$PrefLen"
}
else {
    Write-Host "Network $NATNetwork/$PrefLen for static IP configuration already registered; skipping"
}