[CmdletBinding(DefaultParameterSetName = 'Mod')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Mod')] [string]$Mod,
    [Parameter(Mandatory, ParameterSetName = 'All')] [switch]$All,
    [string]$DestinationRoot = (Join-Path $env:USERPROFILE 'Zomboid\Workshop')
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force
$projects = if ($All) {
    @(Get-ModProjects)
}
else {
    @(Get-ModProjects -Mod $Mod)
}

$resolvedDestinationRoot = [System.IO.Path]::GetFullPath($DestinationRoot)
foreach ($project in $projects) {
    $destination = Join-Path $resolvedDestinationRoot $project.packageName
    & (Join-Path $project.FullPath 'tools\deploy.ps1') -Destination $destination
}

Write-Host "Deployed and verified $($projects.Count) mod(s) at $resolvedDestinationRoot"
