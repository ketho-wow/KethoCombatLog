local _, S = ...

local L = {
	enUS = {
		EVENT_JUKE = "Juke",
		EVENT_CROWDCONTROL = "Crowd Control",

		MSG_TAUNT = "<SRC><SPELL> taunted <DEST>",

		MSG_INTERRUPT = "<SRC><SPELL> "..ACTION_SPELL_INTERRUPT.." <DEST><XSPELL>",
		MSG_JUKE = "<SRC> juked <SPELL> on <DEST>",

		MSG_DISPEL = "<SRC><SPELL> "..ACTION_SPELL_DISPEL_BUFF.." <DEST><XSPELL>",
		MSG_CLEANSE = "<SRC><SPELL> "..ACTION_SPELL_DISPEL_DEBUFF.." <DEST><XSPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> "..ACTION_SPELL_STOLEN.." <DEST><XSPELL>",

		MSG_REFLECT = "<DEST> "..ACTION_SPELL_MISSED_REFLECT.." <SRC><SPELL>",
		MSG_MISS = "<SRC><SPELL> on <DEST> "..ACTION_SPELL_CAST_FAILED.." (<TYPE>)",

		MSG_CROWDCONTROL = "<SRC><SPELL> CC'ed <DEST>",
		-- this particular spell and extraspell order is extra confusing :x
		MSG_BREAK_SPELL = "<SRC><XSPELL> "..ACTION_SPELL_AURA_BROKEN.." <DEST><SPELL>",
		MSG_BREAK = "<SRC> "..ACTION_SPELL_AURA_BROKEN.." <DEST><SPELL>",
		MSG_BREAK_NOSOURCE = "<SPELL> on <DEST> "..ACTION_SPELL_AURA_BROKEN,

		MSG_DEATH = "<DEST> "..ACTION_UNIT_DIED.." <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_MELEE = "<DEST> "..ACTION_UNIT_DIED.." <SRC> <AMOUNT> "..ACTION_SWING,
		MSG_DEATH_ENVIRONMENTAL = "<DEST> "..ACTION_UNIT_DIED.." <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> "..ACTION_SPELL_INSTAKILL.." <DEST>",

		MSG_SAVE = "<SRC><SPELL> saved <DEST> <AMOUNT> <SCHOOL>",
		MSG_RESURRECT = "<SRC><SPELL> "..ACTION_SPELL_RESURRECT.." <DEST>",
		-- source and dest are switched
		MSG_SELFRES_SOULSTONE = "<SRC> used <DEST><SPELL>",
		MSG_SELFRES_REINCARNATION = "<SRC> "..ACTION_SPELL_CAST_SUCCESS.." <SPELL>",

		LOCAL = "Local",
		SELF = "Self",
		ENEMY_PLAYERS_CLASS_COLORS = "Color enemy players by class",
		ABBREVIATE_LARGE_NUMBERS = "Abbreviate Large Numbers",

		USE_CLASS_COLORS = "Please use the |cff71D5FFClass Colors|r AddOn",
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
	},
	deDE = {
		ABBREVIATE_LARGE_NUMBERS = "Lange Zahlen kürzen",
		ENEMY_PLAYERS_CLASS_COLORS = "Gegnerische Spieler nach deren Klasse färben",
		EVENT_CROWDCONTROL = "Massenkontrolle",
		EVENT_JUKE = "Verschwendung", -- Needs review
		-- LOCAL = "",
		MSG_BREAK = "<SRC> brach <DEST><SPELL>",
		MSG_BREAK_NOSOURCE = "<SPELL> auf <DEST> brach",
		MSG_BREAK_SPELL = "<SRC><XSPELL> brach <DEST><SPELL>",
		MSG_CLEANSE = "<SRC><SPELL> reinigte <DEST><XSPELL>", -- Needs review
		MSG_CROWDCONTROL = "<SRC><SPELL> CC'ed <DEST>", -- Needs review
		MSG_DEATH = "<DEST> starb <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_ENVIRONMENTAL = "<DEST> starb <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> tötete <DEST>",
		MSG_DEATH_MELEE = "<DEST> starb <SRC> <AMOUNT> Nahkampf",
		MSG_DISPEL = "<SRC><SPELL> bannte <DEST><XSPELL>",
		MSG_INTERRUPT = "<SRC><SPELL> unterbrach <DEST><XSPELL>",
		MSG_JUKE = "<SRC> verschwendete <SPELL> auf <DEST>", -- Needs review
		MSG_MISS = "<SRC><SPELL> verfehlte <DEST> (<TYPE>)", -- Needs review
		MSG_REFLECT = "<DEST> reflektierte <SRC><SPELL>",
		MSG_RESURRECT = "<SRC><SPELL> belebte <DEST> wieder",
		MSG_SAVE = "<SRC><SPELL> rettete <DEST> <AMOUNT> <SCHOOL>",
		MSG_SELFRES_REINCARNATION = "<SRC> wirkt <SPELL>",
		MSG_SELFRES_SOULSTONE = "<SRC> benutzte <DEST><SPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> stahl <DEST><XSPELL>",
		MSG_TAUNT = "<SRC><SPELL> verspottete <DEST>",
		SELF = "Selbst",

		USE_CLASS_COLORS = "Bitte benützt dafür das |cff71D5FFClass Colors|r AddOn",
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmenü zu öffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
	},
	esES = {
		BROKER_CLICK = "|cffffffffHaz clic|r para ver opciones",
		BROKER_SHIFT_CLICK = "|cffffffffMayús-clic|r para activar/desactivar",
	},
	--esMX = {},
	frFR = {
		SELF = "Soi-même",
	},
	itIT = {
		SELF = "Stesso", -- google translate
	},
	koKR = {
		ABBREVIATE_LARGE_NUMBERS = "천 단위 숫자 구분자 표시",
		ENEMY_PLAYERS_CLASS_COLORS = "직업에 따른 적의 색상 표시",
		EVENT_CROWDCONTROL = "군중제어",
		EVENT_JUKE = "차단",
		LOCAL = "일반",
		MSG_BREAK = "<SRC> 파괴 <DEST><SPELL>",
		MSG_BREAK_NOSOURCE = "<SPELL> on <DEST> 파괴",
		MSG_BREAK_SPELL = "<SRC><XSPELL> 파괴 <DEST><SPELL>",
		MSG_CLEANSE = "<SRC><SPELL> 무효화 <DEST><XSPELL>",
		MSG_CROWDCONTROL = "<SRC><SPELL> 군중제어 <DEST>",
		MSG_DEATH = "<DEST> 죽음 <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_ENVIRONMENTAL = "<DEST> 죽음 <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> 죽임 <DEST>",
		MSG_DEATH_MELEE = " <DEST> 죽음 <SRC> <AMOUNT> 근접",
		MSG_DISPEL = "<SRC><SPELL> 해제 <DEST><XSPELL>",
		MSG_INTERRUPT = "<SRC><SPELL> 방해 <DEST><XSPELL>",
		MSG_JUKE = "<SRC> 차단 <SPELL> on <DEST>",
		MSG_MISS = " <SRC><SPELL> on <DEST> 실패 (<TYPE>)",
		MSG_REFLECT = "<DEST> 반사 <SRC><SPELL>",
		MSG_RESURRECT = "<SRC><SPELL> 부활 <DEST>",
		MSG_SAVE = "<SRC><SPELL> 생명력 회복 <DEST> <AMOUNT> <SCHOOL>",
		MSG_SELFRES_REINCARNATION = "<SRC> 시전 <SPELL>",
		MSG_SELFRES_SOULSTONE = "<SRC> 사용 <DEST><SPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> 훔침 <DEST><XSPELL>",
		MSG_TAUNT = "<SRC><SPELL> 도발 <DEST>",
		SELF = "나",
	},
	ptBR = {
		SELF = "Maga", -- google translate
	},
	ruRU = {
		SELF = "Персонаж",
	},
	zhCN = {
		SELF = "自己",

		USE_CLASS_COLORS = "请使用 |cff71D5FFClassColors|r 插件", -- Needs review
		BROKER_CLICK = "|cffFFFFFF点击|r打开选项菜单",
		BROKER_SHIFT_CLICK = "|cffFFFFFFrShift-点击|r 启用或禁用插件",
	},
	zhTW = {
		SELF = "自己",
		USE_CLASS_COLORS = "請使用 |cff71D5FFClassColors|r 插件", -- Needs review
		BROKER_CLICK = "|cffFFFFFF點擊|r打開選項菜單",
		BROKER_SHIFT_CLICK = "|cffFFFFFFrShift-點擊|r 啟用或禁用插件",
	},
}

L.esMX = L.esES

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
