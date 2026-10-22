# Ribbon Plugin Layout and Registration

## Contents

1. Presentation contract
2. Directory and file responsibilities
3. Initialization order
4. Localization
5. Ribbon generation
6. Startup and versioning
7. Conversion from a legacy menu
8. Automated runtime version switching

## Presentation Contract

A native Ribbon application remains a normal Creo TOOLKIT DLL. The independent tab is created by a generated Ribbon definition file that references commands registered by the DLL.

Required chain:

```text
config.pro protkdat
  -> protk.dat
  -> versioned DLL user_initialize
  -> ProCmdActionAdd / ProCmdDesignate
  -> ProRibbonDefinitionfileLoad
  -> toolkitribbonui.rbn containers and command placement
```

If any link is missing, the DLL may load without a tab or the tab may appear without working commands.

## Directory and File Responsibilities

- `src/plugin.c`: command callbacks, access functions, action registration, Ribbon load, termination cleanup.
- `build.ps1`: resolves the active Creo Common Files path, Toolkit includes/libs, compiler, versioned output filename, and required system libraries.
- `protk.dat`: points Creo to the exact versioned DLL and `text_dir`.
- `text/plugin_msg.txt`: UTF-8-with-BOM source copy of command labels, help, descriptions, and runtime messages.
- `text/chinese_cn/plugin_msg.txt`: deployed Chinese message file; the filename must exactly match the value passed to `ProCmdDesignate`.
- `text/usascii/plugin_msg.txt`: deployed fallback message file with the same complete key set.
- `text/resource`: icon files used by `ProCmdIconSet`.
- `text/ribbon/toolkitribbonui.rbn`: language-neutral Ribbon definition.
- `text/ribbon/ribbon_application_name.txt`: exact stable `protk.dat` `name` that owned the auxiliary UI when the `.rbn` was exported.
- `text/chinese_cn/ribbon`: Chinese-specific Ribbon definition when needed.
- `text/usascii/ribbon`: English fallback Ribbon definition.

The C API search path for `ProRibbonDefinitionfileLoad` is the current directory, `<text_dir>\ribbon`, then `<text_dir>\<language>\ribbon`.

## Initialization Order

Use this order:

```c
ProCmdActionAdd(...);
icon_err = ProCmdIconSet(...);
designate_err = ProCmdDesignate(...);
ProRibbonDefinitionfileLoad(L"toolkitribbonui.rbn");
```

Register all commands before loading the `.rbn`. The `.rbn` only places already known command IDs.
Check and log `icon_err` and `designate_err`; ignoring these return values can leave message keys or default icons visible while the Ribbon itself reports a successful load.

Log the Ribbon load return:

- `PRO_TK_NO_ERROR`: loaded.
- `PRO_TK_E_NOT_FOUND`: wrong directory/name.
- `PRO_TK_INVALID_FILE`: not a valid generated Ribbon file.
- `PRO_TK_IN_USE`: already loaded in this session.

## Localization

Keep internal command names ASCII. Put visible strings in the message file:

```text
Plugin.Command.Label
中文命令
Command
#
Plugin.Command.Help
说明该命令的前置选择和结果
Describe prerequisites and result
#
Plugin.Command.Desc
更完整的中文说明
Full English description
#
```

Generate localized tab/group names through Creo's Ribbon customization workflow. Do not rename command IDs to Chinese.
Save every deployed message file as valid UTF-8 with BOM. Each entry must be exactly four lines—key, source text, localized text, then `#`—with no blank separators, stray terminators, duplicate keys, or unterminated records. Creo resolves Toolkit messages from the active language directory, so the exact filename passed to `ProCmdDesignate` must exist under both `text/chinese_cn/` and `text/usascii/`; keeping only a root `text/` copy is insufficient. Before build, parse the whole file strictly and resolve every label/help/description key in every deployed copy. After restart, require `ProCmdDesignate == PRO_TK_NO_ERROR`; reject `PRO_TK_MSG_NOT_FOUND (-28)` and any visible `...LabelvNNN` text.

## Ribbon Generation

1. Add `tk_enable_ribbon_custom_save yes` temporarily to the effective `config.pro`.
2. Load the Toolkit application so its commands are registered.
3. Open Creo **Customize Ribbon**.
4. Create the independent tab and groups.
5. Add the application's commands and configure every command as **small icon plus visible Chinese label**.
6. Use **Import/Export > Save the Auxiliary Application User Interface**.
7. Place/copy the resulting `toolkitribbonui.rbn` into the application's supported Ribbon directory and record its owning application name in `text/ribbon/ribbon_application_name.txt`.
8. Keep Chinese and `usascii` copies synchronized when the layout is language-neutral.
9. Do not change the `protk.dat` `name` for routine DLL version bumps. If it changes, repeat this GUI export under the new name.

Creo UI Editor is for dialog resources. It is not the supported editor for `.rbn`.

## Button and Icon Standard

Every Ribbon command must satisfy all of these:

- visible label is concise Chinese, normally 2–6 characters;
- button uses a 16×16 small icon plus the visible label;
- icon filename and artwork are unique to that command;
- source references a native 16×16 `.png`, never `.ico`, with a matching 32×32 `_large.png`;
- icon has one clear command metaphor, transparent background, high contrast, and limited detail;
- icon remains distinguishable at native 16×16 size;
- icon does not depend on unreadable text or a number badge;
- similar commands use a coherent family while retaining different silhouettes or strong visual cues.

Create a contact sheet of all 16×16 icons and inspect it before release. Reject duplicate artwork, ambiguous metaphors, clipped edges, muddy low-contrast shapes, and icons that differ only by a tiny letter.
Also inspect the post-restart Ribbon. Repeated default icons are a runtime asset-load failure even when the source files have different hashes.

## Startup and Versioning

Use a new DLL filename per release, for example `plugin_native_v002.dll`. Update `build.ps1` and `protk.dat` `exec_file` together. Do not replace a loaded DLL. Keep the `protk.dat` `name` stable because generated auxiliary Ribbon UI is owned by that application identity.

If the user chooses persistent startup, the effective configuration should contain exactly one registration:

```text
protkdat D:\absolute\plugin-root\protk.dat
```

Runtime switching follows the user's authorized task scope. Persistent startup changes require authorization separately; opening Creo alone is not authorization to modify it.

## Automated Runtime Version Switching

When a plugin update includes runtime integration/testing, follow [live-version-switch.md](live-version-switch.md). Complete Stop, removal of a stopped obsolete registration when needed, Register, Start, and closing Auxiliary Applications, then verify the loaded version and real command. Keep prior authorization for subsequent iterations of the same task. Build-only or manual-registration requests use a handoff instead.

## Conversion from a Legacy Menu

1. Keep existing command callbacks and `ProCmdActionAdd` registrations.
2. Decide whether the legacy menu remains as an intentional fallback.
3. Add icons and complete `ProCmdDesignate` metadata.
4. Generate the `.rbn` in Creo and add `ProRibbonDefinitionfileLoad`.
5. If removing the old presentation, stop calling `ProMenubarMenuAdd` and `ProMenubarmenuPushbuttonAdd`.
6. Validate that each command appears once.
