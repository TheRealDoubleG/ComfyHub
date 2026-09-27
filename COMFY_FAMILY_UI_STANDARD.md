# Comfy Suite UI Standard

**Standard version: 2**  
**Maintainer: TheRealDoubleG**  
**Applies to:** ComfyHub, ComfyOnPoint, ComfyBar, ComfyCC, ComfyMacro, ComfyEnemyBar, ComfyPanel, ComfyBag, ComfyMog, ComfyXP, ComfyProfiles, ComfyKey and all future Comfy Suite addons.

This document is the visual and structural baseline for the addon family. Individual addons may have different feature tabs and window sizes when their content requires it, but they should remain immediately recognizable as part of the same suite.

## Window standard

- Use Blizzard's `BasicFrameTemplateWithInset`.
- Use `HIGH` frame strata and frame level 20 for settings windows.
- Settings windows are movable, clamped to the screen, raised when clicked and remember their position.
- Standard addon windows use **760×620** where practical.
- Larger tools such as ComfyHub may use a wider window when required by tables or dashboards.
- Pages use the same inner margins: top-left at **12, -70** and bottom-right at **-12, 12**.
- Tabs appear across the top using the same Blizzard button style, **110 px** width and **120 px** spacing where practical.
- The active tab remains enabled and uses the pushed/selected Blizzard button state; do not make the selected tab look disabled or grey.
- Every addon has a shared **Settings / Einstellungen** tab immediately before **Info**.
- The **Info** tab is always the final tab.

## Info-tab standard

Every addon must provide the same information structure:

1. Addon name in `GameFontNormalHuge`.
2. Gold **Comfy Suite** family badge in the top-right.
3. One-line addon description/tagline.
4. Version.
5. Build date.
6. Release status.
7. Current WoW Forever client / build / interface.
8. Tested target / build / interface.
9. Compatibility state, green when matching and red/orange when attention is required.
10. Author: **TheRealDoubleG**.
11. Discord: **the.real.double.g**, shown in a copy-friendly edit box.
12. GitHub repository, shown in a copy-friendly edit box.
13. Primary slash commands.
14. Addon-specific UI-only / no-automation notice.
15. Copyright: **© 2026 TheRealDoubleG**.
16. Footer: thanks for using the addon and an invitation to send feedback/bug reports via Discord.

The standard Info panel is **680×455**, positioned at **20, -52** inside the Info page. Standard text widths and row positions follow the ComfyOnPoint/ComfyBar reference implementation.

## Shared Settings tab

The Settings tab contains suite-wide behavior and presentation controls that are not part of the addon's primary feature workflow:

- Automatic per-character saved profile (default).
- Optional account profile.
- Named custom profiles.
- Copy/load another known character profile into the current character profile.
- Profile creation, deletion and reset without requiring another addon.
- Settings-window position lock and position reset.
- Overall window opacity from **10–100%** so the window cannot accidentally become fully invisible.
- Optional Blizzard frame/border.
- Minimal black/grey borderless background mode.
- Independent background opacity from **0–100%**.
- Minimap icon visibility/lock controls where the addon has a minimap icon.
- ComfyHub additionally owns Comfy Suite minimap-icon bundling.

A future optional **ComfyProfiles** addon may provide a central profile-management front end, but individual addons must keep their own profile engine and remain fully usable without it.

## Family metadata

Every suite addon TOC must include:

```
## X-ComfySuite: true
## X-ComfyUI: 2
```

`X-ComfyUI` identifies the family UI-standard generation. Standard generation **2** adds the shared Settings/profile/window system and selected-tab behavior.

## Menu language and behavior

- German client: German labels where translations exist.
- Other clients: English.
- Use the same wording patterns across addons, for example **Enable <AddonName>** / **<AddonName> aktivieren**.
- Use Blizzard-native controls where possible.
- Avoid modern web-style cards or unrelated visual themes.
- Gold is the family accent; green indicates compatible/active; yellow indicates attention/out-of-date; red indicates incompatible/error.

## Standalone behavior

Every addon remains usable on its own. ComfyHub may provide shortcuts, grouping and a central minimap flyout, but the other addons must not require ComfyHub to function.

## Versioning rule

Every code, behavior or UI change increments that addon's version. Changelogs and TOC versions must be updated together.
