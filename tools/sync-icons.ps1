param([string[]]$Mod)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force
$projects = @(Get-ModProjects -Mod $Mod)

foreach ($project in $projects) {
    $script = Join-Path $project.FullPath 'tools\sync-icons.ps1'
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        & $script
    }
    else {
        Write-Host "No icon sync script for $($project.slug); skipped."
    }
}
