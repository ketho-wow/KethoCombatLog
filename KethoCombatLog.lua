-- Author: Ketho (EU-Boulderfist)
-- Created: 2009.09.01

-- Curse			https://www.curseforge.com/wow/addons/kethocombatlog
-- WoWInterface		http://www.wowinterface.com/downloads/info18901-KethoCombatLog.html
-- This is my first addon and was my introduction to programming/scripting

local NAME, S = ...

KethoCombatLog = LibStub("AceAddon-3.0"):NewAddon("KethoCombatLog", "AceEvent-3.0", "AceConsole-3.0", "LibSink-2.0")
local KCL = KethoCombatLog
KethoCombatLog.S = S -- debug purpose

local L = S.L

local profile

function KCL:RefreshDB1()
	profile = self.db.profile
end

local time = time
local rawset = rawset
local sort = sort

	------------
	--- Data ---
	------------

S.SpellSchoolString = {
	[0x1] = STRING_SCHOOL_PHYSICAL,
	[0x2] = STRING_SCHOOL_HOLY,
	[0x4] = STRING_SCHOOL_FIRE,
	[0x8] = STRING_SCHOOL_NATURE,
	[0x10] = STRING_SCHOOL_FROST,
	[0x20] = STRING_SCHOOL_SHADOW,
	[0x40] = STRING_SCHOOL_ARCANE,
-- double
	[0x3] = STRING_SCHOOL_HOLYSTRIKE,
	[0x5] = STRING_SCHOOL_FLAMESTRIKE,
	[0x6] = STRING_SCHOOL_HOLYFIRE,
	[0x9] = STRING_SCHOOL_STORMSTRIKE,
	[0xA] = STRING_SCHOOL_HOLYSTORM,
	[0xC] = STRING_SCHOOL_FIRESTORM,
	[0x11] = STRING_SCHOOL_FROSTSTRIKE,
	[0x12] = STRING_SCHOOL_HOLYFROST,
	[0x14] = STRING_SCHOOL_FROSTFIRE,
	[0x18] = STRING_SCHOOL_FROSTSTORM,
	[0x21] = STRING_SCHOOL_SHADOWSTRIKE,
	[0x22] = STRING_SCHOOL_SHADOWLIGHT, -- Twilight
	[0x24] = STRING_SCHOOL_SHADOWFLAME,
	[0x28] = STRING_SCHOOL_SHADOWSTORM, -- Plague
	[0x30] = STRING_SCHOOL_SHADOWFROST,
	[0x41] = STRING_SCHOOL_SPELLSTRIKE,
	[0x42] = STRING_SCHOOL_DIVINE,
	[0x44] = STRING_SCHOOL_SPELLFIRE,
	[0x48] = STRING_SCHOOL_SPELLSTORM,
	[0x50] = STRING_SCHOOL_SPELLFROST,
	[0x60] = STRING_SCHOOL_SPELLSHADOW,
	[0x1C] = STRING_SCHOOL_ELEMENTAL,
-- triple and more
	[0x7C] = STRING_SCHOOL_CHROMATIC,
	[0x7E] = STRING_SCHOOL_MAGIC,
	[0x7F] = STRING_SCHOOL_CHAOS,
}

S.PvE = {
	party = true,
	raid = true,
	scenario = true,
}

S.PvP = {
	pvp = true,
	arena = true,
}

S.SpellPrefix = {
	SPELL = true,
	RANGE = true,
	DAMAG = true, -- DAMAGE_SHIELD; DAMAGE_SPLIT; havent seen these in a while
}

S.DamageEvent = {
	SWING_DAMAGE = true,
	RANGE_DAMAGE = true,
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
	ENVIRONMENTAL_DAMAGE = true,
}

S.MissEvent = {
	SWING_MISSED = true,
	RANGE_MISSED = true,
	SPELL_MISSED = true,
	SPELL_PERIODIC_MISSED = true,
}

S.MissType = {
	REFLECT = true,
	ABSORB = true,
}

S.HealEvent = {
	SPELL_HEAL = true,
	SPELL_PERIODIC_HEAL = true,
}

S.ExtraSpellEvent = {
	SPELL_INTERRUPT = true,
	SPELL_DISPEL = true,
	SPELL_DISPEL_FAILED = true,
	SPELL_STOLEN = true,
	SPELL_AURA_BROKEN_SPELL = true,
}

S.MissType = {
	ABSORB = COMBAT_TEXT_ABSORB,
	BLOCK = COMBAT_TEXT_BLOCK,
	DEFLECT = COMBAT_TEXT_DEFLECT,
	DODGE = COMBAT_TEXT_DODGE,
	EVADE = COMBAT_TEXT_EVADE,
	IMMUNE = COMBAT_TEXT_IMMUNE,
	MISFIRE = COMBAT_TEXT_MISFIRE,
	MISS = COMBAT_TEXT_MISS,
	PARRY = COMBAT_TEXT_PARRY,
	REFLECT = COMBAT_TEXT_REFLECT,
	RESIST = COMBAT_TEXT_RESIST,
}

S.EnvironmentalDamageType = {
	Drowning = ACTION_ENVIRONMENTAL_DAMAGE_DROWNING,
	Falling = ACTION_ENVIRONMENTAL_DAMAGE_FALLING,
	Fatigue = ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE,
	Fire = ACTION_ENVIRONMENTAL_DAMAGE_FIRE,
	Lava = ACTION_ENVIRONMENTAL_DAMAGE_LAVA,
	Slime = ACTION_ENVIRONMENTAL_DAMAGE_SLIME,
}

S.Talk = {
	SAY = true,
	YELL = true,
}

-- check if a Combat Text addon is available
S.LibSinkCombatText = {
	Blizzard = true,
	MikSBT = true,
	Parrot = true,
	SCT = true,
}

	-------------
	--- Event ---
	-------------

S.Event = {
	[1] = "Taunt",
	[3] = "Interrupt",
	[5] = "Juke",
	[7] = "Dispel",
	[9] = "Reflect",
	[2] = "CrowdControl",
	[4] = "Break",
	[6] = "Death",
	[8] = "Resurrect",
}

S.EventMsg = { -- options order
	"Taunt",
	"Interrupt",
	"Juke",
	"Dispel",
	"Cleanse",
	"Spellsteal",
	"Reflect",
	"Miss",
	"CrowdControl",
	"Break_Spell",
	"Break",
	"Break_NoSource",
	"Death",
	"Death_Melee",
	"Death_Environmental",
	"Death_Instakill",
	"Resurrect",
	"Soulstone",
	"Reincarnation",
}

S.EventString = {
	Taunt = {GetSpellInfo(355), "Spell_Nature_Reincarnation"},
	Interrupt = {INTERRUPT, "Ability_Kick"},
	Juke = {L.EVENT_JUKE, "Spell_Frost_IceShock"},
	Dispel = {GetSpellInfo(25808), "Spell_Holy_DispelMagic"},
	Cleanse = {GetSpellInfo(4987), "Spell_Holy_Purify"},
	Spellsteal = {GetSpellInfo(30449), "Spell_Arcane_Arcane02"},
	Reflect = {REFLECT, "Ability_Warrior_ShieldReflection"},
	Miss = {MISS, "Ability_Hunter_MasterMarksman"},
	CrowdControl = {L.EVENT_CROWDCONTROL, "Spell_Nature_Polymorph"},
	Break_Spell = {GetSpellInfo(82881).." ("..STAT_CATEGORY_SPELL..")", "Spell_Shadow_ShadowWordPain"},
	Break = {GetSpellInfo(82881), "Ability_Seal"},
	Break_NoSource = {GetSpellInfo(82881).." (No "..SOURCE:gsub(":","")..")", "INV_Misc_QuestionMark"},
	Death = {TUTORIAL_TITLE25, "Ability_Rogue_FeignDeath"},
	Death_Melee = {TUTORIAL_TITLE25.." ("..ACTION_SWING..")", "Spell_Holy_FistOfJustice"},
	Death_Environmental = {TUTORIAL_TITLE25.." ("..ENVIRONMENTAL_DAMAGE..")", "Spell_Shaman_LavaFlow"},
	Death_Instakill = {TUTORIAL_TITLE25.." (Instakill)", "INV_Misc_Bone_HumanSkull_01"},
	Resurrect = {GetSpellInfo(2006), "Spell_Holy_Resurrection"},
	Soulstone = {GetSpellInfo(20707), "Spell_Shadow_SoulGem"},
	Reincarnation = {GetSpellInfo(20608), "spell_shaman_improvedreincarnation"},
}

S.EventGroup = {
	Cleanse = "Dispel",
	Spellsteal = "Dispel",
	Miss = "Reflect",
	Death_Melee = "Death",
	Death_Environmental = "Death",
	Death_Instakill = "Death",
	Break_Spell = "Break",
	Break_NoSource = "Break",
	Soulstone = "Resurrect",
	Reincarnation = "Resurrect",
}

S.SelfResRemap = {
	[20707] = "Soulstone",
	[20608] = "Reincarnation",
}

	--------------------
	--- Custom Spell ---
	--------------------

local tags = {
	[1] = "<SRC>",
	[2] = "<SPELL>",
	[4] = "<DEST>",
	[6] = "",
}

local function ConvertTags(s)
	for k, v in pairs(tags) do
		s = s:gsub("%%"..k.."%$s", v)
	end
	return s:gsub("%.", "")
end

S.SpellMsg = {
	unit = {
		CAST_START = ConvertTags(ACTION_SPELL_CAST_START_FULL_TEXT_NO_DEST),
		CAST_SUCCESS = ConvertTags(ACTION_SPELL_CAST_SUCCESS_FULL_TEXT),
		CAST_SUCCESS_NO_DEST = ConvertTags(ACTION_SPELL_CAST_SUCCESS_FULL_TEXT_NO_DEST),
	},
	-- for casts done by yourself, the Blizzard_CombatLog kinda does this the same way
	-- not sure about making this message customizable, I think it would clutter up the spell messages
	player = {
		CAST_START = "<SRC> "..ACTION_SPELL_CAST_START.." <SPELL>",
		CAST_SUCCESS_NO_DEST = "<SRC> "..ACTION_SPELL_CAST_SUCCESS.." <SPELL>",
		CAST_SUCCESS = "<SRC> "..ACTION_SPELL_CAST_SUCCESS.." <SPELL><DEST>",
	},
}

S.SpellMsgOptionKey = {
	"CAST_START",
	"CAST_SUCCESS_NO_DEST",
	"CAST_SUCCESS",
}

S.SpellMsgOptionValue = {
	CAST_START = SPELL_CAST_START_COMBATLOG_TOOLTIP,
	CAST_SUCCESS_NO_DEST = SPELL_CAST_SUCCESS_COMBATLOG_TOOLTIP.." ("..SPELL_FAILED_BAD_IMPLICIT_TARGETS..")",
	CAST_SUCCESS = SPELL_CAST_SUCCESS_COMBATLOG_TOOLTIP,
}

S.SpellRemap = {
	CAST_START = "CAST_START",
	CAST_SUCCESS = "CAST_SUCCESS",
	AURA_APPLIED = "CAST_SUCCESS",
	SUMMON = "CAST_SUCCESS",
	CREATE = "CAST_SUCCESS",
}

S.SpellSummon = {
	SUMMON = true,
	CREATE = true,
}

-- for spell data frame order
S.SpellGroupOrder = {"Feast", "RepairBot", "Bloodlust", "Portal", "Holiday", "Fun", "Misdirection", "TricksTrade"}

	-------------
	--- Class ---
	-------------

S.Class = { -- options order
	[1] = "WARRIOR",
	[3] = "DEATHKNIGHT",
	[5] = "ROGUE",
	[7] = "HUNTER",
	[9] = "MAGE",
	[11] = "WARLOCK",
	[2] = "PALADIN",
	[4] = "DRUID",
	[6] = "MONK",
	[8] = "SHAMAN",
	[10] = "PRIEST",
	[12] = "DEMONHUNTER",
}

S.ClassCoords = {
	WARRIOR = "256:256:4:60:4:60",
	MAGE = "256:256:68:124:4:60",
	ROGUE = "256:256:131:187:4:60",
	DRUID = "256:256:194:250:4:60",
	HUNTER = "256:256:4:60:68:124",
	SHAMAN = "256:256:68:124:68:124",
	PRIEST = "256:256:130:186:68:124",
	WARLOCK = "256:256:194:250:68:124",
	PALADIN = "256:256:4:60:132:188",
	DEATHKNIGHT = "256:256:68:124:133:189",
	MONK = "256:256:130:186:132:188",
	DEMONHUNTER = "256:256:194:250:132:188",
}

	--------------
	--- School ---
	--------------

S.School = { -- options order
	--[1] = "Physical",
	[2] = "Holy",
	[4] = "Fire",
	[6] = "Nature",
	[1] = "Frost",
	[3] = "Shadow",
	[5] = "Arcane",
}

S.SchoolRemap = { -- remap to icon id
	Physical = 1,
	Holy = 2,
	Fire = 3,
	Nature = 4,
	Frost = 5,
	Shadow = 6,
	Arcane = 7,
}

S.SchoolString = {
	Physical = STRING_SCHOOL_PHYSICAL,
	Holy = STRING_SCHOOL_HOLY,
	Fire = STRING_SCHOOL_FIRE,
	Nature = STRING_SCHOOL_NATURE,
	Frost = STRING_SCHOOL_FROST,
	Shadow = STRING_SCHOOL_SHADOW,
	Arcane = STRING_SCHOOL_ARCANE,
}

S.RemapSchoolColor = {
	[0x1] = "Physical",
	[0x2] = "Holy",
	[0x4] = "Fire",
	[0x8] = "Nature",
	[0x10] = "Frost",
	[0x20] = "Shadow",
	[0x40] = "Arcane",
}

S.RemapSchoolColorRev = {}
for k, v in pairs(S.RemapSchoolColor) do
	S.RemapSchoolColorRev[v] = k
end

	-------------
	--- Color ---
	-------------

-- only for class colors
S.ClassColor = setmetatable({}, {__index = function(t, k)
	k = k or "PRIEST" -- fallback
	local color = (CUSTOM_CLASS_COLORS or profile.color)[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

-- only for spell school colors
-- hex values as keys
S.SpellSchoolColor = setmetatable({}, {__index = function(t, k)
	local color = profile.color[S.RemapSchoolColor[k]]
	-- fall back to default color for combination schools
	local v = color and format("%02X%02X%02X", color[1]*255, color[2]*255, color[3]*255) or "71D5FF"
	rawset(t, k, v)
	return v
end})

-- for all kinds of colors
S.GeneralColor = setmetatable({}, {__index = function(t, k)
	local color = profile.color[k]
	local v = format("%02X%02X%02X", color[1]*255, color[2]*255, color[3]*255)
	rawset(t, k, v)
	return v
end})

function KCL:WipeCache()
	wipe(S.ClassColor)
	wipe(S.SpellSchoolColor)
	wipe(S.GeneralColor)
end

	-------------------
	--- Raid Target ---
	-------------------

S.STRING_REACTION_ICON = {
	TEXT_MODE_A_STRING_SOURCE_ICON,
	TEXT_MODE_A_STRING_DEST_ICON,
}

S.COMBATLOG_OBJECT_RAIDTARGET = {}
for i = 1, 8 do
	S.COMBATLOG_OBJECT_RAIDTARGET[_G["COMBATLOG_OBJECT_RAIDTARGET"..i]] = i
end

	-----------------
	--- Timestamp ---
	-----------------

local timestamp = {
	TIMESTAMP_FORMAT_NONE,
	TIMESTAMP_FORMAT_HHMM,
	TIMESTAMP_FORMAT_HHMMSS,
	TIMESTAMP_FORMAT_HHMM_AMPM,
	TIMESTAMP_FORMAT_HHMMSS_AMPM,
	TIMESTAMP_FORMAT_HHMM_24HR,
	TIMESTAMP_FORMAT_HHMMSS_24HR,
}

for i, v in ipairs(timestamp) do
	timestamp[i] = v:trim() -- remove trailing whitespace
end

function S.GetTimestamp()
	local timestampLocal, timestampChat = "", ""
	if profile.Timestamp > 1 then
		timestampChat = format("[%s] ", BetterDate(timestamp[profile.Timestamp], time()))
		timestampLocal = format("|cff%s%s|r", S.GeneralColor.Timestamp, timestampChat)
	end
	return timestampLocal, timestampChat
end

local exampleTime = time({ -- FrameXML\InterfaceOptionsPanels.lua
	year = 2010,
	month = 12,
	day = 15,
	hour = 15,
	min = 27,
	sec = 32,
})

S.xmpl_timestamps = {}

for i, v in ipairs(timestamp) do
	S.xmpl_timestamps[i] = BetterDate(v, exampleTime)
end

	-------------
	--- Timer ---
	-------------

-- screw AceTimer :D
local timers = {}
S.Timer = CreateFrame("Frame")
S.Timer:Hide()

function S.Timer:New(func, delay)
	timers[func] = delay -- add timer
	self:Show()
end

S.Timer:SetScript("OnUpdate", function(self, elapsed)
	local stop = true
	for func, delay in pairs(timers) do
		timers[func] = delay - elapsed
		stop = false
		if timers[func] < 0 then
			timers[func] = nil -- remove timer
			func()
		end
	end
	if stop then -- all timers finished
		self:Hide()
	end
end)

	-------------
	--- Stuff ---
	-------------

-- from lookup table to sequential table
function S.SortTable(t)
	local i, o = 1, {}
	for k, v in pairs(t) do
		o[i] = k
		i = i + 1
	end
	sort(o)
	return o
end

function S.Approx(v, ap, err)
	return v > ap-err and v < ap+err
end

S.crop = ":64:64:4:60:4:60"

S.IconValues = {"|cffFF0000<"..ADDON_DISABLED..">|r"}
for i = 12, 32, 2 do
	S.IconValues[i] = " "..i
end
S.IconValues[16] = " 16  |cffFBDB00("..DEFAULT..")|r"

S.player = {
	name = UnitName("player"),
	class = select(2, UnitClass("player")),
}

local function GetClassColor(class)
	local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
	return format("%02X%02X%02X",color.r*255, color.g*255, color.b*255)
end

S.player.color = GetClassColor(S.player.class)
-- guid not readily available at first startup
S.Timer:New(function() S.player.guid = UnitGUID("player") end, 0)
