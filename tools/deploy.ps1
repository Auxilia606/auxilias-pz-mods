param(
    [Parameter(Mandatory)] [string]$Mod,
    [string]$DestinationRoot = (Join-Path $env:USERPROFILE 'Zomboid\Workshop')
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force
$project = @(Get-ModProjects -Mod $Mod)
if ($project.Count -ne 1) {
    throw 'Deploy accepts exactly one mod slug.'
}

$destination = Join-Path ([System.IO.Path]::GetFullPath($DestinationRoot)) $project[0].packageName
& (Join-Path $project[0].FullPath 'tools\deploy.ps1') -Destination $destination
