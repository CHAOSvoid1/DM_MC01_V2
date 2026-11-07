# DM_MC01_V2

达妙 DM-MC-Board01 V2 的 STM32CubeMX2 / CLion 工程，使用 ARM GCC 编译、ST-LINK + OpenOCD 下载与调试。

克隆后按本文配置本机工具即可构建。OpenOCD、ST-LINK 驱动及 Flash loader 需要单独安装，个人 IDE 配置未纳入仓库。本文步骤以 Windows 为准。

## 1. 克隆并打开正确的工程

~~~powershell
git clone https://github.com/CHAOSvoid1/DM_MC01_V2.git
cd DM_MC01_V2
~~~

在 CLion 中选择 Open，打开仓库内的 **DM_MC01_V2_cmake** 子目录，等待 CMake 加载完成。

~~~text
DM_MC01_V2/                 Git 仓库根目录
├── README.md
├── AI_GIT_WORKFLOW.md
├── DM_MC01_V2.ioc2         CubeMX2 硬件配置
└── DM_MC01_V2_cmake/       CLion 应打开这一层
    ├── CMakeLists.txt
    ├── CMakePresets.json
    ├── main.c
    ├── User_Files/         用户应用代码
    ├── generated/         MX2 生成的初始化
    ├── stm32c5xx_drivers/
    └── tools/             OpenOCD 配置与辅助脚本
~~~

打开外层仓库目录可能只进入文件浏览模式，出现“此文件不属于任何项目目标”、顶部“添加配置”等现象。此时重新打开内层工程。

## 2. 准备工具

以下版本来自维护者已使用的本机环境，其他组合需自行验证。

| 工具 | 配置要求 |
| --- | --- |
| CLion | 安装 CMake、嵌入式开发及 OpenOCD 运行配置相关支持 |
| ARM GNU GCC | 本机使用 arm-none-eabi GCC 13.3.1，安装目录中应有 gcc、g++、gdb、objcopy |
| CMake / Ninja | 本机构建验证使用 CMake 3.28.1 和 Ninja，可使用 CLion 配套版本 |
| OpenOCD | 本机使用 ST 定制版 0.12.0+dev-00664-g72f14cee6，来自 STM32CubeIDE 2.2.0 |
| Flash loader | 对本机检测到的 die ID 0x45A，使用 STM32C5[9A]x.xldr |
| ST-LINK | 安装对应驱动，连接 SWDIO、SWCLK、GND，并按开发板要求供电 |

OpenOCD 需要同时支持 STM32C5、stldr 驱动和对应 relocatable .xldr。仅看到“OpenOCD 0.12.0”无法判断是否具备这些功能。

本机可用工具布局供参考，其他电脑可以放在自己的目录：

~~~text
C:/CLionToolchains/DevEnv/
├── GNU-tools-for-STM32/bin/
├── openocd-c5/
│   ├── bin/openocd.exe
│   └── share/openocd/scripts/
│       ├── interface/stlink-dap.cfg
│       └── target/stm32c5x.cfg
└── stm32c5_loaders/STM32C5[9A]x.xldr
~~~

从 STM32CubeIDE 安装目录的 OpenOCD 外部工具插件中取得配套 bin 和 scripts，保留完整配套目录。
loader 可通过工程中的 tools/get_loader.ps1 获取：

~~~powershell
cd DM_MC01_V2_cmake
powershell -ExecutionPolicy Bypass -File .\tools\get_loader.ps1
~~~

脚本使用固定提交下载到 tools/stldr。下载失败时检查网络、脚本中的远程提交是否存在，或从对应 STM32C5 DFP 的 Flash 目录取得 loader。本文未重新验证远程下载。

当前生成目标是 **STM32C593RET6，链接脚本 ROM 为 512 KB、RAM 为 256 KB**。请核对实际芯片丝印和容量，其他型号需同步调整 .ioc2、生成配置和链接脚本。

## 3. 配置 CLion 编译

打开 Settings → Build, Execution, Deployment → Toolchains，配置本机 ARM GCC、G++、GDB，并选择可用的 CMake 和 Ninja。
将 ARM 工具链 bin 加入该工具链环境 PATH，确保能找到 arm-none-eabi-gcc、arm-none-eabi-g++ 和 arm-none-eabi-objcopy。

项目目前带有默认工具目录 C:/CLionToolchains/DevEnv/GNU-tools-for-STM32/bin。如果使用其他目录，在 CMake profile 的 CMake options 中显式设置：

~~~text
-DMX2_ARM_GCC_BIN=C:/你的工具目录/bin
~~~

路径含空格时给整个参数加引号。工程将使用这个目录里的编译器。

Settings → Build, Execution, Deployment → CMake 中启用 Debug profile，Generator 选择 Ninja，构建目录使用 cmake-build-debug。
工程会将 Debug 映射到生成配置所需的 debug_GCC_STM32C593RET6。

也可以启用共享预设 debug_GCC_STM32C593RET6。维护者本机的 CLion-Debug 来自被忽略的 CMakeUserPresets.json，克隆后不会自动出现。

工具路径已加入 PATH 时，可从工程目录执行：

~~~powershell
cmake --preset debug_GCC_STM32C593RET6
cmake --build --preset debug_GCC_STM32C593RET6
~~~

CLion 中执行 Build Project，确认目标为 DM_MC01_V2。
Debug profile 的固件位于 cmake-build-debug/DM_MC01_V2.elf，预设构建则位于 build/debug_GCC_STM32C593RET6/DM_MC01_V2.elf。

## 4. 配置 OpenOCD

复制 tools/stm32c5_stlink.cfg 到自己的本机配置目录，例如 C:/EmbeddedConfig/stm32c5_stlink.cfg。
打开复制后的文件，将 INTERNAL_FLASH_LOADERS 改为本机 loader 的实际路径，使用正斜杠并保留 Tcl 花括号：

~~~tcl
set INTERNAL_FLASH_LOADERS {C:/EmbeddedConfig/loaders/STM32C5[9A]x.xldr}
source [find interface/stlink-dap.cfg]
source [find target/stm32c5x.cfg]
reset_config none
~~~

这里使用 OpenOCD 安装包配套的 target 脚本。仓库 tools/stm32c5x.cfg 可作参考，使用时需核对其与 OpenOCD 二进制的兼容性。

先做连接检查。以下示例中的工具、脚本和板卡配置路径都替换成本机路径：

~~~powershell
& "C:/CLionToolchains/DevEnv/openocd-c5/bin/openocd.exe" -s "C:/CLionToolchains/DevEnv/openocd-c5/share/openocd/scripts" -f "C:/EmbeddedConfig/stm32c5_stlink.cfg" -c "init; shutdown"
~~~

输出应能识别 Cortex-M33，并出现 Examination succeed。此命令只检查连接。

在 CLion 的 Settings → Build, Execution, Deployment → Embedded Development 中，将 OpenOCD Location 指向本机 openocd.exe。

Run → Edit Configurations → 添加 OpenOCD Download & Run：

| 字段 | 设置 |
| --- | --- |
| Name | MX2_ST-LINK |
| Target / Executable | DM_MC01_V2 |
| Board config file | 本机刚配置好的 stm32c5_stlink.cfg |
| GDB port | 3333 |
| Telnet port | 4444 |
| Reset | INIT |
| Download | Updated only |
| Debugger | ARM 工具链中的 arm-none-eabi-gdb |
| Before launch | Build |

选择 Debug 构建 profile 和 MX2_ST-LINK 运行配置。Run 执行下载运行，Debug 可配合 main 断点进行调试。下载会覆盖板上原固件。

也可直接命令行下载，固件路径改为自己的绝对路径：

~~~powershell
& "C:/CLionToolchains/DevEnv/openocd-c5/bin/openocd.exe" -s "C:/CLionToolchains/DevEnv/openocd-c5/share/openocd/scripts" -f "C:/EmbeddedConfig/stm32c5_stlink.cfg" -c "program {D:/你的仓库/DM_MC01_V2_cmake/cmake-build-debug/DM_MC01_V2.elf} verify reset exit"
~~~

确认输出 Verified OK。tools/flash.bat 是使用 CubeProgrammer 的备用脚本，本文的 CLion 流程使用 OpenOCD。

## 5. 常见问题

- 找不到目标、运行配置为空：确认打开 DM_MC01_V2_cmake，并等 CMake 成功加载。
- 找不到编译器：检查 MX2_ARM_GCC_BIN、PATH，以及工具链架构是否为 arm-none-eabi。
- 找不到 stm32c5x.cfg 或 stldr：检查是否使用支持 C5 的 ST OpenOCD 及完整配套 scripts。
- 找不到 loader 或拒绝 loader 格式：检查实际路径、文件完整性及 OpenOCD 版本兼容性。
- ST-LINK 连接失败：检查驱动、板端供电、共地、SWD 线，以及是否有其他调试器占用探针。
- 移动目录后 CMake 报旧路径：关闭工程，备份或清理原构建缓存，再从新目录加载。
- 3333 或 4444 端口占用：停止之前的 OpenOCD 会话再重试。

## 6. Git 和验证范围

提交 .ioc2、生成源码、用户源码和共享 CMake 配置。build、cmake-build-*、.idea、CMakeUserPresets.json 及编译产物已忽略。
每次修改 MX2 配置，将配置文件和对应生成源码一起提交。稳定固件可附在 GitHub Release 中。

2026-11-07 本机已验证移动后的 CMake 配置、Debug 构建及 OpenOCD/ST-LINK 目标连接。已有本机工具说明记录过下载和调试成功。
本文尚未在另一台全新电脑上完整复现，克隆后仍需完成上述本机工具和运行配置。

AI 协作及提交约定见 [AI_GIT_WORKFLOW.md](AI_GIT_WORKFLOW.md)。
