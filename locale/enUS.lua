local L = LibStub("AceLocale-3.0"):NewLocale("Skada", "enUS", true)

if not L then return end

L["Disable"] = true
L["Profiles"] = true
L["Hint: Left-Click to toggle Skada window."] = true
L["Shift + Left-Click to reset."] = true
L["Right-click to open menu"] = true
L["Options"] = true
L["Appearance"] = true
L["A damage meter."] = true
L["Skada summary"] = true

L["opens the configuration window"] = true
L["resets all data"] = true

L["Current"] = true
L["Total"] = true

L["All data has been reset."] = true
L["Skada: Modes"] = true
L["Skada: Fights"] = true

-- Options
L["Bar font"] = true
L["The font used by all bars."] = true
L["Bar font size"] = true
L["The font size of all bars."] = true
L["Bar texture"] = true
L["The texture used by all bars."] = true
L["Bar spacing"] = true
L["Distance between bars."] = true
L["Bar height"] = true
L["The height of the bars."] = true
L["Bar width"] = true
L["The width of the bars."] = true
L["Bar color"] = true
L["Choose the default color of the bars."] = true
L["Max bars"] = true
L["The maximum number of bars shown."] = true
L["Bar orientation"] = true
L["The direction the bars are drawn in."] = true
L["Left to right"] = true
L["Right to left"] = true
L["Combat mode"] = true
L["Automatically switch to set 'Current' and this mode when entering combat."] = true
L["None"] = true
L["Return after combat"] = true
L["Return to the previous set and mode after combat ends."] = true
L["Show minimap button"] = true
L["Toggles showing the minimap button."] = true

L["reports the active mode"] = true
L["Skada report on %s for %s, %s to %s:"] = true
L["Only keep boss fighs"] = true
L["Boss fights will be kept with this on, and non-boss fights are discarded."] = true
L["Show raw threat"] = true
L["Shows raw threat percentage relative to tank instead of modified for range."] = true

L["Lock window"] = "Lock window"
L["Locks the bar window in place."] = "Locks the bar window in place."
L["Reverse bar growth"] = "Reverse bar growth"
L["Bars will grow up instead of down."] = "Bars will grow up instead of down."
L["Number format"] = "Number format"
L["Controls the way large numbers are displayed."] = "Controls the way large numbers are displayed."
L["Reset on entering instance"] = "Reset on entering instance"
L["Controls if data is reset when you enter an instance."] = "Controls if data is reset when you enter an instance."
L["Reset on joining a group"] = "Reset on joining a group"
L["Controls if data is reset when you join a group."] = "Controls if data is reset when you join a group."
L["Reset on leaving a group"] = "Reset on leaving a group"
L["Controls if data is reset when you leave a group."] = "Controls if data is reset when you leave a group."
L["General options"] = "General options"
L["Mode switching"] = "Mode switching"
L["Data resets"] = "Data resets"
L["Bars"] = "Bars"

L["Yes"] = "Yes"
L["No"] = "No"
L["Ask"] = "Ask"
L["Condensed"] = "Condensed"
L["Detailed"] = "Detailed"

L["'s Death"] = "'s Death"
L["Hide when solo"] = "Hide when solo"
L["Hides Skada's window when not in a party or raid."] = "Hides Skada's window when not in a party or raid."

L["Title bar"] = "Title bar"
L["Background texture"] = "Background texture"
L["The texture used as the background of the title."] = "The texture used as the background of the title."
L["Border texture"] = "Border texture"
L["The texture used for the border of the title."] = "The texture used for the border of the title."
L["Border thickness"] = "Border thickness"
L["The thickness of the borders."] = "The thickness of the borders."
L["Background color"] = "Background color"
L["The background color of the title."] = "The background color of the title."

L["'s "] = "'s "
L["Do you want to reset Skada?"] = "Do you want to reset Skada?"
L["'s Fails"] = "'s Fails"
L["The margin between the outer edge and the background texture."] = "The margin between the outer edge and the background texture."
L["Margin"] = "Margin"
L["Window height"] = "Window height"
L["The height of the window. If this is 0 the height is dynamically changed according to how many bars exist."] = "The height of the window. If this is 0 the height is dynamically changed according to how many bars exist."
L["Adds a background frame under the bars. The height of the background frame determines how many bars are shown. This will override the max number of bars setting."] = "Adds a background frame under the bars. The height of the background frame determines how many bars are shown. This will override the max number of bars setting."
L["Enable"] = "Enable"
L["Background"] = "Background"
L["The texture used as the background."] = "The texture used as the background."
L["The texture used for the borders."] = "The texture used for the borders."
L["The color of the background."] = "The color of the background."
L["Data feed"] = "Data feed"
L["Choose which data feed to show in the DataBroker view. This requires an LDB display addon, such as Titan Panel."] = "Choose which data feed to show in the DataBroker view. This requires an LDB display addon, such as Titan Panel."
L["RDPS"] = "RDPS"
L["Damage: Personal DPS"] = "Damage: Personal DPS"
L["Damage: Raid DPS"] = "Damage: Raid DPS"
L["Threat: Personal Threat"] = "Threat: Personal Threat"

-- SkadaDebuffs
L["Debuff uptimes"] = true
L["'s Debuffs"] = true

-- SkadaDeaths
L["Deaths"] = true
L["Deaths:"] = true

-- SkadaDamageTaken
L["Damage taken"] = true
L["Attack"] = true
L["'s Damage taken"] = true

-- SkadaDamage
L["DPS"] = true
L["Damage"] = true
L["'s Damage"] = true
L["Hit"] = true
L["Critical"] = true
L["Missed"] = true
L["Resisted"] = true
L["Blocked"] = true
L["Glancing"] = true
L["Absorbed"] = true

-- SkadaDispels
L["Dispels"] = true
L["Dispels:"] = true

-- SkadaFailbot
L["Fails"] = true
L["Fails:"] = true
L["'s Fails"] = true

-- SkadaHealing
L["Healing"] = true
L["HPS:"] = true
L["'s Healing"] = true
L["Overhealing"] = true

-- SkadaThreat
L["Threat"] = true
