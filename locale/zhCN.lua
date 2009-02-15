local L = LibStub("AceLocale-3.0"):NewLocale("Skada", "zhCN", false)

if not L then return end

L["Disable"] = "禁用"
L["Profiles"] = "配置文件"
L["Hint: Left-Click to toggle Skada window."] = "左键点击打开窗口"
L["Shift + Left-Click to reset."] = "Shift+左键点击重置"
L["Right-click to configure"] = "右键点击配置"
L["Options"] = "选项"
L["Appearance"] = "外观"
L["A damage meter."] = "伤害统计"
L["Skada summary"] = "Skada概要"

L["opens the configuration window"] = "打开配置窗口"
L["resets all data"] = "重置所有数据"

L["Current"] = "目前"
L["Total"] = "总共"

L["All data has been reset."] = "所有数据已被重置"
L["Skada: Modes"] = "Skada: 模式"
L["Skada: Fights"] = "Skada: 战斗"

-- Options
L["Bar font"] = "条字体"
L["The font used by all bars."] = "所有条的字体"
L["Bar font size"] = "条字体大小"
L["The font size of all bars."] = "所有条的字体大小"
L["Bar texture"] = "条材质"
L["The texture used by all bars."] = "所有条的材质"
L["Bar spacing"] = "条间距"
L["Distance between bars."] = "条与条之间的距离"
L["Bar height"] = "条高度"
L["The height of the bars."] = "条的高度"
L["Bar width"] = "条宽度"
L["The width of the bars."] = "条的宽度"
L["Bar color"] = "条颜色"
L["Choose the default color of the bars."] = "条的颜色"
L["Max bars"] = "最大条数量"
L["The maximum number of bars shown."] = "最大的显示条的数量"
L["Bar orientation"] = "条方向"
L["The direction the bars are drawn in."] = "条的显示方向"
L["Left to right"] = "从左到右"
L["Right to left"] = "从右到左"
L["Combat mode"] = "战斗模式"
L["Automatically switch to set 'Current' and this mode when entering combat."] = "当进入战斗后自动切换到设置'当前'和此模块"
L["None"] = "无"
L["Return after combat"] = "战斗后返回"
L["Return to the previous set and mode after combat ends."] = "当战斗结束后返回原先的设置和模式"
L["Show minimap button"] = "显示小地图按钮"
L["Toggles showing the minimap button."] = "显示/隐藏小地图按钮"

L["reports the active mode"] = "报告当前的模式"
L["Skada report on %s for %s, %s to %s:"] = "Skada报告%s的%s, %s到%s:"
L["Only keep boss fighs"] = "只保留Boss战"
L["Boss fights will be kept with this on, and non-boss fights are discarded."] = "只保留Boss战的纪录, 非Boss战的纪录将被丢弃."

-- SkadaDebuffs
L["Debuff uptimes"] = "减益效果持续时间"
L["'s Debuffs"] = "的减益效果"

-- SkadaDeaths
L["Deaths"] = "死亡"
L["Deaths:"] = "死亡:"

-- SkadaDamageTaken
L["Damage taken"] = "伤害获得"
L["Attack"] = "攻击"
L["'s Damage taken"] = "的伤害获得"

-- SkadaDamage
L["DPS"] = "每秒伤害"
L["Damage"] = "伤害"
L["'s Damage"] = "的伤害"
L["Hit"] = "命中"
L["Critical"] = "暴击"
L["Missed"] = "未命中"
L["Resisted"] = "抵抗"
L["Blocked"] = "被格档"
L["Glancing"] = "偏斜"
L["Absorbed"] = "被吸收"

-- SkadaDispels
L["Dispels"] = "驱散"
L["Dispels:"] = "驱散:"

-- SkadaFailbot
L["Fails"] = "失败"
L["Fails:"] = "失败:"
L["'s Fails"] = "的失败"

-- SkadaHealing
L["Healing"] = "治疗"
L["HPS:"] = "每秒治疗:"
L["'s Healing"] = "的治疗"
L["Overhealing"] = "过量治疗"

-- SkadaThreat
L["Threat"] = "仇恨值"