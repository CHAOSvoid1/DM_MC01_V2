param([string]$ToolchainRoot = (Join-Path $PSScriptRoot 'Toolchain'))
$ErrorActionPreference = 'Stop'
$toolRoot = (Resolve-Path $ToolchainRoot).Path.Replace('\','/')
$project = Join-Path $PSScriptRoot 'DM_MC01_V2_cmake'
$required = @('gcc/bin/arm-none-eabi-gcc.exe','gcc/bin/arm-none-eabi-gdb.exe','cmake/bin/cmake.exe','ninja/bin/ninja.exe','openocd/bin/openocd.exe','openocd/share/openocd/scripts/target/stm32c5x.cfg','loaders/STM32C5[9A]x.xldr')
foreach ($file in $required) {
    if (-not (Test-Path -LiteralPath "$toolRoot/$file")) { throw "Missing tool: $toolRoot/$file" }
}
$preset = @{
    version = 3
    configurePresets = @(@{
        name = 'CLion-Debug'
        inherits = 'debug_GCC_STM32C593RET6'
        generator = 'Ninja'
        binaryDir = '${sourceDir}/build/CLion-Debug'
        environment = @{ TMP = (Join-Path $project 'build/tmp'); TEMP = (Join-Path $project 'build/tmp'); PATH = "$toolRoot/gcc/bin;" + '$penv{PATH}' }
        cacheVariables = @{
            TOOLCHAIN_FILE = 'GCC.14.3.1.cmake'
            CMAKE_BUILD_TYPE = 'debug_GCC_STM32C593RET6'
            CMAKE_MAKE_PROGRAM = "$toolRoot/ninja/bin/ninja.exe"
            CMAKE_PROJECT_DM_MC01_V2_INCLUDE_BEFORE = '${sourceDir}/cmake/user/ProjectHook.cmake'
        }
    })
    buildPresets = @(@{name='CLion-Debug'; configurePreset='CLion-Debug'})
}
New-Item -ItemType Directory -Force (Join-Path $project 'build/tmp') | Out-Null
$presetPath = Join-Path $project 'CMakeUserPresets.json'
if (Test-Path $presetPath) { Copy-Item $presetPath "$presetPath.backup" -Force }
$preset | ConvertTo-Json -Depth 10 | Set-Content $presetPath -Encoding utf8
@"
set INTERNAL_FLASH_LOADERS {$toolRoot/loaders/STM32C5[9A]x.xldr}
source [find interface/stlink-dap.cfg]
source [find target/stm32c5x.cfg]
reset_config none
"@ | Set-Content (Join-Path $project 'tools/local-openocd.cfg') -Encoding ascii
Write-Host "Prepared CLion-Debug preset."
Write-Host "CLion CMake: $toolRoot/cmake/bin/cmake.exe"
Write-Host "CLion OpenOCD: $toolRoot/openocd/bin/openocd.exe"
Write-Host 'ST-LINK driver is provided under Toolchain/STLinkUSBDriver; install it manually if needed.'
