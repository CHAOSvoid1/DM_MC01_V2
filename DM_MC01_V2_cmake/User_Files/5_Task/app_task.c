#include "app_task.h"
#include "stm32_hal.h"

/* 在调试器中观察此结构，验证主循环和毫秒时基。
 * 采用旧综合例程的 init/process 非阻塞调度方式。
 */
volatile app_test_status_t app_test_status;
static uint32_t last_heartbeat_ms;

void app_init(void)
{
    last_heartbeat_ms = HAL_GetTick();
    app_test_status.uptime_ms = last_heartbeat_ms;
    app_test_status.loop_count = 0U;
    app_test_status.heartbeat_count = 0U;
    app_test_status.initialized = 1U;
}

void app_loop(void)
{
    const uint32_t now = HAL_GetTick();
    app_test_status.uptime_ms = now;
    app_test_status.loop_count++;
    if ((uint32_t)(now - last_heartbeat_ms) >= 500U)
    {
        last_heartbeat_ms = now;
        app_test_status.heartbeat_count++;
    }
}
