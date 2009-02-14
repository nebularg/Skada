------------------------------------------------------------------------------
-- Traditional Chinese localization --by andy52005
------------------------------------------------------------------------------
local L = LibStub("AceLocale-3.0"):NewLocale("Skada", "zhTW", false)
if not L then return end

L["Disable"] = "停用"
L["Profiles"] = "設定檔"
L["Hint: Left-Click to toggle Skada window."] = "提示：左鍵點擊切換Skada視窗。"
L["Shift + Left-Click to reset."] = "Shift+左鍵點擊進行重置。"
L["Right-click to configure"] = "右鍵點擊進行設置"
L["Options"] = "選項"
L["Appearance"] = "外觀"
L["A damage meter."] = "一個傷害統計。"
L["Skada summary"] = "Skada一覽"

L["opens the configuration window"] = "開啟配置管理視窗"
L["resets all data"] = "重置所有資料"

L["Current"] = "當前"
L["Total"] = "總體"

L["All data has been reset."] = "所有資料已重置。"
L["Skada: Modes"] = "Skada：模組"
L["Skada: Fights"] = "Skada：作戰"

-- Options
L["Bar font"] = "棒條的字型"
L["The font used by all bars."] = "所有棒條使用這個字型。"
L["Bar font size"] = "棒條的字型大小"
L["The font size of all bars."] = "所有棒條的字型大小。"
L["Bar texture"] = "棒條材質"
L["The texture used by all bars."] = "所有棒條使用這個材質。"
L["Bar spacing"] = "棒條的間距"
L["Distance between bars."] = "棒條之間的距離。"
L["Bar height"] = "棒條高"
L["The height of the bars."] = "棒條的高度。"
L["Bar width"] = "棒條寬"
L["The width of the bars."] = "棒條的寬度"
L["Bar color"] = "棒條顏色"
L["Choose the default color of the bars."] = "變更棒條的預設顏色"
L["Max bars"] = "最大棒條數"
L["The maximum number of bars shown."] = "顯示棒條的最大數量。"
L["Bar orientation"] = "棒條的方向"
L["The direction the bars are drawn in."] = "棒條的方向從哪開始拉長。"
L["Left to right"] = "由左到右"
L["Right to left"] = "由右到左"
L["Combat mode"] = "戰鬥模組"
L["Automatically switch to set 'Current' and this mode when entering combat."] = "當進入戰鬥時，自動切換'當前的'以及選擇的模組。"
L["None"] = "無"
L["Return after combat"] = "戰鬥後返回"
L["Return to the previous set and mode after combat ends."] = "戰鬥結束後返回原先的設定和模組。"
L["Show minimap button"] = "顯示小地圖按鈕"
L["Toggles showing the minimap button."] = "切換顯示小地圖按鈕。"

L["reports the active mode"] = "報告這個現行的模組"
L["Skada report on %s for %s, %s to %s:"] = "Skada報告在 %s 的 %s， %s 到 %s："
L["Only keep boss fighs"] = "只保留首領戰"
L["Boss fights will be kept with this on, and non-boss fights are discarded."] = "將保留與首領之間的戰鬥紀錄，和非首領的戰鬥紀錄將會被消除。"

-- SkadaDebuffs
L["Debuff uptimes"] = "減益效果運行時間"
L["'s Debuffs"] = "的減益效果"

-- SkadaDeaths
L["Deaths"] = "死亡次數"
L["Deaths:"] = "死亡次數："

-- SkadaDamageTaken
L["Damage taken"] = "受到傷害"
L["Attack"] = "近戰攻擊"
L["'s Damage taken"] = "的受到傷害"

-- SkadaDamage
L["DPS"] = "DPS"
L["Damage"] = "傷害"
L["'s Damage"] = "的傷害"
L["Hit"] = "命中"
L["Critical"] = "致命一擊"
L["Missed"] = "未擊中"
L["Resisted"] = "抵抗"
L["Blocked"] = "格擋"
L["Glancing"] = "偏斜"
L["Absorbed"] = "吸收"

-- SkadaDispels
L["Dispels"] = "驅散"
L["Dispels:"] = "的驅散："

-- SkadaFailbot
L["Fails"] = "失誤"
L["Fails:"] = "失誤："
L["'s Fails"] = "的失誤"

-- SkadaHealing
L["Healing"] = "治療"
L["HPS:"] = "HPS："
L["'s Healing"] = "的治療"
L["Overhealing"] = "過量治療"

-- SkadaThreat
L["Threat"] = "威脅值"
