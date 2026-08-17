param(
    [string]$Destination = 'C:\Users\USER\Zomboid\Workshop\AuxiliasCrossbow'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'workshop')).Path
$validateScript = Join-Path $PSScriptRoot 'validate.ps1'
$resolvedDestination = [System.IO.Path]::GetFullPath($Destination)
$normalizedDestination = [System.IO.Path]::TrimEndingDirectorySeparator($resolvedDestination)
$destinationName = [System.IO.Path]::GetFileName($normalizedDestination)
$destinationParent = [System.IO.Path]::GetDirectoryName($normalizedDestination)

if ($destinationName -ne 'AuxiliasCrossbow' -or [string]::IsNullOrWhiteSpace($destinationParent)) {
    throw "Deployment target must be a dedicated AuxiliasCrossbow directory: $resolvedDestination"
}
if ($normalizedDestination -eq [System.IO.Path]::GetPathRoot($normalizedDestination)) {
    throw "Refusing filesystem-root deployment target: $resolvedDestination"
}
if (-not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Workshop source not found: $source"
}

function Assert-NoReparsePoint {
    param([Parameter(Mandatory)] [string] $Root)

    if (-not (Test-Path -LiteralPath $Root)) {
        return
    }

    $rootItem = Get-Item -LiteralPath $Root -Force
    $reparsePoints = @($rootItem) + @(Get-ChildItem -LiteralPath $Root -Recurse -Force)
    $reparsePoints = @($reparsePoints | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint })
    if ($reparsePoints.Count -gt 0) {
        throw "Refusing deployment tree containing a symbolic link or junction: $($reparsePoints[0].FullName)"
    }
}

function Get-TreeManifest {
    param([Parameter(Mandatory)] [string] $Root)

    $rootPath = [System.IO.Path]::TrimEndingDirectorySeparator([System.IO.Path]::GetFullPath($Root))
    return @(
        Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force |
            ForEach-Object {
                [pscustomobject]@{
                    Path = [System.IO.Path]::GetRelativePath($rootPath, $_.FullName).Replace('\', '/')
                    Length = $_.Length
                    Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                }
            } |
            Sort-Object Path
    )
}

function Assert-TreeMatches {
    param(
        [Parameter(Mandatory)] [string] $ExpectedRoot,
        [Parameter(Mandatory)] [string] $ActualRoot
    )

    $expected = @(Get-TreeManifest -Root $ExpectedRoot)
    $actual = @(Get-TreeManifest -Root $ActualRoot)
    if ($expected.Count -ne $actual.Count) {
        throw "Deployment manifest count mismatch: source=$($expected.Count), destination=$($actual.Count)"
    }
    for ($index = 0; $index -lt $expected.Count; $index++) {
        if ($expected[$index].Path -ne $actual[$index].Path -or
            $expected[$index].Length -ne $actual[$index].Length -or
            $expected[$index].Hash -ne $actual[$index].Hash) {
            throw "Deployment manifest mismatch: expected '$($expected[$index].Path)', found '$($actual[$index].Path)'"
        }
    }
}

& $validateScript

New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
$resolvedParent = (Resolve-Path -LiteralPath $destinationParent).Path
$stagingPath = Join-Path $resolvedParent ('.auxilias-crossbow-stage-' + [guid]::NewGuid().ToString('N'))
$backupPath = Join-Path $resolvedParent ('.auxilias-crossbow-backup-' + [guid]::NewGuid().ToString('N'))
$movedExisting = $false
$installedNewTree = $false

try {
    New-Item -ItemType Directory -Path $stagingPath | Out-Null
    foreach ($entry in Get-ChildItem -LiteralPath $source -Force) {
        Copy-Item -LiteralPath $entry.FullName -Destination $stagingPath -Recurse -Force
    }
    Assert-TreeMatches -ExpectedRoot $source -ActualRoot $stagingPath

    if (Test-Path -LiteralPath $normalizedDestination) {
        if (-not (Test-Path -LiteralPath $normalizedDestination -PathType Container)) {
            throw "Deployment target exists but is not a directory: $normalizedDestination"
        }
        Assert-NoReparsePoint -Root $normalizedDestination
        Move-Item -LiteralPath $normalizedDestination -Destination $backupPath
        $movedExisting = $true
    }

    Move-Item -LiteralPath $stagingPath -Destination $normalizedDestination
    $installedNewTree = $true
    Assert-TreeMatches -ExpectedRoot $source -ActualRoot $normalizedDestination

    if ($movedExisting) {
        Assert-NoReparsePoint -Root $backupPath
        Remove-Item -LiteralPath $backupPath -Recurse -Force
        $movedExisting = $false
    }
}
catch {
    if ($installedNewTree -and (Test-Path -LiteralPath $normalizedDestination)) {
        Assert-NoReparsePoint -Root $normalizedDestination
        Remove-Item -LiteralPath $normalizedDestination -Recurse -Force
    }
    if ($movedExisting -and (Test-Path -LiteralPath $backupPath)) {
        Move-Item -LiteralPath $backupPath -Destination $normalizedDestination
        $movedExisting = $false
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $stagingPath) {
        Assert-NoReparsePoint -Root $stagingPath
        Remove-Item -LiteralPath $stagingPath -Recurse -Force
    }
}

Write-Host "Deployed and verified Auxilia's Crossbow at $normalizedDestination"
