param(
    [string]$OutputDirectory,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$workshopRoot = Join-Path $repoRoot 'workshop'
$versionFile = Join-Path $repoRoot 'VERSION'
$validateScript = Join-Path $PSScriptRoot 'validate.ps1'

if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) {
    throw "Version file not found: $versionFile"
}

$version = (Get-Content -LiteralPath $versionFile -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "VERSION must use semantic version format (for example, 0.1.0): $version"
}

$metadataFiles = @(
    (Join-Path $workshopRoot 'workshop.txt'),
    (Join-Path $workshopRoot 'Contents\mods\AuxiliasCrossbow\mod.info'),
    (Join-Path $workshopRoot 'Contents\mods\AuxiliasCrossbow\42.20\mod.info')
)

foreach ($metadataFile in $metadataFiles) {
    if (-not (Test-Path -LiteralPath $metadataFile -PathType Leaf)) {
        throw "Metadata file not found: $metadataFile"
    }

    $metadata = Get-Content -LiteralPath $metadataFile -Raw
    if ($metadata -notmatch [regex]::Escape("Version $version")) {
        throw "Version $version is not present in metadata: $metadataFile"
    }
}

& $validateScript

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot 'dist'
}

$resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null

$archiveName = "AuxiliasCrossbow-$version.zip"
$archivePath = Join-Path $resolvedOutputDirectory $archiveName
$checksumPath = "$archivePath.sha256"

if ((Test-Path -LiteralPath $archivePath) -and -not $Force) {
    throw "Package already exists: $archivePath. Pass -Force to replace it."
}

$compressParameters = @{
    Path = (Join-Path $workshopRoot '*')
    DestinationPath = $archivePath
    CompressionLevel = 'Optimal'
}
if ($Force) {
    $compressParameters.Force = $true
}
Compress-Archive @compressParameters

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $fileEntries = @($archive.Entries | Where-Object { -not [string]::IsNullOrEmpty($_.Name) })
    $entryNames = @($fileEntries | ForEach-Object { $_.FullName.Replace('\', '/') })
    $requiredEntries = @(
        'workshop.txt',
        'preview.png',
        'Contents/mods/AuxiliasCrossbow/mod.info',
        'Contents/mods/AuxiliasCrossbow/42.20/mod.info'
    )

    foreach ($requiredEntry in $requiredEntries) {
        if ($requiredEntry -notin $entryNames) {
            throw "Required package entry is missing: $requiredEntry"
        }
    }

    $sourceFiles = @(Get-ChildItem -LiteralPath $workshopRoot -Recurse -File -Force)
    if ($fileEntries.Count -ne $sourceFiles.Count) {
        throw "Package file count differs from workshop source: archive=$($fileEntries.Count), source=$($sourceFiles.Count)"
    }

    $sourceByPath = @{}
    foreach ($sourceFile in $sourceFiles) {
        $relativePath = [System.IO.Path]::GetRelativePath($workshopRoot, $sourceFile.FullName).Replace('\', '/')
        $sourceByPath[$relativePath] = $sourceFile
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        foreach ($entry in $fileEntries) {
            $entryPath = $entry.FullName.Replace('\', '/')
            if (-not $sourceByPath.ContainsKey($entryPath)) {
                throw "Package contains a file absent from workshop source: $entryPath"
            }

            $sourceFile = $sourceByPath[$entryPath]
            if ($entry.Length -ne $sourceFile.Length) {
                throw "Package length mismatch for $entryPath`: archive=$($entry.Length), source=$($sourceFile.Length)"
            }

            $entryStream = $entry.Open()
            try {
                $entryHash = [Convert]::ToHexString($sha256.ComputeHash($entryStream))
            }
            finally {
                $entryStream.Dispose()
            }
            $sourceHash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
            if ($entryHash -ne $sourceHash) {
                throw "Package content hash mismatch: $entryPath"
            }
        }
    }
    finally {
        $sha256.Dispose()
    }
}
finally {
    $archive.Dispose()
}

$hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumLine = "$hash  $archiveName`n"
[System.IO.File]::WriteAllText(
    $checksumPath,
    $checksumLine,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Package created: $archivePath"
Write-Host "SHA-256: $hash"
