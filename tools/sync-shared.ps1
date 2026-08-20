param([string[]]$Mod)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force

$repoRoot = Get-MonorepoRoot
$target = Get-GameTarget
$projects = @(Get-ModProjects -Mod $Mod)
$copied = 0

foreach ($project in $projects) {
    $versionRoot = Join-Path $project.FullPath "workshop\Contents\mods\$($project.modId)\$($target.releaseLine)"
    foreach ($mapping in @($project.sharedLua)) {
        $source = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $repoRoot 'shared\lua') $mapping.source))
        $destination = [System.IO.Path]::GetFullPath((Join-Path $versionRoot $mapping.destination))
        $sourceRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'shared\lua')).TrimEnd('\') + '\'
        $destinationRoot = [System.IO.Path]::GetFullPath($versionRoot).TrimEnd('\') + '\'
        if (-not $source.StartsWith($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Shared Lua source escapes shared/lua: $($mapping.source)"
        }
        if (-not $destination.StartsWith($destinationRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Shared Lua destination escapes the mod version root: $($mapping.destination)"
        }
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Shared Lua source not found: $source"
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Force
        $copied++
    }
}

Write-Host "Synchronized $copied shared Lua file(s) across $($projects.Count) mod(s)."
