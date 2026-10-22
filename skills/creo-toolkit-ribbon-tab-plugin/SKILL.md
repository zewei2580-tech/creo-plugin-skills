---
name: creo-toolkit-ribbon-tab-plugin
description: Create, convert, localize, build, persistently auto-start, inject, live-switch, and validate a native Creo Parametric TOOLKIT C/C++ plugin that appears as one or more independent Ribbon tabs and groups with mandatory small icons, visible Chinese names, and a unique recognizable icon for every command. Use when the user asks for a Creo plugin like Codex Tools, a dedicated tab, grouped commands, portable UI layout, Chinese command labels, toolkitribbonui.rbn, ProRibbonDefinitionfileLoad, verified automatic loading through the effective config.pro, or any new versioned DLL that must be injected, registered, stopped, reloaded, or switched through Creo Auxiliary Applications.
---

# Creo Toolkit Ribbon Tab Plugin

Build a native TOOLKIT application whose commands appear in a dedicated Creo Ribbon tab. Treat localization and Ribbon deployment as required deliverables; configure persistent startup only when requested.

## Selection Rule

Use this presentation when the plugin has several commands, needs stable groups or tabs across computers, or must show labels and icons directly on the Ribbon.

Use `creo-toolkit-legacy-menu-plugin` instead for a small utility that should live in the traditional Toolkit menu and does not need a `.rbn` layout.

Creo UI Editor creates Toolkit dialog resources. Create a Ribbon definition with Creo Parametric's **Customize Ribbon** interface. Do not hand-edit `.rbn`; PTC documents it as a generated binary definition file.

## 算法先验证，整合后验证真实按钮

开发或修复 CAD 算法时，默认分为以下两个阶段。后文的 DLL 注册、切换和发布流程适用于整合阶段，不要求每次算法试验都重新注册插件。仅修改菜单、资源、注册或加载问题时，直接验证对应的插件入口，不强行增加独立算法试验。

1. **算法阶段**：优先用独立 TOOLKIT 测试程序连接明确识别的真实 Creo 测试会话，调用原生 API 或必要的原生命令，快速编译、运行和定位问题。这是真实 Creo 中的算法验证，不是离线模拟。使用用户授权的测试数据与修改范围，按任务要求核对几何、尺寸、关联及再生结果；记录测试程序/源码版本、Creo 版本、输入和结果。测试程序或模型操作失败时不能只凭进程退出码、宏返回成功判断功能完成。
2. **整合阶段**：算法通过后，将验证过的实现及必要依赖整合到正式插件或配套处理程序。尽量复用同一实现，移除诊断用硬编码路径和人工补救步骤；特别检查 DLL 回调与异步 TOOLKIT 的命令时序、会话连接、窗口切换及错误处理差异。构建最终版本并依照用户授权完成真实 DAT 注册/加载，从实际菜单或 Ribbon 按钮执行到最终结果，核对实际加载的 DLL、配套程序版本和业务验收指标。不能用直接调用 helper、编译成功、初始化成功或按钮出现代替完整命令验证。

独立测试程序成功仅表示“算法已验证”；真实按钮完整通过才表示“插件功能已验证”。若本次还要求独立包，必须用最终包内实际 DAT、DLL、处理程序和资源验证真实按钮，而不是复用开发目录的文件。未完成的阶段要明确标注，不宣称已交付可用。此流程不额外授权修改启动配置、关闭会话、保存模型或新增备份，也不要求每次算法修改都重新打包。

## Required Workflow

1. Locate the real source tree, current loaded DLL, active `protk.dat`, Creo version, and Toolkit include/lib directories. Prove the path of the `config.pro` Creo actually reads at startup; a file found under the plugin, build, output, test, fixture, or sample tree is not proof.
2. Preserve unrelated user changes. Archive the source, registration files, message files, Ribbon files, and effective configuration before modifying them.
3. Use a new versioned DLL filename. Never overwrite a DLL loaded by the active `xtop.exe`. Keep the `protk.dat` `name` stable after a Ribbon is generated; the auxiliary-application owner is part of the Ribbon identity.
4. Register every command with `ProCmdActionAdd`, set its PNG icon with `ProCmdIconSet`, and designate its label/help/description with `ProCmdDesignate`. Capture and log both return values.
5. Register commands before calling `ProRibbonDefinitionfileLoad`.
6. Generate or update the Ribbon through Creo's **Customize Ribbon** interface with `tk_enable_ribbon_custom_save yes`.
7. Save the generated definition as `toolkitribbonui.rbn` under a supported Ribbon search directory. Record the exact owning `protk.dat` application name in `text/ribbon/ribbon_application_name.txt`.
8. Localize command, tab, and group labels. Keep stable internal command IDs; translate only displayed text. Save message files as valid UTF-8 with BOM and strict four-line records: key, source text, localized text, `#`. Blank separator lines, stray `#` lines, duplicate keys, and unterminated records are forbidden. Deploy the exact filename referenced by `ProCmdDesignate` under both `text/chinese_cn/` and `text/usascii/`, then verify every key resolves in each deployed copy and the Chinese copy contains real Chinese labels.
9. Run `scripts/create_icon_contact_sheet.ps1` and inspect the complete 16×16 PNG icon set for duplicates and ambiguity.
10. Build, inspect exported `user_initialize` and `user_terminate`, and verify the output DLL architecture.
11. Update `protk.dat`.
12. Check the proven effective `config.pro` read-only. Install persistent startup only when it is part of the user-authorized task. Runtime version switching and startup configuration are separate operations.
13. Run non-mutating validation against the current files. Separate failures introduced by the current change from unrelated pre-existing plugin-suite findings.
14. For an authorized runtime update/test, perform the automated Auxiliary Applications transition below, including closing the dialog. For build-only or manual-registration requests, provide the exact DAT path and mark runtime validation pending.
15. Verify the actual loaded version, real Ribbon, and requested command result. Distinguish algorithm validation, integrated-button validation, and final-package validation.

## Automated Runtime Version Switching

For an authorized plugin iteration that includes loading/testing, follow [references/live-version-switch.md](references/live-version-switch.md): build a new versioned DLL, stop the exact old application, remove only a stopped obsolete registration if needed, register the stable absolute DAT, start the new version, close Auxiliary Applications, and verify the real button and result. Reuse authorization already established for this task instead of asking the user to repeat these clicks every time.

Do not apply runtime switching to documentation-only or build-only work. If automation is unavailable, unsafe, or explicitly unwanted, hand over the exact DAT path and identify the unverified stage. Never force-close Creo.

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
   ├─ ribbon/
   │  └─ toolkitribbonui.rbn
   ├─ chinese_cn/
   │  ├─ plugin_msg.txt
   │  └─ ribbon/
   │     └─ toolkitribbonui.rbn
   ├─ usascii/
   │  ├─ plugin_msg.txt
   │  └─ ribbon/
   │     └─ toolkitribbonui.rbn
   ├─ resource/
   │  ├─ command.png
   │  └─ command_large.png
   └─ plugin_msg.txt
```

`ProRibbonDefinitionfileLoad(L"toolkitribbonui.rbn")` searches the current directory, `<text_dir>\ribbon`, and `<text_dir>\<language>\ribbon`. Do not rely only on a file placed directly under `<text_dir>`.

## Ribbon Rules

- Preserve the user's existing Ribbon contract by default: do not rename, remove, reorder, regroup, or replace existing tabs, groups, or commands unless the user explicitly identifies the exact UI change. Append new commands after the existing sequence and keep existing command IDs, localized labels, and generated layout resources unchanged. Treat a prior screenshot or working Ribbon as the authoritative order when available.
- Keep the auxiliary application `name` and command IDs stable. Version the DLL filename and release artifacts, not the Ribbon owner identity. If the application name must change, regenerate and re-export the `.rbn` under that exact name.
- Keep command IDs globally unique across all loaded Toolkit applications.
- Render every command as a 16×16 small icon plus a visible Chinese label. Do not use icon-only buttons.
- Give every command its own semantic PNG icon file. Never reuse one icon for multiple buttons.
- Use native 16×16 PNG plus a matching 32×32 `_large.png`. Do not reference `.ico` for Ribbon commands; Creo can fall back to the same default application icon even when different ICO files exist.
- Make icons recognizable at 16×16: use one clear silhouette or metaphor, high contrast, transparent background, limited detail, and a command-specific color or shape cue.
- Do not rely on tiny letters, numbers, or nearly identical recolors as the only distinction.
- Use command-specific filenames such as `repair_geometry.png`; do not use generic names such as `tool.png`.
- Inspect the actual assets at native 16×16 size and as a complete toolbar set before accepting them. Then inspect the running Ribbon; a contact sheet alone cannot detect Creo fallback icons.
- Use concise Chinese button labels, normally 2–6 Chinese characters. Keep English only as the message-file fallback.
- Split broad toolsets into separate tabs or groups before hiding labels.
- Keep optional 32×32 assets for dialogs or future layouts, but deploy every Ribbon button as small icon plus label.
- Load a single authoritative Ribbon definition per application version.
- Keep a legacy menu only as an intentional fallback; do not accidentally expose every command twice.
- Treat a successful `ProRibbonDefinitionfileLoad` return and visible registered commands as separate checks.

## Startup Registration Contract

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

Only when the user explicitly requests automatic startup installation, run:

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

Otherwise, inspect startup configuration read-only. Follow the authorized runtime-switch workflow independently of persistent startup configuration. The installer backs up the configuration, preserves unrelated settings and other plugins, removes duplicate registrations for the same plugin directory, appends one absolute `protkdat` line, and verifies the result. It refuses an unconfirmed or plugin-local/test `config.pro`, requires `startup dll` plus `delay_start false`, and prints the exact effective path and backup path.

Distinguish these two states:

- **Startup registration installed:** the proven effective `config.pro` contains exactly one registration. It will be read on the next full Creo launch.
- **Automatic startup runtime-proven:** after a user-controlled full exit and relaunch, the new `xtop.exe` start time predates the plugin initialization evidence, and the newest trail/startup log or Auxiliary Applications plus the visible Ribbon proves that Creo loaded the registered application. A live Auxiliary Applications start proves only the current session, not automatic startup.

Do not force-close Creo to obtain the second state. When the user has not restarted, report the first state accurately and leave post-restart verification pending.

## Verification Gate

Do not report completion until all are true:

- The versioned DLL exists and is not the currently locked filename.
- `protk.dat` resolves to the built DLL and existing `text_dir`.
- The proven effective startup `config.pro` was checked read-only. If its stable `protkdat` line is absent, startup registration is explicitly reported as pending for the user.
- `protk.dat` explicitly contains `startup dll` and `delay_start false`.
- The source registers commands before loading the Ribbon.
- A valid `.rbn` exists in a supported Ribbon directory.
- Message keys referenced by `ProCmdDesignate` exist.
- The referenced message file exists under `text/`, `text/chinese_cn/`, and `text/usascii/`; every copy is valid UTF-8 with BOM, consists only of strict key/text/translation/`#` records, contains every designation key, and the Chinese copy resolves every label key to Chinese text.
- Runtime logs show `ProCmdDesignate` returns `PRO_TK_NO_ERROR` for every Ribbon command; `PRO_TK_MSG_NOT_FOUND (-28)` is a release blocker even if the Ribbon tab itself loads.
- Every command has a distinct existing icon referenced by `ProCmdIconSet`; no two buttons reuse the same icon.
- Every icon reference is a native 16×16 PNG with a 32×32 companion, the code checks/logs `ProCmdIconSet` failures, and Creo shows no default placeholder icons.
- `protk.dat` `name` exactly matches `text/ribbon/ribbon_application_name.txt`.
- Every Ribbon command is configured as small icon plus visible name.
- Every displayed button name is concise Chinese, not English and not an internal command ID.
- Every 16×16 icon remains visually distinguishable in a contact-sheet review.
- A screenshot of the real running Ribbon proves Chinese labels and distinct icons; a post-restart check is additionally required only when claiming automatic startup.
- The exact registered DAT path, actual version, closed Auxiliary Applications window, and real command result are recorded; unavailable runtime checks are explicitly pending.
- Startup registration is never described as runtime-proven until a later full Creo launch provides process-time plus trail/log/UI evidence.
- A full restart instruction is provided only when needed for automatic-start proof or when the documented live-switch fallback condition applies.

Use [assets/skeleton](assets/skeleton) as a starting point only; replace all `{{...}}` placeholders and generate the `.rbn` in Creo.
