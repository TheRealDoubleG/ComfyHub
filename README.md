# ComfyHub

**Version 0.18 – Beta**  
**Tested target: WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Author: **TheRealDoubleG**  
Discord: **the.real.double.g**

ComfyHub is the central addon manager, performance overview and minimap hub for the Comfy Suite on **World of Warcraft: Forever**.

**Target policy:** ComfyHub is developed and tested for WoW: Forever only. Retail/Modern WoW, Midnight and WoW Classic are not compatibility targets. Ideas from other addon managers are used only as architectural lessons when they also make sense on the Forever client.

## 0.4 Beta foundation

- Lists installed addons with enable/disable checkboxes.
- Search installed addons by title, folder name, version or addon description.
- Filter the list by all, enabled, disabled, loaded or problem-state addons.
- Sort by Comfy Suite first, name, memory usage or compatibility status.
- Hover a list row for a compact technical tooltip with folder name, addon description, enabled/loaded state and load reason when available.
- Shows installed addon version and WoW interface compatibility.
- Uses three simple compatibility states:
  - **Green:** compatible with the current client.
  - **Yellow:** out of date / interface mismatch.
  - **Red:** an explicit load or dependency problem was detected.
- Shows per-addon memory usage and total addon memory.
- RAM sampling is throttled instead of forcing WoW's addon-memory update every second; choose manual-only, 5 s, 10 s or 30 s in Performance.
- Native WoW Forever C_AddOnProfiler support with current, recent-average, peak and encounter CPU time in milliseconds; no scriptProfile toggle is required.
- Changes can be prepared first and applied with a single **Apply & Reload** action.
- Central ComfyHub minimap button.
- A shared **Comfy Suite edit mode** registry lets compatible Comfy addons expose movable UI targets through one global toggle.
- Left click on ComfyHub toggles a compact minimap-edge flyout for **ComfyOnPoint**, **ComfyBar**, **ComfyCC** and **ComfyMacro**.
- Comfy Suite minimap buttons are bundled under ComfyHub by default and can be restored from the shared **Settings** tab.
- Right click on ComfyHub opens the manager.
- Flyout buttons open the corresponding Comfy addon settings when that addon is loaded.
- German UI on a German client, English otherwise.
- Blizzard-style Info tab with version, build target, author and Discord contact.
- Shared **Settings** tab immediately before Info with per-character/account/custom profiles, copy-from-character, window lock, window/background opacity, borderless minimalist mode and minimap controls.
- Compact Explorer-style addon details list with addon icons, clean compatibility text and improved CPU sampling feedback.
- Optional **experimental compact manager preview** in Settings. It is a temporary design-comparison mode inspired only by the information density of the supplied Addon Manargl screenshot; the implementation, layout code and graphics remain ComfyHub/Blizzard-native.
- The experimental preview is intentionally marked for removal or redesign before a public CurseForge release.

## Comfy Suite

- **ComfyHub** – central addon manager and minimap hub.
- **ComfyBar** – customizable utility bars.
- **ComfyBattleText** – customizable scrolling combat text and combat notifications.
- **ComfyCC** – cooldown countdown numbers.
- **ComfyOnPoint** – cursor-following tooltip improvements.
- **ComfyMacro** – guided macro builder and assistant.
- **ComfyProfiles** – central Suite profile coordinator.
- **ComfyKey** – keybinding profile manager.
- **ComfyEnemyBar** – lightweight enemy nameplate information.
- **ComfyPanel** – compact information panel.
- **ComfyBag** – unified searchable normal inventory.
- **ComfyMog** – transmog collection tooltip helper.
- **ComfyXP** – XP progress and session pace bar.
- **ComfyQoL** – modular general quality-of-life features.
- **ComfyMaps** – world map enhancements, coordinates and Suite map data.
- **ComfyGatherer** – personal gathering database and minimap tracker.
- **ComfyKills** – mob-kill database and statistics browser.
- **ComfyData** – persistent shared Suite data service.
- **ComfyDataVault** – independent ComfyData snapshot/recovery service.

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

ComfyHub 0.6 includes a dedicated **Debug** tab:

- Toggle WoW's Lua error popups on or off from inside ComfyHub.
- Capture up to 50 Lua errors from the current session.
- View all captured errors in one scrollable text field.
- Use **Select all** and then **Ctrl+C** to copy the complete log for bug reports.
- Clear the current session log at any time.

ComfyHub cannot place text directly into the operating system clipboard; WoW requires the user to press Ctrl+C after selecting the text.


## ComfyMacro integration

ComfyHub 0.6 recognizes **ComfyMacro** as a Comfy Suite addon and includes it in the suite page and minimap flyout.


## Native Forever profiler

ComfyHub 0.11 uses the WoW Forever C_AddOnProfiler API when available. The Performance page shows current tick time, recent average, peak and encounter average in milliseconds for loaded addons. The older scriptProfile CVar is no longer the normal ComfyHub CPU path.


## 0.12 minimap flyout

The bundled Comfy Suite minimap shortcuts now open in a compact 2-column panel beside the minimap instead of spreading around the minimap edge. The panel automatically opens toward the center of the screen to avoid covering the minimap.


## 0.15 Blizzard AddOns + minimap collector

- ComfyHub now registers in Blizzard's native AddOns settings list.
- Every user-facing Comfy addon is available from the compact ComfyHub minimap collector.
- The collector uses a compact 3-column panel beside the minimap.
- ComfyData and ComfyDataVault stay visible in the Suite list as background services but are not placed in the minimap flyout.
