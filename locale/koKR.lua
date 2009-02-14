local L = LibStub("AceLocale-3.0"):NewLocale("Skada", "koKR", false)

if not L then return end

L["Disable"] = "비활성화"
L["Profiles"] = "프로필"
L["Hint: Left-Click to toggle Skada window."] = "힌트:\n좌-클릭으로 Skada 창을 전환합니다."
L["Shift + Left-Click to reset."] = "Shift + 좌-클릭으로 초기화 합니다."
L["Right-click to configure"] = "우-클릭으로 설정창을 엽니다."
L["Options"] = "옵션"
L["Appearance"] = "발표"
L["A damage meter."] = "데미지 미터기입니다."
L["Skada summary"] = "Skada 요약"

L["opens the configuration window"] = "설정 창 열기"
L["resets all data"] = "모든 자료 초기화"

L["Current"] = "현재"
L["Total"] = "전체"

L["All data has been reset."] = "모든 자료가 초기화 되었습니다."
L["Skada: Modes"] = "Skada: 모드"
L["Skada: Fights"] = "Skada: 전투"

-- Options
L["Bar font"] = "바 글꼴"
L["The font used by all bars."] = "모든 바에 사용되는 글꼴입니다."
L["Bar font size"] = "바 글꼴 크기"
L["The font size of all bars."] = "모든 바의 글꼴 크기입니다."
L["Bar texture"] = "바 무늬"
L["The texture used by all bars."] = "모든 바에 사용되는 바 무늬입니다."
L["Bar spacing"] = "바 간격"
L["Distance between bars."] = "바 사이의 간격입니다."
L["Bar height"] = "바 높이"
L["The height of the bars."] = "바의 높이입니다."
L["Bar width"] = "바 너비"
L["The width of the bars."] = "바의 너비입니다."
L["Bar color"] = "바 색상"
L["Choose the default color of the bars."] = "바의 기본 색상을 선택합니다."
L["Max bars"] = "최대 바"
L["The maximum number of bars shown."] = "표시할 바의 최대 수치입니다."
L["Bar orientation"] = "바 진행 방향"
L["The direction the bars are drawn in."] = "바의 진행 방향입니다."
L["Left to right"] = "좌에서 우"
L["Right to left"] = "우에서 좌"
L["Combat mode"] = "전투 모드"
L["Automatically switch to set 'Current' and this mode when entering combat."] = "전투 시작시 '현재'전투의 설정한 모드에 따라 자동적으로 전환합니다."
L["None"] = "없음"
L["Return after combat"] = "전투 후 돌아가기"
L["Return to the previous set and mode after combat ends."] = "전투 종료 후에 이전 설정 및 모드으로 돌아갑니다."
L["Show minimap button"] = "미니맵 버튼 표시"
L["Toggles showing the minimap button."] = "미니맵 버튼 표시를 전환합니다."

L["reports the active mode"] = "활동한 모드 보고"
L["Skada report on %s for %s, %s to %s:"] = "%s - %s의 Skada 보고, %s ~ %s:"
L["Only keep boss fighs"] = "보스 전투만 기록"
L["Boss fights will be kept with this on, and non-boss fights are discarded."] = "보스와의 전투에서만 기록되며, 보스와의 전투가 아니면 기록하지 않습니다."

-- SkadaDebuffs
L["Debuff uptimes"] = "디버프 지속시간"
L["'s Debuffs"] = "의 디버프"

-- SkadaDeaths
L["Deaths"] = "죽음"
L["Deaths:"] = "죽음:"

-- SkadaDamageTaken
L["Damage taken"] = "받은 피해"
L["Attack"] = "공격"
L["'s Damage taken"] = "의 받은 피해"

-- SkadaDamage
L["DPS"] = "DPS"
L["Damage"] = "데미지"
L["'s Damage"] = "의 데미지"
L["Hit"] = "일반"
L["Critical"] = "치명타"
L["Missed"] = "빚맞힘"
L["Resisted"] = "저항"
L["Blocked"] = "방어"
L["Glancing"] = "빗맞음"
L["Absorbed"] = "흡수"

-- SkadaDispels
L["Dispels"] = "해제"
L["Dispels:"] = "해제:"

-- SkadaFailbot
L["Fails"] = "방해"
L["Fails:"] = "방해:"
L["'s Fails"] = "의 방해"

-- SkadaHealing
L["Healing"] = "치유"
L["HPS:"] = "HPS:"
L["'s Healing"] = "의 치유"
L["Overhealing"] = "초과치유"

-- SkadaThreat
L["Threat"] = "위협"
