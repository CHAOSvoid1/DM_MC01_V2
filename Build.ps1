param([switch]$Flash)
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$project = Join-Path $repo 'DM_MC01_V2_cmake'
$tool = Join-Path $repo 'Toolchain'
$cmake = Join-Path $tool 'cmake/bin/cmake.exe'
Push-Location $project
try {
    & $cmake --preset CLion-Debug
    if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed' }
    & $cmake --build --preset CLion-Debug -j 8
    if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
    if ($Flash) {
        $elf = (Join-Path $project 'build/CLion-Debug/DM_MC01_V2.elf').Replace('\','/')
        & "$tool/openocd/bin/openocd.exe" -s "$tool/openocd/share/openocd/scripts" -f "$project/tools/local-openocd.cfg" -c "program {$elf} verify reset exit"
        if ($LASTEXITCODE -ne 0) { throw 'OpenOCD download failed' }
    }
} finally { Pop-Location }
