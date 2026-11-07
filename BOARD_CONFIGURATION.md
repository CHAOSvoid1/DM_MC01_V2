# 手册核对后的板级配置

依据 V2 使用说明书第 6–20 页，器件 STM32C593RET6，Flash 512 KB，RAM 256 KB。
配置文件使用已有 MX2 完整项目的序列化结构及关联 ID，重新命名为 DM_MC01_V2、RET6。硬件引脚按手册核对。
本次仅修改 .ioc2，生成源码和应用尚未同步。重新加载 MX2、检查诊断并生成后才能验证新配置的编译与实板行为。

## 引脚
| 功能 | 引脚 |
| --- | --- |
| SWD | PA13 SWDIO、PA14 SWCLK |
| 电池 ADC | PA0 ADC1_IN0，板端分压 1/11 |
| LCD 按键 ADC | PC4 ADC2_IN4 |
| 用户 LED / 按键 | PC0 低有效 / PA15 低有效 |
| 对外 5V / 加热5V | PC14 / PC15，初始均低，保持关闭 |
| RS485 P4 | USART2 PA2 TX、PA3 RX、PA1 DE |
| RS485 P5 | UART5 PC12 TX、PD2 RX、PC8 DE |
| CAN1 / CAN2 | PB8 RX、PB9 TX / PB12 RX、PB13 TX |
| USB FS | PA11 DM、PA12 DP |
| SBUS | PA8 UART7_RX |
| USART1 / USART3 | PA9 TX、PA10 RX / PC10 TX、PC11 RX |
| 蜂鸣器 | PB0 TIM3_CH3 |
| 四路 PWM | PC6、PC7、PB5、PC9 对应 TIM8 CH1–4 |
| IMU SPI | PB2 SCK、PB14 MISO、PB15 MOSI，PB1/PC5 片选 |
| IMU 加热 PWM | PB10 TIM2_CH3 |
| LCD SPI | PA5 SCK、PA6 MISO、PA7 MOSI、PA4 CS |
| 配套 LCD 控制 | PB3 背光、PB4 RESET、PC1 DC |
| 扩展备用 | PB6/PB7 I2C1 引脚预留，未添加 I2C 驱动；PC2/PC3 保留未使用 |

LCD 默认选配套 ST7789 模块，因此 PB3/PB4 用作 GPIO。自定义 I2C2 模块需要改成 I2C2 并关闭对应屏幕功能。
IMU 默认使用 SPI BMI088。I2C1 是替代扩展接口，需要时另行增加驱动和时序配置。

## 时钟与默认参数
- 主频与总线 144 MHz，系统源 HSIS；板载 HSE 8 MHz。USB 48 MHz。配置包含供 CAN 使用的 PSI 时钟设置。
- RS485 两路 2 Mbps、8N1，硬件 DE 高有效，接收超时 150 bit，DMA 接收循环、发送直接传输。2 Mbps 是工程默认值，手册给出的收发器能力上限为 10 Mbps。
- 普通串口 115200、8N1，DMA 收发。
- SBUS 100000、8E2、仅接收。HAL 字长设置为 9 位是包含偶校验位的配置。手册第 8 页 Q1 已作硬件反相，UART 软件 RX 反相关闭。
- SPI1/SPI2 主机、8位、MSB、模式0、9 MHz，软件片选。9 MHz 是保守默认值。
- TIM3 蜂鸣器 4 kHz，PSC=143、ARR=249、CCR3=125，初始化不等于启动输出。
- TIM2 加热 PWM 1 kHz，PSC=143、ARR=999、CCR3=0，加热电源保持关闭。
- TIM8 四路 PWM 50 Hz，PSC=143、ARR=19999、CCR1–4=0。按舵机用途选择50Hz，可按执行器要求修改。需要输入捕获时再改变对应通道模式。
- ADC 12 位，长采样时间，规则组软件触发。采样速率由应用调用决定。
- CAN FD 当前默认采用已有配置的 1 Mbps 仲裁 / 8 Mbps 数据时序。手册说明最大8Mbps，实际总线所有节点的模式、波特率及终端需一致。
- 电源开启、PWM启动、USB CDC 数据处理及业务协议仍由应用层完成。
- 未使用 GPIO 不主动输出，BOOT_SEL 选项字节未修改。

## 验证与下一步
已校验各内嵌 JSON 块可以解析，目标名称已统一 RET6，核对关键引脚和定时器公式。
尚未完成 MX2 重新加载后的诊断清零、重新生成及实板验证。此前基础工程的编译通过不能证明本次新增外设配置通过。
请在 MX2 重新打开 DM_MC01_V2.ioc2，检查错误列表后再生成，生成时对 CMakeLists.txt/main.c 等用户修改选择逐项合并。
旧手工配置保存在 Git 提交 6df0f44，可用于比较和恢复。
