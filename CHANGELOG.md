# ComfyHub Changelog

## 0.7 Beta – 27.09.2026
- Reworked the minimap flyout into a tighter arc around the minimap edge.
- Added a subtle dark flyout background with a thin bronze WoW-style border.
- Reduced the visual weight of the ComfyHub/flyout icon border to better match the minimap frame.
- Added a Comfy Suite option to bundle or restore the individual addon minimap buttons.
- Fixed ComfyBar remaining visible while bundling was enabled.
- Fixed individual addon minimap buttons not restoring/hiding consistently when bundling was toggled.
- Collapsed state now shows only the ComfyHub minimap button.


## 0.6 Beta – 27.09.2026
- Added **ComfyMacro** to the Comfy Suite registry.
- Added ComfyMacro to the Comfy Suite page and central minimap flyout.
- Updated the family UI standard to include ComfyMacro.


## 0.5 Beta – 27.09.2026
- Hardened Lua error capture so the logger cannot recursively trigger itself.
- Starts capture during ComfyHub loading and re-checks the handler after login.
- Improved the copy field scrolling for larger error logs.
- Added compatibility guards for optional EditBox methods.


## 0.4 Beta – 27.09.2026
- Added a dedicated Debug tab for Lua errors.
- Added an in-game toggle for WoW's `scriptErrors` setting.
- Added session-based Lua error capture with a 50-error limit.
- Added a scrollable, selectable Lua error log for easy Ctrl+A / Ctrl+C copying.
- Added Select all and Clear log buttons.
- Fixed the duplicate English Info-title localization entry.


## 0.3 Beta – 27.09.2026
- Updated the Comfy Suite integration from OnPoint to **ComfyOnPoint**.
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
