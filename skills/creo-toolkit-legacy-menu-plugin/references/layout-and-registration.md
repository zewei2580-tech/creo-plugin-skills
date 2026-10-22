# Legacy Toolkit Menu Layout and Registration

## Contents

1. Presentation contract
2. Directory and file responsibilities
3. Initialization order
4. Localization
5. Startup and versioning
6. Conversion to Ribbon
7. Live version injection

## Presentation Contract

A legacy menu application is a normal Creo TOOLKIT DLL. The DLL creates menu containers and buttons through Toolkit C APIs; no Ribbon definition is required.

Required chain:

```text
config.pro protkdat
  -> protk.dat
  -> versioned DLL user_initialize
  -> ProCmdActionAdd / ProCmdDesignate
  -> ProMenubarMenuAdd
  -> ProMenubarmenuPushbuttonAdd
```

This is why a plugin can load correctly but appear under a Toolkit-style menu instead of as an independent Ribbon tab.

## Directory and File Responsibilities

- `src/plugin.c`: callbacks, access functions, command registration, parent menu and pushbuttons.
- `build.ps1`: resolves Creo Toolkit includes/libs, compiler, and versioned DLL output.
- `protk.dat`: points to the exact DLL and message/icon directory.
- `text/plugin_msg.txt`: localized menu, command, help, and runtime strings.
- `text/resource`: optional icons.

Do not create an unused `.rbn` file. It creates ambiguity during later maintenance.

## Initialization Order

Use this order:

```c
ProCmdActionAdd(...);
ProCmdDesignate(...);
ProMenubarMenuAdd(...);
ProMenubarmenuPushbuttonAdd(...);
```

Use stable unique names for:

- application
- command action
- parent menu
- pushbutton
- message keys

When `ProCmdActionAdd` returns `PRO_TK_E_FOUND`, call `ProCmdCmdIdFind` and validate the returned ID before adding the button.

Log every menu/button return code. A successful DLL load does not prove that every menu button was added.

## Localization

Keep internal names ASCII. Put visible strings in the message file:

```text
Plugin.Menu.Label
插件工具
Plugin Tools
#
Plugin.Command.Label
执行检查
Run Check
#
Plugin.Command.Help
说明命令的前置选择和结果
Describe prerequisites and result
#
```

Use the same message filename in source and the application's `text_dir`.

## Startup and Versioning

Use a new DLL filename per release. Update `build.ps1` and `protk.dat` together. Never overwrite the DLL loaded by active Creo.

The effective configuration must contain exactly one line for the application:

```text
protkdat D:\absolute\plugin-root\protk.dat
```

Run the skill's startup installer and validator after every registration change.

## Live Version Injection

When Creo is already open, do not reduce a version change to editing `protk.dat` and telling the user to restart. Invoke the `computer-use` skill and follow [live-version-switch.md](live-version-switch.md) to stop the exact old application, register the current absolute `protk.dat`, start the new version, and verify both runtime logs and the real legacy menu.

## Conversion to Ribbon

1. Keep callbacks and action registrations.
2. Add complete icon and message metadata.
3. Load the application so Creo knows its commands.
4. Generate an independent tab through Creo **Customize Ribbon**.
5. Save the auxiliary UI as `toolkitribbonui.rbn`.
6. Add `ProRibbonDefinitionfileLoad` after command registration.
7. Remove legacy menu calls unless a duplicate fallback is explicitly required.
8. Switch to the `creo-toolkit-ribbon-tab-plugin` verification gate.
