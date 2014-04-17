local _, S = ...

local tags = {
	[1] = "<SRC>",
	[2] = "<SPELL>",
	[4] = "<DEST>",
	[6] = "",
}

local function Convert(s)
	for k, v in pairs(tags) do
		s = s:gsub("%%"..k.."%$s", v)
	end
	return s:gsub("%.", "")
end

local L = {
	enUS = {
		EVENT_JUKE = "Juke",
		EVENT_CROWDCONTROL = "Crowd Control",
		EVENT_SAVE = "Save",
		
		MSG_TAUNT = "<SRC><SPELL> taunted <DEST>",
		
		MSG_INTERRUPT = "<SRC><SPELL> "..ACTION_SPELL_INTERRUPT.." <DEST><XSPELL>",
		MSG_JUKE = "<SRC> juked <SPELL> on <DEST>",
		
		MSG_DISPEL = "<SRC><SPELL> "..ACTION_SPELL_DISPEL_BUFF.." <DEST><XSPELL>",
		MSG_CLEANSE = "<SRC><SPELL> "..ACTION_SPELL_DISPEL_DEBUFF.." <DEST><XSPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> "..ACTION_SPELL_STOLEN.." <DEST><XSPELL>",
		
		MSG_REFLECT = "<DEST> "..ACTION_SPELL_MISSED_REFLECT.." <SRC><SPELL>",
		MSG_MISS = "<SRC><SPELL> on <DEST> "..ACTION_SPELL_CAST_FAILED.." (<TYPE>)",
		
		MSG_CROWDCONTROL = "<SRC><SPELL> CC'ed <DEST>",
		MSG_BREAK = "<SRC> "..ACTION_SPELL_AURA_BROKEN.." <SPELL> on <DEST>",
		MSG_BREAK_NOSOURCE = "<SPELL> on <DEST> "..ACTION_SPELL_AURA_BROKEN,
		-- this particular spell and extraspell order is extra confusing :x
		MSG_BREAK_SPELL = "<SRC><XSPELL> "..ACTION_SPELL_AURA_BROKEN.." <SPELL> on <DEST>",
		
		MSG_DEATH = "<DEST> "..ACTION_UNIT_DIED.." <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_MELEE = "<DEST> "..ACTION_UNIT_DIED.." <SRC> <AMOUNT> "..ACTION_SWING,
		MSG_DEATH_ENVIRONMENTAL = "<DEST> "..ACTION_UNIT_DIED.." <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> "..ACTION_SPELL_INSTAKILL.." <DEST>",
		
		MSG_SAVE = "<SRC><SPELL> saved <DEST> <AMOUNT> <SCHOOL>",
		MSG_RESURRECT = "<SRC><SPELL> "..ACTION_SPELL_RESURRECT.." <DEST>",
		-- source and dest are switched
		MSG_SELFRES_SOULSTONE = "<SRC> used <DEST><SPELL>",
		MSG_SELFRES_REINCARNATION = "<SRC> "..ACTION_SPELL_CAST_SUCCESS.." <SPELL>",
		
		MSG_SPELL_CAST_START = Convert(ACTION_SPELL_CAST_START_FULL_TEXT_NO_DEST),
		MSG_SPELL_CAST_SUCCESS = Convert(ACTION_SPELL_CAST_SUCCESS_FULL_TEXT),
		MSG_SPELL_CAST_SUCCESS_NO_DEST = Convert(ACTION_SPELL_CAST_SUCCESS_FULL_TEXT_NO_DEST),
		
		LOCAL = "Local",
		SELF = "Self",
		ENEMY_PLAYERS_CLASS_COLORS = "Color enemy players by class",
		ABBREVIATE_LARGE_NUMBERS = "Abbreviate Large Numbers",
		
		USE_CLASS_COLORS = "Please use the |cff71D5FFClass Colors|r AddOn",
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
	},
	deDE = {
		ABBREVIATE_LARGE_NUMBERS = "Kürze lange Zahlen", -- Needs review
		EVENT_CROWDCONTROL = "Crowd Control", -- Needs review
		EVENT_JUKE = "Verschwendung", -- Needs review
		EVENT_SAVE = "Rettung", -- Needs review
		MSG_BREAK = "<SRC> brach <SPELL> auf <DEST>", -- Needs review
		MSG_BREAK_NOSOURCE = "<SPELL> auf <DEST> brach", -- Needs review
		MSG_BREAK_SPELL = "<SRC><XSPELL> brach <SPELL> auf <DEST>", -- Needs review
		MSG_CLEANSE = "<SRC><SPELL> reinigte <DEST><XSPELL>", -- Needs review
		MSG_CROWDCONTROL = "<SRC><SPELL> CC'ed <DEST>", -- Needs review
		MSG_DEATH = "<DEST> starb <SRC><SPELL> <AMOUNT> <SCHOOL>", -- Needs review
		MSG_DEATH_ENVIRONMENTAL = "<DEST> starb <AMOUNT> <TYPE>", -- Needs review
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> tötete <DEST>", -- Needs review
		MSG_DEATH_MELEE = "<DEST> starb <SRC> <AMOUNT> Nahkampf", -- Needs review
		MSG_DISPEL = "<SRC><SPELL> entzauberte <DEST><XSPELL>", -- Needs review
		MSG_INTERRUPT = "<SRC><SPELL> unterbrach <DEST><XSPELL>", -- Needs review
		MSG_JUKE = "<SRC> verschwendete <SPELL> on <DEST>", -- Needs review
		MSG_MISS = "<SRC><SPELL> verfehlte <DEST> (<TYPE>)", -- Needs review
		MSG_REFLECT = "<DEST> reflektierte <SRC><SPELL>", -- Needs review
		MSG_RESURRECT = "<SRC><SPELL> belebte <DEST> wieder", -- Needs review
		MSG_SAVE = "<SRC><SPELL> rettete <DEST> <AMOUNT> <SCHOOL>", -- Needs review
		MSG_SPELLSTEAL = "<SRC><SPELL> stahl <DEST><XSPELL>", -- Needs review
		MSG_TAUNT = "<SRC><SPELL> spottet <DEST>", -- Needs review
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
