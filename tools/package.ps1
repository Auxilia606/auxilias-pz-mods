param(
    [string[]]$Mod,
    [string]$OutputDirectory,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force

$repoRoot = Get-MonorepoRoot
$projects = @(Get-ModProjects -Mod $Mod)
& (Join-Path $PSScriptRoot 'validate.ps1') -Mod $projects.slug

foreach ($project in $projects) {
    $projectOutput = if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        Join-Path $repoRoot "dist\$($project.slug)"
    }
    else {
        [System.IO.Path]::GetFullPath($OutputDirectory)
    }
    $packageScript = Join-Path $project.FullPath 'tools\package.ps1'
    & $packageScript -OutputDirectory $projectOutput -Force:$Force
}

Write-Host "Packaged $($projects.Count) mod(s)."
