---
name: creo-ai-connection
description: Connect an AI agent to a running Creo Parametric session through an existing CREOSON/MCP bridge or a version-matched native TOOLKIT controller, identify the exact session and active model, run read-first checks, and verify authorized CAD operations. Use for AI连接Creo、CREOSON/MCP配置、会话连接排错或从AI控制Creo；not for offline SDK compilation alone.
---

# AI 连接 Creo

目标是让 AI 的请求到达**明确识别的 Creo 会话**，并从 Creo 返回可核对的结果。MCP 是 AI 客户端到工具服务器的接口；CREOSON 把 JSON 请求转给 Creo 的 J-Link；原生异步 TOOLKIT 是另一条直接控制路径。不要把“端口能连”“工具已列出”或“进程存在”当作已经连到目标模型。具体接线与来源见 [连接路径和验收](references/connection-and-verification.md)。

## 选连接路径

- 已有可用的 CREOSON + MCP 时，优先复用现有桥接，适合读取活动模型、参数和执行其公开支持的命令。先检查桥接实际工具清单，不臆造 API。
- CREOSON 不支持所需原生几何、事件或精细会话控制时，采用对应 Creo 版本的 TOOLKIT/OTK 异步控制器；使用该版本 SDK 和运行时，按目标环境验证。不要把两种路径的能力混为一谈。
- 插件开发仍使用 Ribbon、传统菜单和打包技能；本技能只负责 AI ↔ Creo 的连接与会话核验，不自动重建或注册插件。

## 连接前确认

1. 记录目标 `parametric.exe` 绝对路径、完整版本、位数、PID、启动时间和目标模型。若有多个 Creo 进程，必须能证明桥接绑定的是哪一个；无法证明时只做诊断，不发模型修改或保存命令。
2. 检查 CREOSON 服务监听在本机地址、端口未冲突，Creo 所需 J-Link/通讯组件在目标安装中可用。使用已安装 Creo 的实际路径配置环境，不把本机示例盘符当作通用路径。启动顺序和环境变量以所用桥接/版本文档为准。
3. MCP 客户端配置必须指向实际存在的 Python/服务器文件；只在本机使用可信桥接，避免把可改写模型的接口暴露到公网。

## 最小验收

1. 读取桥接健康状态，确认服务与 Creo 连接分别成功。
2. 读取当前工作目录和活动模型名称/类型/来源；与预期窗口、文件路径及独立的会话身份核对。活动模型变化后重新核对。
3. 先执行一个只读查询并检查返回值。只有任务授权需要时，才在可恢复的测试模型上执行变更，核对 Creo 中的实际结果和保存状态。
4. 记录桥接版本、Creo 版本、目标进程、请求、返回和最终模型状态。完成后断开自己建立的客户端连接；不结束用户的 Creo 会话。

连接失败先分层排查：MCP 客户端配置 → 桥接进程与端口 → Creo 通讯环境 → 会话/模型身份 → 具体命令。不要仅因重新启动某一层后端口恢复就宣称模型操作成功。
