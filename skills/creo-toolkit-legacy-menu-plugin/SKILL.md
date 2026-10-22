---
name: creo-toolkit-legacy-menu-plugin
description: Create, convert, localize, build, persistently auto-start, inject, live-switch, and validate a native Creo Parametric TOOLKIT C/C++ plugin presented through the traditional Toolkit or menubar menu using ProMenubarMenuAdd and ProMenubarmenuPushbuttonAdd. Use when the user asks for a lightweight Creo utility, a Toolkit-group command list, a plugin without a Ribbon tab or toolkitribbonui.rbn, verified automatic loading through the effective config.pro, or any new versioned DLL that must be injected, registered, stopped, reloaded, or switched through Creo Auxiliary Applications.
---

# Creo Toolkit Legacy Menu Plugin

Build a native TOOLKIT application whose commands appear in Creo's traditional Toolkit/menubar presentation. Treat localization as a required deliverable and configure automatic startup when requested.

## Selection Rule

Use this presentation for small utilities, prototypes, diagnostics, and command sets that do not need a dedicated Ribbon tab or carefully managed icon layout.

Use `creo-toolkit-ribbon-tab-plugin` when the plugin needs a stable independent tab, multiple visual groups, direct labels/icons, or a portable Ribbon arrangement across computers.

This mode is not a different Toolkit binary type. It uses the same `protk.dat` application registration; only the UI registration API differs.

## 算法先验证，整合后验证真实按钮

开发或修复 CAD 算法时，默认分为以下两个阶段。后文的 DLL 注册、切换和发布流程适用于整合阶段，不要求每次算法试验都重新注册插件。仅修改菜单、资源、注册或加载问题时，直接验证对应的插件入口，不强行增加独立算法试验。

1. **算法阶段**：优先用独立 TOOLKIT 测试程序连接明确识别的真实 Creo 测试会话，调用原生 API 或必要的原生命令，快速编译、运行和定位问题。这是真实 Creo 中的算法验证，不是离线模拟。使用用户授权的测试数据与修改范围，按任务要求核对几何、尺寸、关联及再生结果；记录测试程序/源码版本、Creo 版本、输入和结果。测试程序或模型操作失败时不能只凭进程退出码、宏返回成功判断功能完成。
2. **整合阶段**：算法通过后，将验证过的实现及必要依赖整合到正式插件或配套处理程序。尽量复用同一实现，移除诊断用硬编码路径和人工补救步骤；特别检查 DLL 回调与异步 TOOLKIT 的命令时序、会话连接、窗口切换及错误处理差异。构建最终版本并依照用户授权完成真实 DAT 注册/加载，从实际菜单或 Ribbon 按钮执行到最终结果，核对实际加载的 DLL、配套程序版本和业务验收指标。不能用直接调用 helper、编译成功、初始化成功或按钮出现代替完整命令验证。

独立测试程序成功仅表示“算法已验证”；真实按钮完整通过才表示“插件功能已验证”。若本次还要求独立包，必须用最终包内实际 DAT、DLL、处理程序和资源验证真实按钮，而不是复用开发目录的文件。未完成的阶段要明确标注，不宣称已交付可用。此流程不额外授权修改启动配置、关闭会话、保存模型或新增备份，也不要求每次算法修改都重新打包。

## Required Workflow

1. Locate the real source tree, current loaded DLL, active `protk.dat`, Creo version, and Toolkit include/lib directories. Prove the path of the `config.pro` Creo actually reads at startup; a file found under the plugin, build, output, test, fixture, or sample tree is not proof.
2. Preserve unrelated user changes. Archive source, registration files, message files, and effective configuration before modifying them.
3. Use a new versioned DLL filename. Never overwrite a DLL loaded by the active `xtop.exe`.
4. Register every action with `ProCmdActionAdd`.
5. Designate label/help/description keys with `ProCmdDesignate`.
6. Create the parent menu with `ProMenubarMenuAdd`.
7. Add commands with `ProMenubarmenuPushbuttonAdd`, preserving a deliberate order and unique button names.
8. Keep display labels and messages in a localized message file.
9. Build, inspect exported `user_initialize` and `user_terminate`, and verify the output DLL architecture.
10. Update `protk.dat`.
11. Inspect the effective startup configuration; run `scripts/install_startup.ps1 -EffectiveConfigConfirmed` only when persistent startup is part of the authorized task. Never use a test configuration as release evidence.
12. Validate built artifacts and, when requested, the proven effective startup configuration. Report unperformed runtime or startup checks explicitly.
13. When runtime loading/testing is authorized, execute the live version-switch workflow below. Close Auxiliary Applications and verify the real menu command. Do not force-close Creo.

## Live Version Injection

For an authorized plugin iteration that includes runtime loading/testing, use an available Computer Use capability and follow [references/live-version-switch.md](references/live-version-switch.md). Preserve existing task authorization across iterations. Documentation-only, build-only, and explicitly manual requests do not authorize live switching; if automation is unavailable, provide a clear handoff and pending verification status.

The required transition is:

```text
archive current registration
  -> build a new versioned DLL
  -> stop the exact old Auxiliary Application
  -> remove only the stopped obsolete registration when needed
  -> register the current absolute protk.dat
  -> start the new registration
  -> close Auxiliary Applications
  -> prove the new version in logs
  -> open and inspect the real legacy menu
  -> execute and verify the actual command
```

Prefer this live switch over asking the user to repeat Auxiliary Applications clicks. Fall back to a user-performed full Creo exit/restart only when `allow_stop` is false, the Stop action is unavailable, Toolkit refuses to unload, or the new application immediately terminates after a verified registration.

## Canonical Layout

Read [references/layout-and-registration.md](references/layout-and-registration.md) before creating or converting a project.
Read [references/live-version-switch.md](references/live-version-switch.md) whenever Creo is already open or the request mentions a new version, injection, registration, reload, or switching DLLs.

Use:

```text
plugin-root/
├─ src/
│  └─ plugin.c
├─ build.ps1
├─ protk.dat
├─ plugin_native_v001.dll
└─ text/
   ├─ resource/
   │  └─ command.png
   └─ plugin_msg.txt
```

A `.rbn` file and `ProRibbonDefinitionfileLoad` are not required. Do not add them unless intentionally converting the project to the Ribbon presentation skill.

## Legacy Menu Rules

Traditional menus may also display icons. Icons are optional for an initial text-menu utility; the distinction from Ribbon is command placement and grouping, not the mere presence of an icon.

- Preserve the user's existing menu contract by default: do not rename, remove, reorder, regroup, or replace existing commands/buttons unless the user explicitly identifies the exact UI change. Append new commands after the existing sequence, preserving every existing internal button name and localized label. Treat a prior screenshot or working menu as the authoritative order when available.
- Keep internal application, command, menu, and button names ASCII and globally unique.
- Translate displayed labels in the message file.
- Register commands before creating menu buttons.
- Treat `PRO_TK_E_FOUND` as an existing registration only after resolving the command ID.
- Keep one parent menu for a compact toolset; split into deliberate menus when the list becomes too long.
- Do not create duplicate Ribbon and legacy entries for the same command unless the user explicitly requests a fallback UI.
- Keep menu registration errors in a startup log so missing buttons can be diagnosed.

## Persistent Startup When Requested

Keep one stable plugin root and one stable `protk.dat`; version the DLL filename inside it. Do not make the user register a new directory for every build.

Identify the effective startup configuration from positive evidence such as the user's known Creo startup working directory, the shortcut's **Start in** directory, a managed launch script, or an already verified site/user configuration location. Merely finding a nearby `config.pro`, editing a test copy, or seeing a validator pass against a supplied path does not prove Creo reads that file. If the effective path cannot be established, report startup registration as pending instead of claiming completion.

`protk.dat` must use absolute paths:

```text
name        plugin_internal_name
description Localized plugin description
toolkit     OBJECT
creo_type   PARAMETRIC
startup     dll
exec_file   D:\absolute\plugin-root\plugin_native_v001.dll
text_dir    D:\absolute\plugin-root\text
allow_stop  true
delay_start false
end
```

When persistent startup is authorized, run:

```powershell
& "<skill-dir>\scripts\install_startup.ps1" `
  -PluginRoot "D:\absolute\plugin-root" `
  -ConfigPro "D:\work\config.pro" `
  -EffectiveConfigConfirmed

& "<skill-dir>\scripts\validate_plugin.ps1" `
  -PluginRoot "D:\absolute\plugin-root" `
  -ConfigPro "D:\work\config.pro" `
  -EffectiveConfigConfirmed
```

The installer backs up the configuration, preserves unrelated settings and other plugins, removes duplicate registrations for the same plugin directory, appends one absolute `protkdat` line, and verifies the result. It refuses an unconfirmed or plugin-local/test `config.pro`, requires `startup dll` plus `delay_start false`, and prints the exact effective path and backup path.

Distinguish these two states:

- **Startup registration installed:** the proven effective `config.pro` contains exactly one registration. It will be read on the next full Creo launch.
- **Automatic startup runtime-proven:** after a user-controlled full exit and relaunch, the new `xtop.exe` start time predates the plugin initialization evidence, and the newest trail/startup log or Auxiliary Applications plus the visible menu proves that Creo loaded the registered application. A live Auxiliary Applications start proves only the current session, not automatic startup.

Do not force-close Creo to obtain the second state. When the user has not restarted, report the first state accurately and leave post-restart verification pending.

## Verification Gate

Do not report completion until all are true:

- The versioned DLL exists and is not the currently locked filename.
- `protk.dat` resolves to the built DLL and existing `text_dir`.
- If persistent startup was requested, the proven effective `config.pro`, not a test copy, contains exactly one active registration for this plugin; otherwise startup installation is not claimed.
- `protk.dat` explicitly contains `startup dll` and `delay_start false`.
- The source contains `ProCmdActionAdd`, `ProMenubarMenuAdd`, and `ProMenubarmenuPushbuttonAdd`.
- No accidental `ProRibbonDefinitionfileLoad` mixes the presentation modes.
- Message keys referenced by `ProCmdDesignate` exist.
- Chinese display labels are readable and internal identifiers remain stable.
- A live switch was attempted through Auxiliary Applications when Creo was open, and the new DLL version was proven by runtime logs and the actual legacy menu.
- Startup registration is never described as runtime-proven until a later full Creo launch provides process-time plus trail/log/UI evidence.
- A full restart instruction is provided only when needed for automatic-start proof or when the documented live-switch fallback condition applies.

Use [assets/skeleton](assets/skeleton) as a starting point only and replace all `{{...}}` placeholders.
