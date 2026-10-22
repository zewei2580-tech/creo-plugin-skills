# Automated Auxiliary Application Version Switch

Use this workflow when the user-authorized plugin development or update task includes loading and testing the new version in a running Creo session. Carry forward that authorization during the same task; do not make the user repeat the GUI sequence after every iteration. Documentation-only, build-only, and explicitly manual-registration requests do not authorize runtime switching.

## Prepare and identify

- Identify the exact Creo process/window, target application name, current DLL, and stable absolute `protk.dat`. Never select an application by row position alone.
- Build a new versioned DLL and validate its resources and architecture. Do not overwrite, move, or delete a loaded DLL.
- Retain the previous registration and recoverable files. Keep the application name stable, particularly for Ribbon ownership.
- Runtime re-registration does not require changing startup configuration. Modify the effective `config.pro` only when automatic startup is part of the authorized task.
- Use an available, authorized Computer Use capability for GUI operations and follow its observation and confirmation rules. If unavailable, provide the exact DAT path and manual steps, and mark runtime verification pending.

## Stop, remove the old registration, register, start, close

1. Activate the identified Creo window and open **Tools > Auxiliary Applications**.
2. Resolve the exact target application. Use **Info** and logs to distinguish similarly named or truncated rows.
3. If running, click **Stop**. Verify the stopped state and termination evidence before continuing.
4. Remove the target's stopped, obsolete registration when necessary to replace it or avoid duplicate registrations. This removes an Auxiliary Applications entry, not DLLs or model files. Never remove an unrelated application or a running entry. Follow any applicable confirmation requirement for this UI operation.
5. Click **Register**. Replace the file dialog's path with the complete absolute path to the current `protk.dat`; do not append it to an existing filename.
6. Re-identify the registered row and verify that its DLL path is the intended new version.
7. Click **Start**. Verify successful initialization and the expected version marker, not merely a row appearing in the list.
8. **Close Auxiliary Applications.** Open the actual Ribbon tab or traditional menu and confirm the expected command entry points.
9. Run the requested command on authorized test data and verify the final CAD result. If model mutation is outside the task's authorization, leave that test pending rather than silently expanding the scope.

For a first installation with no old entry, skip Stop and Remove. For an unchanged already-loaded version, verify its identity rather than cycling it unnecessarily. Independent algorithm experiments do not require this full registration cycle; use it after integration into the formal plugin.

## Stop conditions and recovery

- Stop if application identity is ambiguous, the process has disappeared, or a security/permission prompt needs the user.
- If Stop is unavailable, `allow_stop` is false, unloading fails, or a valid new registration immediately terminates, do not force-close Creo or discard unsaved model work. Preserve the prior configuration and explain the restart blocker.
- Allow one targeted retry after a concrete, identified correction such as a wrong DAT path. Do not loop through unload/register/start indefinitely.
- If the new version cannot start, restore the known-good registration when authorized and feasible. Record what remains loaded; do not report success.
- Do not automatically save models, close unrelated dialogs/sessions, edit other plugin registrations, or delete old binaries as part of this workflow.

## Completion evidence

Record the Creo version/process, application name, old and new DLL names, registered DAT path, Stop/Remove/Register/Start results (including skipped steps), closed Auxiliary Applications window, initialization/version log, actual command UI, and command result. A live switch does not prove automatic startup after a full restart.
