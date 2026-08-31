param(
    [Parameter(Position = 0)]
    [string]$GeneratorZip,

    [string]$MCreatorHome = $env:MCREATOR_HOME,

    [string]$MCreatorExe,

    [string]$GeneratorId
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$SpecPath = Join-Path $ProjectRoot 'compatibility-spec.json'

if (-not (Test-Path -LiteralPath $SpecPath)) {
    Write-Error "compatibility-spec.json was not found at $SpecPath"
    exit 2
}

$Spec = Get-Content -LiteralPath $SpecPath -Raw | ConvertFrom-Json
$Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Status, [string]$Area, [string]$Check, [string]$Details)
    $Results.Add([pscustomobject]@{
        status = $Status.ToUpperInvariant()
        area = $Area
        check = $Check
        details = $Details
    })
}

function Get-Sha256HexFromBytes {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-ZipEntryBytes {
    param($Archive, [string]$Name)
    $entry = $Archive.GetEntry($Name)
    if ($null -eq $entry) { return $null }
    $stream = $entry.Open()
    try {
        $memory = New-Object System.IO.MemoryStream
        try {
            $stream.CopyTo($memory)
            return $memory.ToArray()
        } finally {
            $memory.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

function Get-ZipEntryText {
    param($Archive, [string]$Name)
    $bytes = Get-ZipEntryBytes $Archive $Name
    if ($null -eq $bytes) { return $null }
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Test-SourceContract {
    param($Contract)
    $path = Join-Path $ProjectRoot ([string]$Contract.file)
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Result $Contract.severity 'Plugin source' $Contract.file 'Required plugin source file is missing.'
        return
    }
    $text = Get-Content -LiteralPath $path -Raw
    foreach ($needle in $Contract.contains) {
        if ($text.Contains([string]$needle)) {
            Add-Result 'PASS' 'Plugin source' "$($Contract.file) anchor" "Found: $needle"
        } else {
            Add-Result $Contract.severity 'Plugin source' "$($Contract.file) anchor" "Missing: $needle"
        }
    }
}

Write-Host '============================================================'
Write-Host 'Custom Spawn Categories compatibility checker'
Write-Host "Plugin baseline: $($Spec.plugin_version) / $($Spec.source_package_revision)"
Write-Host '============================================================'
Write-Host

# ---------------------------------------------------------------------------
# Plugin source self-check
# ---------------------------------------------------------------------------
foreach ($contract in $Spec.plugin_source_contracts) {
    Test-SourceContract $contract
}

# ---------------------------------------------------------------------------
# Input selection / friendly auto-detection
# ---------------------------------------------------------------------------
$MCreatorSelection = ''
$GeneratorSelection = ''

if (-not [string]::IsNullOrWhiteSpace($GeneratorZip)) {
    try {
        $GeneratorZip = [System.IO.Path]::GetFullPath($GeneratorZip)
    } catch {
        # Keep the original value so the normal existence check can report it.
    }
    $GeneratorSelection = 'supplied explicitly'
}

if (-not [string]::IsNullOrWhiteSpace($MCreatorExe)) {
    try { $MCreatorExe = [System.IO.Path]::GetFullPath($MCreatorExe) } catch {}
    $MCreatorSelection = 'supplied explicitly as mcreator.exe'
} elseif (-not [string]::IsNullOrWhiteSpace($MCreatorHome)) {
    try { $MCreatorHome = [System.IO.Path]::GetFullPath($MCreatorHome) } catch {}
    $MCreatorSelection = 'supplied through -MCreatorHome or MCREATOR_HOME'
}

# Most MCreator generator packages live in <MCreator>\plugins. When the user
# drags such a ZIP onto the batch file, infer the matching MCreator install.
# Explicit -MCreatorExe / -MCreatorHome / MCREATOR_HOME always wins.
if ([string]::IsNullOrWhiteSpace($MCreatorExe) -and
    [string]::IsNullOrWhiteSpace($MCreatorHome) -and
    -not [string]::IsNullOrWhiteSpace($GeneratorZip) -and
    (Test-Path -LiteralPath $GeneratorZip)) {
    try {
        $generatorDir = Split-Path -Parent (Resolve-Path -LiteralPath $GeneratorZip)
        if ((Split-Path -Leaf $generatorDir) -ieq 'plugins') {
            $candidateHome = Split-Path -Parent $generatorDir
            $candidateExe = Join-Path $candidateHome 'mcreator.exe'
            if (Test-Path -LiteralPath $candidateExe) {
                $MCreatorHome = $candidateHome
                $MCreatorSelection = 'auto-detected from generator ZIP location'
                Write-Host "Auto-detected matching MCreator installation: $MCreatorHome"
            }
        }
    } catch {
        # Auto-detection is convenience only. Normal checks below will report
        # any real input problem.
    }
}

# ---------------------------------------------------------------------------
# MCreator application checks
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($MCreatorExe)) {
    if ([string]::IsNullOrWhiteSpace($MCreatorHome)) {
        $MCreatorHome = 'C:\Program Files\Pylo\MCreator'
        $MCreatorSelection = 'default installation path'
    }
    $MCreatorExe = Join-Path $MCreatorHome 'mcreator.exe'
} elseif ([string]::IsNullOrWhiteSpace($MCreatorHome)) {
    $MCreatorHome = Split-Path -Parent $MCreatorExe
}
if ([string]::IsNullOrWhiteSpace($MCreatorSelection)) {
    $MCreatorSelection = 'resolved MCreator installation'
}
if (-not (Test-Path -LiteralPath $MCreatorExe)) {
    Add-Result 'FAIL' 'MCreator' 'mcreator.exe' "Not found: $MCreatorExe"
} else {
    if ([string]::IsNullOrWhiteSpace($MCreatorHome)) {
        $MCreatorHome = Split-Path -Parent $MCreatorExe
    }
    $JdkBin = Join-Path $MCreatorHome 'jdk\bin'
    $JarExe = Join-Path $JdkBin 'jar.exe'
    $JavapExe = Join-Path $JdkBin 'javap.exe'
    $JavacExe = Join-Path $JdkBin 'javac.exe'

    foreach ($tool in @($JarExe, $JavapExe, $JavacExe)) {
        if (-not (Test-Path -LiteralPath $tool)) {
            Add-Result 'FAIL' 'MCreator' 'Bundled JDK tool' "Not found: $tool"
        }
    }

    if ((Test-Path -LiteralPath $JarExe) -and (Test-Path -LiteralPath $JavapExe)) {
        $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('custom-spawn-categories-check-' + [Guid]::NewGuid().ToString('N'))
        $ApiRoot = Join-Path $TempRoot 'mcreator-api'
        $CompileRoot = Join-Path $TempRoot 'compile'
        New-Item -ItemType Directory -Path $ApiRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $CompileRoot -Force | Out-Null
        try {
            Push-Location $ApiRoot
            try {
                & $JarExe xf $MCreatorExe
                if ($LASTEXITCODE -ne 0) { throw "jar.exe could not extract mcreator.exe" }
            } finally {
                Pop-Location
            }

            $manifestPath = Join-Path $ApiRoot 'META-INF\MANIFEST.MF'
            if (Test-Path -LiteralPath $manifestPath) {
                $manifest = Get-Content -LiteralPath $manifestPath -Raw
                $version = if ($manifest -match '(?m)^MCreator-Version:\s*(.+)$') { $Matches[1].Trim() } else { '?' }
                $build = if ($manifest -match '(?m)^Build-Date:\s*(.+)$') { $Matches[1].Trim() } else { '?' }
                if ($version -eq [string]$Spec.tested_with.mcreator.version -and $build -eq [string]$Spec.tested_with.mcreator.build) {
                    Add-Result 'PASS' 'MCreator' 'Version/build' "$version build $build matches tested baseline."
                } else {
                    Add-Result 'WARN' 'MCreator' 'Version/build' "Found $version build $build; tested baseline is $($Spec.tested_with.mcreator.version) build $($Spec.tested_with.mcreator.build)."
                }
            } else {
                Add-Result 'FAIL' 'MCreator' 'Manifest' 'META-INF/MANIFEST.MF was not extracted.'
            }

            foreach ($entry in $Spec.mcreator.required_archive_entries) {
                $local = Join-Path $ApiRoot ([string]$entry).Replace('/', '\')
                if (Test-Path -LiteralPath $local) {
                    Add-Result 'PASS' 'MCreator' 'Required class/resource' ([string]$entry)
                } else {
                    Add-Result 'FAIL' 'MCreator' 'Required class/resource' "Missing: $entry"
                }
            }

            foreach ($property in $Spec.mcreator.baseline_class_sha256.psobject.Properties) {
                $entry = [string]$property.Name
                $expected = [string]$property.Value
                $local = Join-Path $ApiRoot $entry.Replace('/', '\')
                if (Test-Path -LiteralPath $local) {
                    $actual = (Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToLowerInvariant()
                    if ($actual -eq $expected) {
                        Add-Result 'PASS' 'MCreator' 'Baseline class hash' $entry
                    } else {
                        Add-Result 'WARN' 'MCreator' 'Baseline class hash' "$entry changed since the tested MCreator build. Public API/reflection checks still decide whether this is a hard failure."
                    }
                }
            }

            foreach ($contract in $Spec.mcreator.reflection_contracts) {
                $args = @('-classpath', $ApiRoot)
                if ([string]$contract.mode -eq 'private') { $args += '-private' } else { $args += '-public' }
                $args += [string]$contract.class
                $javapOutput = (& $JavapExe @args 2>&1 | Out-String)
                if ($LASTEXITCODE -ne 0) {
                    Add-Result 'FAIL' 'MCreator reflection/API' ([string]$contract.class) 'javap failed for this class.'
                    continue
                }
                foreach ($needle in $contract.contains) {
                    if ($javapOutput.Contains([string]$needle)) {
                        Add-Result 'PASS' 'MCreator reflection/API' ([string]$contract.class) "Found: $needle"
                    } else {
                        Add-Result 'FAIL' 'MCreator reflection/API' ([string]$contract.class) "Missing expected signature/field: $needle"
                    }
                }
            }

            if (Test-Path -LiteralPath $JavacExe) {
                $javaRoot = Join-Path $ProjectRoot 'src\main\java'
                $sources = @(Get-ChildItem -LiteralPath $javaRoot -Recurse -File -Filter '*.java')
                if ($sources.Count -eq 0) {
                    Add-Result 'FAIL' 'MCreator compile' 'Plugin Java' 'No Java sources found.'
                } else {
                    $sourcesFile = Join-Path $TempRoot 'sources.txt'
                    $sourceLines = $sources | ForEach-Object { '"' + $_.FullName.Replace('\', '/') + '"' }
                    Set-Content -LiteralPath $sourcesFile -Value $sourceLines -Encoding ASCII
                    $compileOutput = (& $JavacExe '--release' '21' '-cp' $ApiRoot '-d' $CompileRoot ('@' + $sourcesFile) 2>&1 | Out-String)
                    if ($LASTEXITCODE -eq 0) {
                        Add-Result 'PASS' 'MCreator compile' 'Plugin Java' 'All plugin Java sources compile against the installed MCreator application classes.'
                    } else {
                        $short = (($compileOutput -split "`r?`n") | Select-Object -First 20) -join ' | '
                        Add-Result 'FAIL' 'MCreator compile' 'Plugin Java' $short
                    }
                }
            }
        } catch {
            Add-Result 'FAIL' 'MCreator' 'Application inspection' $_.Exception.Message
        } finally {
            Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Generator ZIP checks
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($GeneratorZip) -and -not [string]::IsNullOrWhiteSpace($MCreatorHome)) {
    $pluginsDir = Join-Path $MCreatorHome 'plugins'
    if (Test-Path -LiteralPath $pluginsDir) {
        $installedCandidates = @(Get-ChildItem -LiteralPath $pluginsDir -File -Filter 'generator-*.zip' -ErrorAction SilentlyContinue)
        if ($installedCandidates.Count -eq 1) {
            $GeneratorZip = $installedCandidates[0].FullName
            $GeneratorSelection = 'auto-detected from MCreator plugins folder'
            Write-Host "Auto-detected generator package: $GeneratorZip"
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GeneratorZip)) {
    $localCandidates = @(Get-ChildItem -LiteralPath $ProjectRoot -File -Filter 'generator-*.zip' -ErrorAction SilentlyContinue)
    if ($localCandidates.Count -eq 1) {
        $GeneratorZip = $localCandidates[0].FullName
        $GeneratorSelection = 'auto-detected from source root'
    }
}

if ([string]::IsNullOrWhiteSpace($GeneratorZip)) {
    Add-Result 'SKIP' 'Generator' 'Generator ZIP' 'No unambiguous generator ZIP was found. Drag a generator ZIP onto check-compatibility.bat or pass its path explicitly.'
} elseif (-not (Test-Path -LiteralPath $GeneratorZip)) {
    Add-Result 'FAIL' 'Generator' 'Generator ZIP' "Not found: $GeneratorZip"
} else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $GeneratorZip))
    try {
        $rootPlugin = Get-ZipEntryText $archive 'plugin.json'
        if ($null -ne $rootPlugin) {
            try {
                $pluginJson = $rootPlugin | ConvertFrom-Json
                $foundPluginId = [string]$pluginJson.id
                if ($foundPluginId -eq [string]$Spec.tested_with.generator_plugin.id) {
                    Add-Result 'PASS' 'Generator' 'Generator plugin ID' $foundPluginId
                } else {
                    Add-Result 'WARN' 'Generator' 'Generator plugin ID' "Found '$foundPluginId'; tested baseline is '$($Spec.tested_with.generator_plugin.id)'."
                }
            } catch {
                Add-Result 'WARN' 'Generator' 'Generator plugin ID' 'plugin.json exists but could not be parsed.'
            }
        } else {
            Add-Result 'WARN' 'Generator' 'Generator plugin ID' 'Root plugin.json not found.'
        }

        $candidateIds = @($archive.Entries | ForEach-Object {
            if ($_.FullName -match '^(neoforge-[^/]+)/') { $Matches[1] }
        } | Sort-Object -Unique)

        if ([string]::IsNullOrWhiteSpace($GeneratorId)) {
            $baselineId = [string]$Spec.tested_with.generator.id
            if ($candidateIds -contains $baselineId) {
                $GeneratorId = $baselineId
            } elseif ($candidateIds.Count -eq 1) {
                $GeneratorId = $candidateIds[0]
            }
        }

        if ([string]::IsNullOrWhiteSpace($GeneratorId)) {
            Add-Result 'FAIL' 'Generator' 'NeoForge generator selection' ("Could not choose one generator. Candidates: " + ($candidateIds -join ', ') + ". Run the PowerShell script with -GeneratorId.")
        } elseif (-not ($candidateIds -contains $GeneratorId)) {
            Add-Result 'FAIL' 'Generator' 'NeoForge generator selection' "'$GeneratorId' was not found. Candidates: $($candidateIds -join ', ')"
        } else {
            Add-Result 'PASS' 'Generator' 'NeoForge generator selection' $GeneratorId
            if ($GeneratorId -ne [string]$Spec.tested_with.generator.id) {
                Add-Result 'WARN' 'Generator' 'Generator ID changed' "Source resources currently target '$($Spec.tested_with.generator.id)'. A port/review for '$GeneratorId' is required."
            }

            $generatorYaml = Get-ZipEntryText $archive ($GeneratorId + '/generator.yaml')
            if ($null -ne $generatorYaml -and $generatorYaml -match '(?m)^buildfileversion:\s*([^\s]+)') {
                $buildFileVersion = $Matches[1]
                if ($GeneratorId -eq [string]$Spec.tested_with.generator.id -and $buildFileVersion -eq [string]$Spec.tested_with.generator.buildfileversion) {
                    Add-Result 'PASS' 'Generator' 'NeoForge buildfileversion' $buildFileVersion
                } else {
                    Add-Result 'WARN' 'Generator' 'NeoForge buildfileversion' "Found $buildFileVersion; tested baseline is $($Spec.tested_with.generator.buildfileversion)."
                }
            } else {
                Add-Result 'FAIL' 'Generator' 'NeoForge buildfileversion' 'Could not read buildfileversion from generator.yaml.'
            }

            foreach ($relative in $Spec.generator.required_files) {
                $entryName = $GeneratorId + '/' + [string]$relative
                if ($null -ne $archive.GetEntry($entryName)) {
                    Add-Result 'PASS' 'Generator' 'Required file' ([string]$relative)
                } else {
                    Add-Result 'FAIL' 'Generator' 'Required file' "Missing: $entryName"
                }
            }

            if ($GeneratorId -eq [string]$Spec.tested_with.generator.id) {
                foreach ($property in $Spec.generator.baseline_file_sha256.psobject.Properties) {
                    $relative = [string]$property.Name
                    $expected = [string]$property.Value
                    $bytes = Get-ZipEntryBytes $archive ($GeneratorId + '/' + $relative)
                    if ($null -ne $bytes) {
                        $actual = Get-Sha256HexFromBytes $bytes
                        if ($actual -eq $expected) {
                            Add-Result 'PASS' 'Generator' 'Baseline upstream hash' $relative
                        } else {
                            Add-Result 'WARN' 'Generator' 'Baseline upstream hash' "$relative changed since the tested generator package. Rebase/review plugin overrides before updating the baseline hash."
                        }
                    }
                }
            } else {
                Add-Result 'WARN' 'Generator' 'Baseline hashes' 'Generator ID differs from the tested baseline, so old-path hash comparisons are not treated as compatibility proof.'
            }

            foreach ($contract in $Spec.generator.anchors) {
                $entryName = $GeneratorId + '/' + [string]$contract.file
                $text = Get-ZipEntryText $archive $entryName
                if ($null -eq $text) {
                    Add-Result 'FAIL' 'Generator anchors' ([string]$contract.file) 'File is missing, so its anchors cannot be checked.'
                    continue
                }
                foreach ($needle in $contract.contains) {
                    if ($text.Contains([string]$needle)) {
                        Add-Result 'PASS' 'Generator anchors' ([string]$contract.file) "Found: $needle"
                    } else {
                        Add-Result ([string]$contract.severity) 'Generator anchors' ([string]$contract.file) "Missing: $needle"
                    }
                }
            }
        }
    } finally {
        $archive.Dispose()
    }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
$ReportDir = Join-Path $ProjectRoot 'reports'
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$textReport = Join-Path $ReportDir ("compatibility-$stamp.txt")
$jsonReport = Join-Path $ReportDir ("compatibility-$stamp.json")

$counts = @{}
foreach ($name in @('PASS', 'WARN', 'FAIL', 'SKIP')) {
    $counts[$name] = @($Results | Where-Object { $_.status -eq $name }).Count
}

$overall = if ($counts['FAIL'] -gt 0) {
    'NOT READY - hard compatibility failures require porting.'
} elseif ($counts['WARN'] -gt 0) {
    'REVIEW REQUIRED - no hard failure was found, but upstream differences need inspection.'
} elseif ($counts['SKIP'] -gt 0) {
    'INCOMPLETE - one or more checks were skipped.'
} else {
    'BASELINE MATCH - automated checks match the recorded tested baseline.'
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('Custom Spawn Categories compatibility report')
$lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
$lines.Add("Project: $ProjectRoot")
$lines.Add("MCreator: $MCreatorExe")
$lines.Add("MCreator selection: $MCreatorSelection")
$lines.Add("Generator ZIP: $GeneratorZip")
$lines.Add("Generator selection: $GeneratorSelection")
$lines.Add("Requested/selected generator: $GeneratorId")
$lines.Add('')
$lines.Add("Overall: $overall")
$lines.Add("PASS=$($counts['PASS'])  WARN=$($counts['WARN'])  FAIL=$($counts['FAIL'])  SKIP=$($counts['SKIP'])")
$lines.Add('')
foreach ($result in $Results) {
    $lines.Add("[$($result.status)] [$($result.area)] $($result.check)")
    if (-not [string]::IsNullOrWhiteSpace([string]$result.details)) {
        $lines.Add("    $($result.details)")
    }
}
$lines.Add('')
$lines.Add('Manual runtime contracts still to verify:')
foreach ($item in $Spec.manual_runtime_contracts) {
    $lines.Add("  - $item")
}

Set-Content -LiteralPath $textReport -Value $lines -Encoding UTF8
$reportObject = [pscustomobject]@{
    generated_at = (Get-Date).ToString('o')
    plugin_version = [string]$Spec.plugin_version
    source_package_revision = [string]$Spec.source_package_revision
    overall = $overall
    counts = $counts
    mcreator_exe = $MCreatorExe
    mcreator_selection = $MCreatorSelection
    generator_zip = $GeneratorZip
    generator_selection = $GeneratorSelection
    generator_id = $GeneratorId
    results = $Results
    manual_runtime_contracts = $Spec.manual_runtime_contracts
}
$reportObject | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonReport -Encoding UTF8

Write-Host
Write-Host '============================================================'
Write-Host $overall
Write-Host "PASS=$($counts['PASS'])  WARN=$($counts['WARN'])  FAIL=$($counts['FAIL'])  SKIP=$($counts['SKIP'])"
Write-Host "Text report: $textReport"
Write-Host "JSON report: $jsonReport"
Write-Host '============================================================'

if ($counts['FAIL'] -gt 0) { exit 2 }
if ($counts['SKIP'] -gt 0) { exit 3 }
exit 0
