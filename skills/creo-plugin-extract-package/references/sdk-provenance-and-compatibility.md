# Creo TOOLKIT SDK 来源与兼容性核验

此流程用于从已有安装介质提取、归档和选用 TOOLKIT SDK，并为跨版本插件包留下可复查证据。SDK 归档和最终插件包分开；PTC SDK 仅作本地授权构建资料，分享前核对许可，不默认塞进插件交付包或上传仓库。

## 选择和归档 SDK

1. 记录目标 `parametric.exe` 的完整版本、日期码与位数。一个 `Creo N` 名称不足以判断实际 SDK 或编译工具链；以目标介质自带 `protoolkit`、`make_install` 和 PTC 对应版本文档为准。
2. 如介质是 ISO、ZIP、RAR 或 CAB，先只读列目录，定位 `protoolkit/includes/ProToolkit.h` 与架构匹配的库，再提取完整 `protoolkit` 树。旧版库可能叫 `protk_dllmd.lib`，新版可能叫 `protk_dllmd_NU.lib`；Win32 常在 `i486_nt/obj`，Win64 常在 `x86e_win64/obj`。不要凭新版文件名断言旧版 SDK 缺失。不要运行安装器或绕过介质许可来代替提取。
3. 每个版本和位数单独归档。记录原始介质路径、相关 CAB 名、提取路径、文件数、关键头/库路径、ZIP SHA-256；ZIP 内放逐文件 SHA-256 清单，解压后保持 `protoolkit` 相对目录。复用前重新核对文件和哈希。
4. 检查实际库的目标机器类型、SDK 示例构建参数、编译器版本、运行库依赖。不要混合不同 Creo SDK 的头、库、消息文件或 DLL。

## 构建与验证边界

依次记录：`SDK 已提取` → `源码通过目标头文件编译` → `目标库成功链接` → `DLL 位数、导出及依赖检查` → `实际 DAT 加载` → `真实命令与代表模型运行`。只有完成最后两个阶段，才能称相应 Creo 环境已实测通过。缺失对应版本会话时标记“仅构建”，不要说“兼容所有版本”。

- PTC 的[版本兼容规则](https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r11.0/usascii/creo_toolkit/user_guide/Version_Compatibility_Creo_ParametricCreo_and_Creo_Toolkit.html)说明，新 SDK 构建的应用不支持旧 Creo；旧 SDK 构建的应用在新 Creo 上可以运行的情况较多，但不是承诺。每个目标版本均需实机验证。
- 按目标 SDK 的[链接说明](https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r11.0/usascii/creo_toolkit/user_guide/Linking_the_Applications.html)选库和运行时。`ucore46.dll`、`ucore64.dll`、`ucore68.dll` 等依赖是不同构建结果，不可随意复制 Creo 系统 DLL 进包。Creo 8 及之后的 Legacy Toolkit Application Runtime 可能影响旧构建的加载，须核对目标安装选项。
- 本机 2026-10-23 的 Creo 3 Win32/Win64 与 Creo 4 SDK：核心源码可编译，但当前 VS 2026 链接出现 `_MSC_VER` 1700/1900 不匹配及旧 CRT 符号缺失。其介质中的构建文件指定旧工具链参数；解决方式是取得相应 MSVC 工具集（例如 v110/VS 2012）或适用目标日期码的新版正式 SDK，而非压制 LNK2038、伪造 CRT 或将运行库安装包当编译器。微软的[平台工具集说明](https://learn.microsoft.com/en-us/cpp/build/how-to-modify-the-target-framework-and-platform-toolset?view=msvc-170)可用于核对。此观察仅限这批介质，不推广为所有 Creo 4 日期码。
- 本机 Creo 5–11 对应 SDK 已完成隔离的源码编译与 DLL 链接探针；这只证明当前源码/工具链在这些 SDK 下可构建。除用户反馈的 Creo 8 试用外，其余版本不因该探针获得运行验证。跨版本共用 DLL 仍需逐版本 DAT 加载及业务测试。

本机示例归档目录为 `F:\安装包\Creo_Toolkit_SDK_Archive_20261023`，目录中的 `CATALOG.json` 提供每包来源与 ZIP 哈希，ZIP 内 `SDK_MANIFEST.json` 提供逐文件哈希。这是当日证据快照，不是其他机器的默认路径或永久事实；路径不存在时从实际介质重新建立记录。
