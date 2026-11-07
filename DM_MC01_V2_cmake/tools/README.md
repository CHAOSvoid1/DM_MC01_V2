# tools —— 烧录相关配置

MX2 的目标芯片是 **STM32C593RET6**（Cortex-M33，C5 系列）。C5 是 2026 年新出的系列，
**老工具链里没有它的支持**，这是配烧录时唯一真正的坑，先说清楚现状：

| 工具 | 本机版本 | 支持 C5？ |
|---|---|---|
| OpenOCD `C:\CLionToolchains\DevEnv\openocd-v0.12.0-...` | 0.12.0 (2023) | ❌ 没有 `target/stm32c5x.cfg`，也没有 stldr flash 驱动 |
| STM32CubeProgrammer `D:\ENG\stm32\STM32cube\cubeProgrammer` | **2.23.0** | ✅ 数据表里有 0x44E/0x44F/0x45A，**已用 ST-Link 实机烧录验证通过** |
| CubeCLT 1.18 自带的 CubeProgrammer | 2.19.0 | ❌ |

所以现在：**编译、烧录都能用**。`flash.bat` 已验证：`Download verified successfully` → `MCU Reset` →
`-coreReg` 读到 PC=0x08003820 / SP=0x20000950（固件在跑）。CLion 原生 OpenOCD 烧录/调试仍缺 C5 支持，
要么按路线 B 换 OpenOCD，要么在 CLion 里把 `flash.bat` 挂成 External Tool。

---

## 实际验证结果（2026-11-06，本机 + 真板子）

| 用途 | 用什么 | 状态 |
|---|---|---|
| 烧录（CLion 里一键） | `C:\CLionToolchains\DevEnv\openocd-c5\bin\openocd.exe` | ✅ `program → Verify OK → reset` 已实机验证 |
| 调试（断点/单步/变量） | 同上 + GDB | ✅ `load` 全部 section 成功、`break main` 正常 |
| 备用烧录 | `tools\flash.bat`（CubeProgrammer 2.23 CLI） | ✅ `Download verified successfully` → `MCU Reset` |

**可用的 OpenOCD 是从 STM32CubeIDE 2.2.0 里提取的**：

```
D:\ENG\stm32\STM32cube\cubeIDE\STM32CubeIDE_2.2.0\STM32CubeIDE\plugins\
  com.st.stm32cube.ide.mcu.externaltools.openocd.win32_2.4.500.202604080855\tools
  → 版本 0.12.0+dev-00664-g72f14cee6 (2026-04-16)，stldr 驱动能解析 2026 的 relocatable .xldr
```

已复制到 `C:\CLionToolchains\DevEnv\openocd-c5\`（bin + scripts，317 个 target 脚本，
含官方 `target\stm32c5x.cfg`）。板卡配置：`C:\CLionToolchains\DevEnv\stm32c5_stlink.cfg`。

实机日志片段：

```
Info : [stm32c5.cpu] Cortex-M33 r0p4 processor detected
#0 : stldr at 0x08000000, size 0x00100000, buswidth 0, chipwidth 16
Loader file for STM32C59Axx 1M Flash
Info : Running loader function SectorErase(0x8000000, 0x8004000, 0x0, 0x0)
Info : Running loader function Write(0x8000000, 0x2880, 0x20001774, 0x0)
** Programming Finished **  ** Verify Started **  ** Verified OK **
```

GDB 侧（这就是 CLion 里按 Debug 时走的路径）：

```
Loading section .vectors, size 0x1d0 lma 0x8000000
Loading section .text, size 0x4560 lma 0x80001d0
...
Transfer rate: 19 KB/sec, 1964 bytes/write.
Breakpoint 1 at 0x8003520: file .../main.c, line 38.
```

C5 的 die id 实测 **0x45A** → `STM32C5[9A]x.xldr`（另两个：0x44E→C5[56]x、0x44F→C5[34]x），
loader 已放在 `C:\CLionToolchains\DevEnv\stm32c5_loaders\`。

### CLion 里怎么设（只做一次）

1. `Settings ▸ Build, Execution, Deployment ▸ Embedded Development`
   - OpenOCD Location：`C:\CLionToolchains\DevEnv\openocd-c5\bin\openocd.exe`
   - Board config file：`C:\CLionToolchains\DevEnv\stm32c5_stlink.cfg`
2. `Run ▸ Edit Configurations ▸ + ▸ OpenOCD Download & Run`
   - Name：`MX2_ST-LINK`
   - GDB port 3333、Telnet 4444、Reset `init`、Download `Updated only`
   - Target：`DM_MC01_V2`
3. 之后 **Shift+F9 / F5** 就是「编译 → 烧录 → 停在 main 断点」。

### 失败的几份（留着备查）

| 路径 | 为什么不行 |
|---|---|
| `C:\Users\chaos\Downloads\openocd-v0.12.0-...` | 2023 年的 0.12.0，二进制里 `stldr` 0 次，无 `stm32c5x.cfg` |
| `C:\Users\chaos\Downloads\openocd-9f2d876-...` | 2026-11-04 的 upstream nightly，同样没有 `stldr`、没有 C5 脚本 |
| `C:\Users\chaos\Downloads\OpenOCD-openocd-cubeide-r7` | ST fork 的**源码**，代码是对的（有 relocatable 支持）但没编译好的 bin |
| `C:\CLionToolchains\DevEnv\openocd-stm32c5` | CubeIDE 1.18 的旧 fork（2025-02），能调试但不能烧（拒绝 relocatable loader） |

---

## 路线 A（备用）：CubeProgrammer + `flash.bat`

1. 装 CubeProgrammer >= 2.21（ST 官网 `STM32CubeProg` 下载页）。
2. 设置环境变量（或直接改 `flash.bat` 里的默认值）：
   ```
   setx STM32CUBEPROG "D:\ENG\stm32\STM32cube\cubeProgrammer"
   ```
3. 烧录：
   ```
   tools\flash.bat
   ```
   它默认烧 `build\CLion-Debug\DM_MC01_V2.elf`，也接受第一个参数指定别的 elf。

4. 想在 CLion 里一键烧（F5 旁边那个按钮）：
   `File > Settings > Tools > External Tools > +`，填
   - Program: `$ProjectFileDir$\tools\flash.bat`
   - Arguments: `$ProjectFileDir$\build\CLion-Debug\DM_MC01_V2.elf`
   - Working directory: `$ProjectFileDir$`
   然后用 `Tools > External Tools > flash` 触发；也可以把它加进某个 Run 配置的
   "Before launch" 里，做到 Build 完自动烧。

> CLion 原生的 "Flash" 按钮只走 OpenOCD，不认 CubeProgrammer，所以路线 A 只能通过
> External Tool / 命令行触发，不能用 IDE 自带的烧录按钮。

---

## 路线 B：换一个带 STM32C5 支持的 OpenOCD，用 CLion 原生 OpenOCD 配置

> 本机现状：CubeIDE 带的 ST 定制版能**连上调试试**，但**不能烧**（见上面「实际验证结果」）。
> 想用这条路烧录，得换一个真正支持 2026 版 `.xldr`（relocatable loader）的 OpenOCD 构建。

2026-07 官方给 OpenOCD 提交了 STM32C5 支持补丁（新增 `tcl/target/stm32c5x.cfg`，
用 stldr flash 驱动，按 die id 选 `STM32C55x/56x/53x/54x/59x/5Ax.xldr`）。
等你的 OpenOCD 版本包含它之后：

1. `tools/stm32c5_stlink.cfg` 已经按 C_Board 的格式写好了
   （`interface/stlink.cfg` + `target/stm32c5x.cfg` + `reset_config none`），
   缺 target 脚本时它会直接报错退出，不会静默失败。
2. 部分版本需要把 flash loader（`*.xldr`）放到磁盘上：
   ```
   pwsh -File tools\get_loader.ps1
   ```
   会从 `STMicroelectronics/stm32c5xx-dfp` 仓库的 `Flash/` 目录下载所有 xldr 到
   `tools\stldr\`。
3. 让 CLion 用这个 OpenOCD（**全局设置，只改一次**）：
   `File > Settings > Build, Execution, Deployment > Embedded Development`
   → OpenOCD Location 指到新 OpenOCD 的 `bin\openocd.exe`。
4. 新增运行配置：`Run > Edit Configurations > + > OpenOCD Download & Run`
   - Name: `MX2_ST-LINK`
   - Target / Executable: `DM_MC01_V2`（CLion 会解析到 `build/CLion-Debug/DM_MC01_V2.elf`）
   - Board config file: `D:\ENG\stm32\STM32cube_Project\MX2\DM_MC01_V2_cmake\tools\stm32c5_stlink.cfg`
   - GDB port `3333`，Telnet port `4444`，Reset type `init`
   - Download: `Updated only`（和 C_Board 一致）
   - 勾上 "Build"（CLION.COMPOUND.BUILD），这样 F5 就是"先编译再烧"。

> 注意：CLion 正在运行时会在退出时回写 `.idea/workspace.xml`，
> 所以运行配置请在 IDE 界面里加，不要手改 XML（会被覆盖）。

---

## 为什么 C_Board 能直接烧、MX2 不行

C_Board 是 STM32F407（2012 年的芯片），OpenOCD 0.12.0 自带 `stm32f4x.cfg`，
一条 `stm32f4_stlink.cfg` 就能用；MX2 是 C5，新到 OpenOCD 0.12.0 / CubeProgrammer
2.20 都还没收录。不是配置写错了，是工具版本不够。
