local _, S = ...

local L = {
	enUS = {
		EVENT_JUKE = "Juke",
		EVENT_CROWDCONTROL = "Crowd Control",
		EVENT_BREAK = GetSpellInfo(82881),
		EVENT_SAVE = "Save",
		
		MSG_TAUNT = "<SRC><SPELL><ICON> taunted <DEST>",
		MSG_TAUNT_AOE = "<SRC><SPELL><ICON> AoE "..GetSpellInfo(355),
		MSG_GROWL = "<SRC><SPELL><ICON> growled <DEST>",
		
		MSG_INTERRUPT = "<SRC><SPELL><ICON> "..ACTION_SPELL_INTERRUPT.." <DEST><XSPELL><XICON>",
		MSG_JUKE = "<SRC> juked <SPELL><ICON> on <DEST>",
		
		-- http://us.battle.net/wow/en/forum/topic/6413023639
		-- "The Combat log is reporting purges, friendly dispels, and spellsteals backwards."
		MSG_DISPEL = "<SRC><XSPELL><XICON> "..ACTION_SPELL_DISPEL_BUFF.." <DEST><SPELL><ICON>",
		MSG_CLEANSE = "<SRC><XSPELL><XICON> "..ACTION_SPELL_DISPEL_DEBUFF.." <DEST><SPELL><ICON>",
		MSG_SPELLSTEAL = "<SRC><XSPELL><XICON> "..ACTION_SPELL_STOLEN.." <DEST><SPELL><ICON>",
		
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
		
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
	},
	deDE = {
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
	},
	ptBR = {
	},
	ruRU = {
	},
	zhCN = {
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
