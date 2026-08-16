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
    $entryNames = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
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
