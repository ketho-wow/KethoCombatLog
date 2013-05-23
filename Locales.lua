local _, S = ...

local L = {
	enUS = {
		EVENT_JUKE = "Juke",
		EVENT_CROWDCONTROL = "Crowd Control",
		EVENT_BREAK = GetSpellInfo(82881), -- "Break"
		EVENT_SAVE = "Save",
		
		MSG_TAUNT = "<SRC><SPELL><ICON> taunted <DEST>",
		MSG_TAUNT_AOE = "<SRC><SPELL><ICON> AoE "..GetSpellInfo(355), -- "Taunt"
		MSG_GROWL = "<SRC><SPELL><ICON> growled <DEST>",
		
		MSG_INTERRUPT = "<SRC><SPELL><ICON> "..ACTION_SPELL_INTERRUPT.." <DEST><XSPELL><XICON>",
		MSG_JUKE = "<SRC> juked <SPELL><ICON> on <DEST>",
		
		MSG_DISPEL = "<SRC><SPELL><ICON> "..ACTION_SPELL_DISPEL_BUFF.." <DEST><XSPELL><XICON>",
		MSG_CLEANSE = "<SRC><SPELL><ICON> "..ACTION_SPELL_DISPEL_DEBUFF.." <DEST><XSPELL><XICON>",
		MSG_SPELLSTEAL = "<SRC><SPELL><ICON> "..ACTION_SPELL_STOLEN.." <DEST><XSPELL><XICON>",
		
		MSG_REFLECT = "<DEST> "..ACTION_SPELL_MISSED_REFLECT.." <SRC><SPELL><ICON>",
		MSG_MISS = "<SRC><SPELL><ICON> on <DEST> "..ACTION_SPELL_CAST_FAILED.." (<TYPE>)",
		
		MSG_CROWDCONTROL = "<SRC><SPELL><ICON> CC'ed <DEST>",
		MSG_BREAK = "<SRC> "..ACTION_SPELL_AURA_BROKEN.." <SPELL><ICON> on <DEST>",
		MSG_BREAK_NOSOURCE = "<SPELL><ICON> on <DEST> "..ACTION_SPELL_AURA_BROKEN,
		MSG_BREAK_SPELL = "<SRC><SPELL><ICON> "..ACTION_SPELL_AURA_BROKEN.." <XSPELL><XICON> on <DEST>",
		
		MSG_DEATH = "<DEST> "..ACTION_UNIT_DIED.." <SRC><SPELL><ICON> <AMOUNT> <SCHOOL>",
		MSG_DEATH_MELEE = "<DEST> "..ACTION_UNIT_DIED.." <SRC> <AMOUNT> "..ACTION_SWING,
		MSG_DEATH_ENVIRONMENTAL = "<DEST> "..ACTION_UNIT_DIED.." <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL><ICON> "..ACTION_SPELL_INSTAKILL.." <DEST>",
		
		MSG_SAVE = "<SRC><SPELL><ICON> saved <DEST> <AMOUNT> <SCHOOL>",
		MSG_RESURRECT = "<SRC><SPELL><ICON> "..ACTION_SPELL_RESURRECT.." <DEST>",
		
		SELF = "Self",
		
		USE_CLASS_COLORS = "Please use the |cff71D5FFClass Colors|r AddOn",
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
	},
	deDE = {
		EVENT_BREAK = "CC Brechen", -- Needs review
		EVENT_CROWDCONTROL = "Crowd Control", -- Needs review
		EVENT_JUKE = "Verschwendung", -- Needs review
		EVENT_SAVE = "Rettung", -- Needs review
		MSG_BREAK = "<SRC> brach <SPELL><ICON> auf <DEST>", -- Needs review
		MSG_BREAK_NOSOURCE = "<SPELL><ICON> auf <DEST> brach", -- Needs review
		MSG_BREAK_SPELL = "<SRC><SPELL><ICON> brach <XSPELL><XICON> auf <DEST>", -- Needs review
		MSG_CLEANSE = "<SRC><SPELL><ICON> reinigte <DEST><XSPELL><XICON>", -- Needs review
		MSG_CROWDCONTROL = "<SRC><SPELL><ICON> CC'ed <DEST>", -- Needs review
		MSG_DEATH = "<DEST> starb <SRC><SPELL><ICON> <AMOUNT> <SCHOOL>", -- Needs review
		MSG_DEATH_ENVIRONMENTAL = "<DEST> starb <AMOUNT> <TYPE>", -- Needs review
		MSG_DEATH_INSTAKILL = "<SRC><SPELL><ICON> tötete <DEST>", -- Needs review
		MSG_DEATH_MELEE = "<DEST> starb <SRC> <AMOUNT> Nahkampf", -- Needs review
		MSG_DISPEL = "<SRC><SPELL><ICON> entzauberte <DEST><XSPELL><XICON>", -- Needs review
		MSG_GROWL = "<SRC><SPELL><ICON> knurrte <DEST>", -- Needs review
		MSG_INTERRUPT = "<SRC><SPELL><ICON> unterbrach <DEST><XSPELL><XICON>", -- Needs review
		MSG_JUKE = "<SRC> verschwendete <SPELL><ICON> on <DEST>", -- Needs review
		MSG_MISS = "<SRC><SPELL><ICON> verfehlte <DEST> (<TYPE>)", -- Needs review
		MSG_REFLECT = "<DEST> reflektierte <SRC><SPELL><ICON>", -- Needs review
		MSG_RESURRECT = "<SRC><SPELL><ICON> belebte <DEST> wieder", -- Needs review
		MSG_SAVE = "<SRC><SPELL><ICON> rettete <DEST> <AMOUNT> <SCHOOL>", -- Needs review
		MSG_SPELLSTEAL = "<SRC><SPELL><ICON> stahl <DEST><XSPELL><XICON>", -- Needs review
		MSG_TAUNT = "<SRC><SPELL><ICON> spottet <DEST>", -- Needs review
		MSG_TAUNT_AOE = "<SRC><SPELL><ICON> AoE Spott", -- Needs review
		SELF = "Selbst", -- Needs review
		
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
	},
	itIT = {
	},
	koKR = {
		EVENT_CROWDCONTROL = "군중제어", -- Needs review
	},
	ptBR = {
	},
	ruRU = {
	},
	zhCN = {
		USE_CLASS_COLORS = "请使用 |cff71D5FFClassColors|r 插件", -- Needs review
		BROKER_CLICK = "|cffFFFFFF点击|r打开选项菜单",
		BROKER_SHIFT_CLICK = "|cffFFFFFFrShift-点击|r 启用或禁用插件",
	},
	zhTW = {
	},
}

L.esMX = L.esES

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
