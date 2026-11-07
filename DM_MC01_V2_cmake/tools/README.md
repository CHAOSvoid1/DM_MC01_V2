# 工具说明

完整的 CLion 编译、OpenOCD + ST-LINK 下载调试配置见 [仓库首页 README](../../README.md)。

- stm32c5_stlink.cfg 是板卡配置模板，包含维护者的本机 loader 路径，使用前复制并修改。
- stm32c5x.cfg 是目标脚本参考，优先使用 OpenOCD 安装包自带的配套版本。
- get_loader.ps1 从固定远程提交下载 Flash loader 到 tools/stldr，需要联网。
- flash.bat 是 CubeProgrammer 备用下载脚本，使用 STM32CUBEPROG 指定本机安装目录。
- OpenOCD、loader、驱动及个人 CLion 运行配置需要在本机准备。

本机已成功连接的 OpenOCD 版本为 0.12.0+dev-00664-g72f14cee6，来自 STM32CubeIDE 2.2.0。
