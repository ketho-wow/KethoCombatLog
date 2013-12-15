-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2009.09.01					---
--- Version: 1.15 [2013.12.15]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/ketho-combatlog
--- WoWInterface	http://www.wowinterface.com/downloads/info18901-KethoCombatLog.html

--- Notes:
-- This is my first addon, and was my introduction to programming/scripting
-- If you notice variables defined which are only just used once, then it's for readability ..

local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.BUILD = "Release"

KethoCombatLog = LibStub("AceAddon-3.0"):NewAddon("KethoCombatLog", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibSink-2.0")
local KCL = KethoCombatLog
KethoCombatLog.S = S -- debug purpose

local L = S.L

local profile

function KCL:RefreshDB1()
	profile = self.db.profile
end

	------------
	--- Data ---
	------------

S.Taunt = {
	[355] = true, -- Warrior: [Taunt]
	[6795] = true, -- Druid: [Growl]
	[17735] = true, -- Warlock: [Suffering] (Voidwalker)
	[20736] = true, -- Hunter: [Distracting Shot]
	[116189] = true, -- Monk: [Provoke]; 115546
-- Death Knight
	[49560] = true, -- [Death Grip]
	[51399] = true, -- [Death Grip] (melee range)
	[56222] = true, -- [Dark Command]
-- Paladin
	[31790] = true, -- [Righteous Defense]
	[62124] = true, -- [Hand of Reckoning]
}

-- wtf .. removed?
S.Taunt_AoE = {
	[1161] = true, -- Warrior: [Challenging Shout]
	[5209] = true, -- Druid: [Challenging Roar]
}

S.Growl = {
	[2649] = true, -- Pet: [Growl]
	[17735] = true, -- Voidwalker: [Suffering]
	[36213] = true, -- Greater Earth Elemental: [Angered Earth]
}

S.Interrupt = {
	[1766] = true, -- Rogue: [Kick]
	[2139] = true, -- Mage: [Counterspell]
	[6552] = true, -- Warrior: [Pummel]
	[47528] = true, -- Death Knight: [Mind Freeze]
	[57994] = true, -- Shaman: [Wind Shear]
	[96231] = true, -- Paladin: [Rebuke]
	[116705] = true, -- Monk: [Spear Hand Strike] (silence)
-- Druid
	[80964] = true, -- [Skull Bash] (Bear); pre-interrupt
	[80965] = true, -- [Skull Bash] (Cat); pre-interrupt
	[93985] = true, -- [Skull Bash; Interrupt
}

-- to do
S.CrowdControl = {
-- Druid
	[339] = true, -- [Entangling Roots]
	[2637] = true, -- [Hibernate]
	[33786] = true, -- [Cyclone]
-- Hunter
	[1513] = true, -- [Scare Beast]
	[3355] = true, -- [Freezing Trap]
	[19386] = true, -- [Wyvern Sting]
-- Mage
	[118] = true, -- [Polymorph]
-- Monk
	[115078] = true, -- [Paralysis]
-- Paladin
	[10326] = true, -- [Turn Evil]
	[20066] = true, -- [Repentance]
-- Priest
	[605] = true, -- [Dominate Mind]
	[5782] = true, -- [Fear]
	[9484] = true, -- [Shackle Undead]
-- Rogue
	[2094] = true, -- [Blind]
	[6770] = true, -- [Sap]
-- Warlock
	[710] = true, -- [Banish]
	[6358] = true, -- [Seduction] (Succubus)
	[51514] = true, -- [Hex]
}

-- dest buff applied to both the target unit and source unit
S.CrowdControlDouble = {
	[605] = true, -- [Dominate Mind]
}

S.Save = {
	[48153] = true, -- Priest: [Guardian Spirit]
	[66235] = true, -- Paladin: [Ardent Defender]
}

S.Blacklist = {
	[48743] = true, -- SPELL_INSTAKILL, Death Knight: [Death Pact] 
	[49560] = true, -- SPELL_MISSED, Death Knight: [Death Grip] 
	[81280] = true, -- SPELL_INSTAKILL, Death Knight: Bloodworm: [Blood Burst]
	[108503] = true, -- SPELL_INSTAKILL, Warlock: [Grimoire of Sacrifice]
}

S.Feast = {
	[56245] = true, -- [Chocolate Celebration Cake]
	[56255] = true, -- [Lovely Cake]
	[57301] = true, -- [Great Feast]
	[57426] = true, -- [Fish Feast]
	[58465] = true, -- [Gigantic Feast]
	[58474] = true, -- [Small Feast]
	[66476] = true, -- [Bountiful Feast]
	[87644] = true, -- [Seafood Magnifique Feast]
	[87643] = true, -- [Broiled Dragon Feast]
	[87915] = true, -- [Goblin Barbecue Feast]
	[92649] = true, -- [Cauldron of Battle]
	[92712] = true, -- [Big Cauldron of Battle]
	
    [104958] = true, -- Pandaren Banquet, 275 primary stat or 375 stamina
    [126503] = true, -- Banquet of the Brew, 250 primary stat or 375 stamina
    [126501] = true, -- Banquet of the Oven, 250 primary stat or 415 stamina
    [126492] = true, -- Banquet of the Grill, 250 primary stat or 275 strength or 375 stamina
    [126497] = true, -- Banquet of the Pot, 250 primary stat or 275 intellect or 375 stamina
    [126499] = true, -- Banquet of the Steamer, 250 primary stat or 275 spirit or 375 stamina
    [126495] = true, -- Banquet of the Wok, 250 primary stat or 275 agility or 375 stamina
    -- "Great" Banquets have 25 charges, otherwise identical
    [105193] = true, -- Great Pandaren Banquet, 275 primary stat or 375 stamina
    [126504] = true, -- Great Banquet of the Brew, 250 primary stat or 375 stamina
    [126494] = true, -- Great Banquet of the Oven, 250 primary stat or 415 stamina
    [126502] = true, -- Great Banquet of the Grill, 250 primary stat or 275 strength or 375 stamina
    [126498] = true, -- Great Banquet of the Pot, 250 primary stat or 275 intellect or 375 stamina
    [126498] = true, -- Great Banquet of the Steamer, 250 primary stat or 275 spirit or 375 stamina
    [126496] = true, -- Great Banquet of the Wok, 250 primary stat or 275 agility or 375 stamina
}

S.RepairBot = {
	[22700] = true, -- [Field Repair Bot 74A]
	[44389] = true, -- [Field Repair Bot 110G]
	[54710] = true, -- [MOLL-E]
	[54711] = true, -- [Scrapbot]
	[67826] = true, -- [Jeeves]
	[126459] = true, -- [Blingtron 4000]
}

S.Seasonal = {
-- Hallow's End
	[24717] = true, -- [Pirate Costume]
	[24718] = true, -- [Ninja Costume]
	[24719] = true, -- [Leper Gnome Costume]
	[24720] = true, -- [Random Costume]
	[24724] = true, -- [Skeleton Costume]
	[24733] = true, -- [Bat Costume]
	[24737] = true, -- [Ghost Costume]
	[24741] = true, -- [Wisp Costume]
	[44212] = true, -- [Jack-o'-Lanterned!]
-- Feast of Winter Veil
	[25677] = true, -- [Hardpacked Snowball] 
	[26004] = true, -- [Mistletoe]
	[44755] = true, -- [Snowflakes]
-- Midsummer Fire Festival
	[45417] = true, -- [Handful of Summer Petals]
	[46661] = true, -- [Huge Snowball]
-- Love is in the Air
	[61415] = true, -- [Bouquet of Ebon Roses] [Cascade of Ebon Petals]
	[27571] = true, -- [Bouquet of Red Roses] [Cascade of Roses]
-- Rest
	[61781] = true, -- [Turkey Feathers] Pilgrim's Bounty
	[61815] = true, -- [Sprung!] Noblegarden
}

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

S.NPCID = {
	[3] = true, -- NPC
	[4] = true, -- pet
	[5] = true, -- vehicle
}

S.DamageEvent = {
	SWING_DAMAGE = true,
	RANGE_DAMAGE = true,
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
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
	DROWNING = ACTION_ENVIRONMENTAL_DAMAGE_DROWNING,
	FALLING = ACTION_ENVIRONMENTAL_DAMAGE_FALLING,
	FATIGUE = ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE,
	FIRE = ACTION_ENVIRONMENTAL_DAMAGE_FIRE,
	LAVA = ACTION_ENVIRONMENTAL_DAMAGE_LAVA,
	SLIME = ACTION_ENVIRONMENTAL_DAMAGE_SLIME,
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
	[8] = "Save",
	[10] = "Resurrect",
}

S.EventMsg = { -- options order
	"Taunt",
	"Taunt_AoE",
	"Growl",
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
	"Save",
	"Resurrect",
}

S.EventString = {
	Taunt = {GetSpellInfo(355), "Spell_Nature_Reincarnation"},
	Taunt_AoE = {GetSpellInfo(355).." (AoE)", "Ability_BullRush"},
	Growl = {GetSpellInfo(2649), "Ability_Physical_Taunt"},
	Interrupt = {INTERRUPT, "Ability_Kick"},
	Juke = {L.EVENT_JUKE, "Spell_Frost_IceShock"},
	Dispel = {GetSpellInfo(25808), "Spell_Holy_DispelMagic"},
	Cleanse = {GetSpellInfo(4987), "Spell_Holy_Purify"},
	Spellsteal = {GetSpellInfo(30449), "Spell_Arcane_Arcane02"},
	Reflect = {REFLECT, "Ability_Warrior_ShieldReflection"},
	Miss = {MISS, "Ability_Hunter_MasterMarksman"},
	CrowdControl = {L.EVENT_CROWDCONTROL, "Spell_Nature_Polymorph"},
	Break_Spell = {L.EVENT_BREAK.." (Spell)", "Spell_Shadow_ShadowWordPain"},
	Break = {L.EVENT_BREAK, "Ability_Seal"},
	Break_NoSource = {L.EVENT_BREAK.." (No "..SOURCE:gsub(":","")..")", "INV_Misc_QuestionMark"},
	Death = {TUTORIAL_TITLE25, "Ability_Rogue_FeignDeath"},
	Death_Melee = {TUTORIAL_TITLE25.." ("..ACTION_SWING..")", "Spell_Holy_FistOfJustice"},
	Death_Environmental = {TUTORIAL_TITLE25.." ("..ENVIRONMENTAL_DAMAGE..")", "Spell_Shaman_LavaFlow"},
	Death_Instakill = {TUTORIAL_TITLE25.." (Instakill)", "INV_Misc_Bone_HumanSkull_01"},
	Save = {L.EVENT_SAVE, "Spell_Holy_GuardianSpirit"},
	Resurrect = {GetSpellInfo(2006), "Spell_Holy_Resurrection"},
}

S.EventGroup = {
	Taunt_AoE = "Taunt",
	Growl = "Taunt",
	Cleanse = "Dispel",
	Spellsteal = "Dispel",
	Miss = "Reflect",
	Death_Melee = "Death",
	Death_Environmental = "Death",
	Death_Instakill = "Death",
	Break_Spell = "Break",
	Break_NoSource = "Break",
}

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
}

S.ClassCoords = {
	WARRIOR = "256:256:4:60:4:60",
	PALADIN = "256:256:4:60:132:188",
	HUNTER = "256:256:4:60:68:124",
	ROGUE = "256:256:131:187:4:60",
	PRIEST = "256:256:130:186:68:124",
	DEATHKNIGHT = "256:256:68:124:133:189",
	SHAMAN = "256:256:68:124:68:124",
	MAGE = "256:256:68:124:4:60",
	WARLOCK = "256:256:194:250:68:124",
	MONK = "256:256:130:186:132:188",
	DRUID = "256:256:194:250:4:60",
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
	timestamp[i] = v:trim() -- remove trailing space
end

function S.GetTimestamp()
	local timestampLocal, timestampChat = "", ""
	if profile.Timestamp > 1 then
		timestampChat = format("[%s] ", BetterDate(timestamp[profile.Timestamp], time()))
		timestampLocal = format("|cff%s%s|r", S.GeneralColor.Timestamp, timestampChat)
	end
	return timestampLocal, timestampChat
end

local exampleTime = time({ -- FrameXML\InterfaceOptionsPanels.lua L1203 (4.3.4.15595)
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
	--- Stuff ---
	-------------

S.crop = ":64:64:4:60:4:60"

S.IconValues = {"|cffFF0000<"..ADDON_DISABLED..">|r"}
for i = 12, 32, 2 do
	S.IconValues[i] = " "..i
end
S.IconValues[16] = " 16  |cffFBDB00("..DEFAULT..")|r"

function S.GetClassColor(class)
	local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
	return format("%02X%02X%02X",color.r*255, color.g*255, color.b*255)
end

S.Player = {
	name = UnitName("player"),
	class = select(2, UnitClass("player")),
}
local player = S.Player

player.color = S.GetClassColor(player.class)
