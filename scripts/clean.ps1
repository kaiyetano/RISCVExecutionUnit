$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$targets = @(
    "db",
    "incremental_db",
    "output_files",
    "transcript",
    "vsim.wlf",
    "modelsim.ini",
    "FinalProject.qws",
    "Simulation/work",
    "Simulation/transcript",
    "Simulation/vsim.wlf",
    "Simulation/modelsim.ini"
)

foreach ($target in $targets) {
    $path = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $target))
    if (-not $path.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete outside repository: $path"
    }

    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

Write-Host "Cleaned generated Quartus and ModelSim outputs."
