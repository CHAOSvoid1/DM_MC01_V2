# MX2 工程结构说明（STM32C593RET6 / CubeMX2 生成）

> 一句话：**只有 `DM_MC01_V2.ioc2` 是"源头"，`DM_MC01_V2_cmake/` 里的文件几乎全是它生成的。**
> 你的代码写 `User_Files/`，main 在工程根的 `main.c`，`generated/` 和 `cmake/*.cmake` 不要手改。

## 0. 现状速查

| 事项 | 状态 |
|---|---|
| 编译（GCC 13.3.1 + Ninja） | ✅ 已配好并验证，产出 `build/CLion-Debug/DM_MC01_V2.elf` |
| 用户代码自动纳入编译 | ✅ `User_Files/**/*.c` 递归 GLOB，已编译进 ELF |
| 烧录 | ✅ 双通道已验证：CLion 原生 OpenOCD（`C:\CLionToolchains\DevEnv\openocd-c5`，取自 CubeIDE 2.2.0）一键烧+调试；备用 `tools\flash.bat`（CubeProgrammer 2.23）。详见 [tools/README.md](tools/README.md) |

## 1. 两个目录的关系

```
D:\ENG\stm32\STM32cube_Project\MX2\
├── DM_MC01_V2.ioc2          ← CubeMX2 工程文件（芯片、时钟、外设配置都在这里）
└── DM_MC01_V2_cmake\        ← CubeMX2 生成的 CMake 工程，CLion 打开这个目录
    ├── main.c / main.h      ← 你的 main
    ├── User_Files\          ← 你的代码全放这里
    ├── tools\               ← 烧录脚本与 OpenOCD 配置
    └── （其余都是生成的）
```

改外设/时钟 → 改 `.ioc2` 再 Generate；改业务逻辑 → 只动 `main.c` 和 `User_Files/`。

## 2. 目录地图：哪些能改，哪些会被覆盖

CubeMX2 在 `.settings\exported-files.json` 里给每个文件标了归属，决定了重新生成时会不会被覆盖：

| 归属 | 含义 | 典型文件 | 能不能改 |
|---|---|---|---|
| `user_code` | 纯用户文件，永不覆盖 | `main.c`、`main.h` | ✅ 随便改 |
| `project_file` | 只生成一次，之后归你 | `CMakeLists.txt`、各组件 `CMakeLists.txt` | ✅ 可以改（我已在此加 User_Files 接入） |
| `RTE` | 运行时环境件 | `user_modifiable\Device\STM32C593RET6\startup_stm32c593xx.c`、`stm32c593xe_flash.ld`、`user_modifiable\_debug_GCC_STM32C593RET6\RTE_Components.h` | ⚠️ 可改，但生成器可能提示冲突 |
| `generated` | **每次生成都重写** | `cmake\{files,flags,components,target,GCC.14.3.1}.cmake`、`CMakePresets.json`、`generated\hal\mx_*.c`、`generated\utilities\*` | ❌ 别改，改了会被冲掉 |

其余目录：

| 路径 | 内容 |
|---|---|
| `arch\cmsis\` | CMSIS 6.3.0 内核头文件 |
| `stm32c5xx_dfp\` | 器件支持包 2.1.0（启动文件、器件头、链接脚本模板） |
| `stm32c5xx_drivers\` | STM32C5 HAL / LL 驱动源码（`hal\`、`ll\`、`timebases\`） |
| `generated\hal\` | CubeMX2 生成的外设初始化：`mx_system.c`、`mx_rcc.c`、`mx_icache.c`、`mx_cortex_nvic.c`、`mx_cortex_mpu.c` … |
| `utilities\syscalls\` | newlib 的 `_write/_sbrk` 等系统调用桩 |
| `build\CLion-Debug\` | 编译输出（elf / map / compile_commands.json） |
| `cmake-build-debug\` | 早期用错工具链留下的空壳，可以直接删 |
| `.idea\` | CLion 工程配置 |

⚠️ **不要往 `cmake\files.cmake` 里加源文件**——它只列了 `main.c`，而且是 generated，重新生成就被覆盖。
用户代码一律走 `User_Files/`。

## 3. main 在哪，启动流程是什么

`main.c`（工程根，49 行）就是入口：

```c
int main(void)
{
    if (mx_system_init() != SYSTEM_OK) {
        return (-1);
    } else {
        app_init();
        while (1) {
            app_loop();
        }
    }
}
```

调用链：

```
启动文件 startup_stm32c593xx.c（Reset_Handler → SystemInit → __libc_init_array → main）
   └─ main()                     main.c            ← 你写业务的地方
        └─ mx_system_init()      generated\hal\mx_system.c
             ├─ mx_rcc / mx_icache / mx_cortex_nvic / mx_cortex_mpu 配置
             ├─ 各外设 HAL_XXX_Init()（你在 .ioc2 里勾的）
             └─ HAL_Init() / 时钟树
        └─ app_init() / app_loop()  User_Files\5_Task\app_task.c
```

`mx_system_init()` 是生成的，别改；它做的事等价于 CubeMX 老工程的 `SystemClock_Config() + MX_GPIO_Init() + ...` 打包。

## 4. 你的代码放哪：`User_Files/`

按 C_Board_v1.0 的分层习惯建的（和 C_Board 的 `User_Files` 完全同构）：

```
User_Files\
├── 1_Middleware\    移植/第三方代码（如 FreeRTOS、DSP 库、滤波库）
├── 2_Module\        BSP 驱动（电机、IMU、遥控接收机、OLED…）
├── 3_Robot\         机器人层：姿态解算、控制算法、混控
├── 4_Interaction\   交互层：遥控解析、上位机协议、图传/灯效
├── 5_Task\          调度层：app_init() / app_loop()
└── README.md        目录规划与规则
```

规则很简单：

- 任意层级下的 `.c` / `.cpp` / `.s` 都会被自动编译（`CMakeLists.txt` 里 `file(GLOB_RECURSE ... CONFIGURE_DEPENDS)`）；
- 只要目录里有头文件，该目录就自动加入 include 路径；
- 新增/删除文件后 CMake 会自动重新 GLOB；如果 CLion 里没反应，右键 `Reload CMake Project`。

这和 C_Board 的做法一模一样（C_Board 也是 `file(GLOB_RECURSE USER_SOURCES ... User_Files/*.c ...)` + `add_subdirectory(cmake/stm32cubemx)`），
区别只是 MX2 的底层（HAL/启动/链接脚本）由 CubeMX2 自己的 `cmake/components.cmake` 负责，不需要你维护 `Core/`、`Drivers/`。

## 5. 怎么编译

### CLion 里

1. 打开 `D:\ENG\stm32\STM32cube_Project\MX2\DM_MC01_V2_cmake`。
2. `Settings > Build, Execution, Deployment > CMake`，Profile 选 **`CLion-Debug`**（来自 `CMakeUserPresets.json`）。
3. Build（Ctrl+F9）。产物：`build\CLion-Debug\DM_MC01_V2.elf`。
   如果 CLion 用的是自动生成的 `Debug` profile，产物会在 `cmake-build-debug\DM_MC01_V2.elf`；
   两个位置都行，`tools\flash.bat` 会自动找最新的。

`CLion-Debug` 这个 preset 固定了：GCC 工具链 = `C:\CLionToolchains\DevEnv\GNU-tools-for-STM32\bin`（13.3.1），
Ninja = CubeCLT 1.18 的 ninja，构建目录 `build\CLion-Debug`。

### 命令行

```bat
cd /d D:\ENG\stm32\STM32cube_Project\MX2\DM_MC01_V2_cmake
set PATH=C:\CLionToolchains\DevEnv\GNU-tools-for-STM32\bin;%PATH%
cmake --preset CLion-Debug
cmake --build --preset CLion-Debug
```

当前固件体积：ROM 19,648 B / 512 KB（3.75%），RAM 2,384 B / 256 KB（0.91%）。

## 6. 怎么烧录

**先看 [tools/README.md](tools/README.md)。** 核心结论：

- 芯片是 C5 系列（新），要**能从 CubeIDE 2.2.0 里提取的 OpenOCD**（`0.12.0+dev-00664`，2026-04）才支持；
- 首选（✅ 已实机验证，烧录+调试都已通过）：`C:\CLionToolchains\DevEnv\openocd-c5\bin\openocd.exe` + 板卡配置 `C:\CLionToolchains\DevEnv\stm32c5_stlink.cfg`；CLion 里设好 OpenOCD Location 和 Board config，建一个 `OpenOCD Download & Run` 就能 F5 编译→烧录→停在 main；
- 备用（✅ 也已验证）：CubeProgrammer 2.23 → `tools\flash.bat`，输出 `Download verified successfully` + `MCU Reset`；
- 会用到的 loader：`C:\CLionToolchains\DevEnv\stm32c5_loaders\` 下按 die id 分三个，本板 STM32C593RET6 实测 die id = **0x45A** → `STM32C5[9A]x.xldr`；
- 例程 `E:\湘大\RM\开发板\DM_MC01\V2\例程\C593_all` 用的是 **pyOCD + CMSIS pack**，本机没装 pyOCD。

## 7. 几个坑（都是这次踩过的）

1. **文件名骗人**：`cmake\GCC.14.3.1.cmake` 只是名字，实际用的是 `C:\CLionToolchains\DevEnv` 里的 **13.3.1**。脚本不校验版本，能编就没问题。
2. **PATH 里有一堆失效路径**（`D:\G\stm32\...` 整个不存在）。所以 `CLion-Debug` preset 显式加了工具链目录到 PATH 前面，不依赖系统 PATH。
3. **`cmake-build-debug\`** 是早期用 CLion 自带 MinGW + 已删除的 gcc-10.3 试出来的垃圾配置，删掉以免 CLion 选错 profile。
4. **改 `.ioc2` 重新生成后**，`cmake\*.cmake` 和 `generated\*` 会被重写；`CMakeLists.txt`、`main.c`、`User_Files\`、`tools\` 不受影响。
5. 想用 `printf("%f")` 已加 `-u _printf_float`；每次链接会打印 flash/RAM 占用（`--print-memory-usage`）。
