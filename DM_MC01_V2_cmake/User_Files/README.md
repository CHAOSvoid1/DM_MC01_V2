# User_Files —— 你自己的代码放这里

这个目录对应 CubeMX2 工程里的"用户代码区"，结构照搬 `C_Board_v1.0` 的 `User_Files/`：

```
User_Files/
├── 1_Middleware/    移植层 / 第三方库（printf 重定向、环形缓冲、PID 工具、滤波库…）
├── 2_Module/        板级驱动 BSP：某个具体传感器、电机、LED、按键的封装
├── 3_Robot/         与"机器人本体"强相关的算法：姿态解算、控制律、混控、功率限制
├── 4_Interaction/   人机与上位机交互：遥控接收、DBUS、VOFA+/匿名上位机、图传协议
└── 5_Task/          任务调度层：app_init() / app_loop()，把上面几层串起来
```

## 规则

1. `User_Files/` 下任意层级的 `.c / .cpp / .s` 都会自动加入编译（`CMakeLists.txt` 里的 `GLOB_RECURSE`），
   `.h` 所在的目录会自动加入 include 路径。
2. 新增文件后**不需要**改任何 CMake 文件；Ninja 会在下次构建时自动重新 GLOB
   （`CONFIGURE_DEPENDS`）。CLion 里如果没看到新文件编译，Reload CMake Project 一次即可。
3. **绝对不要**把代码加进 `cmake/files.cmake`、`cmake/flags.cmake` 等 `generated` 文件，
   它们是 STM32CubeMX2 每次生成时重写的，改动会丢。
4. 目录名带序号只是按依赖方向排序（中间件 → 驱动 → 算法 → 交互 → 任务），
   新模块往里加子目录即可，例如 `2_Module/bsp_imu/bsp_imu.c`。
