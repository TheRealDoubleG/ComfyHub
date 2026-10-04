# ComfyHub Changelog

## 0.22 Beta – 04.10.2026
- Minimap flyout now uses a fixed top-right anchor beside the Hub button and expands to the left.
- Added grouped Lua-error capture with duplicate counters and unread status.
- Added a compact error indicator with badge in the Hub flyout.
- Added Blizzard, Comfy Silent and Everything Silent error modes.
- Added grouped error report text, mark-read and clear handling.

## 0.21 Beta – 04.10.2026
- Added the first playtest error-management enhancements and grouped error database.

## 0.20 Beta – 28.09.2026
- Continued Comfy Suite registry and minimap-hub integration for the full addon family.

## 0.19 Beta – 28.09.2026
- Added ComfyCastBar, ComfyFrames and ComfyHeal to the Comfy Suite registry and flyout.
- The new addons can be opened directly from ComfyHub once loaded.
- ComfyCastBar and ComfyFrames use the shared Suite Edit Mode; ComfyHeal registers its Dispel Center.

## 0.18 Beta – 28.09.2026
- Added the shared Comfy Suite layout/edit-mode registry.
- Added a Settings toggle and /ch edit command for Suite edit mode.
- Comfy addons can register movable UI targets without becoming dependent on ComfyHub.

## 0.17 Beta – 28.09.2026
- Added ComfyBattleText to the Suite registry and ComfyHub minimap flyout.

## 0.16 Beta – 28.09.2026
- Added ComfyQoL and ComfyMaps to the Suite registry and minimap collector.
- Compacted the Suite page to fit the expanded addon family.
- Switched the minimap collector to a compact 4-column layout.

## 0.15 Beta – 28.09.2026
- Registered ComfyHub in Blizzard's native AddOns settings list.
- Expanded the minimap collector to every user-facing Comfy addon.
- Switched the collector panel to a compact 3-column layout.
- Kept ComfyData and ComfyDataVault as non-openable background services in the Suite registry.

## 0.14 Beta – 28.09.2026
- Added ComfyGatherer and ComfyKills to the Suite registry and compact minimap flyout.
- Added ComfyData and ComfyDataVault to the Suite registry as background services.
- Compacted the Suite page so the expanded addon family still fits cleanly.
- Background data services no longer show an unusable Open button.

## 0.13 Beta – 27.09.2026
- Fixed the experimental Addons preview so the old layout no longer shows through behind it.
- Realigned the preview filter, search, sort and Profiles controls.
- Fixed Background opacity so 0% fully removes the Comfy window background while the border can remain.
- Aligned the shared Load / copy control with its profile dropdown.

## 0.12 Beta – 27.09.2026
- Replaced the circular Suite minimap flyout with a compact 2-column grid.
- Flyout now opens beside the minimap toward the center of the screen.
- Removed the oversized backdrop that could cover much of the minimap.
- Installed Suite shortcuts are packed tightly without empty slots.

## 0.11 Beta – 27.09.2026
- Switched the normal CPU path to WoW Forever's native C_AddOnProfiler API.
- Added current, recent-average, peak and encounter CPU time columns in milliseconds.
- Removed the need to toggle scriptProfile or reload the UI for normal Forever CPU measurements.
- Expanded the Comfy Suite registry with ComfyEnemyBar, ComfyPanel, ComfyBag, ComfyMog, ComfyXP, ComfyProfiles and ComfyKey.
- Reworked the Comfy Suite page into a compact eleven-addon list.
- Kept the minimap flyout compact: management shortcuts plus the existing core tools are shown, while the full suite remains available in ComfyHub.

## 0.10 Beta – 27.09.2026
- Added an optional experimental compact manager preview under Settings for local layout comparison.
- The preview uses an original ComfyHub implementation with Blizzard/Comfy assets only; no Addon Manargl code or artwork is copied.
- Added a darker compact manager surface with search, filter, sort, profile shortcut, status metrics and dense addon rows.
- The preview keeps the same ComfyHub addon enable/disable queue, search/filter/sort model, refresh button and Apply & Reload flow.
- Added compact summary metrics for current sampled CPU, addon RAM, enabled addon count and compatibility-problem count.
- The standard Explorer-style ComfyHub addon view remains the default and can be restored instantly by unticking the Settings option.
- Marked the preview as temporary test UI to be removed or redesigned before a public CurseForge release.
- No Retail/Midnight/Classic-only API or feature was introduced; WoW: Forever remains the only compatibility target.

## 0.9 Beta – 27.09.2026
- Added addon search across title, folder name, version and addon description.
- Added list filters for all, enabled, disabled, loaded and problem-state addons.
- Added sorting by Comfy Suite first, name, memory usage or compatibility status while keeping the compact Explorer-style list.
- Added row tooltips with addon description, folder name, loaded/enabled state and reported load reason.
- Optimized RAM sampling so UpdateAddOnMemoryUsage is no longer forced every second while ComfyHub is open.
- Added configurable RAM refresh cadence: manual only, 5 seconds, 10 seconds or 30 seconds; manual Refresh always forces a fresh sample.
- Kept the existing WoW: Forever/legacy CPU path instead of depending on Retail/Midnight-only profiler APIs.
- Documented ComfyHub as a WoW: Forever-only target; Retail/Midnight/Classic are not compatibility targets.
- Changes were inspired by general addon-manager lessons such as filtering, sorting and memory-update throttling, without copying Addon Manargl code or its multi-client architecture.

## 0.8 Beta – 27.09.2026
- Added the suite-wide Settings tab immediately before Info.
- Added standalone per-character, account and named custom saved profiles, including copying another known character profile as a template.
- Added settings-window lock, 10–100% window opacity, optional Blizzard border, minimalist black/grey background mode and independent background opacity.
- Moved ComfyHub minimap and suite-icon bundling controls into Settings.
- Reworked the Addons page into a tighter details-list layout with addon icons and subtle row separators.
- Removed the unsupported status glyph that appeared as a square before Compatible.
- Hardened CPU profiling across legacy and C_AddOns APIs and added clear collecting/unavailable states.
- Changed active tabs to use a selected/pushed state instead of looking disabled.
- Cleaned Info footer spacing.

## 0.7 Beta – 27.09.2026
- Reworked the minimap flyout into a tighter arc around the minimap edge.
- Added a subtle dark flyout background with a thin bronze WoW-style border.
- Reduced the visual weight of the ComfyHub/flyout icon border to better match the minimap frame.
- Added a Comfy Suite option to bundle or restore the individual addon minimap buttons.
- Fixed ComfyBar remaining visible while bundling was enabled.
- Fixed individual addon minimap buttons not restoring/hiding consistently when bundling was toggled.
- Collapsed state now shows only the ComfyHub minimap button.

## 0.6 Beta – 27.09.2026
- Added ComfyMacro to the Comfy Suite registry.
- Added ComfyMacro to the Comfy Suite page and central minimap flyout.
- Updated the family UI standard to include ComfyMacro.

## 0.5 Beta – 27.09.2026
- Hardened Lua error capture so the logger cannot recursively trigger itself.
- Starts capture during ComfyHub loading and re-checks the handler after login.
- Improved the copy field scrolling for larger error logs.
- Added compatibility guards for optional EditBox methods.

## 0.4 Beta – 27.09.2026
- Added a dedicated Debug tab for Lua errors.
- Added an in-game toggle for WoW's scriptErrors setting.
- Added session-based Lua error capture with a 50-error limit.
- Added a scrollable, selectable Lua error log for easy Ctrl+A / Ctrl+C copying.
- Added Select all and Clear log buttons.
- Fixed the duplicate English Info-title localization entry.

## 0.3 Beta – 27.09.2026
- Updated the Comfy Suite integration from OnPoint to ComfyOnPoint.
- The ComfyHub minimap flyout now opens ComfyOnPoint.
- The Comfy Suite tab now lists ComfyOnPoint.
- Updated the family UI standard and documentation to the new addon name.

## 0.2 Beta – 27.09.2026
- Established ComfyHub as the reference implementation for the shared Comfy Suite UI standard.
- Standardized tab geometry and Info-tab structure with OnPoint, ComfyBar and ComfyCC.
- Added the Comfy Suite badge and copy-friendly GitHub field.
- Added Comfy Suite metadata to the TOC for family identification.
- Added the canonical COMFY_FAMILY_UI_STANDARD.md for all current and future suite addons.

## 0.1 Beta – 27.09.2026
- Initial ComfyHub foundation.
- Added installed-addon discovery with compatibility status.
- Added enable/disable controls with one-click Apply & Reload.
- Added per-addon and total memory reporting.
- Added optional CPU profiling hooks where supported by the client.
- Added a central minimap button.
- Added a Comfy Suite minimap flyout for OnPoint, ComfyBar and ComfyCC.
- Added direct settings opening for loaded Comfy Suite addons.
- Added Addons, Performance, Comfy Suite and Info tabs.
- Added German and English localization.
