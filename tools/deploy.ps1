param(
    [string]$Destination = 'C:\Users\USER\Zomboid\Workshop\AuxiliasCrossbow'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'workshop')).Path
$expected = [System.IO.Path]::GetFullPath('C:\Users\USER\Zomboid\Workshop\AuxiliasCrossbow')
$resolvedDestination = [System.IO.Path]::GetFullPath($Destination)

if ($resolvedDestination -ne $expected) {
    throw "Refusing unexpected deployment target: $resolvedDestination"
}
if (-not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Workshop source not found: $source"
}

New-Item -ItemType Directory -Path $resolvedDestination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'workshop.txt') -Destination $resolvedDestination -Force
Copy-Item -LiteralPath (Join-Path $source 'preview.png') -Destination $resolvedDestination -Force
Copy-Item -LiteralPath (Join-Path $source 'Contents') -Destination $resolvedDestination -Recurse -Force

Write-Host "Deployed Auxilia's Crossbow to $resolvedDestination"

