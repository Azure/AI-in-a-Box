./scripts/loadenv.ps1

# Install InteractiveMenu module
$module = Get-Module -Name "InteractiveMenu" -ListAvailable
if ($module) {
    Update-Module -Name "InteractiveMenu" -Force
}
else {
    Install-Module -Name InteractiveMenu
}

Import-Module InteractiveMenu