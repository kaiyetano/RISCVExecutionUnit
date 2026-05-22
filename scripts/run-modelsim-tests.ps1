param(
    [ValidateSet("all", "8", "16", "32", "64")]
    [string]$Width = "all",

    [ValidateSet("all", "Baseline", "BKA_BRL", "BKA_SFT", "CSA_BRL", "CSA_SFT")]
    [string]$Variant = "all",

    [switch]$KeepWork
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $repoRoot "Simulation"
$sourceDir = Join-Path $repoRoot "SourceCode"

$baseSources = @(
    "ExecUnit.vhdl",
    "ArithmeticUnit.vhdl",
    "ArithmeticArchitecture.vhdl",
    "LogicUnit.vhdl",
    "LogicArchitecture.vhdl",
    "ShiftUnit.vhdl",
    "ShiftArchitecture.vhdl",
    "ExecUnit_Baseline.vhdl",
    "ExecUnit_BKA_BRL.vhdl",
    "ExecUnit_BKA_SFT.vhdl",
    "ExecUnit_CSA_BRL.vhdl",
    "ExecUnit_CSA_SFT.vhdl"
) | ForEach-Object { Join-Path $sourceDir $_ }

$variants = @(
    @{ Name = "Baseline"; File = Join-Path $sourceDir "ExecUnit_Baseline.vhdl"; Config = "ExecUnit_tb_func" },
    @{ Name = "BKA_BRL";  File = Join-Path $sourceDir "ExecUnit_BKA_BRL.vhdl";  Config = "ExecUnit_tb_BKA_BRL" },
    @{ Name = "BKA_SFT";  File = Join-Path $sourceDir "ExecUnit_BKA_SFT.vhdl";  Config = "ExecUnit_tb_BKA_SFT" },
    @{ Name = "CSA_BRL";  File = Join-Path $sourceDir "ExecUnit_CSA_BRL.vhdl";  Config = "ExecUnit_tb_CSA_BRL" },
    @{ Name = "CSA_SFT";  File = Join-Path $sourceDir "ExecUnit_CSA_SFT.vhdl";  Config = "ExecUnit_tb_CSA_SFT" }
)

if ($Variant -ne "all") {
    $variants = $variants | Where-Object { $_.Name -eq $Variant }
}

function Invoke-CheckedCommand {
    param(
        [string]$Label,
        [scriptblock]$Command
    )

    Write-Host "== $Label =="
    $output = & $Command 2>&1
    $output | Write-Host

    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }

    return $output
}

function Assert-SimulationPassed {
    param(
        [string]$Label,
        [string[]]$Output
    )

    $failed = $Output | Select-String -Pattern "Failed:\s+[1-9]|TESTBENCH FAILED|SOME TESTS FAILED|Fatal|Error:"
    $passed = $Output | Select-String -Pattern "ALL TESTS PASSED"

    if ($failed -or -not $passed) {
        throw "$Label did not report a clean pass"
    }
}

Push-Location $simDir
try {
    Invoke-CheckedCommand "Create work library" { vlib work }
    Invoke-CheckedCommand "Compile common source" { vcom -2008 @baseSources (Join-Path $simDir "ExecUnit_tb.vhd") }

    if (($Width -eq "all") -or ($Width -eq "64")) {
        foreach ($arch in $variants) {
            $label = "64-bit $($arch.Name)"
            $out = Invoke-CheckedCommand $label { vsim -c -t ps $arch.Config -do "run 20 us; quit" }
            Assert-SimulationPassed $label $out
        }
    }

    $benches = @(
        @{ Width = 8;  File = "ExecUnit_tb_8.vhd" },
        @{ Width = 16; File = "ExecUnit_tb_16.vhd" },
        @{ Width = 32; File = "ExecUnit_tb_32.vhd" }
    )

    foreach ($bench in $benches) {
        if (($Width -ne "all") -and ($Width -ne [string]$bench.Width)) {
            continue
        }

        foreach ($arch in $variants) {
            $label = "$($bench.Width)-bit $($arch.Name)"
            Invoke-CheckedCommand "Compile $label" { vcom -2008 $arch.File (Join-Path $simDir $bench.File) }
            $out = Invoke-CheckedCommand $label { vsim -c -t ps ExecUnit_tb -do "run 20 us; quit" }
            Assert-SimulationPassed $label $out
        }
    }
}
finally {
    Pop-Location
    if (-not $KeepWork) {
        $cleanupTargets = @(
            (Join-Path $simDir "work"),
            (Join-Path $simDir "transcript")
        )

        foreach ($target in $cleanupTargets) {
            if ((Resolve-Path $target -ErrorAction SilentlyContinue) -and
                ((Resolve-Path $target).Path.StartsWith((Resolve-Path $simDir).Path))) {
                Remove-Item -LiteralPath $target -Recurse -Force
            }
        }
    }
}

Write-Host "All source-level ModelSim tests passed."
