# 独立插件打包的历史验证经验

这是维护者对历史测试的总结。个人电脑路径和私有项目文件未随公开仓库提供；这些经验不代表新环境已验证。

- 独立发布 V008；CAD 实现冻结基线 V494；实测 Creo 12.4.3.0、Windows x64、中文环境。
- 入口 `src/plugin.c`，冻结实现 `src/engine`，输出路径 `src/portable_paths.h`。
- 生成器 `installer/generate_dat.c`；构建 `tools/build_dat_generator.ps1`；发布 `tools/package_v008.py`；测试 `tests/test_dat_v008.py`。
- 运行证据 `dist/v008_runtime_verification.json`。

## 证据和推断的边界

1. 旧包沿用原工具 codex_creo_tools_msg.txt 和消息键，存在全局缓存冲突风险。V008 改用独立文件、键、图标和命令。不能只凭结构风险断言每次旧报错都由缓存造成。
2. 同一 V007 DLL 和资源，通过 ProToolkitDllLoad 报 MSG_NOT_FOUND(-28)；通过真正 DAT 注册后，八组消息格式及 UI 注册都返回 0。这组程序接口测试不能作为包损坏判据；更底层差异没有被证明。
3. BOM/无 BOM、中文/英文、第四行空白/# 的实验在真实 DAT 下都能读到。不要臆断 BOM 或中文内容是根因。正式版沿用已验证的 UTF-8 BOM + 四行 # 格式。
4. V008 实际 DAT 日志的 initialize、command、designate、icon、menu、button、用户执行的 detach_result 均为 0，用户确认“已经可以了”。只证明这次加载及所测模型，不证明任意外部依赖都支持。
5. C 盘用户目录当时仍是 V004；移动旧包不会升级 DLL 或修复资源。最终同步包、生成器和实际 DAT，升级要求核对辅助应用真实版本。
6. 早期构建脚本更新 DLL 名后仍生成旧消息文件，依靠手工复制补齐。V008 改为权威消息源生成三份语言目录，构建默认复用冻结实现。

## 排错要点

读取初始化日志最早的非零阶段，再查实际路径和资源。目标 SDK 对 ProCmdDesignate 区分 E_NOT_FOUND（消息文件找不到）和 MSG_NOT_FOUND（一个或多个键找不到）；具体原因仍需现场证据。

消息在会话内缓存。可用新会话或新的诊断文件名区分缓存与新内容，但正式应用身份不应随每次诊断改变。成功要由真实 DAT、日志、UI 和命令结果共同证明。

当时解锁使用 Parametric/bin/protk_unlock.bat -c，随后 -readall 确认 UNLOCKED；直接调用 Common Files 下 exe 曾缺许可环境。以后查当地正式工具与许可，不硬编码本机路径。

官方资料入口，需要具体语义时查目标 SDK 或对应版本资料：
- https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r13/usascii/creo_toolkit/user_guide/Restrictions_on_the_Text_Message_File.html
- https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r12/usascii/creo_toolkit/user_guide/Unlocking_a_Creo_Toolkit_Application.html

本机旧项目可能变化。技能附带生成器模板是独立副本，不依赖上述项目路径存在。

## V498 / 独立 V011 的执行环境经验

2026-10-16，草绘原生 References/Delete 在独立异步 SDK 程序中成功，直接放进 DLL 按钮回调却返回 -26。最终按钮按实际依赖类别自动调用配套异步程序，核对调用者的精确连接ID，执行同一引擎并断开连接，不启动或结束用户 Creo。

配套程序必须随 DLL 分发、使用对应冻结源码构建、正式解锁，并加入 GenerateDAT 的必需文件清单。通信程序位置从调用者 Creo 的实际安装路径推导，不要求朋友预设开发环境变量。主插件在处理期间保留原有保存保护，处理结束后再释放。

真正的端到端验证也发现备份顺序问题：必须在任何修改前完成原始状态复制和磁盘备份，不能修改后再用“必须已保存”检查拦截。V498/V011 最终注册命令及保存重开、尺寸独立性检查通过。
