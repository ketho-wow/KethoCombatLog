local _, S = ...

local L = {
	deDE = {
	},
	enUS = {
		HELLO = "why hello there",
		--[[
		TAUNT = "",
		CROWD_CONTROL = "",
		INTERRUPT = "",
		CC_BREAK = "",
		JUKE = "",
		DEATH = "",
		DISPEL = "",
		SAVE = "",
		REFLECT = "",
		RESURRECT = "",
		]]
	},
	esES = {
	},
	esMX = {
	},
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
	},
	zhTW = {
	},
}

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
