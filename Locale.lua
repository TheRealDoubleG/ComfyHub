ComfyHub = ComfyHub or {}
local CH = ComfyHub

local locale = GetLocale and GetLocale() or "enUS"
local de = locale == "deDE"

local EN = {
    TAB_ADDONS = "Addons",
    TAB_PERFORMANCE = "Performance",
    TAB_SUITE = "Comfy Suite",
    TAB_INFO = "Info",

    COL_ADDON = "Addon",
    COL_VERSION = "Version",
    COL_STATUS = "Status",
    COL_MEMORY = "RAM",
    COL_CPU = "CPU",

    STATUS_OK = "Compatible",
    STATUS_OUTDATED = "Out of date",
    STATUS_INCOMPATIBLE = "Incompatible",
    STATUS_UNKNOWN = "Unknown",

    APPLY_RELOAD = "Apply & Reload",
    REFRESH = "Refresh",
    PREVIOUS = "Previous",
    NEXT = "Next",
    PAGE = "Page",
    PENDING_NONE = "No pending changes",
    PENDING_ONE = "1 change pending",
    PENDING_MANY = "%d changes pending",

    TOTAL_MEMORY = "Total addon memory",
    CPU_PROFILING = "Enable advanced CPU profiling",
    CPU_RELOAD_HINT = "Changing CPU profiling requires a UI reload. Profiling itself adds a small amount of overhead.",
    CPU_UNAVAILABLE = "CPU profiling is not available or not enabled.",
    PERFORMANCE_HINT = "RAM is sampled from WoW's addon memory counters. CPU is shown as an approximate short-window percentage when profiling is available.",

    SUITE_HINT = "ComfyHub can open the settings of loaded Comfy Suite addons. The minimap flyout uses the same entries.",
    OPEN = "Open",
    NOT_INSTALLED = "Not installed",
    NOT_LOADED = "Not loaded",
    LOADED = "Loaded",

    MINIMAP_LEFT = "Left click: show / hide Comfy Suite",
    MINIMAP_RIGHT = "Right click: open ComfyHub",
    MINIMAP_DRAG = "Drag: move around the minimap",
    MINIMAP_LOCKED = "Minimap button is locked",
    MINIMAP_SHOW = "Show ComfyHub minimap button",
    MINIMAP_LOCK = "Lock ComfyHub minimap button",

    INFO_VERSION = "Version",
    INFO_BUILD_DATE = "Build date",
    INFO_STATUS = "Status",
    INFO_CLIENT = "Current client",
    INFO_TESTED_TARGET = "Tested target",
    INFO_COMPAT_STATUS = "Compatibility",
    INFO_AUTHOR = "Author",
    INFO_DISCORD = "Discord",
    INFO_GITHUB = "GitHub",
    INFO_COMMANDS = "Slash commands",
    INFO_COPY = "Click the field to copy",
    INFO_NOTICE = "ComfyHub manages addon/UI settings and performance information only. It does not automate gameplay.",
    INFO_THANKS = "Thanks for using ComfyHub! Feedback and bug reports are welcome via Discord.",
    COMPAT_MATCH = "Compatible",
    COMPAT_UPDATE_REQUIRED = "Interface differs from the tested target",

    CPU_RELOAD_REQUIRED = "CPU profiling changed. Reload the UI to apply it.",
    ADDON_CHANGE_QUEUED = "Addon setting changed. Apply & Reload when you are ready.",
    SUITE_NOT_LOADED = "%s is installed but not currently loaded.",
    SUITE_NOT_INSTALLED = "%s is not installed.",
}

local DE = {
    TAB_ADDONS = "Addons",
    TAB_PERFORMANCE = "Leistung",
    TAB_SUITE = "Comfy Suite",
    TAB_INFO = "Info",

    COL_ADDON = "Addon",
    COL_VERSION = "Version",
    COL_STATUS = "Status",
    COL_MEMORY = "RAM",
    COL_CPU = "CPU",

    STATUS_OK = "Kompatibel",
    STATUS_OUTDATED = "Veraltet",
    STATUS_INCOMPATIBLE = "Inkompatibel",
    STATUS_UNKNOWN = "Unbekannt",

    APPLY_RELOAD = "Anwenden & UI neu laden",
    REFRESH = "Aktualisieren",
    PREVIOUS = "Zurück",
    NEXT = "Weiter",
    PAGE = "Seite",
    PENDING_NONE = "Keine Änderungen ausstehend",
    PENDING_ONE = "1 Änderung ausstehend",
    PENDING_MANY = "%d Änderungen ausstehend",

    TOTAL_MEMORY = "Gesamter Addon-RAM",
    CPU_PROFILING = "Erweiterte CPU-Messung aktivieren",
    CPU_RELOAD_HINT = "Eine Änderung der CPU-Messung benötigt einen UI-Neustart. Die Messung selbst erzeugt etwas zusätzlichen Aufwand.",
    CPU_UNAVAILABLE = "CPU-Messung ist nicht verfügbar oder nicht aktiviert.",
    PERFORMANCE_HINT = "RAM wird über WoWs Addon-Speicherzähler erfasst. CPU wird – falls verfügbar – als ungefährer Wert über ein kurzes Messfenster angezeigt.",

    SUITE_HINT = "ComfyHub kann die Einstellungen geladener Comfy-Suite-Addons öffnen. Das Minimap-Flyout verwendet dieselben Einträge.",
    OPEN = "Öffnen",
    NOT_INSTALLED = "Nicht installiert",
    NOT_LOADED = "Nicht geladen",
    LOADED = "Geladen",

    MINIMAP_LEFT = "Linksklick: Comfy Suite ein-/ausklappen",
    MINIMAP_RIGHT = "Rechtsklick: ComfyHub öffnen",
    MINIMAP_DRAG = "Ziehen: um die Minimap verschieben",
    MINIMAP_LOCKED = "Minimap-Button ist gesperrt",
    MINIMAP_SHOW = "ComfyHub-Minimap-Button anzeigen",
    MINIMAP_LOCK = "ComfyHub-Minimap-Button sperren",

    INFO_VERSION = "Version",
    INFO_BUILD_DATE = "Build-Datum",
    INFO_STATUS = "Status",
    INFO_CLIENT = "Aktueller Client",
    INFO_TESTED_TARGET = "Getestetes Ziel",
    INFO_COMPAT_STATUS = "Kompatibilität",
    INFO_AUTHOR = "Autor",
    INFO_DISCORD = "Discord",
    INFO_GITHUB = "GitHub",
    INFO_COMMANDS = "Slash-Befehle",
    INFO_COPY = "Feld anklicken zum Kopieren",
    INFO_NOTICE = "ComfyHub verwaltet ausschließlich Addon-/UI-Einstellungen und Leistungsinformationen. Es automatisiert keine Spielaktionen.",
    INFO_THANKS = "Danke, dass du ComfyHub nutzt! Feedback und Fehlermeldungen sind über Discord willkommen.",
    COMPAT_MATCH = "Kompatibel",
    COMPAT_UPDATE_REQUIRED = "Interface weicht vom getesteten Ziel ab",

    CPU_RELOAD_REQUIRED = "CPU-Messung geändert. Lade die UI neu, damit die Änderung aktiv wird.",
    ADDON_CHANGE_QUEUED = "Addon-Einstellung geändert. Wenn du fertig bist, Anwenden & UI neu laden.",
    SUITE_NOT_LOADED = "%s ist installiert, aber aktuell nicht geladen.",
    SUITE_NOT_INSTALLED = "%s ist nicht installiert.",
}

local STRINGS = de and DE or EN

function CH:T(key)
    return STRINGS[key] or EN[key] or key
end
