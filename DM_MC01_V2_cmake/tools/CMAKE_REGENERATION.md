# MX2 生成后的自动构建

当前使用 CMake 的 CMAKE_PROJECT_DM_MC01_V2_INCLUDE_BEFORE 加载 cmake/user/ProjectHook.cmake。
该钩子在 project() 初始化前加载，并将用户目标配置延迟到根目录配置结束执行。
用户源文件、头文件目录由 cmake/user/Application.cmake 管理。
根 CMakeLists 和驱动子目录 CMakeLists 可使用 MX2 新生成的内容，无需恢复脚本。

日常步骤：
1. MX2 生成代码。
2. CLion Reload CMake。
3. Build，使用既有 MX2_ST-LINK OpenOCD 运行配置下载。

当前本机 Debug 缓存已配置钩子，CMakeUserPresets.json 的 CLion-Debug 也已配置。
CLion Debug profile 的 CMake options 应保留：
    -DTOOLCHAIN_FILE=GCC.14.3.1.cmake
    -DCMAKE_PROJECT_DM_MC01_V2_INCLUDE_BEFORE="$PROJECT_DIR$/cmake/user/ProjectHook.cmake"
其他电脑初次配置或清空缓存后，也需设置这两个选项，或使用已配置的本机预设。
ARM GCC bin 必须存在于工具链 PATH。使用 CMake 3.30 或更新版本。

保留必要的用户源文件与 include 路径。浮点 printf 和额外内存占用输出已移除，需要时可单独添加。
MX2 当前 ADC 软件触发生成了 HAL_ADC_REG_TRIG_ 空符号。Application.cmake 在配置时将这一个精确的无效赋值替换为 HAL_ADC_REG_TRIG_SOFTWARE，其他合法触发选择保持原值。
这是当前软件触发选择的生成兼容处理，升级生成器后需复查。

本次在不包含用户 include 的生成根 CMakeLists 下，全部源码编译链接通过。
未在本次验证中重新烧录。已有 OpenOCD 配置保持原值。
