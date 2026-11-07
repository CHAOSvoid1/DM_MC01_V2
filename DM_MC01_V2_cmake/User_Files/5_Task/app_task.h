/**
  ******************************************************************************
  * file  : app_task.h
  * brief : 用户应用层入口（放在 User_Files/5_Task 下）
  *
  * 说明：MX2 工程里，CubeMX2 只负责生成"底层初始化 + main()"，
  *       你自己的业务代码全部写在 User_Files/ 下，CMake 会自动递归收进来，
  *       不需要手动改任何 cmake 文件。
  ******************************************************************************
  */
#ifndef APP_TASK_H
#define APP_TASK_H

#ifdef __cplusplus
extern "C" {
#endif

/* 上电初始化：外设、驱动、算法模块的 init 都放这里，只在 main 里调用一次 */
void app_init(void);

/* 主循环体：被 while(1) 反复调用，里面放调度/轮询/控制解算 */
void app_loop(void);

#ifdef __cplusplus
}
#endif

#endif /* APP_TASK_H */
