param(
    [string[]]$Widths = @("8", "16", "32", "64"),
    [string[]]$Variants = @("Baseline", "BKA_BRL", "BKA_SFT", "CSA_BRL", "CSA_SFT"),
    [string]$OutputRoot = "analysis/quartus_matrix",
    [string]$ResultsJson = "analysis/quartus_results.json",
    [string]$QuartusSh = $(if ($env:QUARTUS_SH) { $env:QUARTUS_SH } else { "quartus_sh" })
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot "SourceCode"
$outputRootAbs = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputRoot))
$resultsJsonAbs = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ResultsJson))

$variantFiles = @{
    Baseline = "ExecUnit_Baseline.vhdl"
    BKA_BRL  = "ExecUnit_BKA_BRL.vhdl"
    BKA_SFT  = "ExecUnit_BKA_SFT.vhdl"
    CSA_BRL  = "ExecUnit_CSA_BRL.vhdl"
    CSA_SFT  = "ExecUnit_CSA_SFT.vhdl"
}

function Convert-ToQuartusPath {
    param([string]$Path)
    return ([System.IO.Path]::GetFullPath($Path)).Replace("\", "/")
}

function Get-FirstRegexNumber {
    param(
        [string]$Text,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        $match = [regex]::Match($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($match.Success) {
            return [int]($match.Groups[1].Value -replace ",", "")
        }
    }

    return $null
}

function Read-ReportText {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return Get-Content -Raw -LiteralPath $Path
    }

    return ""
}

function Resolve-Tool {
    param([string]$Tool)

    if (Test-Path -LiteralPath $Tool) {
        return (Resolve-Path -LiteralPath $Tool).Path
    }

    $command = Get-Command $Tool -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw "Unable to find '$Tool'. Put it on PATH, set QUARTUS_SH, or pass -QuartusSh <path>."
}

function New-QuartusProject {
    param(
        [string]$RunDir,
        [string]$Width,
        [string]$Variant
    )

    New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
    $project = "ExecUnit_${Variant}_${Width}"
    $qpf = Join-Path $RunDir "$project.qpf"
    $qsf = Join-Path $RunDir "$project.qsf"

    $commonSources = @(
        "ExecUnit.vhdl",
        "ArithmeticUnit.vhdl",
        "ArithmeticArchitecture.vhdl",
        "LogicUnit.vhdl",
        "LogicArchitecture.vhdl",
        "ShiftUnit.vhdl",
        "ShiftArchitecture.vhdl",
        $variantFiles[$Variant]
    )

    $qpfText = @"
QUARTUS_VERSION = "20.1"
PROJECT_REVISION = "$project"
"@

    $sourceAssignments = foreach ($src in $commonSources) {
        $srcPath = Convert-ToQuartusPath (Join-Path $sourceDir $src)
        "set_global_assignment -name VHDL_FILE `"$srcPath`""
    }

    $qsfText = @"
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY ExecUnit
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
set_global_assignment -name OPTIMIZATION_TECHNIQUE BALANCED
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF
set_global_assignment -name REMOVE_REDUNDANT_LOGIC_CELLS OFF
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim (VHDL)"
set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation
set_parameter -name N $Width
$($sourceAssignments -join [Environment]::NewLine)
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top
"@

    Set-Content -LiteralPath $qpf -Value $qpfText -Encoding ASCII
    Set-Content -LiteralPath $qsf -Value $qsfText -Encoding ASCII

    return $project
}

function Read-QuartusStats {
    param(
        [string]$RunDir,
        [string]$Project,
        [string]$Variant,
        [string]$Width,
        [int]$ExitCode,
        [double]$ElapsedSeconds
    )

    $outDir = Join-Path $RunDir "output_files"
    $flowText = Read-ReportText (Join-Path $outDir "$Project.flow.rpt")
    $mapSummary = Read-ReportText (Join-Path $outDir "$Project.map.summary")
    $fitSummary = Read-ReportText (Join-Path $outDir "$Project.fit.summary")
    $staSummary = Read-ReportText (Join-Path $outDir "$Project.sta.summary")

    $logicElements = Get-FirstRegexNumber $fitSummary @(
        "Total logic elements\s*;\s*([\d,]+)",
        "Total logic elements\s*:\s*([\d,]+)"
    )
    $combinational = Get-FirstRegexNumber $fitSummary @(
        "Total combinational functions\s*;\s*([\d,]+)",
        "Total combinational functions\s*:\s*([\d,]+)",
        "Combinational ALUTs\s*;\s*([\d,]+)"
    )
    $registers = Get-FirstRegexNumber $fitSummary @(
        "Dedicated logic registers\s*;\s*([\d,]+)",
        "Dedicated logic registers\s*:\s*([\d,]+)",
        "Total registers\s*:\s*([\d,]+)",
        "Total registers\s*;\s*([\d,]+)"
    )
    $pins = Get-FirstRegexNumber $fitSummary @(
        "Total pins\s*;\s*([\d,]+)",
        "Total pins\s*:\s*([\d,]+)"
    )
    $memoryBits = Get-FirstRegexNumber $fitSummary @(
        "Total memory bits\s*;\s*([\d,]+)",
        "Total memory bits\s*:\s*([\d,]+)"
    )
    $multipliers = Get-FirstRegexNumber $fitSummary @(
        "Embedded Multiplier 9-bit elements\s*;\s*([\d,]+)",
        "Embedded Multiplier 9-bit elements\s*:\s*([\d,]+)"
    )

    $status = if ($ExitCode -eq 0 -and ($flowText -match "Flow Status\s*:\s*Successful|Flow Status\s*;\s*Successful")) { "PASS" }
              elseif ($ExitCode -eq 0) { "PASS" }
              else { "FAIL" }

    return [pscustomobject]@{
        variant = $Variant
        width = [int]$Width
        compile_status = $status
        quartus_exit_code = $ExitCode
        elapsed_seconds = [math]::Round($ElapsedSeconds, 2)
        logic_elements = $logicElements
        combinational_functions = $combinational
        registers = $registers
        pins = $pins
        memory_bits = $memoryBits
        dsp_9bit_elements = $multipliers
        sta_available = [bool]($staSummary.Trim().Length)
        notes = if ($status -eq "PASS") { "Full Quartus compile completed" } else { "Quartus compile failed; inspect run log" }
    }
}

$quartusShCmd = Resolve-Tool $QuartusSh

New-Item -ItemType Directory -Path $outputRootAbs -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $resultsJsonAbs) -Force | Out-Null

$results = @()

foreach ($width in $Widths) {
    foreach ($variant in $Variants) {
        if (-not $variantFiles.ContainsKey($variant)) {
            throw "Unknown variant: $variant"
        }

        $runName = "${variant}_${width}"
        $runDir = Join-Path $outputRootAbs $runName
        $project = New-QuartusProject -RunDir $runDir -Width $width -Variant $variant
        $logPath = Join-Path $runDir "quartus_compile.log"

        Write-Host "== Quartus compile $runName =="
        Push-Location $runDir
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $output = & $quartusShCmd --flow compile $project 2>&1
            $exitCode = $LASTEXITCODE
            $output | Set-Content -LiteralPath $logPath -Encoding UTF8
        }
        finally {
            $timer.Stop()
            Pop-Location
        }

        $result = Read-QuartusStats -RunDir $runDir -Project $project -Variant $variant -Width $width -ExitCode $exitCode -ElapsedSeconds $timer.Elapsed.TotalSeconds
        $results += $result

        Write-Host ("{0} width={1} status={2} LEs={3} regs={4} pins={5}" -f $variant, $width, $result.compile_status, $result.logic_elements, $result.registers, $result.pins)
    }
}

$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $resultsJsonAbs -Encoding UTF8
Write-Host "Wrote $resultsJsonAbs"
