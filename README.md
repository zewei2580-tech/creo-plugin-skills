# Creo Plugin Skills

[中文介绍](README.zh-CN.md)

Reusable skills for AI-assisted Creo TOOLKIT plugin development: **Ribbon interfaces, traditional menus, automated version switching, real command validation, and standalone packaging**.

## Why I built this

During more than 500 plugin-version iterations, I repeatedly had to stop the old plugin in Creo, remove its old registration, register the new version, start it, and close Auxiliary Applications before testing again.

Those repetitive clicks became exhausting. Writing code was only part of the work; getting the intended DLL into the right Creo session was another task every single time.

I collected that experience into these skills so an AI assistant can follow a repeatable workflow and, within an authorized update/test task, finish the runtime switch instead of handing the same manual steps back to me after every iteration.

These are skill instructions, references, scripts, and templates—not precompiled plugins or a bundled PTC SDK.

## Three skills

| Skill | Purpose | UI convention |
|---|---|---|
| [Ribbon tab plugin](skills/creo-toolkit-ribbon-tab-plugin/SKILL.md) | Dedicated tabs and grouped commands | Uniform 16×16 icons plus Chinese labels; matching 32×32 resources |
| [Traditional menu plugin](skills/creo-toolkit-legacy-menu-plugin/SKILL.md) | Small utilities and compact command lists | Chinese text menus; icons are optional initially |
| [Extract and package](skills/creo-plugin-extract-package/SKILL.md) | Turn selected functionality into a shareable plugin | Required commands, resources, dependencies, and registration files only |

## Interface examples

Traditional menus can also have icons. The difference is where commands are organized: menus/submenus versus a dedicated Ribbon tab.

**Traditional menu examples**

![Traditional plugin menu](assets/traditional-menu-1.png)

![Traditional submenu with icons](assets/traditional-menu-2.png)

**Ribbon tab example**

![Ribbon tab with labeled command icons](assets/ribbon-tab.png)

## Finish the iteration

```text
Identify the exact Creo session and target plugin
  → build a new versioned DLL
  → stop the old target application
  → remove its stopped obsolete registration when needed
  → register the current absolute protk.dat
  → start and confirm the intended new version
  → close Auxiliary Applications
  → run the actual menu/Ribbon command and verify the result
```

Removing a registration means removing an Auxiliary Applications entry, not deleting DLLs or models. First installations skip steps with no old application. Existing authorization carries across iterations of the same task; documentation-only, build-only, or explicitly manual requests do not authorize runtime switching.

Persistent startup configuration is separate from a live reload. Do not overwrite loaded DLLs, force-close Creo, discard unsaved work, or change unrelated plugin registrations. If unloading or automation is unavailable, report the specific blocker and the unverified stage.

## Algorithm first, real button second

Validate CAD algorithms with an independent TOOLKIT test program connected to a clearly identified **real Creo test session**. Then integrate the tested implementation into the formal plugin and verify it from the actual button.

- **Algorithm validated:** the independent test produces the intended CAD result.
- **Plugin feature validated:** the real menu/Ribbon command completes the intended workflow.
- **Distribution validated:** the final package's own DAT, DLL, helpers, and resources pass the checks.

Compilation, initialization, and a visible button are not substitutes for a verified result. UI-only or registration-only changes should test their relevant paths without adding unrelated algorithm experiments.

## Versions and environment

My work currently uses Creo 12 and later. Plugins I develop with the Creo 12 SDK can be used in Creo 12 and Creo 13 when validated for those environments. Follow each actual plugin's supported-version information; this repository does not make every generated DLL universally compatible.

Prepare the target Creo TOOLKIT SDK, an appropriate licensing environment, and a compatible Windows C/C++ toolchain. Build templates require your actual Creo Common Files path. No proprietary SDK, Creo system DLL, or customer CAD model is included.

The detailed skills reference [PTC's compatibility rules](https://support.ptc.com/help/creo_toolkit/protoolkit_pma/r12/usascii/creo_toolkit/user_guide/Version_Compatibility_Creo_ParametricCreo_and_Creo_Toolkit.html).

## Install

Copy the three complete folders under `skills/` into your assistant's skill directory. For Codex, use `~/.codex/skills/`, or the `skills` folder under your configured Codex home. Keep each skill's references, scripts, and assets together.

Invoke the relevant folder name or let the assistant select the matching skill. Specify the desired function, target Creo version, UI style, and authorized model changes/runtime tests. Replace template placeholders when generating a concrete plugin project.

Automated window operations require a supported Computer Use capability in the assistant's environment. These skill files are not an independently executable automatic-registration program. Where GUI control is unavailable, provide a manual handoff and mark runtime validation pending.

## Contact

- WeChat: **ZEWEI2580**
- Email: **992823232@qq.com**
- Email: **zewei2580@gmail.com**

Maintained by [zewei2580-tech](https://github.com/zewei2580-tech).
