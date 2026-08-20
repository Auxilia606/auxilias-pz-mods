Set-StrictMode -Version Latest

function Get-MonorepoRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}

function Read-MonorepoJson {
    param([Parameter(Mandatory)] [string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Configuration file not found: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-ModRegistry {
    $root = Get-MonorepoRoot
    $registry = Read-MonorepoJson -Path (Join-Path $root 'config\mods.json')
    if ($registry.schemaVersion -ne 1 -or $null -eq $registry.mods) {
        throw 'config/mods.json must use schemaVersion 1 and contain a mods array.'
    }
    return $registry
}

function Get-GameTarget {
    $root = Get-MonorepoRoot
    $configuration = Read-MonorepoJson -Path (Join-Path $root 'config\project-zomboid.json')
    if ($configuration.schemaVersion -ne 1 -or $null -eq $configuration.target) {
        throw 'config/project-zomboid.json must use schemaVersion 1 and contain target.'
    }
    if ($configuration.target.releaseLine -notmatch '^\d+\.\d+$') {
        throw "Project Zomboid releaseLine must look like 42.20: $($configuration.target.releaseLine)"
    }
    if ($configuration.target.testedBuild -notmatch '^\d+\.\d+(\.\d+)?$') {
        throw "Project Zomboid testedBuild is invalid: $($configuration.target.testedBuild)"
    }
    if (-not $configuration.target.testedBuild.StartsWith("$($configuration.target.releaseLine).")) {
        throw "testedBuild $($configuration.target.testedBuild) must belong to releaseLine $($configuration.target.releaseLine)."
    }
    return $configuration.target
}

function Get-ModProjects {
    param([string[]]$Mod)

    $root = Get-MonorepoRoot
    $all = @(Get-ModRegistry | Select-Object -ExpandProperty mods)
    if ($all.Count -eq 0) {
        throw 'No mods are registered in config/mods.json.'
    }

    $selected = if ($null -eq $Mod -or $Mod.Count -eq 0) {
        $all
    }
    else {
        $unknown = @($Mod | Where-Object { $_ -notin $all.slug })
        if ($unknown.Count -gt 0) {
            throw "Unknown mod slug(s): $($unknown -join ', '). Registered: $($all.slug -join ', ')"
        }
        @($all | Where-Object { $_.slug -in $Mod })
    }

    foreach ($project in $selected) {
        $projectPath = [System.IO.Path]::GetFullPath((Join-Path $root $project.path))
        $rootPrefix = [System.IO.Path]::TrimEndingDirectorySeparator($root) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $projectPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Mod path escapes the repository: $($project.path)"
        }
        $project | Add-Member -NotePropertyName FullPath -NotePropertyValue $projectPath -Force
    }
    return $selected
}

Export-ModuleMember -Function Get-MonorepoRoot, Get-ModRegistry, Get-GameTarget, Get-ModProjects
