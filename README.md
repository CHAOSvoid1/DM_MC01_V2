# DM_MC01_V2

STM32C593RET6 达妙 V2 开发板工程。CLion + ARM GCC 编译，ST-LINK + 支持 STM32C5 的 OpenOCD 烧录调试。

## 拿到工程后怎么使用

需要两份内容：
1. 本 GitHub 仓库源码。
2. 维护者提供的 DM_MC01_V2-tools.zip 工具附件。解压后应得到 Toolchain 文件夹，放到仓库根目录。

工具包已整理 ARM GCC 13.3.1、CMake、Ninja、ST 定制 OpenOCD、STM32C5 loader 和 ST-LINK 驱动安装文件。
工具包约1.2GB解压大小，未放入 Git，也不会随 git clone 下载。发布者需要将工具压缩包另行分发或附在 GitHub Release。
本 README 不代表附件已经上传。工具按各自附带许可使用和分发。

~~~text
DM_MC01_V2/
├── README.md
├── Setup.ps1
├── Build.ps1
├── Toolchain/                 解压工具附件到这里，Git忽略
│   ├── gcc/
│   ├── cmake/
│   ├── ninja/
│   ├── openocd/
│   ├── loaders/
│   └── STLinkUSBDriver/
├── DM_MC01_V2.ioc2
└── DM_MC01_V2_cmake/           CLion打开这一层
~~~

### 首次配置，只执行一次

在仓库根目录打开 PowerShell：

~~~powershell
powershell -ExecutionPolicy Bypass -File .\Setup.ps1
~~~

脚本检查工具是否齐全，生成本机 CMakeUserPresets.json 和 tools/local-openocd.cfg。已有本机预设会备份。
工具目录、源码可以放在不同盘，默认使用仓库根目录 Toolchain。
移动整个仓库后，再执行一次 Setup.ps1 更新本机绝对路径。

如电脑尚未识别 ST-LINK，安装 Toolchain/STLinkUSBDriver 下对应的驱动安装程序，按系统提示授权。脚本不会静默安装驱动。

### 在 CLion 中使用

1. Open 打开 DM_MC01_V2_cmake，等待工程加载。
2. Settings → Build, Execution, Deployment → Toolchains，把 CMake 指向 Toolchain/cmake/bin/cmake.exe。工具链选择本机可用的 ARM/嵌入式环境，ARM GDB 在 Toolchain/gcc/bin/arm-none-eabi-gdb.exe。
3. Settings → Build, Execution, Deployment → CMake，启用 CLion-Debug 预设，停用不需要的手工 Debug profile。预设已经设置 GCC PATH、Ninja 和自动用户代码钩子。
4. Build Project，固件生成在 build/CLion-Debug/DM_MC01_V2.elf。

### 配置 CLion 一键 OpenOCD 烧录调试

1. Settings → Build, Execution, Deployment → Embedded Development，把 OpenOCD Location 指向 Toolchain/openocd/bin/openocd.exe。
2. Run → Edit Configurations，添加 OpenOCD Download & Run。
3. 名称填 MX2_ST-LINK，Target / Executable 选 DM_MC01_V2，构建 profile 选 CLion-Debug。
4. Board config 选工程下 tools/local-openocd.cfg。
5. GDB port 3333，Telnet port 4444，Reset INIT，Download Updated only，Before launch 保留 Build。
6. 使用 ARM GDB；点击 Run 下载运行，Debug 用于断点和单步。

这些工具选择属于 CLion 本机设置，需要首次指定。完成后，每次打开工程可直接 Build / Run / Debug。
使用 SWDIO、SWCLK、GND连接ST-LINK，按开发板要求供电。下载会覆盖板上固件。
普通旧版 OpenOCD 不一定支持 STM32C5，请使用工具附件中的配套版本和脚本。

### 不进入 CLion，直接编译或烧录

~~~powershell
powershell -ExecutionPolicy Bypass -File .\Build.ps1
powershell -ExecutionPolicy Bypass -File .\Build.ps1 -Flash
~~~

第一条仅编译，第二条编译成功后通过 OpenOCD 写入、校验并复位。

## MX2 重新生成代码

打开 DM_MC01_V2.ioc2 保存配置并生成，然后在 CLion Reload CMake → Build。
CLion-Debug 预设通过 CMake 的项目初始化前钩子加载 cmake/user/ProjectHook.cmake。
用户代码放在 User_Files，其源文件和头文件目录自动加入构建。根 CMakeLists 可以使用生成结果。
当前 ADC 软件触发的空枚举生成问题在用户 CMake 中作了精确兼容修正。
详细说明见 [CMake 自动配置](DM_MC01_V2_cmake/tools/CMAKE_REGENERATION.md)。

## 例程中还有什么可以迁移

| 模块 | 内容与迁移要点 |
| --- | --- |
| board/bsp | LED、按键、供电、ADC、蜂鸣器、加热PWM、RS485、UART、SBUS、CAN FD、SPI2、LCD、USB CDC、TIM8 |
| middleware/bmi08x | BMI088 厂商驱动，需要SPI读写、延时与片选适配 |
| app | IMU采样、温控、LCD绘图/字体、通信测试、按键/电压测试、USB报告 |
| board_config.h | 板级引脚与应用参数，需按当前配置核对 |
| board.c | 供电入口和BOOT_SEL选项字节处理，选项字节行为需单独审查 |

建议按 LED/按键 → RS485 → UART/CAN/ADC → IMU/LCD/USB → 温控迁移。
RS485 中断转接涉及 bsp_uart 与 bsp_sbus_internal，需要检查关联文件。
旧 TIM8 测试使用两路捕获、两路输出，当前配置为四路PWM，不能直接启用旧回环测试。
底层 HAL 配置只负责初始化，DMA接收启动、PWM启动、协议解析和业务处理在BSP/应用层完成。
本仓库目前仍是基础时基测试，以上 BSP 和综合应用尚未整体迁入。

## 版本管理与验证

提交 .ioc2、生成源码、User_Files、共享 CMake 和脚本。Toolchain、构建产物、个人 IDE 配置忽略。
.before-move 是移动目录前的旧构建缓存备份，当前工程不再依赖，已清理。
AI协作规则见 [AI_GIT_WORKFLOW.md](AI_GIT_WORKFLOW.md)，硬件配置见 [BOARD_CONFIGURATION.md](BOARD_CONFIGURATION.md)。
已使用工具包副本完成 Setup → 编译链接，并通过 OpenOCD 连接识别开发板。压缩包 CRC 完整性检查通过，旁边的 .sha256 文件提供校验值。本次未重新烧录，尚未在另一台电脑完成全流程复现。
