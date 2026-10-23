# 连接路径与可核对证据

## 连接结构

```text
AI 客户端 → MCP 工具服务器 → CREOSON 本地 JSON 服务 → J-Link → Creo Parametric
AI 客户端 → 本地控制程序 → 异步 TOOLKIT/OTK → Creo Parametric
```

这两条路径各有能力边界。CREOSON 官方说明 JSON 服务通过 J-Link 与 Creo 通讯：[CREOSON 项目](https://github.com/SimplifiedLogic/creoson)。原生异步 TOOLKIT 需要按 PTC 的[通信模式](https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r12/usascii/creo_toolkit/get_started/Communication_Modes_for_Creo_TOOLKIT.html)和[异步应用配置](https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r13/italian/creo_toolkit/user_guide/Setting_up_an_Asynchronous_Creo_Toolkit_Application.html)准备通讯环境。CREOSON 与 MCP 服务本身不属于 PTC SDK，也不是本仓库附带的软件。

## CREOSON + MCP 接线

1. 在目标机安装并启用对应 Creo 的 J-Link；从 CREOSON 官方发行版取得服务，记录其版本。只绑定本机地址。确认服务自己的健康接口可访问后，再接 MCP。
2. 在 MCP 客户端登记本地服务器命令、参数和工作目录。下面仅是结构示例，路径和工具名取决于实际安装；不要直接复制成个人电脑配置：

   ```json
   {
     "mcpServers": {
       "creo-local": {
         "command": "<absolute path to python>",
         "args": ["<absolute path to your CREOSON MCP server>"],
         "cwd": "<bridge project directory>"
       }
     }
   }
   ```

3. 在已有实现中，可按 `health → get_active → pwd` 的只读顺序检查；命令是否存在以该 MCP 服务器实际公开的工具为准。`health` 仅证明链路可达；`get_active` 仅证明返回了某个活动模型，不一定唯一标识 Creo PID。多个 Creo 同时运行时，需要桥接额外提供进程绑定证据，或改用能明确指定连接对象的原生控制器。
4. 每次切换模型或 Creo 窗口后复核活动文件。模型修改、重生、保存和原始命令透传只在用户任务授权的对象上执行；先在副本上检查影响，再查看 Creo 中结果。

## 原生异步 TOOLKIT/OTK 接线

- 使用目标 Creo 安装与匹配 SDK。PTC 文档要求异步应用设置 `PRO_COMM_MSG_EXE` 指向该安装的 `pro_comm_msg.exe`；`PRO_DIRECTORY` 等依实际接口和安装目录核对。参见[PTC 异步应用配置](https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r13/italian/creo_toolkit/user_guide/Setting_up_an_Asynchronous_Creo_Toolkit_Application.html)和[异步 OTK 排错](https://support.ptc.com/help/creo_toolkit/otk_cpp_plus/usascii/creo_toolkit/user_guide/Troubleshooting_Asynchronous_Creo_Object_TOOLKIT.html)。
- 同时有多个会话时，记录并验证目标 PID、启动时间、可执行路径、连接 ID、工作目录和活动模型；拒绝不确定的连接。控制程序不能在异常或超时清理中顺手关闭用户已有的 Creo。
- 开发插件及分版本构建时，再结合 `creo-plugin-extract-package` 的 SDK 来源/兼容性核验流程。编译通过不代表已连接或模型命令通过。

## 实际验收记录

至少记录目标 Creo 完整版本和位数、PID/启动时间、桥接版本及端口、活动模型名称与来源、所调用工具、原始结果、Creo 画面或模型状态的对应结果。把结果分为“服务可达”“Creo 已连接”“目标会话已确认”“只读查询通过”“模型操作通过”。停止在任何一层，都如实报告该层状态。

本技能说明连接方法，不内置 CREOSON、PTC SDK、个人路径、凭据或会修改模型的预设脚本。各安装和接口随版本变化，应以现场文件、工具清单及对应官方文档核对。
