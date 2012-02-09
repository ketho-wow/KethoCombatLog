local _, S = ...

local L = {
	deDE = {
	},
	enUS = {
		HELLO = "why hello there",
	},
	esES = {
	},
	esMX = {
	},
	frFR = {
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
