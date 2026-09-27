# ComfyHub

**Version 0.5 – Beta**  
**Tested target: WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Author: **TheRealDoubleG**  
Discord: **the.real.double.g**

ComfyHub is the central addon manager, performance overview and minimap hub for the Comfy Suite on WoW Forever.

## 0.4 Beta foundation

- Lists installed addons with enable/disable checkboxes.
- Shows installed addon version and WoW interface compatibility.
- Uses three simple compatibility states:
  - **Green:** compatible with the current client.
  - **Yellow:** out of date / interface mismatch.
  - **Red:** an explicit load or dependency problem was detected.
- Shows per-addon memory usage and total addon memory.
- Optional CPU profiling support when the WoW client exposes addon CPU profiling.
- Changes can be prepared first and applied with a single **Apply & Reload** action.
- Central ComfyHub minimap button.
- Left click on ComfyHub toggles a small flyout for **ComfyOnPoint**, **ComfyBar** and **ComfyCC**.
- Right click on ComfyHub opens the manager.
- Flyout buttons open the corresponding Comfy addon settings when that addon is loaded.
- German UI on a German client, English otherwise.
- Blizzard-style Info tab with version, build target, author and Discord contact.

## Comfy Suite

- **ComfyHub** – central addon manager and minimap hub.
- **ComfyBar** – customizable utility bars.
- **ComfyCC** – cooldown countdown numbers.
- **ComfyOnPoint** – cursor-following tooltip improvements.

## Important version-status note

ComfyHub 0.1 can determine whether an installed addon matches the current WoW Forever interface and whether WoW reports a load/dependency problem.

It cannot determine the newest internet release of arbitrary third-party addons from inside the game. A later optional companion/manifest system can add true online version checking for supported addons.

## Slash commands

- `/comfyhub` or `/ch` – open ComfyHub.
- `/ch flyout` – toggle the Comfy minimap flyout.
- `/ch refresh` – refresh addon and performance data.

ComfyHub changes only addon/UI configuration and presentation. It does not automate gameplay.


## Comfy Suite UI standard

ComfyHub is the reference implementation for the shared Comfy Suite menu and Info-tab design. Current and future suite addons should use the same Blizzard-style window treatment, top-tab navigation, persistent window position, Info layout, Comfy Suite badge, compatibility details, author/Discord/GitHub fields and footer styling.

See `COMFY_FAMILY_UI_STANDARD.md` for the canonical family standard.


## ComfyOnPoint integration

ComfyHub 0.3 uses **ComfyOnPoint** as the tooltip addon name throughout the suite. The minimap flyout and Comfy Suite page open the renamed addon directly.


## Lua error tools

ComfyHub 0.5 includes a dedicated **Debug** tab:

- Toggle WoW's Lua error popups on or off from inside ComfyHub.
- Capture up to 50 Lua errors from the current session.
- View all captured errors in one scrollable text field.
- Use **Select all** and then **Ctrl+C** to copy the complete log for bug reports.
- Clear the current session log at any time.

ComfyHub cannot place text directly into the operating system clipboard; WoW requires the user to press Ctrl+C after selecting the text.
