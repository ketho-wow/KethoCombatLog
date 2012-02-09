-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2009.09.01					---
--- Version: 1.05 [2012.02.09]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/ketho-combatlog
--- WoWInterface	http://www.wowinterface.com/downloads/info18901-KethoCombatLog.html

--- I don't have any previous programming experience or background in any (scripting) language
--- Note: This is my first AddOn

--- To Do:
-- Improve Crowd Control checking
-- Move the Ace3 Options Table into a separate file
-- Custom Message Strings
-- Support for Localization
-- DevTools style debugging, and similar way to easily announce a chatlog entry

--- Done: v1.04
-- Added option to the Custom Spells for the verbose "Self" as in "[Player][Spell] on [Self]"
-- The LibDataBroker display now toggles the options menu when clicked, instead of just opening
-- Added [Cauldron of Battle] and [Big Cauldron of Battle] to Feasts
-- Added requests for only showing Battlerezzes, and MD/TotT done on Tanks
-- check out BetterDate function

local NAME, S = ...
local NAME2 = "Ketho CombatLog"
local VERSION = 1.05
local BUILD = "Release"

KethoCombatLog = LibStub("AceAddon-3.0"):NewAddon("KethoCombatLog", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibSink-2.0")
local KCL = KethoCombatLog

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local LB = LibStub("LibBabble-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local L = S.L

	----------------
	--- Upvalues ---
	----------------

local _G = _G
--# Lua APIs
local pairs, type = pairs, type
local tonumber = tonumber
local unpack, select = unpack, select
local time = time
local format = format
local strsub = strsub
local strlower = strlower
local strmatch = strmatch
local bit_band = bit.band

--# WoW APIs
local UnitName, UnitClass = UnitName, UnitClass
local UnitInParty, UnitInRaid = UnitInParty, UnitInRaid
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetNumPartyMembers, GetNumRaidMembers = GetNumPartyMembers, GetNumRaidMembers
local GetSpellInfo, oldGetSpellLink = GetSpellInfo, GetSpellLink

--# Global Strings / Format Strings / Bitmasks
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local LOCALIZED_RACE_NAMES = LB.data["LibBabble-Race-3.0"].current
local LOCALIZED_TALENT_NAMES = LB.data["LibBabble-TalentTree-3.0"].current

local TEXT_MODE_A_STRING_SOURCE_UNIT = TEXT_MODE_A_STRING_SOURCE_UNIT
local TEXT_MODE_A_STRING_DEST_UNIT = TEXT_MODE_A_STRING_DEST_UNIT
local TEXT_MODE_A_STRING_SOURCE_ICON = TEXT_MODE_A_STRING_SOURCE_ICON
local TEXT_MODE_A_STRING_DEST_ICON = TEXT_MODE_A_STRING_DEST_ICON
local TEXT_MODE_A_STRING_SPELL = TEXT_MODE_A_STRING_SPELL
local TEXT_MODE_A_TIMESTAMP = TEXT_MODE_A_TIMESTAMP

local TEXT_MODE_A_STRING_RESULT_OVERKILLING = TEXT_MODE_A_STRING_RESULT_OVERKILLING
local TEXT_MODE_A_STRING_RESULT_CRITICAL = TEXT_MODE_A_STRING_RESULT_CRITICAL
local TEXT_MODE_A_STRING_RESULT_GLANCING = TEXT_MODE_A_STRING_RESULT_GLANCING
local TEXT_MODE_A_STRING_RESULT_CRUSHING = TEXT_MODE_A_STRING_RESULT_CRUSHING

local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local COMBATLOG_OBJECT_RAIDTARGET_MASK = COMBATLOG_OBJECT_RAIDTARGET_MASK
local COMBATLOG_OBJECT_RAIDTARGET1 = COMBATLOG_OBJECT_RAIDTARGET1
local COMBATLOG_OBJECT_RAIDTARGET2 = COMBATLOG_OBJECT_RAIDTARGET2
local COMBATLOG_OBJECT_RAIDTARGET3 = COMBATLOG_OBJECT_RAIDTARGET3
local COMBATLOG_OBJECT_RAIDTARGET4 = COMBATLOG_OBJECT_RAIDTARGET4
local COMBATLOG_OBJECT_RAIDTARGET5 = COMBATLOG_OBJECT_RAIDTARGET5
local COMBATLOG_OBJECT_RAIDTARGET6 = COMBATLOG_OBJECT_RAIDTARGET6
local COMBATLOG_OBJECT_RAIDTARGET7 = COMBATLOG_OBJECT_RAIDTARGET7
local COMBATLOG_OBJECT_RAIDTARGET8 = COMBATLOG_OBJECT_RAIDTARGET8

-- modified globalstrings
local ADVANCED = gsub(ADVANCED_LABEL, "|T.-|t", "")
local OVERKILLING = gsub(TEXT_MODE_A_STRING_RESULT_OVERKILLING, "[%%d ()]", "")
local CRITICAL = gsub(TEXT_MODE_A_STRING_RESULT_CRITICAL, "[()]", "")
local GLANCING = gsub(TEXT_MODE_A_STRING_RESULT_GLANCING, "[()]", "")
local CRUSHING = gsub(TEXT_MODE_A_STRING_RESULT_CRUSHING, "[()]", "")

-- table reference shortcuts
local profile, char
local color, message, spell

-- other
local optionsFrame
local ChatFrame
local iconSize
local cropped = ":64:64:4:60:4:60"
local _

-- customizable arrays
local UnitColor, ClassColor
local SpellSchoolColor, EventColor

local spell_success, spell_successNT
local spell_applied, spell_appliedNT
local spell_summon, spell_create
local spell_start, spell_precast
local CrowdControl

local cd = {} -- internal cooldowns

local player = {
	name = UnitName("player"),
	class = select(2, UnitClass("player")),
}

local SpellSchoolString = {
	[0x1] = STRING_SCHOOL_PHYSICAL,
	[0x2] = STRING_SCHOOL_HOLY,
	[0x4] = STRING_SCHOOL_FIRE,
	[0x8] = STRING_SCHOOL_NATURE,
	[0x10] = STRING_SCHOOL_FROST,
	[0x20] = STRING_SCHOOL_SHADOW,
	[0x40] = STRING_SCHOOL_ARCANE,
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
	[0x7C] = STRING_SCHOOL_CHROMATIC,
	[0x7E] = STRING_SCHOOL_MAGIC,
	[0x7F] = STRING_SCHOOL_CHAOS,
}

local STRING_REACTION_ICON = {
	TEXT_MODE_A_STRING_SOURCE_ICON,
	TEXT_MODE_A_STRING_DEST_ICON,
}

local damageEvent = {
	["SWING_DAMAGE"] = true,
	["RANGE_DAMAGE"] = true,
	["SPELL_DAMAGE"] = true,
	["SPELL_PERIODIC_DAMAGE"] = true,
}

local healEvent = {
	["SPELL_HEAL"] = true,
	["SPELL_PERIODIC_HEAL"] = true,
}

-- in rare cases some players have 8 as the Unit Type
local playerID = {
	[0] = true,
	[8] = true,
}

local extraSpellEvent = {
	["SPELL_INTERRUPT"] = true,
	["SPELL_DISPEL"] = true,
	["SPELL_DISPEL_FAILED"] = true,
	["SPELL_STOLEN"] = true,
	["SPELL_AURA_BROKEN_SPELL"] = true,
}

local missType = {
	["ABSORB"] = COMBAT_TEXT_ABSORB,
	["BLOCK"] = COMBAT_TEXT_BLOCK,
	["DEFLECT"] = COMBAT_TEXT_DEFLECT,
	["DODGE"] = COMBAT_TEXT_DODGE,
	["EVADE"] = COMBAT_TEXT_EVADE,
	["IMMUNE"] = COMBAT_TEXT_IMMUNE,
	["MISS"] = COMBAT_TEXT_MISS,
	["PARRY"] = COMBAT_TEXT_PARRY,
	["REFLECT"] = COMBAT_TEXT_REFLECT,
	["RESIST"] = COMBAT_TEXT_RESIST,
}

local environmentalDamageType = {
	["DROWNING"] = ACTION_ENVIRONMENTAL_DAMAGE_DROWNING,
	["FALLING"] = ACTION_ENVIRONMENTAL_DAMAGE_FALLING,
	["FATIGUE"] = ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE,
	["FIRE"] = ACTION_ENVIRONMENTAL_DAMAGE_FIRE,
	["LAVA"] = ACTION_ENVIRONMENTAL_DAMAGE_LAVA,
	["SLIME"] = ACTION_ENVIRONMENTAL_DAMAGE_SLIME,
}

local Taunt = {
	[355] = true, -- Warrior: Taunt
	[6795] = true, -- Druid: Growl
	[17735] = true, -- Warlock: Suffering [Voidwalker]
	[20736] = true, -- Hunter: Distracting Shot
-- Death Knight
	[49560] = true, -- Death Grip
	[51399] = true, -- Death Grip (melee range)
	[56222] = true, -- Dark Command
-- Paladin
	[31790] = true, -- Righteous Defense
	[62124] = true, -- Hand of Reckoning
}

local Interrupt = {
	[1766] = true, -- Rogue: Kick
	[2139] = true, -- Mage: Counterspell
	[6552] = true, -- Warrior: Pummel
	[47528] = true, -- Death Knight: Mind Freeze
	[57994] = true, -- Shaman: Wind Shear
	[96231] = true, -- Paladin: Rebuke
-- Druid
	[80964] = true, -- Skull Bash (Bear); pre-interrupt
	[80965] = true, -- Skull Bash (Cat); pre-interrupt
	[93985] = true, -- Skull Bash; Interrupt
}

local Feast = {
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
}

local RepairBot = {
	[22700] = true, -- [Field Repair Bot 74A]
	[44389] = true, -- [Field Repair Bot 110G]
	[54710] = true, -- [MOLL-E]
	[54711] = true, -- [Scrapbot]
	[67826] = true, -- [Jeeves]
}

local Seasonal = {
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

local TankSupport = {
	[34477] = true, -- Misdirection
	[57934] = true, -- Tricks of the Trade
}

-- check if a Combat Text addon is available
local LibSinkCombatText = {
	["Blizzard"] = true,
	["MikSBT"] = true,
	["Parrot"] = true,
	["SCT"] = true,
}

local function isCombatText()
	return LibSinkCombatText[KCL.db.profile.sink20OutputSink]
end

	-------------------------
	--- Caching Functions ---
	-------------------------

local SpellIconChache = {}

local function GetSpellIcon(spellID)
	if not SpellIconChache[spellID] then
		SpellIconChache[spellID] = select(3, GetSpellInfo(spellID))
	end
	return SpellIconChache[spellID]
end

local SpellLinkCache = {}

local function GetSpellLink(spellID)
	if not SpellLinkCache[spellID] then
		SpellLinkCache[spellID] = oldGetSpellLink(spellID)
	end
	return SpellLinkCache[spellID] or "[CACHE ERROR]"
end

	------------------------
	--- Scanning Tooltip ---
	------------------------

local tooltip = CreateFrame("GameTooltip", "KethoCombatLogScanTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

local scanCache, dumpCache = {}, {}
scanCache.spell = {}

local function ScanTooltip(linkType, id, line)
	if scanCache[linkType][id] then
		return scanCache[linkType][id]
	else
		-- problem: sometimes the tooltip dies, and not sure how to "reactivate it"
		-- trying to avoid setting the same spell again; this should also be prevented by using caching
		if select(3, tooltip:GetSpell()) ~= id then
			tooltip:SetHyperlink(linkType..":"..id)
		end
		wipe(dumpCache)
		-- this is a bit ugly with the coloring and all :s
		for i = 2, line do
			if i == line then
				-- problem: a line can be omitted depending on the current glyphs+class
				tinsert(dumpCache, "|r"..(_G["KethoCombatLogScanTooltipTextLeft"..i]:GetText() or "|cffFF0000Error|r"))
				break
			end
			tinsert(dumpCache, _G["KethoCombatLogScanTooltipTextLeft"..i]:GetText())
			tinsert(dumpCache, _G["KethoCombatLogScanTooltipTextRight"..i]:GetText())
		end
		scanCache[linkType][id] = "|cffFFFF00"..strjoin("\n", unpack(dumpCache))
		return scanCache[linkType][id]
	end
end

	--------------------------
	--- Extra Tooltip Info ---
	--------------------------

-- determine if it's a mana class
-- tooltips may vary depending on if the player's class utilises mana
local ManaClass = {
	["PALADIN"] = true,
	["SHAMAN"] = true,
	["DRUID"] = true,
	["PRIEST"] = true,
	["MAGE"] = true,
	["WARLOCK"] = true,
}
local isManaClass = ManaClass[player.class]

-- could have used data from EncounterJournal_SetFlagIcon,
-- but there it included some whitespace, so using own coords now
local EJ_Coords = {
	{2, 6, 32, 96}, -- tank
	{10, 14, 32, 96}, -- dps
	{18, 22, 32, 96}, -- healer
	{26, 30, 32, 96}, -- heroic
	{34, 38, 32, 96}, -- deadly
	{42, 46, 32, 96}, -- imporant
	{50, 54, 32, 96}, -- interruptible
	{58, 62, 32, 96}, -- magic
	{2, 6, 120, 224}, -- curse
	{10, 14, 160, 224}, -- poison
	{18, 22, 160, 224}, -- disease
	{26, 30, 160, 224}, -- enrage
}

-- show buff type
local function EJ_Desc(index)
	local iconCoords = strjoin(":", unpack(EJ_Coords[index+1]))
	local iconString = "|TInterface\\EncounterJournal\\UI-EJ-Icons:18:18:1:"..(index == 11 and 1 or 3)..":64:256:"..iconCoords.."|t"
	return iconString.." ".._G["ENCOUNTER_JOURNAL_SECTION_FLAG"..index].."\n"
end

local schoolDescInfo = {
	["HOLY"] = {2, 0x2, "FFE680"},
	["FIRE"] = {3, 0x4, "FF8000"},
	["NATURE"] = {4, 0x8, "4DFF4D"},
	["FROST"] = {5, 0x10, "80FFFF"},
	["SHADOW"] = {6, 0x20, "8080FF"},
	["ARCANE"] = {7, 0x40, "FF80FF"},
}

-- show school type
local function SchoolDesc(school)
	local values = schoolDescInfo[school]

	local iconString = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon"..values[1]..":18:18:1:3:16:16:1:15:1:15|t"
	local nameString = SpellSchoolString[values[2]]
	return iconString.." |cff"..values[3]..nameString.."|r\n"
end

-- talent description
local function TalentDesc(amount, spec)
	return "|cffADFF2F"..amount.." "..LOCALIZED_TALENT_NAMES[spec].." "..TALENTS.."|r\n"
end

	-------------------------
	-- Options & Defaults ---
	-------------------------

local defaults = {
	profile = { -- KethoCombatLog.db.defaults.profile
		Taunt = true,
		Interrupt = true,
		Death = true,
		
		PvE = true,
		PvP = true,
		World = true,
		
		chatWindow = 2, -- ChatFrame1
		chatChannel = 1, -- Disabled

		iconSize = 16,
		iconCropped = true,
		UnitBracesChat = true,
		TrimRealmNames = true,
		criticalFormat = true,
		filterSelf = true,
		filterEverythingElse = true,
		filterPlayers = true,
		
		TankTaunt = true,
		FriendlyDispel = true,
		HostileDispel = true,
		BlizzardCombatLog = true,
		MissTaunt = true,
		MissInterrupt = true,
		MissCC = true,

		color = {
			Taunt = {1, 0, 0}, -- #FF0000 (Red)
			Interrupt = {0, 110/255, 1}, -- #006EFF
			Dispel = {1, 1, 1},
			Reflect = {1, 1, 1},
			CrowdControl = {1, 1, 1},
			CC_Break = {1, 1, 1},
			Death = {1, 1, 1},
			Resurrection = {175/255, 1, 47/255}, -- #ADFF2F (GreenYellow)
			-- Constants.lua: SCHOOL_MASK_PHYSICAL, ...
			Physical = {1.00, 1.00, 0.00}, -- #FFFF00
			Holy = {1.00, 0.90, 0.50}, -- #FFE680
			Fire = {1.00, 0.50, 0.00}, -- #FF8000
			Nature = {0.30, 1.00, 0.30}, -- #4DFF4D
			Frost = {0.50, 1.00, 1.00}, -- #80FFFF
			Shadow = {0.50, 0.50, 1.00}, -- #8080FF
			Arcane = {1.00, 0.50, 1.00}, -- #FF80FF
			-- RAID_CLASS_COLORS
			DeathKnight = {0.77, 0.12, 0.23}, -- #C41F3B
			Druid = {1.00 , 0.49, 0.04}, -- #FF7D0A
			Hunter = {0.67, 0.83, 0.45}, -- #ABD473
			Mage = {0.41, 0.80, 0.94}, -- #69CCF0
			Paladin = {0.96, 0.55, 0.73}, -- #F58CBA
			Priest = {1.00, 1.00, 1.00}, -- #FFFFFF
			Rogue = {1.00, 0.96, 0.41}, -- #FFF569
			Shaman = {0.00, 0.44, 0.87}, -- #0070DE
			Warlock = {0.58, 0.51, 0.79}, -- #9482C9
			Warrior = {0.78, 0.61, 0.43}, -- #C79C6E
			-- /dump COMBATLOG_DEFAULT_COLORS.unitColoring[32542]
			Friendly = {0.34, 0.64, 1.00}, -- #57A3FF
			Hostile = {0.75, 0.05, 0.05}, -- #BF0D0D
			Unknown = {191/255, 191/255, 191/255}, -- #BFBFBF
		},
		enableSpell = true,
		SpellFriend = true,
		SpellEnemy = true,
		spell = {
			-- Crowd Control
			[118] = true, -- Polymorph
			[339] = true, -- Entangling Roots
			[605] = true, -- Mind Control
			[710] = true, -- Banish
			[1513] = true, -- Scare Beast
			[2094] = true, -- Blind
			[2637] = true, -- Hibernate
			[3355] = true, -- Freezing Trap
			[5782] = true, -- Fear
			[6358] = true, -- Seduction (Succubus)
			[6770] = true, -- Sap
			[9484] = true, -- Shackle Undead
			[10326] = true, -- Turn Evil
			[19386] = true, -- Wyvern Sting
			[20066] = true, -- Repentance
			[33786] = true, -- Cyclone
			[51514] = true, -- Hex
			[76780] = true, -- Bind Elemental
		},
		sink20OutputSink = "None",
	},
}

local options = {
	type = "group",
	childGroups = "tab",
	name = " \124cffADFF2FKetho\124r |cffFFFFFFCombatLog|r |cffB6CA00v"..VERSION.."|r",
	args = {
		Main = {
			type = "group", order = 1,
			name = "Main",
			handler = KCL,
			args = {
				groupLocal = {
					type = "group",
					name = function() return profile.ChatFilters and "|cff71D5FFLocal|r" or " " end,
					order = 1,
					inline = true,
					args = {
						LocalTaunt = {
							type = "toggle",
							order = 1,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Nature_Reincarnation:20:20:1:0"..cropped.."|t  |cff"..EventColor["TAUNT"]..GetSpellInfo(355).."|r" end,
							get = function(i) return profile.Taunt end,
							set = function(i, v) profile.Taunt = v end,
						},
						LocalCrowdControl = {
							type = "toggle",
							order = 2,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Nature_Polymorph:20:20:1:0"..cropped.."|t  |cff"..EventColor["CROWDCONTROL"].."Crowd Control|r" end,
							get = function(i) return profile.CrowdControl end,
							set = function(i, v) profile.CrowdControl = v end,
						},
					--	force newline for Blizzard/AceConfigDialog "wide" Options Window; http://forums.wowace.com/showthread.php?p=312303
						newline01 = {type = "description", order = 3, name = ""},
						LocalInterrupt = {
							type = "toggle",
							order = 4,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Kick:20:20:1:0"..cropped.."|t  |cff"..EventColor["INTERRUPT"]..INTERRUPT.."|r" end,
							get = function(i) return profile.Interrupt end,
							set = function(i, v) profile.Interrupt = v end,
						},
						LocalCC_Break = {
							type = "toggle",
							order = 5,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Seal:20:20:1:0"..cropped.."|t  |cff"..EventColor["CC_BREAK"].."CC Breaker|r" end,
							get = function(i) return profile.CC_Break end,
							set = function(i, v) profile.CC_Break = v end,
						},
						newline02 = {type = "description", order = 6, name = ""},
						LocalWastedInterrupt = {
							type = "toggle",
							order = 7,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Spell_Frost_IceShock:20:20:1:0"..cropped.."|t  Wasted "..INTERRUPT end,
							disabled = function() return not profile.Interrupt or not KCL:IsEnabled() end,
							get = function(i) return profile.WastedInterrupt end,
							set = function(i, v) profile.WastedInterrupt = v end,
						},
						LocalDeath = {
							type = "toggle",
							order = 8,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Rogue_FeignDeath:20:20:1:0"..cropped.."|t  |cff"..EventColor["DEATH"]..TUTORIAL_TITLE25.."|r" end,
							get = function(i) return profile.Death end,
							set = function(i, v) profile.Death = v end,
						},
						newline03 = {type = "description", order = 9, name = ""},
						LocalDispel = {
							type = "toggle",
							order = 10,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Holy_DispelMagic:20:20:1:0"..cropped.."|t  |cff"..EventColor["DISPEL"]..GetSpellInfo(25808).."|r" end,
							get = function(i) return profile.Dispel end,
							set = function(i, v) profile.Dispel = v end,
						},
						LocalDeathPrevent = {
							type = "toggle",
							order = 11,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Spell_Holy_GuardianSpirit:20:20:1:0"..cropped.."|t  "..TUTORIAL_TITLE25.." Prevent" end,
							disabled = function() return not profile.Death or not KCL:IsEnabled() end,
							get = function(i) return profile.DeathPrevent end,
							set = function(i, v) profile.DeathPrevent = v end,
						},
						newline04 = {type = "description", order = 12, name = ""},
						LocalReflect = {
							type = "toggle",
							order = 13,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Warrior_ShieldReflection:20:20:1:0"..cropped.."|t  |cff"..EventColor["REFLECT"]..REFLECT.."|r" end,
							get = function(i) return profile.Reflect end,
							set = function(i, v) profile.Reflect = v end,
						},
						LocalResurrection = {
							type = "toggle",
							order = 14,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Holy_Resurrection:20:20:1:0"..cropped.."|t  |cff"..EventColor["RESURRECTION"]..GetSpellInfo(2006).."|r" end,
							get = function(i) return profile.Resurrection end,
							set = function(i, v) profile.Resurrection = v end,
						},
					},
				},
				groupChat = {
					type = "group",
					name = " ",
					order = 2,
					inline = true,
					name = function() return profile.ChatFilters and "|cff71D5FF"..CHAT.."|r" or " " end,
					hidden = function() return not profile.ChatFilters end,
					args = {
						ChatTaunt = {
							type = "toggle",
							order = 1,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Nature_Reincarnation:20:20:1:0"..cropped.."|t  |cff"..EventColor["TAUNT"]..GetSpellInfo(355).."|r" end,
							get = function(i) return profile.ChatTaunt end,
							set = function(i, v) profile.ChatTaunt = v end,
						},
						ChatCrowdControl = {
							type = "toggle",
							order = 2,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Nature_Polymorph:20:20:1:0"..cropped.."|t  |cff"..EventColor["CROWDCONTROL"].."Crowd Control|r" end,
							get = function(i) return profile.ChatCrowdControl end,
							set = function(i, v) profile.ChatCrowdControl = v end,
						},
						newline01 = {type = "description", order = 3, name = ""},
						ChatInterrupt = {
							type = "toggle",
							order = 4,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Kick:20:20:1:0"..cropped.."|t  |cff"..EventColor["INTERRUPT"]..INTERRUPT.."|r" end,
							get = function(i) return profile.ChatInterrupt end,
							set = function(i, v) profile.ChatInterrupt = v end,
						},
						ChatCC_Break = {
							type = "toggle",
							order = 5,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Seal:20:20:1:0"..cropped.."|t  |cff"..EventColor["CC_BREAK"].."CC Breaker|r" end,
							get = function(i) return profile.ChatCC_Break end,
							set = function(i, v) profile.ChatCC_Break = v end,
						},
						newline02 = {type = "description", order = 6, name = ""},
						ChatWastedInterrupt = {
							type = "toggle",
							order = 7,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Spell_Frost_IceShock:20:20:1:0"..cropped.."|t  Wasted "..INTERRUPT end,
							disabled = function() return not profile.ChatInterrupt or not KCL:IsEnabled() end,
							get = function(i) return profile.ChatWastedInterrupt end,
							set = function(i, v) profile.ChatWastedInterrupt = v end,
						},
						ChatDeath = {
							type = "toggle",
							order = 8,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Rogue_FeignDeath:20:20:1:0"..cropped.."|t  |cff"..EventColor["DEATH"]..TUTORIAL_TITLE25.."|r" end,
							get = function(i) return profile.ChatDeath end,
							set = function(i, v) profile.ChatDeath = v end,
						},
						newline03 = {type = "description", order = 9, name = ""},
						ChatDispel = {
							type = "toggle",
							order = 10,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Holy_DispelMagic:20:20:1:0"..cropped.."|t  |cff"..EventColor["DISPEL"]..GetSpellInfo(25808).."|r" end,
							get = function(i) return profile.ChatDispel end,
							set = function(i, v) profile.ChatDispel = v end,
						},
						ChatDeathPrevent = {
							type = "toggle",
							order = 11,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Spell_Holy_GuardianSpirit:20:20:1:0"..cropped.."|t  "..TUTORIAL_TITLE25.." Prevent" end,
							disabled = function() return not profile.ChatDeath or not KCL:IsEnabled() end,
							get = function(i) return profile.ChatDeathPrevent end,
							set = function(i, v) profile.ChatDeathPrevent = v end,
						},
						newline04 = {type = "description", order = 12, name = ""},
						ChatReflect = {
							type = "toggle",
							order = 13,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Ability_Warrior_ShieldReflection:20:20:1:0"..cropped.."|t  |cff"..EventColor["REFLECT"]..REFLECT.."|r" end,
							get = function(i) return profile.ChatReflect end,
							set = function(i, v) profile.ChatReflect = v end,
						},
						ChatResurrection = {
							type = "toggle",
							order = 14,
							descStyle = "",
							disabled = "OptionsDisabled",
							name = function() return "|TInterface\\Icons\\Spell_Holy_Resurrection:20:20:1:0"..cropped.."|t  |cff"..EventColor["RESURRECTION"]..GetSpellInfo(2006).."|r" end,
							get = function(i) return profile.ChatResurrection end,
							set = function(i, v) profile.ChatResurrection = v end,
						},
					},
				},
				spacing = {
					type = "description",
					order = 3,
					name = "",
				},
				togglePvE = {
					type = "toggle",
					order = 4,
					descStyle = "",
					width = "half",
					name = " |cffA8A8FFPvE|r", -- /dump ChatTypeInfo.PARTY {r = 0.666, g = 0.666, b = 1.000}
					disabled = "OptionsDisabled",
					get = function(i) return profile.PvE end,
					set = function(i, v) profile.PvE = v end,
				},
				togglePvP = {
					type = "toggle",
					order = 5,
					width = "half",
					descStyle = "",
					name = " |cffFF7F00"..PVP.."|r", -- /dump ChatTypeInfo.RAID {r = 1.000, g = 0.498, b = 0.000}
					disabled = "OptionsDisabled",
					get = function(i) return profile.PvP end,
					set = function(i, v) profile.PvP = v end,
				},
				toggleWorld = {
					type = "toggle",
					order = 6,
					descStyle = "",
					name = " World",
					width = "half",
					disabled = "OptionsDisabled",
					get = function(i) return profile.World end,
					set = function(i, v) profile.World = v end,
				},
				toggleChatFilters = {
					type = "toggle",
					order = 7,
					descStyle = "",
					disabled = "OptionsDisabled",
					name = "|cff71D5FF"..CHAT.." "..FILTERS.."|r",
					get = function(i) return profile.ChatFilters end,
					set = function(i, v) profile.ChatFilters = v end,
				},
				newline = {
					type = "description",
					order = 8,
					name = "",
				},
				selectChatWindow = {
					type = "select",
					order = 9,
					descStyle = "",
					name = "   |cffFFFFFF"..CHAT.." Window|r",
					disabled = "OptionsDisabled",
					values = function()
						local ChatWindowList = {}
						ChatWindowList[1] = "|cffFF0000<"..ADDON_DISABLED..">|r"
						for i = 1, NUM_CHAT_WINDOWS do
							if GetChatWindowInfo(i) ~= "" then
								ChatWindowList[i+1] = "|cff2E9AFE"..i..".|r  "..select(1, GetChatWindowInfo(i))
							end
						end
						return ChatWindowList end,
					get = function(i) return profile.chatWindow end,
					set = function(i, v) profile.chatWindow = v
						if v > 1 then
							ChatFrame = _G["ChatFrame"..v-1]
							ChatFrame:AddMessage("|cffADFF2FKetho CombatLog|r: Chat Frame |cff57A3FF"..(v-1)..".|r |cffADFF2F"..GetChatWindowInfo(v-1).."|r")
						end
					end,
				},
				selectChatChannel = {
					type = "select",
					order = 10,
					descStyle = "",
					name = "   |cffFFFFFF"..CHAT.." "..CHANNEL.."|r",
					disabled = "OptionsDisabled",
					values = function() local ChatChannelList = {}
						ChatChannelList[1] = "|cffFF0000<"..ADDON_DISABLED..">|r"
						ChatChannelList[2] = "|cff2E9AFE#|r   "..CHAT_MSG_SAY
						ChatChannelList[3] = "|cff2E9AFE#|r   |cffFF4040"..CHAT_MSG_YELL.."|r"
						ChatChannelList[4] = "|cff2E9AFE#|r   |cffA8A8FF"..CHAT_MSG_PARTY.."|r / |cffFF7F00"..CHAT_MSG_RAID.."|r"
						for i = 1, 10 do
							local channelID = select((i*2)-1, GetChannelList()) -- this is was kinda hard to code, seeing how GetChannelList() works..
							if channelID then
								ChatChannelList[channelID+4] = "|cff2E9AFE"..channelID..".|r  "..select(i*2,GetChannelList())
							end
						end
						return ChatChannelList end,
					get = function(i) return profile.chatChannel end,
					set = function(i, v) profile.chatChannel = v end,
				},
				descEnable = {
					type = "description",
					order = 11,
					fontSize = "large",
					name = function() return KCL:OptionsDisabled() and " Type |cff2E9AFE/ket on|r to enable" or "" end,
				},
			},
		},
		Advanced = {
			type = "group", order = 2,
			name = "Advanced",
			handler = KCL,
			args = {
				groupAdvanced = {
					type = "group",
					order = 1,
					name = "|TINTERFACE\\ICONS\\inv_misc_orb_05:14:14:1:0"..cropped.."|t  |cffFFFFFF"..ADVANCED.."|r",
					args = {
						header1 = {type = "header", order = 1, name = "Icons"},
						IconSize = {
							type = "select",
							order = 2,
							descStyle = "", 
							name = "|cffFFFFFF"..EMBLEM_SYMBOL.." Size|r",
							values = {"|cffFF0000<"..ADDON_DISABLED..">|r", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, " 12", nil, " 14", nil, " 16  |cffFBDB00(Default)|r", nil, " 18",  nil, " 20", nil, " 22", nil, " 24", nil, " 26", nil, " 28", nil, " 30", nil, " 32"},
							get = function(i) return profile.iconSize end,
							set = function(i, v) profile.iconSize = v; iconSize = profile.iconSize end,
						},
						newline = {type = "description", order = 3, name = " "},
						CropIcon = {
							type = "toggle",
							order = 4,
							descStyle = "",
							name = "|TInterface\\Icons\\inv_misc_orb_05:20:20:1:0|t -> |TInterface\\Icons\\inv_misc_orb_05:20:20:1:0:64:64:4:60:4:60|t  Crop",
							disabled = function() return not profile.iconSize end,
							get = function(i) return profile.iconCropped end,
							set = function(i, v) profile.iconCropped = v
								cropped = v and ":64:64:4:60:4:60" or ""
							end,
						},
						header2 = {type = "header", order = 5, name = "Message "..FORMATTING},
						TrimRealmNames = {
							type = "toggle",
							order = 6,
							desc = UnitName("player").."-|cffFF0000"..GetRealmName().."|r -> "..UnitName("player"),
							name = "|cff71D5FFTrim Realm Names|r",
							get = function(i) return profile.TrimRealmNames end,
							set = function(i, v) profile.TrimRealmNames = v end,
						},
						Timestamp = {
							type = "toggle",
							order = 8,
							desc = TIMESTAMP_COMBATLOG_TOOLTIP.."\n|cffFF0000["..TEXT_MODE_A_TIMESTAMP.."]|r",
							name = "|cff71D5FF"..TIMESTAMPS_LABEL.."|r",
							get = function(i) return profile.Timestamp end,
							set = function(i, v) profile.Timestamp = v end,
						},
						UnitBracesLocal = {
							type = "toggle",
							order = 7,
							desc = UNIT_NAMES_SHOW_BRACES_COMBATLOG_TOOLTIP.."\n"..UnitName("player").." -> |cffFF0000[|r"..UnitName("player").."|cffFF0000]|r",
							name = "|cff71D5FF"..SHOW_BRACES.."|r (Local)",
							get = function(i) return profile.UnitBracesLocal end,
							set = function(i, v) profile.UnitBracesLocal = v end,
						},
						UnitBracesChat = {
							type = "toggle",
							order = 9,
							desc = UNIT_NAMES_SHOW_BRACES_COMBATLOG_TOOLTIP.."\n"..UnitName("player").." -> |cffFF0000[|r"..UnitName("player").."|cffFF0000]|r",
							name = "|cff71D5FF"..SHOW_BRACES.."|r ("..CHAT..")",
							get = function(i) return profile.UnitBracesChat end,
							set = function(i, v) profile.UnitBracesChat = v end,
						},
						header3 = {type = "header", order = 10, name = DAMAGE.." "..FORMATTING},
						OverkillFormat = {
							type = "toggle",
							order = 11,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_OVERKILLING.."|r",
							name = OVERKILLING,
							get = function(i) return profile.overkillFormat end,
							set = function(i, v) profile.overkillFormat = v end,
						},
						CriticalFormat = {
							type = "toggle",
							order = 13,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_CRITICAL.."|r",
							name = CRITICAL,
							get = function(i) return profile.criticalFormat end,
							set = function(i, v) profile.criticalFormat = v end,
						},
						GlancingFormat = {
							type = "toggle",
							order = 12,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_GLANCING .."|r",
							name = GLANCING,
							get = function(i) return profile.glancingFormat end,
							set = function(i, v) profile.glancingFormat = v end,
						},
						CrushingFormat = {
							type = "toggle",
							order = 14,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_CRUSHING.."|r",
							name = CRUSHING,
							get = function(i) return profile.crushingFormat end,
							set = function(i, v) profile.crushingFormat = v end,
						},
						header4 = {type = "header", order = 15, name = OTHER.." (1)"},
						BlizzardCombatLog = {
							type = "toggle",
							order = 16,
							desc = BINDING_NAME_TOGGLECOMBATLOG,
							width = "full",
							name = "|cff2E9AFEBlizzard CombatLog|r",
							get = function(i) return profile.BlizzardCombatLog end,
							set = function(i, v) profile.BlizzardCombatLog = v
								if v then
									COMBATLOG:RegisterEvent("COMBAT_LOG_EVENT")
									print("Blizzard CombatLog: |cffB6CA00Enabled|r")
								else
									COMBATLOG:UnregisterEvent("COMBAT_LOG_EVENT")
									print("Blizzard CombatLog: |cffFF2424Disabled|r")
								end
							end,
						},
						LoggingChat = {
							type = "toggle",
							order = 17,
							desc = "Note: |cff71D5FFPrat|r can override these settings",
							width = "full",
							name = CHAT.." Logging",
							get = function() return LoggingChat() end,
							set = SlashCmdList["CHATLOG"],
						},
						LoggingCombat = {
							type = "toggle",
							order = 18,
							desc = "Note: |cff71D5FFPrat|r can override these settings",
							width = "full",
							name = COMBAT.." Logging",
							get = function() return LoggingCombat() end,
							set = SlashCmdList["COMBATLOG"],
						},
						header5 = {type = "header", order = 19, name = OTHER.." (2)"},
						SpellSpellName = {
							type = "toggle",
							order = 20,
							descStyle = "",
							name = "|cffFFFF00Spell Name|r instead of Spell Link",
							width = "full",
							get = function(i) return profile.SpellSpellName end,
							set = function(i, v) profile.SpellSpellName = v end,
						},
						BattleRez = {
							type = "toggle",
							order = 21,
							descStyle = "",
							name = "|TInterface\\Icons\\Spell_Holy_Resurrection:16:16:1:0"..cropped.."|t  Only show |cffADFF2FBattlerezzes|r",
							width = "full",
							get = function(i) return profile.BattleRez end,
							set = function(i, v) profile.BattleRez = v end,
						},
						TankSupport = {
							type = "toggle",
							order = 22,
							descStyle = "",
							name = "|TInterface\\LFGFRAME\\UI-LFG-ICON-ROLES:20:20:-3:0:256:256:1:65:68:132|t Only show |cffABD473"..GetSpellInfo(34477).."|r/|cffFFF569"..GetSpellInfo(57934).."|r on "..TANK,
							width = "full",
							get = function(i) return profile.TankSupport end,
							set = function(i, v) profile.TankSupport = v end,
						},
					},
				},
				groupColoring = {
					type = "group",
					order = 2,
					name = "|TInterface\\Icons\\INV_Misc_Gem_Variety_02:14:14:1:0"..cropped.."|t  |cffFFFFFF"..COLORS.."|r",
					args = {
						colorTaunt = {
							type = "color",
							order = 1,
							name = "|TInterface\\Icons\\Spell_Nature_Reincarnation:16:16:1:0"..cropped.."|t  "..GetSpellInfo(355),
							get = function(i) return unpack(color.Taunt) end,
							set = function(i, r,g,b) color.Taunt = {r, g, b}; EventColor["TAUNT"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorInterrupt = {
							type = "color",
							order = 3,
							name = "|TInterface\\Icons\\Ability_Kick:16:16:1:0"..cropped.."|t  "..INTERRUPT,
							get = function(i) return unpack(color.Interrupt) end,
							set = function(i, r,g,b) color.Interrupt = {r, g, b}; EventColor["INTERRUPT"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorDispel = {
							type = "color",
							order = 5,
							name = "|TInterface\\Icons\\Spell_Holy_DispelMagic:16:16:1:0"..cropped.."|t  "..GetSpellInfo(25808),
							get = function(i) return unpack(color.Dispel) end,
							set = function(i, r,g,b) color.Dispel = {r, g, b}; EventColor["DISPEL"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorReflect = {
							type = "color",
							order = 7,
							name = "|TInterface\\Icons\\Ability_Warrior_ShieldReflection:16:16:1:0"..cropped.."|t  "..REFLECT,
							get = function(i) return unpack(color.Reflect) end,
							set = function(i, r,g,b) color.Reflect = {r, g, b}; EventColor["REFLECT"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorCrowdControl = {
							type = "color",
							order = 2,
							name = "|TInterface\\Icons\\Spell_Nature_Polymorph:16:16:1:0"..cropped.."|t  Crowd Control",
							get = function(i) return unpack(color.CrowdControl) end,
							set = function(i, r,g,b) color.CrowdControl = {r, g, b}; EventColor["CROWDCONTROL"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorCC_Break = {
							type = "color",
							order = 4,
							name = "|TInterface\\Icons\\Ability_Seal:16:16:1:0"..cropped.."|t  CC Breaker",
							get = function(i) return unpack(color.CC_Break) end,
							set = function(i, r,g,b) color.CC_Break = {r, g, b}; EventColor["CC_BREAK"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorDeath = {
							type = "color",
							order = 6,
							name = "|TInterface\\Icons\\Ability_Rogue_FeignDeath:16:16:1:0"..cropped.."|t  "..TUTORIAL_TITLE25,
							get = function(i) return unpack(color.Death) end,
							set = function(i, r,g,b) color.Death = {r, g, b}; EventColor["DEATH"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorResurrection = {
							type = "color",
							
							order = 8,
							name = "|TInterface\\Icons\\Spell_Holy_Resurrection:16:16:1:0"..cropped.."|t  "..GetSpellInfo(2006),
							get = function(i) return unpack(color.Resurrection) end,
							set = function(i, r,g,b) color.Resurrection = {r, g, b}; EventColor["RESURRECTION"] = KCL:Dec2Hex(r, g, b) end,
						},
						header01 = {type = "header", order = 9, name = ""},
						colorWarrior = {
							type = "color",
							order = 10,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:4:60:4:60|t  "..LOCALIZED_CLASS_NAMES_MALE["WARRIOR"],
							get = function(i) return unpack(color.Warrior) end,
							set = function(i, r,g,b) color.Warrior = {r, g, b}; ClassColor["WARRIOR"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorDeathKnight = {
							type = "color",
							order = 12,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:68:124:133:189|t  "..LOCALIZED_CLASS_NAMES_MALE["DEATHKNIGHT"],
							get = function(i) return unpack(color.DeathKnight) end,
							set = function(i, r,g,b) color.DeathKnight = {r, g, b}; ClassColor["DEATHKNIGHT"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorPaladin = {
							type = "color",
							order = 14,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:4:60:132:188|t  "..LOCALIZED_CLASS_NAMES_MALE["PALADIN"],
							get = function(i) return unpack(color.Paladin) end,
							set = function(i, r,g,b) color.Paladin = {r, g, b}; ClassColor["PALADIN"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorHunter = {
							type = "color",
							order = 16,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:4:60:68:124|t  "..LOCALIZED_CLASS_NAMES_MALE["HUNTER"],
							get = function(i) return unpack(color.Hunter) end,
							set = function(i, r,g,b) color.Hunter = {r, g, b}; ClassColor["HUNTER"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorShaman = {
							type = "color",
							order = 18,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:68:124:68:124|t  "..LOCALIZED_CLASS_NAMES_MALE["SHAMAN"],
							get = function(i) return unpack(color.Shaman) end,
							set = function(i, r,g,b) color.Shaman = {r, g, b}; ClassColor["SHAMAN"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorRogue = {
							type = "color",
							order = 11,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:131:187:4:60|t  "..LOCALIZED_CLASS_NAMES_MALE["ROGUE"],
							get = function(i) return unpack(color.Rogue) end,
							set = function(i, r,g,b) color.Rogue = {r, g, b}; ClassColor["ROGUE"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorDruid = {
							type = "color",
							order = 13,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:194:250:4:60|t  "..LOCALIZED_CLASS_NAMES_MALE["DRUID"],
							get = function(i) return unpack(color.Druid) end,
							set = function(i, r,g,b) color.Druid = {r, g, b}; ClassColor["DRUID"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorMage = {
							type = "color",
							order = 15,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:68:124:4:60|t  "..LOCALIZED_CLASS_NAMES_MALE["MAGE"],
							get = function(i) return unpack(color.Mage) end,
							set = function(i, r,g,b) color.Mage = {r, g, b}; ClassColor["MAGE"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorPriest = {
							type = "color",
							order = 17,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:130:186:68:124|t  "..LOCALIZED_CLASS_NAMES_MALE["PRIEST"],
							get = function(i) return unpack(color.Priest) end,
							set = function(i, r,g,b) color.Priest = {r, g, b}; ClassColor["PRIEST"] = KCL:Dec2Hex(r, g, b) end,
						},
						colorWarlock = {
							type = "color",
							order = 19,
							name = "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:256:256:194:250:68:124|t  "..LOCALIZED_CLASS_NAMES_MALE["WARLOCK"],
							get = function(i) return unpack(color.Warlock) end,
							set = function(i, r,g,b) color.Warlock = {r, g, b}; ClassColor["WARLOCK"] = KCL:Dec2Hex(r, g, b) end,
						},
						header02 = {type = "header", order = 20, name = ""},
						colorPhysical = {
							type = "color",
							order = 21,
							name = "|TInterface\\Icons\\Spell_Nature_Strength:16:16:1:0"..cropped.."|t  "..STRING_SCHOOL_PHYSICAL,
							get = function(i) return unpack(color.Physical) end,
							set = function(i, r,g,b) color.Physical = {r, g, b}; SpellSchoolColor[0x1] = KCL:Dec2Hex(r, g, b) end,
						},
						colorHoly = {
							type = "color",
							order = 23,
							name = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon2:16:16:1:0:16:16:1:15:1:15|t  "..STRING_SCHOOL_HOLY,
							get = function(i) return unpack(color.Holy) end,
							set = function(i, r,g,b) color.Holy = {r, g, b}; SpellSchoolColor[0x2] = KCL:Dec2Hex(r, g, b) end,
						},
						colorFire = {
							type = "color",
							order = 25,
							name = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon3:16:16:1:0:16:16:1:15:1:15|t  "..STRING_SCHOOL_FIRE,
							get = function(i) return unpack(color.Fire) end,
							set = function(i, r,g,b) color.Fire = {r, g, b}; SpellSchoolColor[0x4] = KCL:Dec2Hex(r, g, b) end,
						},
						colorNature = {
							type = "color",
							order = 27,
							name = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon4:16:16:1:0:16:16:1:15:1:15|t  "..STRING_SCHOOL_NATURE,
							get = function(i) return unpack(color.Nature) end,
							set = function(i, r,g,b) color.Nature = {r, g, b}; SpellSchoolColor[0x8] = KCL:Dec2Hex(r, g, b) end,
						},
						colorFrost = {
							type = "color",
							order = 22,
							name = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon5:16:16:1:0:16:16:1:15:1:15|t  "..STRING_SCHOOL_FROST,
							get = function(i) return unpack(color.Frost) end,
							set = function(i, r,g,b) color.Frost = {r, g, b}; SpellSchoolColor[0x10] = KCL:Dec2Hex(r, g, b) end,
						},
						colorShadow = {
							type = "color",
							order = 24,
							name = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon6:16:16:1:0:16:16:1:15:1:15|t  "..STRING_SCHOOL_SHADOW,
							get = function(i) return unpack(color.Shadow) end,
							set = function(i, r,g,b) color.Shadow = {r, g, b}; SpellSchoolColor[0x20] = KCL:Dec2Hex(r, g, b) end,
						},
						colorArcane = {
							type = "color",
							order = 26,
							name = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon7:16:16:1:0:16:16:1:15:1:15|t  "..STRING_SCHOOL_ARCANE,
							get = function(i) return unpack(color.Arcane) end,
							set = function(i, r,g,b) color.Arcane = {r, g, b}; SpellSchoolColor[0x40] = KCL:Dec2Hex(r, g, b) end,
						},
						header03 = {type = "header", order = 28, name = ""},
						colorFriendly = {
							type = "color",
							order = 29,
							width = "full",
							name = "|TInterface\\Icons\\Spell_ChargePositive:16:16:1:0"..cropped.."|t  "..FRIENDLY,
							get = function(i) return unpack(color.Friendly) end,
							set = function(i, r,g,b) color.Friendly = {r, g, b}; UnitColor[1] = KCL:Dec2Hex(r, g, b) end,
						},
						colorHostile = {
							type = "color",
							order = 30,
							width = "full",
							name = "|TInterface\\Icons\\Spell_ChargeNegative:16:16:1:0"..cropped.."|t  "..HOSTILE,
							get = function(i) return unpack(color.Hostile) end,
							set = function(i, r,g,b) color.Hostile = {r, g, b}; UnitColor[2] = KCL:Dec2Hex(r, g, b) end,
						},
						colorUnknown = {
							type = "color",
							order = 31,
							width = "full",
							name = "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:1:0"..cropped.."|t  "..UNKNOWN,
							get = function(i) return unpack(color.Unknown) end,
							set = function(i, r,g,b) color.Unknown = {r, g, b}; UnitColor[3] = KCL:Dec2Hex(r, g, b) end,
						},
						spacing = {type = "description", order = 32, name = ""},
						executeReset = {
							type = "execute",
							order = 33,
							descStyle = "",
							name = "|cffFFFFFFReset Colors|r",
							confirm = true, confirmText = "Reset Colors?",
							func = function()
								for k, v in pairs(defaults.profile.color) do
									--print(v) -- debug
									profile.color[k] = v
								end
								-- 20120127: this one is a bit weird; maybe needed for updating hex stuff
								KCL:RefreshConfig()
							end,
						},
					},
				},
				groupFilter = {
					type = "group",
					order = 3,
					name = "|TInterface\\Icons\\Spell_Holy_Silence:14:14:1:0"..cropped.."|t  |cffFFFFFF"..FILTERS.."|r",
					args = {
						header1 = {type = "header", order = 1, name = COMBAT_LOG_MENU_BOTH},
						toggleSelf = {
							type = "toggle",
							order = 2,
							descStyle = "",
							width = "full",
							name = YOU,
							get = function(i) return profile.filterSelf end,
							set = function(i, v) profile.filterSelf = v
								if not v then profile.filterEverythingElse = true end
							end,
						},
						toggleEverythingElse = {
							type = "toggle",
							order = 3,
							descStyle = "",
							name = "Others",
							get = function(i) return profile.filterEverythingElse end,
							set = function(i, v) profile.filterEverythingElse = v
								if not v then profile.filterSelf = true end
							end,
						},
						header2 = {type = "header", order = 4, name = BY_SOURCE.." "..TYPE},
						togglePlayers = {
							type = "toggle",
							order = 5,
							descStyle = "",
							width = "full",
							name = TUTORIAL_TITLE19,
							get = function(i) return profile.filterPlayers end,
							set = function(i, v) profile.filterPlayers = v
								if not v then profile.filterMonsters = true end
							end,
						},
						toggleMonsters = {
							type = "toggle",
							order = 6,
							descStyle = "",
							width = "full",
							name = "NPCs",
							get = function(i) return profile.filterMonsters end,
							set = function(i, v) profile.filterMonsters = v
								if not v then profile.filterPlayers = true end
							end,
						},
					},
				},
				groupExtraEvent = {
					type = "group",
					order = 4,
					name = "|TInterface\\Icons\\Ability_Marksmanship:14:14:1:0"..cropped.."|t  |cffFFFFFFExtra|r",
					args = {
						header1 = {type = "header", order = 1, name = "|TInterface\\LFGFRAME\\UI-LFG-ICON-ROLES:20:20:0:0:256:256:1:65:68:132|t "..TANK},
						toggleTankTaunt = {
							type = "toggle",
							order = 2,
							descStyle = "",
							width = "full",
							name = function() return "|TInterface\\LFGFRAME\\UI-LFG-ICON-ROLES:20:20:-3:0:256:256:1:65:68:132|t|TInterface\\Icons\\Spell_Nature_Reincarnation:16:16:0:0"..cropped.."|t  |cff6FAFE6"..TANK.."|r Taunt" end,
							disabled = function() return not profile.Taunt end,
							get = function(i) return profile.TankTaunt end,
							set = function(i, v) profile.TankTaunt = v end,
						},
						toggleTankBreak = {
							type = "toggle",
							order = 3,
							descStyle = "",
							width = "full",
							name = function() return "|TInterface\\LFGFRAME\\UI-LFG-ICON-ROLES:20:20:-3:0:256:256:1:65:68:132|t|TInterface\\Icons\\Ability_Seal:16:16:0:0"..cropped.."|t  |cff6FAFE6"..TANK.."|r CC Break" end,
							disabled = function() return not profile.CC_Break end,
							get = function(i) return profile.TankBreak end,
							set = function(i, v) profile.TankBreak = v end,
						},
						togglePetGrowl = {
							type = "toggle",
							order = 4,
							descStyle = "",
							width = "full",
							name = function() return " |TInterface\\Icons\\INV_Weapon_Bow_07:16:16:-4:0"..cropped.."|t|TInterface\\Icons\\Ability_Physical_Taunt:16:16:1:0"..cropped.."|t  |cffABD473"..PET.."|r "..GetSpellInfo(2649) end,
							disabled = function() return not profile.Taunt end,
							get = function(i) return profile.PetGrowl end,
							set = function(i, v) profile.PetGrowl = v end,
						},
						header2 = {type = "header", order = 5, name = "|TInterface\\Icons\\Spell_Holy_DispelMagic:16:16:1:0"..cropped.."|t  "..DISPELS},
						toggleFriendlyDispel = {
							type = "toggle",
							order = 6,
							descStyle = "",
							name = " "..FRIENDLY.." (|cff71D5FF"..ACTION_SPELL_DISPEL_DEBUFF.."|r)",
							disabled = function() return not profile.Dispel end,
							get = function(i) return profile.FriendlyDispel end,
							set = function(i, v) profile.FriendlyDispel = v end,
						},
						toggleHostileDispel = {
							type = "toggle",
							order = 7,
							descStyle = "",
							width = "full",
							name = " "..HOSTILE.." (|cff71D5FF"..ACTION_SPELL_DISPEL_BUFF.."|r)",
							disabled = function() return not profile.Dispel end,
							get = function(i) return profile.HostileDispel end,
							set = function(i, v) profile.HostileDispel = v end,
						},
						header3 = {type = "header", order = 8, name = "|TInterface\\Icons\\Ability_Marksmanship:14:14:1:0"..cropped.."|t  "..MISSES},
						toggleMissTaunt = {
							type = "toggle",
							order = 9,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Spell_Nature_Reincarnation:16:16:1:0"..cropped.."|t  "..GetSpellInfo(355) end,
							disabled = function() return not profile.Taunt or profile.MissAll end,
							get = function(i) return profile.MissTaunt end,
							set = function(i, v) profile.MissTaunt = v end,
						},
						newline01 = {type = "description", order = 10, name = ""},
						toggleMissInterrupt = {
							type = "toggle",
							order = 11,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Ability_Kick:16:16:1:0"..cropped.."|t  "..INTERRUPT end,
							disabled = function() return not profile.Interrupt or profile.MissAll end,
							get = function(i) return profile.MissInterrupt end,
							set = function(i, v) profile.MissInterrupt = v end,
						},
						newline02 = {type = "description", order = 12, name = ""},
						toggleMissCC = {
							type = "toggle",
							order = 13,
							descStyle = "",
							name = function() return "|TInterface\\Icons\\Spell_Nature_Polymorph:16:16:1:0"..cropped.."|t  Crowd Control" end,
							disabled = function() return not profile.CrowdControl or profile.MissAll end,
							get = function(i) return profile.MissCC end,
							set = function(i, v) profile.MissCC = v end,
						},
						newline03 = {type = "description", order = 14, name = ""},
						toggleMissAll = {
							type = "toggle",
							order = 15,
							descStyle = "",
							name = function() return " |cff71D5FF"..ALL.." "..MISSES.."|r" end,
							disabled = "OptionsDisabled",
							get = function(i) return profile.MissAll end,
							set = function(i, v) profile.MissAll = v end,
						},						
					},
				},
				groupSpacing1 = {type = "group", order = 5, name = "", disabled = true, args = {}},
				groupFun = {
					type = "group",
					order = 6,
					name = "|TInterface\\AddOns\\Ketho_CombatLog\\Awesome:16:16:1:0|t  |cffFFFFFFFun|r",
					args = {
						toggleFeast = {
							type = "toggle",
							order = 1,
							width = "full",
							desc = "|cffF6ADC6\"om nom nom nom\"|r", 
							name = " Feasts  |TInterface\\Icons\\Spell_Misc_Food:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Misc_Food_Meat_Cooked_02:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Misc_Food_99:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Misc_Fish_52:16:16:0:0"..cropped.."|t |TInterface\\Icons\\Ability_Hunter_Pet_Boar:16:16:0:0"..cropped.."|t",
							get = function(i) return profile.Feast end,
							set = function(i, v) profile.Feast = v end,
						},
						toggleRepairBot = {
							type = "toggle",
							order = 2,
							width = "full",
							desc = "", 
							name = " Repair Bots  |TInterface\\Minimap\\Tracking\\Repair:18:18:-2:0"..cropped.."|t|TInterface\\Icons\\inv_pet_lilsmoky:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Misc_EngGizmos_14:16:16:0:0"..cropped.."|t |TInterface\\Icons\\inv_misc_molle:16:16:0:0"..cropped.."|t",
							get = function(i) return profile.RepairBot end,
							set = function(i, v) profile.RepairBot = v end,
						},
						toggleSeasonal = {
							type = "toggle",
							order = 3,
							width = "full",
							desc = "", 
							name = " Seasonal  |TInterface\\Icons\\INV_Misc_Herb_09:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Misc_Bag_28_Halloween:16:16:0:0"..cropped.."|t |TInterface\\Icons\\inv_misc_tabardsummer01:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_ValentinesCandy:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Egg_09:16:16:0:0"..cropped.."|t |TInterface\\Icons\\INV_Helmet_67:16:16:0:0"..cropped.."|t",
							get = function(i) return profile.Seasonal end,
							set = function(i, v) profile.Seasonal = v end,
						},
						header = {type = "header", order = 4, name = ""},
						toggleHeavyLeatherBall = {
							type = "toggle",
							order = 5,
							desc = function() return ScanTooltip("spell", 23135, 4) end,
							width = "full",
							name = "|TInterface\\Icons\\INV_Misc_ThrowingBall_01:16:16:1:0"..cropped.."|t |T"..select(3, GetSpellInfo(23065))..":16:16:1:0"..cropped.."|t |TInterface\\Icons\\inv_misc_toy_09:16:16:1:0"..cropped.."|t  "..GetSpellInfo(23135),
							get = function(i) return spell.HeavyLeatherBall end,
							set = function(i, v) spell.HeavyLeatherBall = v; spell_success[23135] = v; spell_success[23065] = v; spell_success[42383] = v; spell_success[45129] = v; spell_success[45133] = v end,
						},
						toggleFocusingLens = {
							type = "toggle",
							order = 6,
							desc = function() return ScanTooltip("spell", 56191, 4) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(56191))..":16:16:1:0"..cropped.."|t |T"..select(3, GetSpellInfo(56190))..":16:16:1:0"..cropped.."|t |T"..select(3, GetSpellInfo(55346))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(56191),
							get = function(i) return spell.FocusingLens end,
							set = function(i, v) spell.FocusingLens = v; spell_success[55346] = v; spell_success[56190] = v; spell_success[56191] = v end,
						},
						toggleToyTrainSet = {
							type = "toggle",
							order = 7,
							desc = function() return ScanTooltip("spell", 61031, 4) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(61031))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(61031),
							get = function(i) return spell[61031] end,
							set = function(i, v) spell[61031] = v; spell_create[61031] = v end,
						},
						toggleDirebrewRemote = {
							type = "toggle",
							order = 8,
							desc = function() return ScanTooltip("spell", 49844, 3) end,
							width = "full",
							name = "|TInterface\\Icons\\INV_Gizmo_GoblingTonkController:16:16:1:0"..cropped.."|t  "..GetSpellInfo(49844),
							get = function(i) return spell[49844] end,
							set = function(i, v) spell[49844] = v; spell_create[49844] = v end,
						},
						toggleBrewfestPonyKeg = {
							type = "toggle",
							order = 9,
							desc = function() return ScanTooltip("spell", 43808, 4) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(43808))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(43808),
							get = function(i) return spell[43808] end,
							set = function(i, v) spell[43808] = v; spell_create[43808] = v end,
						},
						toggleSandboxTiger = {
							type = "toggle",
							order = 10,
							desc = function() return ScanTooltip("spell", 62857, 4) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(62857))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(62857),
							get = function(i) return spell[62857] end,
							set = function(i, v) spell[62857] = v; spell_summon[62857] = v end,
						},
						toggleMohawkGrenade = {
							type = "toggle",
							order = 11,
							desc = function() return ScanTooltip("spell", 58493, 4) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(58493))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(58493),
							get = function(i) return spell[58493] end,
							set = function(i, v) spell[58493] = v; spell_start[58493] = v end,
						},
						toggleBabySpice = {
							type = "toggle",
							order = 12,
							desc = function() return ScanTooltip("spell", 60122, 4) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(60122))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(60122),
							get = function(i) return spell[60122] end,
							set = function(i, v) spell[60122] = v; spell_success[60122] = v end,
						},
						toggleSnowball = {
							type = "toggle",
							order = 13,
							desc = function() return GetSpellDescription(21343) end,
							width = "full",
							name = "|T"..select(3, GetSpellInfo(21343))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(21343),
							get = function(i) return spell[21343] end,
							set = function(i, v) spell[21343] = v; spell_success[21343] = v end,
						},
					},
				},
			},
		},
		Spell1 = {
			type = "group", order = 3,
			name = "Spell |cff71D5FF(1)|r|r",
			handler = KCL,
			args = {
				description = {
					type = "description",
					order = 1,
					fontSize = "medium",
					name = function() return "Output to |cffADFF2F[LibSink: Combat Text]|r recommended"..(SHOW_COMBAT_TEXT == "0" and "\n|cffFF0000Note:|r |cffADFF2F[Blizzard "..COMBAT_TEXT_LABEL.."]|r has to be enabled for it to show up in LibSink" or "") end,
					hidden = isCombatText,
				},
				enableSpell = {
					type = "toggle",
					order = 2,
					descStyle = "", 
					name = "|TInterface\\EncounterJournal\\UI-EJ-Icons:16:16:2:2:64:256:58:62:32:96|t|TInterface\\EncounterJournal\\UI-EJ-Icons:16:16:2:1:64:256:50:54:32:96|t  Toggle "..STAT_CATEGORY_SPELL,
					get = function(i) return profile.enableSpell end,
					set = function(i, v) profile.enableSpell = v end,
				},
				SpellChat = {
					type = "toggle",
					order = 3,
					descStyle = "", 
					name = "|TInterface\\AddOns\\Ketho_CombatLog\\Awesome:18:18:2:0|t  |cff2E9AFE"..CHAT.." "..CHAT_ANNOUNCE.."|r",
					get = function(i) return profile.SpellChat end,
					set = function(i, v) profile.SpellChat = v end,
				},
				SelfCast = {
					type = "toggle",
					order = 4,
					desc = "[Player][Slowfall]\n          -->\n[Player][Slowfall] on |cff71D5FF[Self]|r", 
					name = " |cff71D5FFSelf|r Cast (Verbose)",
					get = function(i) return profile.SelfCast end,
					set = function(i, v) profile.SelfCast = v end,
				},
				Filters = {
					type = "group",
					name = "|cffFFFFFF"..FILTERS.."|r",
					order = 5,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						SpellSelf = {
							type = "toggle",
							order = 1,
							descStyle = "", 
							name = " Yourself",
							get = function(i) return profile.SpellSelf end,
							set = function(i, v) profile.SpellSelf = v end,
						},
						SpellFriend = {
							type = "toggle",
							order = 2,
							descStyle = "", 
							name = " |cff57A3FF"..FRIENDLY.."|r",
							get = function(i) return profile.SpellFriend end,
							set = function(i, v) profile.SpellFriend = v end,
						},
						SpellEnemy = {
							type = "toggle",
							order = 3,
							descStyle = "", 
							name = " |cffBF0D0D"..HOSTILE.."|r",
							get = function(i) return profile.SpellEnemy end,
							set = function(i, v) profile.SpellEnemy = v end,
						},
					},
				},
				General = {
					type = "group",
					name = GENERAL_SPELLS,
					order = 6,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						BloodlustHeroism = {
							type = "toggle",
							order = 1,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", UnitFactionGroup("player") == "Alliance" and 32182 or 2825, isManaClass and 4 or 3) end,
							name = function()
								local id = UnitFactionGroup("player") == "Alliance" and 32182 or 2825
								return "|T"..select(3, GetSpellInfo(id))..":16:16:1:0"..cropped.."|t |T"..select(3, GetSpellInfo(80353))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(id).."|r / |cff69CCF0"..GetSpellInfo(80353).."|r"
							end,
							get = function(i) return spell.BloodlustHeroism end,
							set = function(i, v) spell.BloodlustHeroism = v; spell_successNT[2825] = v; spell_successNT[32182] = v; spell_successNT[80353] = v end,
						},
						TricksTrade = {
							type = "toggle",
							order = 4,
							desc = function() return ScanTooltip("spell", 57934, 4) end,
							name = "|T"..select(3, GetSpellInfo(57934))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(57934).."|r",
							get = function(i) return spell[57934] end,
							set = function(i, v) spell[57934] = v; spell_success[57934] = v end,
						},
						FocusMagic = {
							type = "toggle",
							order = 7,
							desc = function() return TalentDesc(25, "Arcane")..EJ_Desc(7)..ScanTooltip("spell", 54646, 4) end,
							name = "|T"..select(3, GetSpellInfo(54646))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(54646).."|r",
							get = function(i) return spell[54646] end,
							set = function(i, v) spell[54646] = v; spell_applied[54646] = v end,
						},
						DarkIntent = {
							type = "toggle",
							order = 10,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 80398, 4) end,
							name = "|T"..select(3, GetSpellInfo(80398))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(80398).."|r",
							get = function(i) return spell[80398] end,
							set = function(i, v) spell[80398] = v; spell_applied[80398] = v end,
						},
						Vigilance = {
							type = "toggle",
							order = 13,
							desc = function() return TalentDesc(20, "Protection")..ScanTooltip("spell", 50720, 4) end,
							name = "|T"..select(3, GetSpellInfo(50720))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(50720).."|r",
							get = function(i) return spell[50720] end,
							set = function(i, v) spell[50720] = v; spell_applied[50720] = v end,
						},
						Misdirection = {
							type = "toggle",
							order = 2,
							desc = function() return ScanTooltip("spell", 34477, 4) end,
							name = "|T"..select(3, GetSpellInfo(34477))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(34477).."|r",
							get = function(i) return spell[34477] end,
							set = function(i, v) spell[34477] = v; spell_success[34477] = v end,
						},
						UnholyFrenzy = {
							type = "toggle",
							order = 5,
							desc = function() return TalentDesc(10, "Unholy")..EJ_Desc(11)..ScanTooltip("spell", 49016, 4) end,
							name = "|T"..select(3, GetSpellInfo(49016))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49016).."|r",
							get = function(i) return spell[49016] end,
							set = function(i, v) spell[49016] = v; spell_applied[49016] = v end,
						},
						PowerInfusion = {
							type = "toggle",
							order = 8,
							desc = function() return TalentDesc(10, "Discipline")..EJ_Desc(7)..ScanTooltip("spell", 10060, 4) end,
							name = "|T"..select(3, GetSpellInfo(10060))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(10060),
							get = function(i) return spell[10060] end,
							set = function(i, v) spell[10060] = v; spell_applied[10060] = v end,
						},
						Innervate = {
							type = "toggle",
							order = 11,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 29166, 4) end,
							name = "|T"..select(3, GetSpellInfo(29166))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(29166).."|r",
							get = function(i) return spell[29166] end,
							set = function(i, v) spell[29166] = v; spell_applied[29166] = v end,
						},
						LeapFaith = {
							type = "toggle",
							order = 14,
							desc = function() return ScanTooltip("spell", 73325, 4) end,
							name = "|T"..select(3, GetSpellInfo(73325))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(73325),
							get = function(i) return spell[73325] end,
							set = function(i, v) spell[73325] = v; spell_success[73325] = v end,
						},
						GuardianSpirit = {
							type = "toggle",
							order = 3,
							desc = function() return TalentDesc(30, "Holy")..ScanTooltip("spell", 47788, 4) end,
							name = "|T"..select(3, GetSpellInfo(47788))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(47788),
							get = function(i) return spell[47788] end,
							set = function(i, v) spell[47788] = v; spell_applied[47788] = v end,
						},
						LayHands = {
							type = "toggle",
							order = 6,
							desc = function() return ScanTooltip("spell", 633, 4) end,
							name = "|T"..select(3, GetSpellInfo(633))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(633).."|r",
							get = function(i) return spell[633] end,
							set = function(i, v) spell[633] = v; spell_success[633] = v end,
						},
						PainSuppression = {
							type = "toggle",
							order = 9,
							desc = function() return TalentDesc(20, "Discipline")..ScanTooltip("spell", 33206, 4) end,
							name = "|T"..select(3, GetSpellInfo(33206))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(33206),
							get = function(i) return spell[33206] end,
							set = function(i, v) spell[33206] = v; spell_applied[33206] = v end,
						},
						HandProtection = {
							type = "toggle",
							order = 12,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1022, 4) end,
							name = "|T"..select(3, GetSpellInfo(1022))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(1022).."|r",
							get = function(i) return spell[1022] end,
							set = function(i, v) spell[1022] = v; spell_applied[1022] = v end,
						},
						SoulstoneResurrection = {
							type = "toggle",
							order = 15,
							desc = function() return ScanTooltip("spell", 20707, 4) end,
							name = "|T"..select(3, GetSpellInfo(20707))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(20707).."|r",
							get = function(i) return spell[20707] end,
							set = function(i, v) spell[20707] = v; spell_applied[20707] = v end,
						},
						spacing1 = {type = "description", order = 20, name = " "},
						Lightwell = {
							type = "toggle",
							order = 21,
							desc = function() return TalentDesc(10, "Holy")..ScanTooltip("spell", 724, 4) end,
							name = "|T"..select(3, GetSpellInfo(724))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(724),
							get = function(i) return spell[724] end,
							set = function(i, v) spell[724] = v; spell_summon[724] = v end,
						},
						RitualRefreshment = {
							type = "toggle",
							order = 24,
							desc = function() return ScanTooltip("spell", 43987, isManaClass and 5 or 4) end,
							name = "|T"..select(3, GetSpellInfo(43987))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(43987).."|r",
							get = function(i) return spell[43987] end,
							set = function(i, v) spell[43987] = v; spell_successNT[43987] = v end,
						},
						RitualSouls = {
							type = "toggle",
							order = 27,
							desc = function() return ScanTooltip("spell", 29893, isManaClass and 4 or 3) end,
							name = "|T"..select(3, GetSpellInfo(29893))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(29893).."|r",
							get = function(i) return spell[29893] end,
							set = function(i, v) spell[29893] = v; spell_successNT[29893] = v end,
						},
						RitualSummoning = {
							type = "toggle",
							order = 30,
							desc = function() return ScanTooltip("spell", 698, isManaClass and 4 or 3) end,
							name = "|T"..select(3, GetSpellInfo(698))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(698).."|r",
							get = function(i) return spell[698] end,
							set = function(i, v) spell[698] = v; spell_successNT[698] = v end,
						},
						DivineShield = {
							type = "toggle",
							order = 22,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 642, isManaClass and 4 or 3) end,
							name = "|T"..select(3, GetSpellInfo(642))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(642).."|r",
							get = function(i) return spell[642] end,
							set = function(i, v) spell[642] = v; spell_successNT[642] = v end,
						},
						IceBlock = {
							type = "toggle",
							order = 25,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 45438, 4) end,
							name = "|T"..select(3, GetSpellInfo(45438))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(45438).."|r",
							get = function(i) return spell[45438] end,
							set = function(i, v) spell[45438] = v; spell_successNT[45438] = v end,
						},
						Vanish = {
							type = "toggle",
							order = 28,
							desc = function() return ScanTooltip("spell", 1856, 3) end,
							name = "|T"..select(3, GetSpellInfo(1856))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(1856).."|r",
							get = function(i) return spell[1856] end,
							set = function(i, v) spell[1856] = v; spell_successNT[1856] = v end,
						},
						FeignDeath = {
							type = "toggle",
							order = 31,
							desc = function() return ScanTooltip("spell", 5384, 3) end,
							name = "|T"..select(3, GetSpellInfo(5384))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(5384).."|r",
							get = function(i) return spell[5384] end,
							set = function(i, v) spell[5384] = v; spell_successNT[5384] = v end,
						},
						Disarm = {
							type = "toggle",
							order = 23,
							desc = function() return ScanTooltip("spell", 676, 5) end,
							name = "|T"..select(3, GetSpellInfo(676))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(676).."|r",
							get = function(i) return spell[676] end,
							set = function(i, v) spell[676] = v; spell_applied[676] = v end,
						},
						Dismantle = {
							type = "toggle",
							order = 26,
							desc = function() return ScanTooltip("spell", 51722, 4) end,
							name = "|T"..select(3, GetSpellInfo(51722))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(51722).."|r",
							get = function(i) return spell[51722] end,
							set = function(i, v) spell[51722] = v; spell_applied[51722] = v end,
						},
						PsychicHorror = {
							type = "toggle",
							order = 29,
							desc = function() return TalentDesc(25, "Shadow")..EJ_Desc(7)..ScanTooltip("spell", 64044, 4) end,
							name = "|T"..select(3, GetSpellInfo(64044))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(64044),
							get = function(i) return spell[64058] end,
							set = function(i, v) spell[64058] = v; spell_applied[64058] = v end,
						},
						FearWard = {
							type = "toggle",
							order = 32,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 6346, 4) end,
							name = "|T"..select(3, GetSpellInfo(6346))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(6346),
							get = function(i) return spell[6346] end,
							set = function(i, v) spell[6346] = v; spell_applied[6346] = v end,
						},
						spacing2 = {type = "description", order = 40, name = " "},
						MindVision = {
							type = "toggle",
							order = 41,
							desc = function() return ScanTooltip("spell", 2096, 4) end,
							name = "|T"..select(3, GetSpellInfo(2096))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(2096),
							get = function(i) return spell[2096] end,
							set = function(i, v) spell[2096] = v; spell_success[2096] = v end,
						},
						FarSight = {
							type = "toggle",
							order = 44,
							desc = function() return ScanTooltip("spell", 6196, 4) end,
							name = "|T"..select(3, GetSpellInfo(6196))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(6196).."|r",
							get = function(i) return spell[6196] end,
							set = function(i, v) spell[6196] = v; spell_appliedNT[6196] = v end,
						},
						EagleEye = {
							type = "toggle",
							order = 47,
							desc = function() return ScanTooltip("spell", 6197, 4) end,
							name = "|T"..select(3, GetSpellInfo(6197))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(6197).."|r",
							get = function(i) return spell[6197] end,
							set = function(i, v) spell[6197] = v; spell_appliedNT[6197] = v end,
						},
						EyeKilrogg = {
							type = "toggle",
							order = 50,
							desc = function() return ScanTooltip("spell", 126, isManaClass and 4 or 3) end,
							name = "|T"..select(3, GetSpellInfo(126))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(126).."|r",
							get = function(i) return spell[126] end,
							set = function(i, v) spell[126] = v; spell_summon[126] = v end,
						},
						Stealth = {
							type = "toggle",
							order = 42,
							desc = function() return ScanTooltip("spell", 1784, 3) end,
							name = "|T"..select(3, GetSpellInfo(1784))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(1784).."|r",
							get = function(i) return spell[1784] end,
							set = function(i, v) spell[1784] = v; spell_appliedNT[1784] = v end,
						},
						Prowl = {
							type = "toggle",
							order = 45,
							desc = function() return ScanTooltip("spell", 5215, 4) end,
							name = "|T"..select(3, GetSpellInfo(5215))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(5215).."|r",
							get = function(i) return spell[5215] end,
							set = function(i, v) spell[5215] = v; spell_successNT[5215] = v end,
						},
						Levitate = {
							type = "toggle",
							order = 48,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1706, 5) end,
							name = "|T"..select(3, GetSpellInfo(1706))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(1706),
							get = function(i) return spell[1706] end,
							set = function(i, v) spell[1706] = v; spell_applied[1706] = v end,
						},
						SlowFall = {
							type = "toggle",
							order = 51,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 130, 5) end,
							name = "|T"..select(3, GetSpellInfo(130))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(130).."|r",
							get = function(i) return spell[130] end,
							set = function(i, v) spell[130] = v; spell_applied[130] = v end,
						},
						PathFrost = {
							type = "toggle",
							order = 43,
							desc = function() return ScanTooltip("spell", 3714, 4) end,
							name = "|T"..select(3, GetSpellInfo(3714))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(3714).."|r",
							get = function(i) return spell[3714] end,
							set = function(i, v) spell[3714] = v; spell_successNT[3714] = v end,
						},
						WaterWalking = {
							type = "toggle",
							order = 46,
							desc = function() return ScanTooltip("spell", 546, 5) end,
							name = "|T"..select(3, GetSpellInfo(546))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(546).."|r",
							get = function(i) return spell[546] end,
							set = function(i, v) spell[546] = v; spell_applied[546] = v end,
						},
						WaterBreathing = {
							type = "toggle",
							order = 49,
							desc = function() return ScanTooltip("spell", 131, 5) end,
							name = "|T"..select(3, GetSpellInfo(131))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(131).."|r",
							get = function(i) return spell[131] end,
							set = function(i, v) spell[131] = v; spell_applied[131] = v end,
						},
						UnendingBreath = {
							type = "toggle",
							order = 52,
							desc = function() return ScanTooltip("spell", 5697, 4) end,
							name = "|T"..select(3, GetSpellInfo(5697))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(5697).."|r",
							get = function(i) return spell[5697] end,
							set = function(i, v) spell[5697] = v; spell_applied[5697] = v end,
						},
					},
				},
				Class = {
					type = "group",
					name = CLASS,
					order = 7,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						HeroicLeap = {
							type = "toggle",
							order = 1,
							desc = function() return ScanTooltip("spell", 52174, 3) end,
							name = "|T"..select(3, GetSpellInfo(52174))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(52174).."|r",
							get = function(i) return spell[52174] end,
							set = function(i, v) spell[52174] = v; spell_successNT[52174] = v end,
						},
						RallyingCry = {
							type = "toggle",
							order = 4,
							desc = function() return ScanTooltip("spell", 97462, 3) end,
							name = "|T"..select(3, GetSpellInfo(97462))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(97462).."|r",
							get = function(i) return spell[97462] end,
							set = function(i, v) spell[97462] = v; spell_successNT[97462] = v end,
						},
						VictoryRush = {
							type = "toggle",
							order = 7,
							desc = function() return ScanTooltip("spell", 34428, 4) end,
							name = "|T"..select(3, GetSpellInfo(34428))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(34428).."|r",
							get = function(i) return spell[34428] end,
							set = function(i, v) spell[34428] = v; spell_success[34428] = v end,
						},
						BerserkerRage = {
							type = "toggle",
							order = 10,
							desc = function() return EJ_Desc(11)..ScanTooltip("spell", 18499, 3) end,
							name = "|T"..select(3, GetSpellInfo(18499))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(18499).."|r",
							get = function(i) return spell[18499] end,
							set = function(i, v) spell[18499] = v; spell_appliedNT[18499] = v end,
						},
						EnragedRegeneration = {
							type = "toggle",
							order = 13,
							desc = function() return ScanTooltip("spell", 55694, 4) end,
							name = "|T"..select(3, GetSpellInfo(55694))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(55694).."|r",
							get = function(i) return spell[55694] end,
							set = function(i, v) spell[55694] = v; spell_appliedNT[55694] = v end,
						},
						Retaliation = {
							type = "toggle",
							order = 16,
							desc = function() return ScanTooltip("spell", 20230, 3) end,
							name = "|T"..select(3, GetSpellInfo(20230))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(20230).."|r",
							get = function(i) return spell[20230] end,
							set = function(i, v) spell[20230] = v; spell_appliedNT[20230] = v end,
						},
						Recklessness = {
							type = "toggle",
							order = 19,
							desc = function() return ScanTooltip("spell", 1719, 3) end,
							name = "|T"..select(3, GetSpellInfo(1719))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(1719).."|r",
							get = function(i) return spell[1719] end,
							set = function(i, v) spell[1719] = v; spell_appliedNT[1719] = v end,
						},
						Intervene = {
							type = "toggle",
							order = 2,
							desc = function() return ScanTooltip("spell", 3411, 5) end,
							name = "|T"..select(3, GetSpellInfo(3411))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(3411).."|r",
							get = function(i) return spell[3411] end,
							set = function(i, v) spell[3411] = v; spell_success[3411] = v end,
						},
						SpellReflection = {
							type = "toggle",
							order = 5,
							desc = function() return ScanTooltip("spell", 23920, 6) end,
							name = "|T"..select(3, GetSpellInfo(23920))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(23920).."|r",
							get = function(i) return spell[23920] end,
							set = function(i, v) spell[23920] = v; spell_appliedNT[23920] = v end,
						},
						ShieldBlock = {
							type = "toggle",
							order = 8,
							desc = function() return ScanTooltip("spell", 2565, 6) end,
							name = "|T"..select(3, GetSpellInfo(2565))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(2565).."|r",
							get = function(i) return spell[2565] end,
							set = function(i, v) spell[2565] = v; spell_appliedNT[2565] = v end,
						},
						ShieldWall = {
							type = "toggle",
							order = 11,
							desc = function() return ScanTooltip("spell", 871, 4) end,
							name = "|T"..select(3, GetSpellInfo(871))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(871).."|r",
							get = function(i) return spell[871] end,
							set = function(i, v) spell[871] = v; spell_appliedNT[871] = v end,
						},
						SweepingStrikes = {
							type = "toggle",
							order = 14,
							desc = function() return TalentDesc(10, "Arms")..ScanTooltip("spell", 12328, 5) end,
							name = "|T"..select(3, GetSpellInfo(12328))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(12328).."|r",
							get = function(i) return spell[12328] end,
							set = function(i, v) spell[12328] = v; spell_appliedNT[12328] = v end,
						},
						DeadlyCalm = {
							type = "toggle",
							order = 17,
							desc = function() return TalentDesc(15, "Arms")..ScanTooltip("spell", 85730, 3) end,
							name = "|T"..select(3, GetSpellInfo(85730))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(85730).."|r",
							get = function(i) return spell[85730] end,
							set = function(i, v) spell[85730] = v; spell_appliedNT[85730] = v end,
						},
						Throwdown = {
							type = "toggle",
							order = 20,
							desc = function() return TalentDesc(25, "Arms")..ScanTooltip("spell", 85388, 6) end,
							name = "|T"..select(3, GetSpellInfo(85388))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(85388).."|r",
							get = function(i) return spell[85388] end,
							set = function(i, v) spell[85388] = v; spell_applied[85388] = v end,
						},
						Bladestorm = {
							type = "toggle",
							order = 3,
							desc = function() return TalentDesc(30, "Arms")..ScanTooltip("spell", 46924, 5) end,
							name = "|T"..select(3, GetSpellInfo(46924))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(46924).."|r",
							get = function(i) return spell[46924] end,
							set = function(i, v) spell[46924] = v; spell_appliedNT[46924] = v end,
						},
						DeathWish = {
							type = "toggle",
							order = 6,
							desc = function() return TalentDesc(10, "Fury")..EJ_Desc(11)..ScanTooltip("spell", 12292, 4) end,
							name = "|T"..select(3, GetSpellInfo(12292))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(12292).."|r",
							get = function(i) return spell[12292] end,
							set = function(i, v) spell[12292] = v; spell_appliedNT[12292] = v end,
						},
						HeroicFury = {
							type = "toggle",
							order = 9,
							desc = function() return TalentDesc(15, "Fury")..ScanTooltip("spell", 60970, 3) end,
							name = "|T"..select(3, GetSpellInfo(60970))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(60970).."|r",
							get = function(i) return spell[60970] end,
							set = function(i, v) spell[60970] = v; spell_appliedNT[60970] = v end,
						},
						LastStand = {
							type = "toggle",
							order = 12,
							desc = function() return TalentDesc(10, "Protection")..ScanTooltip("spell", 12975, 3) end,
							name = "|T"..select(3, GetSpellInfo(12975))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(12975).."|r",
							get = function(i) return spell[12975] end,
							set = function(i, v) spell[12975] = v; spell_successNT[12975] = v end,
						},
						ConcussionBlow = {
							type = "toggle",
							order = 15,
							desc = function() return TalentDesc(10, "Protection")..ScanTooltip("spell", 12809, 5) end,
							name = "|T"..select(3, GetSpellInfo(12809))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(12809).."|r",
							get = function(i) return spell[12809] end,
							set = function(i, v) spell[12809] = v; spell_applied[12809] = v end,
						},
						Shockwave = {
							type = "toggle",
							order = 18,
							desc = function() return TalentDesc(30, "Protection")..ScanTooltip("spell", 46968, 4) end,
							name = "|T"..select(3, GetSpellInfo(46968))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(46968).."|r",
							get = function(i) return spell[46968] end,
							set = function(i, v) spell[46968] = v; spell_successNT[46968] = v end,
						},
						spacing1 = {type = "description", order = 21, name = ""},
						DarkSimulacrum = {
							type = "toggle",
							order = 22,
							desc = function() return ScanTooltip("spell", 77606, 4) end,
							name = "|T"..select(3, GetSpellInfo(77606))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(77606).."|r",
							get = function(i) return spell[77606] end,
							set = function(i, v) spell[77606] = v; spell_appliedNT[77606] = v end,
						},
						ArmyDead = {
							type = "toggle",
							order = 25,
							desc = function() return ScanTooltip("spell", 42650, 4) end,
							name = "|T"..select(3, GetSpellInfo(42650))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(42650).."|r",
							get = function(i) return spell[42650] end,
							set = function(i, v) spell[42650] = v; spell_successNT[42650] = v end,
						},
						EmpowerRuneWeapon = {
							type = "toggle",
							order = 28,
							desc = function() return ScanTooltip("spell", 47568, 3) end,
							name = "|T"..select(3, GetSpellInfo(47568))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(47568).."|r",
							get = function(i) return spell[47568] end,
							set = function(i, v) spell[47568] = v; spell_successNT[47568] = v end,
						},
						DeathDecay = {
							type = "toggle",
							order = 31,
							desc = function() return SchoolDesc("SHADOW")..ScanTooltip("spell", 43265, 4) end,
							name = "|T"..select(3, GetSpellInfo(43265))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(43265).."|r",
							get = function(i) return spell[43265] end,
							set = function(i, v) spell[43265] = v; spell_successNT[43265] = v end,
						},
						Outbreak = {
							type = "toggle",
							order = 34,
							desc = function() return ScanTooltip("spell", 77575, 4) end,
							name = "|T"..select(3, GetSpellInfo(77575))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(77575).."|r",
							get = function(i) return spell[77575] end,
							set = function(i, v) spell[77575] = v; spell_success[77575] = v end,
						},
						DeathPact = {
							type = "toggle",
							order = 23,
							desc = function() return ScanTooltip("spell", 48743, 4) end,
							name = "|T"..select(3, GetSpellInfo(48743))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(48743).."|r",
							get = function(i) return spell[48743] end,
							set = function(i, v) spell[48743] = v; spell_successNT[48743] = v end,
						},
						AntiMagicShell = {
							type = "toggle",
							order = 26,
							desc = function() return ScanTooltip("spell", 48707, 3) end,
							name = "|T"..select(3, GetSpellInfo(48707))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(48707).."|r",
							get = function(i) return spell[48707] end,
							set = function(i, v) spell[48707] = v; spell_successNT[48707] = v end,
						},
						IceboundFortitude = {
							type = "toggle",
							order = 29,
							desc = function() return ScanTooltip("spell", 48792, 4) end,
							name = "|T"..select(3, GetSpellInfo(48792))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(48792).."|r",
							get = function(i) return spell[48792] end,
							set = function(i, v) spell[48792] = v; spell_appliedNT[48792] = v end,
						},
						BoneShield = {
							type = "toggle",
							order = 32,
							desc = function() return TalentDesc(10, "Blood")..ScanTooltip("spell", 49222, 4) end,
							name = "|T"..select(3, GetSpellInfo(49222))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49222).."|r",
							get = function(i) return spell[49222] end,
							set = function(i, v) spell[49222] = v; spell_appliedNT[49222] = v end,
						},
						VampiricBlood = {
							type = "toggle",
							order = 35,
							desc = function() return TalentDesc(20, "Blood")..ScanTooltip("spell", 55233, 3) end,
							name = "|T"..select(3, GetSpellInfo(55233))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(55233).."|r",
							get = function(i) return spell[55233] end,
							set = function(i, v) spell[55233] = v; spell_appliedNT[55233] = v end,
						},
						DancingRuneWeapon = {
							type = "toggle",
							order = 24,
							desc = function() return TalentDesc(30, "Blood")..ScanTooltip("spell", 49028, 5) end,
							name = "|T"..select(3, GetSpellInfo(49028))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49028).."|r",
							get = function(i) return spell[49028] end,
							set = function(i, v) spell[49028] = v; spell_successNT[49028] = v end,
						},
						Lichborne = {
							type = "toggle",
							order = 27,
							desc = function() return TalentDesc(5, "Frost")..ScanTooltip("spell", 49039, 3) end,
							name = "|T"..select(3, GetSpellInfo(49039))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49039).."|r",
							get = function(i) return spell[49039] end,
							set = function(i, v) spell[49039] = v; spell_appliedNT[49039] = v end,
						},
						PillarFrost = {
							type = "toggle",
							order = 30,
							desc = function() return TalentDesc(15, "Frost")..ScanTooltip("spell", 51271, 4) end,
							name = "|T"..select(3, GetSpellInfo(51271))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(51271).."|r",
							get = function(i) return spell[51271] end,
							set = function(i, v) spell[51271] = v; spell_appliedNT[51271] = v end,
						},
						AntiMagicZone = {
							type = "toggle",
							order = 33,
							desc = function() return TalentDesc(20, "Unholy")..ScanTooltip("spell", 51052, 4) end,
							name = "|T"..select(3, GetSpellInfo(51052))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(51052).."|r",
							get = function(i) return spell[51052] end,
							set = function(i, v) spell[51052] = v; spell_successNT[51052] = v end,
						},
						SummonGargoyle = {
							type = "toggle",
							order = 36,
							desc = function() return TalentDesc(30, "Unholy")..ScanTooltip("spell", 49206, 4) end,
							name = "|T"..select(3, GetSpellInfo(49206))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49206).."|r",
							get = function(i) return spell[49206] end,
							set = function(i, v) spell[49206] = v; spell_successNT[49206] = v end,
						},
						spacing2 = {type = "description", order = 40, name = ""},
						AvengingWrath = {
							type = "toggle",
							order = 41,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 31884, 4) end,
							name = "|T"..select(3, GetSpellInfo(31884))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(31884).."|r",
							get = function(i) return spell[31884] end,
							set = function(i, v) spell[31884] = v; spell_appliedNT[31884] = v end,
						},
						GuardianAncientKings = {
							type = "toggle",
							order = 44,
							desc = function() return ScanTooltip("spell", 86150, 3) end,
							name = "|T"..select(3, GetSpellInfo(86150))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(86150).."|r",
							get = function(i) return spell[86150] end,
							set = function(i, v) spell[86150] = v; spell_successNT[86150] = v end,
						},
						DivinePlea = {
							type = "toggle",
							order = 47,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 54428, 3) end,
							name = "|T"..select(3, GetSpellInfo(54428))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(54428).."|r",
							get = function(i) return spell[54428] end,
							set = function(i, v) spell[54428] = v; spell_appliedNT[54428] = v end,
						},
						HolyRadiance = {
							type = "toggle",
							order = 50,
							desc = function() return ScanTooltip("spell", 82327, 4) end,
							name = "|T"..select(3, GetSpellInfo(82327))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(82327).."|r",
							get = function(i) return spell[82327] end,
							set = function(i, v) spell[82327] = v; spell_successNT[82327] = v end,
						},
						DivineProtection = {
							type = "toggle",
							order = 53,
							desc = function() return ScanTooltip("spell", 498, 4) end,
							name = "|T"..select(3, GetSpellInfo(498))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(498).."|r",
							get = function(i) return spell[498] end,
							set = function(i, v) spell[498] = v; spell_appliedNT[498] = v end,
						},
						HandFreedom = {
							type = "toggle",
							order = 42,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1044, 4) end,
							name = "|T"..select(3, GetSpellInfo(1044))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(1044).."|r",
							get = function(i) return spell[1044] end,
							set = function(i, v) spell[1044] = v; spell_applied[1044] = v end,
						},
						HandSacrifice = {
							type = "toggle",
							order = 45,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 6940, 4) end,
							name = "|T"..select(3, GetSpellInfo(6940))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(6940).."|r",
							get = function(i) return spell[6940] end,
							set = function(i, v) spell[6940] = v; spell_applied[6940] = v end,
						},
						HandSalvation = {
							type = "toggle",
							order = 48,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1038, 4) end,
							name = "|T"..select(3, GetSpellInfo(1038))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(1038).."|r",
							get = function(i) return spell[1038] end,
							set = function(i, v) spell[1038] = v; spell_applied[1038] = v end,
						},
						DivineFavor = {
							type = "toggle",
							order = 51,
							desc = function() return TalentDesc(10, "Holy")..EJ_Desc(7)..ScanTooltip("spell", 31842, 3) end,
							name = "|T"..select(3, GetSpellInfo(31842))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(31842).."|r",
							get = function(i) return spell[31842] end,
							set = function(i, v) spell[31842] = v; spell_appliedNT[31842] = v end,
						},
						AuraMastery = {
							type = "toggle",
							order = 54,
							desc = function() return TalentDesc(20, "Holy")..ScanTooltip("spell", 31821, 3) end,
							name = "|T"..select(3, GetSpellInfo(31821))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(31821).."|r",
							get = function(i) return spell[31821] end,
							set = function(i, v) spell[31821] = v; spell_successNT[31821] = v end,
						},
						LightDawn = {
							type = "toggle",
							order = 43,
							desc = function() return TalentDesc(30, "Holy")..ScanTooltip("spell", 85222, 4) end,
							name = "|T"..select(3, GetSpellInfo(85222))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(85222).."|r",
							get = function(i) return spell[85222] end,
							set = function(i, v) spell[85222] = v; spell_successNT[85222] = v end,
						},
						HolyShield = {
							type = "toggle",
							order = 46,
							desc = function() return TalentDesc(20, "Protection")..EJ_Desc(7)..ScanTooltip("spell", 20925, 5) end,
							name = "|T"..select(3, GetSpellInfo(20925))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(20925).."|r",
							get = function(i) return spell[20925] end,
							set = function(i, v) spell[20925] = v; spell_appliedNT[20925] = v end,
						},
						DivineGuardian = {
							type = "toggle",
							order = 49,
							desc = function() return TalentDesc(20, "Protection")..ScanTooltip("spell", 70940, 3) end,
							name = "|T"..select(3, GetSpellInfo(70940))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(70940).."|r",
							get = function(i) return spell[70940] end,
							set = function(i, v) spell[70940] = v; spell_successNT[70940] = v end,
						},
						ArdentDefender = {
							type = "toggle",
							order = 52,
							desc = function() return TalentDesc(30, "Protection")..ScanTooltip("spell", 31850, 3) end,
							name = "|T"..select(3, GetSpellInfo(31850))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(31850).."|r",
							get = function(i) return spell[31850] end,
							set = function(i, v) spell[31850] = v; spell_appliedNT[31850] = v end,
						},
						Zealotry = {
							type = "toggle",
							order = 55,
							desc = function() return TalentDesc(30, "Retribution")..ScanTooltip("spell", 85696, 4) end,
							name = "|T"..select(3, GetSpellInfo(85696))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(85696).."|r",
							get = function(i) return spell[85696] end,
							set = function(i, v) spell[85696] = v; spell_appliedNT[85696] = v end,
						},
						spacing3 = {type = "description", order = 60, name = ""},
						RapidFire = {
							type = "toggle",
							order = 61,
							desc = function() return ScanTooltip("spell", 3045, 3) end,
							name = "|T"..select(3, GetSpellInfo(3045))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(3045).."|r",
							get = function(i) return spell[3045] end,
							set = function(i, v) spell[3045] = v; spell_appliedNT[3045] = v end,
						},
						IceTrap = {
							type = "toggle",
							order = 64,
							desc = function() return ScanTooltip("spell", 13809, 3) end,
							name = "|T"..select(3, GetSpellInfo(13809))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(13809).."|r",
							get = function(i) return spell[13809] end,
							set = function(i, v) spell[13809] = v; spell_successNT[13809] = v; spell_successNT[82941] = v end,
						},
						MasterCall = {
							type = "toggle",
							order = 67,
							desc = function() return ScanTooltip("spell", 53271, 4) end,
							name = "|T"..select(3, GetSpellInfo(53271))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(53271).."|r",
							get = function(i) return spell[53271] end,
							set = function(i, v) spell[53271] = v; spell_successNT[53271] = v end,
						},
						Deterrence = {
							type = "toggle",
							order = 70,
							desc = function() return ScanTooltip("spell", 19263, 3) end,
							name = "|T"..select(3, GetSpellInfo(19263))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(19263).."|r",
							get = function(i) return spell[19263] end,
							set = function(i, v) spell[19263] = v; spell_successNT[19263] = v end,
						},
						Disengage = {
							type = "toggle",
							order = 73,
							desc = function() return ScanTooltip("spell", 781, 3) end,
							name = "|T"..select(3, GetSpellInfo(781))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(781).."|r",
							get = function(i) return spell[781] end,
							set = function(i, v) spell[781] = v; spell_successNT[781] = v end,
						},
						Camouflage = {
							type = "toggle",
							order = 62,
							desc = function() return ScanTooltip("spell", 51753, 4) end,
							name = "|T"..select(3, GetSpellInfo(51753))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(51753).."|r",
							get = function(i) return spell[51753] end,
							set = function(i, v) spell[51753] = v; spell_successNT[51753] = v end,
						},
						Flare = {
							type = "toggle",
							order = 65,
							desc = function() return ScanTooltip("spell", 1543, 4) end,
							name = "|T"..select(3, GetSpellInfo(1543))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(1543).."|r",
							get = function(i) return spell[1543] end,
							set = function(i, v) spell[1543] = v; spell_successNT[1543] = v end,
						},
						TrackHumanoids = {
							type = "toggle",
							order = 68,
							desc = function() return ScanTooltip("spell", 19883, 3) end,
							name = "|T"..select(3, GetSpellInfo(19883))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(19883).."|r",
							get = function(i) return spell[19883] end,
							set = function(i, v) spell[19883] = v; spell_successNT[19883] = v end,
						},
						Intimidation = {
							type = "toggle",
							order = 71,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES["Beast Mastery"].." Specialization|r\n"..ScanTooltip("spell", 19577, 3) end,
							name = "|T"..select(3, GetSpellInfo(19577))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(19577).."|r",
							get = function(i) return spell[19577] end,
							set = function(i, v) spell[19577] = v; spell_successNT[19577] = v end,
						},
						Fervor = {
							type = "toggle",
							order = 63,
							desc = function() return TalentDesc(10, "Beast Mastery")..ScanTooltip("spell", 82726, 3) end,
							name = "|T"..select(3, GetSpellInfo(82726))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(82726).."|r",
							get = function(i) return spell[82726] end,
							set = function(i, v) spell[82726] = v; spell_successNT[82726] = v end,
						},
						BestialWrath = {
							type = "toggle",
							order = 66,
							desc = function() return TalentDesc(20, "Beast Mastery")..ScanTooltip("spell", 19574, 4) end,
							name = "|T"..select(3, GetSpellInfo(19574))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(19574).."|r",
							get = function(i) return spell[19574] end,
							set = function(i, v) spell[19574] = v; spell_applied[19574] = v end,
						},
						Readiness = {
							type = "toggle",
							order = 69,
							desc = function() return TalentDesc(20, "Marksmanship")..ScanTooltip("spell", 23989, 3) end,
							name = "|T"..select(3, GetSpellInfo(23989))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(23989).."|r",
							get = function(i) return spell[23989] end,
							set = function(i, v) spell[23989] = v; spell_successNT[23989] = v end,
						},
						BlackArrow = {
							type = "toggle",
							order = 72,
							desc = function() return TalentDesc(30, "Survival")..SchoolDesc("SHADOW")..EJ_Desc(7)..ScanTooltip("spell", 3674, 5) end,
							name = "|T"..select(3, GetSpellInfo(3674))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(3674).."|r",
							get = function(i) return spell[3674] end,
							set = function(i, v) spell[3674] = v; spell_applied[3674] = v end,
						},
						spacing4 = {type = "description", order = 80, name = ""},
						SpiritwalkerGrace = {
							type = "toggle",
							order = 81,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 79206, 4) end,
							name = "|T"..select(3, GetSpellInfo(79206))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(79206).."|r",
							get = function(i) return spell[79206] end,
							set = function(i, v) spell[79206] = v; spell_appliedNT[79206] = v end,
						},
						TremorTotem = {
							type = "toggle",
							order = 84,
							desc = function() return ScanTooltip("spell", 8143, 4) end,
							name = "|T"..select(3, GetSpellInfo(8143))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(8143).."|r",
							get = function(i) return spell[8143] end,
							set = function(i, v) spell[8143] = v; spell_summon[8143] = v end,
						},
						GroundingTotem = {
							type = "toggle",
							order = 87,
							desc = function() return ScanTooltip("spell", 8177, 4) end,
							name = "|T"..select(3, GetSpellInfo(8177))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(8177).."|r",
							get = function(i) return spell[8177] end,
							set = function(i, v) spell[8177] = v; spell_summon[8177] = v end,
						},
						FireElementalTotem = {
							type = "toggle",
							order = 90,
							desc = function() return ScanTooltip("spell", 2894, 4) end,
							name = "|T"..select(3, GetSpellInfo(2894))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(2894).."|r",
							get = function(i) return spell[2894] end,
							set = function(i, v) spell[2894] = v; spell_summon[2894] = v end,
						},
						EarthElementalTotem = {
							type = "toggle",
							order = 93,
							desc = function() return ScanTooltip("spell", 2062, 4) end,
							name = "|T"..select(3, GetSpellInfo(2062))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(2062).."|r",
							get = function(i) return spell[2062] end,
							set = function(i, v) spell[2062] = v; spell_summon[2062] = v end,
						},
						GhostWolf = {
							type = "toggle",
							order = 82,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 2645, 4) end,
							name = "|T"..select(3, GetSpellInfo(2645))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(2645).."|r",
							get = function(i) return spell[2645] end,
							set = function(i, v) spell[2645] = v; spell_appliedNT[2645] = v end,
						},
						Thunderstorm = {
							type = "toggle",
							order = 85,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Elemental.." Specialization|r\n"..SchoolDesc("NATURE")..ScanTooltip("spell", 51490, 3) end,
							name = "|T"..select(3, GetSpellInfo(51490))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(51490).."|r",
							get = function(i) return spell[51490] end,
							set = function(i, v) spell[51490] = v; spell_successNT[51490] = v end,
						},
						ElementalMastery = {
							type = "toggle",
							order = 88,
							desc = function() return TalentDesc(20, "Elemental")..EJ_Desc(7)..ScanTooltip("spell", 16166, 3) end,
							name = "|T"..select(3, GetSpellInfo(16166))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(16166).."|r",
							get = function(i) return spell[16166] end,
							set = function(i, v) spell[16166] = v; spell_appliedNT[16166] = v end,
						},
						ShamanisticRage = {
							type = "toggle",
							order = 91,
							desc = function() return TalentDesc(20, "Enhancement")..ScanTooltip("spell", 30823, 3) end,
							name = "|T"..select(3, GetSpellInfo(30823))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(30823).."|r",
							get = function(i) return spell[30823] end,
							set = function(i, v) spell[30823] = v; spell_appliedNT[30823] = v end,
						},
						FeralSpirit = {
							type = "toggle",
							order = 83,
							desc = function() return TalentDesc(30, "Enhancement")..ScanTooltip("spell", 51533, 4) end,
							name = "|T"..select(3, GetSpellInfo(51533))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(51533).."|r",
							get = function(i) return spell[51533] end,
							set = function(i, v) spell[51533] = v; spell_successNT[51533] = v end,
						},
						NatureSwiftness = {
							type = "toggle",
							order = 86,
							desc = function() return TalentDesc(10, "Restoration")..EJ_Desc(7)..ScanTooltip("spell", 16188, 3) end,
							name = "|T"..select(3, GetSpellInfo(16188))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(16188).."|r",
							get = function(i) return spell[16188] end,
							set = function(i, v) spell[16188] = v; spell_successNT[16188] = v end,
						},
						ManaTideTotem = {
							type = "toggle",
							order = 89,
							desc = function() return TalentDesc(20, "Restoration")..ScanTooltip("spell", 16190, 3) end,
							name = "|T"..select(3, GetSpellInfo(16190))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(16190).."|r",
							get = function(i) return spell[16190] end,
							set = function(i, v) spell[16190] = v; spell_summon[16190] = v end,
						},
						SpiritLinkTotem = {
							type = "toggle",
							order = 92,
							desc = function() return TalentDesc(20, "Restoration")..ScanTooltip("spell", 98008, 4) end,
							name = "|T"..select(3, GetSpellInfo(98008))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(98008).."|r",
							get = function(i) return spell[98008] end,
							set = function(i, v) spell[98008] = v; spell_summon[98008] = v end,
						},
						spacing5 = {type = "description", order = 100, name = ""},
						CloakShadows = {
							type = "toggle",
							order = 101,
							desc = function() return ScanTooltip("spell", 31224, 3) end,
							name = "|T"..select(3, GetSpellInfo(31224))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(31224).."|r",
							get = function(i) return spell[31224] end,
							set = function(i, v) spell[31224] = v; spell_appliedNT[31224] = v end,
						},
						Evasion = {
							type = "toggle",
							order = 104,
							desc = function() return ScanTooltip("spell", 5277, 3) end,
							name = "|T"..select(3, GetSpellInfo(5277))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(5277).."|r",
							get = function(i) return spell[5277] end,
							set = function(i, v) spell[5277] = v; spell_successNT[5277] = v end,
						},
						SmokeBomb = {
							type = "toggle",
							order = 107,
							desc = function() return ScanTooltip("spell", 76577, 3) end,
							name = "|T"..select(3, GetSpellInfo(76577))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(76577).."|r",
							get = function(i) return spell[76577] end,
							set = function(i, v) spell[76577] = v; spell_successNT[76577] = v end,
						},
						Sprint = {
							type = "toggle",
							order = 110,
							desc = function() return ScanTooltip("spell", 2983, 3) end,
							name = "|T"..select(3, GetSpellInfo(2983))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(2983).."|r",
							get = function(i) return spell[2983] end,
							set = function(i, v) spell[2983] = v; spell_successNT[2983] = v end,
						},
						Distract = {
							type = "toggle",
							order = 113,
							desc = function() return ScanTooltip("spell", 1725, 4) end,
							name = "|T"..select(3, GetSpellInfo(1725))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(1725).."|r",
							get = function(i) return spell[1725] end,
							set = function(i, v) spell[1725] = v; spell_successNT[1725] = v end,
						},
						ColdBlood = {
							type = "toggle",
							order = 102,
							desc = function() return TalentDesc(10, "Assassination")..ScanTooltip("spell", 14177, 3) end,
							name = "|T"..select(3, GetSpellInfo(14177))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(14177).."|r",
							get = function(i) return spell[14177] end,
							set = function(i, v) spell[14177] = v; spell_successNT[14177] = v end,
						},
						Vendetta = {
							type = "toggle",
							order = 105,
							desc = function() return TalentDesc(30, "Assassination")..ScanTooltip("spell", 79140, 4) end,
							name = "|T"..select(3, GetSpellInfo(79140))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(79140).."|r",
							get = function(i) return spell[79140] end,
							set = function(i, v) spell[79140] = v; spell_appliedNT[79140] = v end,
						},
						AdrenalineRush = {
							type = "toggle",
							order = 108,
							desc = function() return TalentDesc(20, "Combat")..ScanTooltip("spell", 13750, 3) end,
							name = "|T"..select(3, GetSpellInfo(13750))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(13750).."|r",
							get = function(i) return spell[13750] end,
							set = function(i, v) spell[13750] = v; spell_appliedNT[13750] = v end,
						},
						KillingSpree = {
							type = "toggle",
							order = 111,
							desc = function() return TalentDesc(30, "Combat")..ScanTooltip("spell", 51690, 5) end,
							name = "|T"..select(3, GetSpellInfo(51690))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(51690).."|r",
							get = function(i) return spell[51690] end,
							set = function(i, v) spell[51690] = v; spell_successNT[51690] = v end,
						},
						Shadowstep = {
							type = "toggle",
							order = 114,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Subtlety.." Specialization|r\n"..ScanTooltip("spell", 36554, 4) end,
							name = "|T"..select(3, GetSpellInfo(36554))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(36554).."|r",
							get = function(i) return spell[36554] end,
							set = function(i, v) spell[36554] = v; spell_successNT[36554] = v end,
						},
						Premeditation = {
							type = "toggle",
							order = 103,
							desc = function() return TalentDesc(15, "Subtlety")..ScanTooltip("spell", 14183, 5) end,
							name = "|T"..select(3, GetSpellInfo(14183))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(14183).."|r",
							get = function(i) return spell[14183] end,
							set = function(i, v) spell[14183] = v; spell_success[14183] = v end,
						},
						Preparation = {
							type = "toggle",
							order = 106,
							desc = function() return TalentDesc(20, "Subtlety")..ScanTooltip("spell", 14185, 3) end,
							name = "|T"..select(3, GetSpellInfo(14185))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(14185).."|r",
							get = function(i) return spell[14185] end,
							set = function(i, v) spell[14185] = v; spell_successNT[14185] = v end,
						},
						CheatDeath = {
							type = "toggle",
							order = 109,
							desc = function() return TalentDesc(20, "Subtlety")..ScanTooltip("spell", 45182, 3) end,
							name = "|T"..select(3, GetSpellInfo(45182))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(45182).."|r",
							get = function(i) return spell[45182] end,
							set = function(i, v) spell[45182] = v; spell_appliedNT[45182] = v end,
						},
						ShadowDance = {
							type = "toggle",
							order = 112,
							desc = function() return TalentDesc(30, "Subtlety")..ScanTooltip("spell", 51713, 3) end,
							name = "|T"..select(3, GetSpellInfo(51713))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(51713).."|r",
							get = function(i) return spell[51713] end,
							set = function(i, v) spell[51713] = v; spell_successNT[51713] = v end,
						},
						spacing6 = {type = "description", order = 120, name = ""},
						StampedingRoar = {
							type = "toggle",
							order = 121,
							desc = function() return ScanTooltip("spell", 77761, 4) end,
							name = "|T"..select(3, GetSpellInfo(77761))..":16:16:1:0"..cropped.."|t |T"..select(3, GetSpellInfo(77764))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(77761).."|r",
							get = function(i) return spell.StampedingRoar end,
							set = function(i, v) spell.StampedingRoar = v; spell_successNT[77761] = v; spell_successNT[77764] = v end,
						},
						WildMushroomDetonate = {
							type = "toggle",
							order = 124,
							desc = function() return SchoolDesc("NATURE")..ScanTooltip("spell", 88751, 4) end,
							name = "|T"..select(3, GetSpellInfo(88751))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(88751).."|r",
							get = function(i) return spell[88751] end,
							set = function(i, v) spell[88751] = v; spell_successNT[88751] = v end,
						},
						NatureGrasp = {
							type = "toggle",
							order = 127,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 16689, 3) end,
							name = "|T"..select(3, GetSpellInfo(16689))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(16689).."|r",
							get = function(i) return spell[16689] end,
							set = function(i, v) spell[16689] = v; spell_appliedNT[16689] = v end,
						},
						Tranquility = {
							type = "toggle",
							order = 130,
							desc = function() return ScanTooltip("spell", 740, 4) end,
							name = "|T"..select(3, GetSpellInfo(740))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(740).."|r",
							get = function(i) return spell[740] end,
							set = function(i, v) spell[740] = v; spell_successNT[740] = v end,
						},
						Thorns = {
							type = "toggle",
							order = 133,
							desc = function() return SchoolDesc("NATURE")..EJ_Desc(7)..ScanTooltip("spell", 467, 4) end,
							name = "|T"..select(3, GetSpellInfo(467))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(467).."|r",
							get = function(i) return spell[467] end,
							set = function(i, v) spell[467] = v; spell_appliedNT[467] = v end,
						},
						Barkskin = {
							type = "toggle",
							order = 136,
							desc = function() return ScanTooltip("spell", 22812, 3) end,
							name = "|T"..select(3, GetSpellInfo(22812))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(22812).."|r",
							get = function(i) return spell[22812] end,
							set = function(i, v) spell[22812] = v; spell_appliedNT[22812] = v end,
						},
						Dash = {
							type = "toggle",
							order = 122,
							desc = function() return ScanTooltip("spell", 1850, 3) end,
							name = "|T"..select(3, GetSpellInfo(1850))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(1850).."|r",
							get = function(i) return spell[1850] end,
							set = function(i, v) spell[1850] = v; spell_appliedNT[1850] = v end,
						},
						TigerFury = {
							type = "toggle",
							order = 125,
							desc = function() return ScanTooltip("spell", 5217, 4) end,
							name = "|T"..select(3, GetSpellInfo(5217))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(5217).."|r",
							get = function(i) return spell[5217] end,
							set = function(i, v) spell[5217] = v; spell_appliedNT[5217] = v end,
						},
						Bash = {
							type = "toggle",
							order = 128,
							desc = function() return ScanTooltip("spell", 5211, 5) end,
							name = "|T"..select(3, GetSpellInfo(5211))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(5211).."|r",
							get = function(i) return spell[5211] end,
							set = function(i, v) spell[5211] = v; spell_success[5211] = v end,
						},
						Enrage = {
							type = "toggle",
							order = 131,
							desc = function() return EJ_Desc(11)..ScanTooltip("spell", 5229, 4) end,
							name = "|T"..select(3, GetSpellInfo(5229))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(5229).."|r",
							get = function(i) return spell[5229] end,
							set = function(i, v) spell[5229] = v; spell_appliedNT[5229] = v end,
						},
						FrenziedRegeneration = {
							type = "toggle",
							order = 134,
							desc = function() return ScanTooltip("spell", 22842, 4) end,
							name = "|T"..select(3, GetSpellInfo(22842))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(22842).."|r",
							get = function(i) return spell[22842] end,
							set = function(i, v) spell[22842] = v; spell_appliedNT[22842] = v end,
						},
						Typhoon = {
							type = "toggle",
							order = 137,
							desc = function() return TalentDesc(10, "Balance")..SchoolDesc("NATURE")..ScanTooltip("spell", 50516, 4) end,
							name = "|T"..select(3, GetSpellInfo(50516))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(50516).."|r",
							get = function(i) return spell[50516] end,
							set = function(i, v) spell[50516] = v; spell_successNT[50516] = v end,
						},
						ForceNature = {
							type = "toggle",
							order = 123,
							desc = function() return TalentDesc(20, "Balance")..ScanTooltip("spell", 33831, 4) end,
							name = "|T"..select(3, GetSpellInfo(33831))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(33831).."|r",
							get = function(i) return spell[33831] end,
							set = function(i, v) spell[33831] = v; spell_successNT[33831] = v end,
						},
						Starfall = {
							type = "toggle",
							order = 126,
							desc = function() return TalentDesc(30, "Balance")..SchoolDesc("ARCANE")..ScanTooltip("spell", 48505, 4) end,
							name = "|T"..select(3, GetSpellInfo(48505))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(48505).."|r",
							get = function(i) return spell[48505] end,
							set = function(i, v) spell[48505] = v; spell_successNT[48505] = v end,
						},
						SurvivalInstincts = {
							type = "toggle",
							order = 129,
							desc = function() return TalentDesc(20, "Feral Combat")..ScanTooltip("spell", 61336, 3) end,
							name = "|T"..select(3, GetSpellInfo(61336))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(61336).."|r",
							get = function(i) return spell[61336] end,
							set = function(i, v) spell[61336] = v; spell_appliedNT[61336] = v end,
						},
						Berserk = {
							type = "toggle",
							order = 132,
							desc = function() return TalentDesc(30, "Feral Combat")..ScanTooltip("spell", 50334, 3) end,
							name = "|T"..select(3, GetSpellInfo(50334))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(50334).."|r",
							get = function(i) return spell[50334] end,
							set = function(i, v) spell[50334] = v; spell_successNT[50334] = v end,
						},
						TreeLife = {
							type = "toggle",
							order = 135,
							desc = function() return TalentDesc(30, "Restoration")..ScanTooltip("spell", 33891, 4) end,
							name = "|T"..select(3, GetSpellInfo(33891))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(33891).."|r",
							get = function(i) return spell[33891] end,
							set = function(i, v) spell[33891] = v; spell_appliedNT[33891] = v end,
						},
						spacing7 = {type = "description", order = 140, name = ""},
						MirrorImage = {
							type = "toggle",
							order = 141,
							desc = function() return ScanTooltip("spell", 55342, 4) end,
							name = "|T"..select(3, GetSpellInfo(55342))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(55342).."|r",
							get = function(i) return spell[55342] end,
							set = function(i, v) spell[55342] = v; spell_successNT[55342] = v end,
						},
						FlameOrb = {
							type = "toggle",
							order = 144,
							desc = function() return SchoolDesc("FIRE")..ScanTooltip("spell", 82731, 4) end,
							name = "|T"..select(3, GetSpellInfo(82731))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(82731).."|r",
							get = function(i) return spell[82731] end,
							set = function(i, v) spell[82731] = v; spell_successNT[82731] = v end,
						},
						RingFrost = {
							type = "toggle",
							order = 147,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 82676, 4) end,
							name = "|T"..select(3, GetSpellInfo(82676))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(82676).."|r",
							get = function(i) return spell[82676] end,
							set = function(i, v) spell[82676] = v; spell_summon[82676] = v end,
						},
						Invisibility = {
							type = "toggle",
							order = 150,
							desc = function() return ScanTooltip("spell", 66, 4) end,
							name = "|T"..select(3, GetSpellInfo(66))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(66).."|r",
							get = function(i) return spell[66] end,
							set = function(i, v) spell[66] = v; spell_successNT[66] = v end,
						},
						Evocation = {
							type = "toggle",
							order = 153,
							desc = function() return ScanTooltip("spell", 12051, 3) end,
							name = "|T"..select(3, GetSpellInfo(12051))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(12051).."|r",
							get = function(i) return spell[12051] end,
							set = function(i, v) spell[12051] = v; spell_successNT[12051] = v end,
						},
						MageWard = {
							type = "toggle",
							order = 156,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 543, 4) end,
							name = "|T"..select(3, GetSpellInfo(543))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(543).."|r",
							get = function(i) return spell[543] end,
							set = function(i, v) spell[543] = v; spell_successNT[543] = v end,
						},
						ManaShield = {
							type = "toggle",
							order = 142,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1463, 3) end,
							name = "|T"..select(3, GetSpellInfo(1463))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(1463).."|r",
							get = function(i) return spell[1463] end,
							set = function(i, v) spell[1463] = v; spell_appliedNT[1463] = v end,
						},
						Blink = {
							type = "toggle",
							order = 145,
							desc = function() return ScanTooltip("spell", 1953, 4) end,
							name = "|T"..select(3, GetSpellInfo(1953))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(1953).."|r",
							get = function(i) return spell[1953] end,
							set = function(i, v) spell[1953] = v; spell_successNT[1953] = v end,
						},
						PresenceMind = {
							type = "toggle",
							order = 148,
							desc = function() return TalentDesc(10, "Arcane")..EJ_Desc(7)..ScanTooltip("spell", 12043, 3) end,
							name = "|T"..select(3, GetSpellInfo(12043))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(12043).."|r",
							get = function(i) return spell[12043] end,
							set = function(i, v) spell[12043] = v; spell_successNT[12043] = v end,
						},
						ArcanePower = {
							type = "toggle",
							order = 151,
							desc = function() return TalentDesc(30, "Arcane")..EJ_Desc(7)..ScanTooltip("spell", 12042, 3) end,
							name = "|T"..select(3, GetSpellInfo(12042))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(12042).."|r",
							get = function(i) return spell[12042] end,
							set = function(i, v) spell[12042] = v; spell_appliedNT[12042] = v end,
						},
						Cauterize = {
							type = "toggle",
							order = 154,
							desc = function() return TalentDesc(10, "Fire")..ScanTooltip("spell", 87023, 3) end,
							name = "|T"..select(3, GetSpellInfo(87023))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(87023).."|r",
							get = function(i) return spell[87023] end,
							set = function(i, v) spell[87023] = v; spell_appliedNT[87023] = v end,
						},
						Combustion = {
							type = "toggle",
							order = 143,
							desc = function() return TalentDesc(15, "Fire")..SchoolDesc("FIRE")..ScanTooltip("spell", 11129, 4) end,
							name = "|T"..select(3, GetSpellInfo(11129))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(11129).."|r",
							get = function(i) return spell[11129] end,
							set = function(i, v) spell[11129] = v; spell_success[11129] = v end,
						},
						IcyVeins = {
							type = "toggle",
							order = 146,
							desc = function() return TalentDesc(10, "Frost")..ScanTooltip("spell", 12472, 4) end,
							name = "|T"..select(3, GetSpellInfo(12472))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(12472).."|r",
							get = function(i) return spell[12472] end,
							set = function(i, v) spell[12472] = v; spell_appliedNT[12472] = v end,
						},
						ColdSnap = {
							type = "toggle",
							order = 149,
							desc = function() return TalentDesc(15, "Frost")..EJ_Desc(7)..ScanTooltip("spell", 11958, 3) end,
							name = "|T"..select(3, GetSpellInfo(11958))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(11958).."|r",
							get = function(i) return spell[11958] end,
							set = function(i, v) spell[11958] = v; spell_successNT[11958] = v end,
						},
						IceBarrier = {
							type = "toggle",
							order = 152,
							desc = function() return TalentDesc(20, "Frost")..EJ_Desc(7)..ScanTooltip("spell", 11426, 4) end,
							name = "|T"..select(3, GetSpellInfo(11426))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(11426).."|r",
							get = function(i) return spell[11426] end,
							set = function(i, v) spell[11426] = v; spell_appliedNT[11426] = v end,
						},
						DeepFreeze = {
							type = "toggle",
							order = 155,
							desc = function() return TalentDesc(30, "Frost")..EJ_Desc(7)..SchoolDesc("FROST")..ScanTooltip("spell", 44572, 4) end,
							name = "|T"..select(3, GetSpellInfo(44572))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(44572).."|r",
							get = function(i) return spell[44572] end,
							set = function(i, v) spell[44572] = v; spell_success[44572] = v end,
						},
						spacing8 = {type = "description", order = 160, name = ""},
						DivineHymn = {
							type = "toggle",
							order = 161,
							desc = function() return ScanTooltip("spell", 64843, 4) end,
							name = "|T"..select(3, GetSpellInfo(64843))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(64843),
							get = function(i) return spell[64843] end,
							set = function(i, v) spell[64843] = v; spell_successNT[64843] = v end,
						},
						HymnHope = {
							type = "toggle",
							order = 164,
							desc = function() return ScanTooltip("spell", 64901, 4) end,
							name = "|T"..select(3, GetSpellInfo(64901))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(64901),
							get = function(i) return spell[64901] end,
							set = function(i, v) spell[64901] = v; spell_successNT[64901] = v end,
						},
						HolyWordSanctuary = {
							type = "toggle",
							order = 167,
							desc = function() return ScanTooltip("spell", 88685, 4) end,
							name = "|T"..select(3, GetSpellInfo(88685))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(88685),
							get = function(i) return spell[88685] end,
							set = function(i, v) spell[88685] = v; spell_start[88685] = v end,
						},
						Shadowfiend = {
							type = "toggle",
							order = 170,
							desc = function() return ScanTooltip("spell", 34433, 4) end,
							name = "|T"..select(3, GetSpellInfo(34433))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(34433),
							get = function(i) return spell[34433] end,
							set = function(i, v) spell[34433] = v; spell_summon[34433] = v end,
						},
						Fade = {
							type = "toggle",
							order = 173,
							desc = function() return ScanTooltip("spell", 586, 4) end,
							name = "|T"..select(3, GetSpellInfo(586))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(586),
							get = function(i) return spell[586] end,
							set = function(i, v) spell[586] = v; spell_appliedNT[586] = v end,
						},
						MindSoothe = {
							type = "toggle",
							order = 162,
							desc = function() return ScanTooltip("spell", 453, 4) end,
							name = "|T"..select(3, GetSpellInfo(453))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(453),
							get = function(i) return spell[453] end,
							set = function(i, v) spell[453] = v; spell_applied[453] = v end,
						},
						InnerFire = {
							type = "toggle",
							order = 165,
							desc = function() return ScanTooltip("spell", 588, 3) end,
							name = "|T"..select(3, GetSpellInfo(588))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(588),
							get = function(i) return spell[588] end,
							set = function(i, v) spell[588] = v; spell_appliedNT[588] = v end,
						},
						InnerWill = {
							type = "toggle",
							order = 168,
							desc = function() return ScanTooltip("spell", 73413, 3) end,
							name = "|T"..select(3, GetSpellInfo(73413))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(73413),
							get = function(i) return spell[73413] end,
							set = function(i, v) spell[73413] = v; spell_appliedNT[73413] = v end,
						},
						Archangel = {
							type = "toggle",
							order = 171,
							desc = function() return TalentDesc(5, "Discipline")..ScanTooltip("spell", 87151, 3) end,
							name = "|T"..select(3, GetSpellInfo(87151))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(87151),
							get = function(i) return spell[87151] end,
							set = function(i, v) spell[87151] = v; spell_successNT[87151] = v end,
						},
						InnerFocus = {
							type = "toggle",
							order = 174,
							desc = function() return TalentDesc(10, "Discipline")..EJ_Desc(7)..ScanTooltip("spell", 89485, 3) end,
							name = "|T"..select(3, GetSpellInfo(89485))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(89485),
							get = function(i) return spell[89485] end,
							set = function(i, v) spell[89485] = v; spell_successNT[89485] = v end,
						},
						PowerWordBarrier = {
							type = "toggle",
							order = 163,
							desc = function() return TalentDesc(30, "Discipline")..ScanTooltip("spell", 62618, 4) end,
							name = "|T"..select(3, GetSpellInfo(62618))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(62618),
							get = function(i) return spell[62618] end,
							set = function(i, v) spell[62618] = v; spell_successNT[62618] = v end,
						},
						DesperatePrayer = {
							type = "toggle",
							order = 166,
							desc = function() return TalentDesc(5, "Holy")..ScanTooltip("spell", 19236, 3) end,
							name = "|T"..select(3, GetSpellInfo(19236))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(19236),
							get = function(i) return spell[19236] end,
							set = function(i, v) spell[19236] = v; spell_successNT[19236] = v end,
						},
						SpiritRedemption = {
							type = "toggle",
							order = 169,
							desc = function() return TalentDesc(15, "Holy")..ScanTooltip("spell", 20711, 2) end,
							name = "|T"..select(3, GetSpellInfo(20711))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(20711),
							get = function(i) return spell[27827] end,
							set = function(i, v) spell[27827] = v; spell_appliedNT[27827] = v end,
						},
						Chakra = {
							type = "toggle",
							order = 172,
							desc = function() return TalentDesc(20, "Holy")..EJ_Desc(7)..ScanTooltip("spell", 14751, 3) end,
							name = "|T"..select(3, GetSpellInfo(14751))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(14751),
							get = function(i) return spell.Chakra end,
							set = function(i, v) spell.Chakra = v; spell_successNT[14751] = v; spell_appliedNT[81209] = v; spell_appliedNT[81206] = v; spell_appliedNT[81208] = v end,
						},
						Dispersion = {
							type = "toggle",
							order = 175,
							desc = function() return TalentDesc(30, "Shadow")..ScanTooltip("spell", 47585, 3) end,
							name = "|T"..select(3, GetSpellInfo(47585))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(47585),
							get = function(i) return spell[47585] end,
							set = function(i, v) spell[47585] = v; spell_appliedNT[47585] = v end,
						},
						spacing9 = {type = "description", order = 180, name = ""},
						Soulburn = {
							type = "toggle",
							order = 181,
							desc = function() return ScanTooltip("spell", 74434, 4) end,
							name = "|T"..select(3, GetSpellInfo(74434))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(74434).."|r",
							get = function(i) return spell[74434] end,
							set = function(i, v) spell[74434] = v; spell_successNT[74434] = v end,
						},
						SoulHarvest = {
							type = "toggle",
							order = 184,
							desc = function() return ScanTooltip("spell", 79268, 3) end,
							name = "|T"..select(3, GetSpellInfo(79268))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(79268).."|r",
							get = function(i) return spell[79268] end,
							set = function(i, v) spell[79268] = v; spell_appliedNT[79268] = v end,
						},
						Soulshatter = {
							type = "toggle",
							order = 187,
							desc = function() return ScanTooltip("spell", 29858, 4) end,
							name = "|T"..select(3, GetSpellInfo(29858))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(29858).."|r",
							get = function(i) return spell[29858] end,
							set = function(i, v) spell[29858] = v; spell_successNT[29858] = v end,
						},
						ShadowWard = {
							type = "toggle",
							order = 191,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 6229, 4) end,
							name = "|T"..select(3, GetSpellInfo(6229))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(6229).."|r",
							get = function(i) return spell.ShadowWard end,
							set = function(i, v) spell.ShadowWard = v; spell_appliedNT[6229] = v; spell_appliedNT[91711] = v end,
						},
						DemonSoul = {
							type = "toggle",
							order = 193,
							desc = function() return ScanTooltip("spell", 77801, 4) end,
							name = "|T"..select(3, GetSpellInfo(77801))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(77801).."|r",
							get = function(i) return spell[77801] end,
							set = function(i, v) spell[77801] = v; spell_successNT[77801] = v end,
						},
						EnslaveDemon = {
							type = "toggle",
							order = 196,
							desc = function() return ScanTooltip("spell", 1098, 4) end,
							name = "|T"..select(3, GetSpellInfo(1098))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(1098).."|r",
							get = function(i) return spell[1098] end,
							set = function(i, v) spell[1098] = v; spell_applied[1098] = v end,
						},
						SummonInfernal = {
							type = "toggle",
							order = 182,
							desc = function() return ScanTooltip("spell", 1122, 4) end,
							name = "|T"..select(3, GetSpellInfo(1122))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(1122).."|r",
							get = function(i) return spell[1122] end,
							set = function(i, v) spell[1122] = v; spell_summon[1122] = v end,
						},
						SummonDoomguard = {
							type = "toggle",
							order = 185,
							desc = function() return ScanTooltip("spell", 18540, 4) end,
							name = "|T"..select(3, GetSpellInfo(18540))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(18540).."|r",
							get = function(i) return spell[18540] end,
							set = function(i, v) spell[18540] = v; spell_summon[18540] = v end,
						},
						DemonicCircleSummon = {
							type = "toggle",
							order = 188,
							desc = function() return ScanTooltip("spell", 48018, 4) end,
							name = "|T"..select(3, GetSpellInfo(48018))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(48018).."|r",
							get = function(i) return spell[48018] end,
							set = function(i, v) spell[48018] = v; spell_appliedNT[48018] = v end,
						},
						DemonicCircleTeleport = {
							type = "toggle",
							order = 191,
							desc = function() return ScanTooltip("spell", 48020, 4) end,
							name = "|T"..select(3, GetSpellInfo(48020))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(48020).."|r",
							get = function(i) return spell[48020] end,
							set = function(i, v) spell[48020] = v; spell_successNT[48020] = v end,
						},
						SoulSwap = {
							type = "toggle",
							order = 194,
							desc = function() return TalentDesc(15, "Affliction")..SchoolDesc("SHADOW")..ScanTooltip("spell", 86121, 4) end,
							name = "|T"..select(3, GetSpellInfo(86121))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(86121).."|r",
							get = function(i) return spell.SoulSwap end,
							set = function(i, v) spell.SoulSwap = v; spell_success[86121] = v; spell_success[86213] = v end,
						},
						DemonicEmpowerment = {
							type = "toggle",
							order = 183,
							desc = function() return TalentDesc(15, "Demonology")..ScanTooltip("spell", 47193, 4) end,
							name = "|T"..select(3, GetSpellInfo(47193))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(47193).."|r",
							get = function(i) return spell[47193] end,
							set = function(i, v) spell[47193] = v; spell_successNT[47193] = v end,
						},
						HandGuldan = {
							type = "toggle",
							order = 186,
							desc = function() return TalentDesc(15, "Demonology")..ScanTooltip("spell", 71521, 4) end,
							name = "|T"..select(3, GetSpellInfo(71521))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(71521).."|r",
							get = function(i) return spell[71521] end,
							set = function(i, v) spell[71521] = v; spell_success[71521] = v end,
						},
						Metamorphosis = {
							type = "toggle",
							order = 189,
							desc = function() return TalentDesc(30, "Demonology")..ScanTooltip("spell", 47241, 3) end,
							name = "|T"..select(3, GetSpellInfo(47241))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(47241).."|r",
							get = function(i) return spell[47241] end,
							set = function(i, v) spell[47241] = v; spell_appliedNT[47241] = v end,
						},
						DemonLeap = {
							type = "toggle",
							order = 192,
							desc = function() return "|cff9482C9"..GetSpellInfo(47241).."|r\n"..ScanTooltip("spell", 54785, 4) end,
							name = "|T"..select(3, GetSpellInfo(54785))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(54785).."|r",
							get = function(i) return spell[54785] end,
							set = function(i, v) spell[54785] = v; spell_successNT[54785] = v end,
						},
						Shadowfury = {
							type = "toggle",
							order = 195,
							desc = function() return TalentDesc(20, "Destruction")..EJ_Desc(7)..ScanTooltip("spell", 30283, 4) end,
							name = "|T"..select(3, GetSpellInfo(30283))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(30283).."|r",
							get = function(i) return spell[30283] end,
							set = function(i, v) spell[30283] = v; spell_successNT[30283] = v end,
						},
					},
				},
			},
		},
		Spell2 = {
			type = "group", order = 4,
			name = "Spell |cff71D5FF(2)|r",
			handler = KCL,
			args = {
				CrowdControl = {
					type = "group",
					name = "|TInterface\\Icons\\Spell_Nature_Polymorph:14:14:1:0"..cropped.."|t  |cffFFFFFFCrowd Control|r",
					order = 1,
					inline = true,
					args = {
						FreezingTrap = {
							type = "toggle",
							order = 1,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 3355, 4) end,
							name = "|T"..select(3, GetSpellInfo(3355))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(3355).."|r",
							get = function(i) return spell[3355] end,
							set = function(i, v) spell[3355]  = v; CrowdControl[3355] = v end,
						},
						Polymorph = {
							type = "toggle",
							order = 4,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 118, 4) end,
							name = "|T"..select(3, GetSpellInfo(118))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(118).."|r",
							get = function(i) return spell[118] end,
							set = function(i, v) spell[118] = v; CrowdControl[118] = v; CrowdControl[28271] = v; CrowdControl[28272] = v; CrowdControl[61305] = v; CrowdControl[61721] = v; CrowdControl[61780] = v end,
						},
						Sap = {
							type = "toggle",
							order = 7,
							desc = function() return ScanTooltip("spell", 6770, 6) end,
							name = "|T"..select(3, GetSpellInfo(6770))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(6770).."|r",
							get = function(i) return spell[6770] end,
							set = function(i, v) spell[6770] = v; CrowdControl[6770] = v end,
						},
						Repentance = {
							type = "toggle",
							order = 10,
							desc = function() return TalentDesc(20, "Retribution")..EJ_Desc(7)..ScanTooltip("spell", 20066, 4) end,
							name = "|T"..select(3, GetSpellInfo(20066))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(20066).."|r",
							get = function(i) return spell[20066] end,
							set = function(i, v) spell[20066] = v; CrowdControl[20066] = v end,
						},
						Hex = {
							type = "toggle",
							order = 2,
							desc = function() return EJ_Desc(8)..ScanTooltip("spell", 51514, 4) end,
							name = "|T"..select(3, GetSpellInfo(51514))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(51514).."|r",
							get = function(i) return spell[51514] end,
							set = function(i, v) spell[51514] = v; CrowdControl[51514] = v end,
						},
						BindElemental = {
							type = "toggle",
							order = 5,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 76780, 4) end,
							name = "|T"..select(3, GetSpellInfo(76780))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(76780).."|r",
							get = function(i) return spell[76780] end,
							set = function(i, v) spell[76780] = v; CrowdControl[76780] = v end,
						},
						Banish = {
							type = "toggle",
							order = 8,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 710, 4) end,
							name = "|T"..select(3, GetSpellInfo(710))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(710).."|r",
							get = function(i) return spell[710] end,
							set = function(i, v) spell[710] = v; CrowdControl[710] = v end,
						},
						ShackleUndead = {
							type = "toggle",
							order = 11,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 9484, 4) end,
							name = "|T"..select(3, GetSpellInfo(9484))..":16:16:1:0"..cropped.."|t  |cffFFFFFF"..GetSpellInfo(9484).."|r",
							get = function(i) return spell[9484] end,
							set = function(i, v) spell[9484] = v; CrowdControl[9484] = v end,
						},
						Hibernate = {
							type = "toggle",
							order = 3,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 2637, 4) end,
							name = "|T"..select(3, GetSpellInfo(2637))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(2637).."|r",
							get = function(i) return spell[2637] end,
							set = function(i, v) spell[2637] = v; CrowdControl[2637] = v end,
						},
						ScareBeast = {
							type = "toggle",
							order = 6,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1513, 4) end,
							name = "|T"..select(3, GetSpellInfo(1513))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(1513).."|r",
							get = function(i) return spell[1513] end,
							set = function(i, v) spell[1513] = v; CrowdControl[1513] = v end,
						},
						TurnEvil = {
							type = "toggle",
							order = 9,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 10326, 4) end,
							name = "|T"..select(3, GetSpellInfo(10326))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(10326).."|r",
							get = function(i) return spell[10326] end,
							set = function(i, v) spell[10326] = v; CrowdControl[10326] = v end,
						},
						MindControl = {
							type = "toggle",
							order = 12,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 605, 4) end,
							name = "|T"..select(3, GetSpellInfo(605))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(605),
							get = function(i) return spell[605] end,
							set = function(i, v) spell[605] = v; spell_applied[605] = v end,
						},
						spacing1 = {type = "description", order = 20, name = " "},
						SeductionSuccubus = {
							type = "toggle",
							order = 21,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 6358, 4) end,
							name = "|T"..select(3, GetSpellInfo(6358))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(6358).."|r",
							get = function(i) return spell[6358] end,
							set = function(i, v) spell[6358] = v; CrowdControl[6358] = v end,
						},
						Fear = {
							type = "toggle",
							order = 24,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 5782, 4) end,
							name = "|T"..select(3, GetSpellInfo(5782))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(5782).."|r",
							get = function(i) return spell[5782] end,
							set = function(i, v) spell[5782] = v; CrowdControl[5782] = v end,
						},
						HowlTerror = {
							type = "toggle",
							order = 27,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 5484, 4) end,
							name = "|T"..select(3, GetSpellInfo(5484))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(5484).."|r",
							get = function(i) return spell[5484] end,
							set = function(i, v) spell[5484] = v; CrowdControl[5484] = v end,
						},
						PsychicScream = {
							type = "toggle",
							order = 30,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 8122, isManaClass and 4 or 3) end,
							name = "|T"..select(3, GetSpellInfo(8122))..":16:16:1:0"..cropped.."|t  |cffFFFFFF"..GetSpellInfo(8122).."|r",
							get = function(i) return spell[8122] end,
							set = function(i, v) spell[8122] = v; CrowdControl[8122] = v end,
						},
						IntimidatingShout = {
							type = "toggle",
							order = 33,
							desc = function() return ScanTooltip("spell", 5246, 4) end,
							name = "|T"..select(3, GetSpellInfo(5246))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(5246).."|r",
							get = function(i) return spell[5246] end,
							set = function(i, v) spell[5246] = v; CrowdControl[5246] = v end,
						},
						Blind = {
							type = "toggle",
							order = 22,
							desc = function() return ScanTooltip("spell", 2094, 4) end,
							name = "|T"..select(3, GetSpellInfo(2094))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(2094).."|r",
							get = function(i) return spell[2094] end,
							set = function(i, v) spell[2094] = v; CrowdControl[2094] = v end,
						},
						WyvernSting = {
							type = "toggle",
							order = 25,
							desc = function() return TalentDesc(20, "Survival")..EJ_Desc(9)..ScanTooltip("spell", 19386, 5) end,
							name = "|T"..select(3, GetSpellInfo(19386))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(19386).."|r",
							get = function(i) return spell[19386] end,
							set = function(i, v) spell[19386] = v; CrowdControl[19386] = v end,
						},
						ScatterShot = {
							type = "toggle",
							order = 28,
							desc = function() return ScanTooltip("spell", 19503, 5) end,
							name = "|T"..select(3, GetSpellInfo(19503))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(19503).."|r",
							get = function(i) return spell[19503] end,
							set = function(i, v) spell[19503] = v; CrowdControl[19503] = v end,
						},
						DeathCoil = {
							type = "toggle",
							order = 31,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 6789, 4) end,
							name = "|T"..select(3, GetSpellInfo(6789))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(6789).."|r",
							get = function(i) return spell[6789] end,
							set = function(i, v) spell[6789] = v; CrowdControl[6789] = v end,
						},
						Cyclone = {
							type = "toggle",
							order = 23,
							desc = function() return ScanTooltip("spell", 33786, 4) end,
							name = "|T"..select(3, GetSpellInfo(33786))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(33786).."|r",
							get = function(i) return spell[33786] end,
							set = function(i, v) spell[33786] = v; CrowdControl[33786] = v end,
						},
						EntanglingRoots = {
							type = "toggle",
							order = 26,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 339, 4) end,
							name = "|T"..select(3, GetSpellInfo(339))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(339).."|r",
							get = function(i) return spell[339] end,
							set = function(i, v) spell[339] = v; CrowdControl[339] = v end,
						},
						RingFrost = {
							type = "toggle",
							order = 29,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 82691, 3) end,
							name = "|T"..select(3, GetSpellInfo(82691))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(82691).."|r",
							get = function(i) return spell.RingFrostCC end,
							set = function(i, v) spell.RingFrostCC = v; CrowdControl[82691] = v end,
						},
						HungeringCold = {
							type = "toggle",
							order = 32,
							desc = function() return TalentDesc(20, "Frost")..EJ_Desc(7)..ScanTooltip("spell", 49203, 4) end,
							name = "|T"..select(3, GetSpellInfo(49203))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49203).."|r",
							get = function(i) return spell[49203] end,
							set = function(i, v) spell[49203] = v; CrowdControl[49203] = v end,
						},
						PrecastDesc = {
							type = "header",
							order = 34,
							name = "|cffFFFFFFPrecasting|r |TInterface\\EncounterJournal\\UI-EJ-Icons:12:12:0:1:64:256:42:46:32:96|t",
						},
						PrePolymorph = {
							type = "toggle",
							order = 35,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 118, 4) end,
							name = "|T"..select(3, GetSpellInfo(118))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(118).."|r",
							get = function(i) return spell.PrePolymorph end,
							set = function(i, v) spell.PrePolymorph = v; spell_precast[118] = v; spell_precast[28271] = v; spell_precast[28272] = v; spell_precast[61305] = v; spell_precast[61721] = v; spell_precast[61780] = v end,
							disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
						},
						PreHex = {
							type = "toggle",
							order = 38,
							desc = function() return EJ_Desc(8)..ScanTooltip("spell", 51514, 4) end,
							name = "|T"..select(3, GetSpellInfo(51514))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(51514).."|r",
							get = function(i) return spell.PreHex end,
							set = function(i, v) spell.PreHex = v; spell_precast[51514] = v end,
							disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
						},
						PreMindControl = {
							type = "toggle",
							order = 36,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 605, 4) end,
							name = "|T"..select(3, GetSpellInfo(605))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(605),
							get = function(i) return spell.PreMindControl end,
							set = function(i, v) spell.PreMindControl = v; spell_precast[605] = v end,
							disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
						},
						PreFear = {
							type = "toggle",
							order = 38,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 5782, 4) end,
							name = "|T"..select(3, GetSpellInfo(5782))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(5782).."|r",
							get = function(i) return spell.PreFear end,
							set = function(i, v) spell.PreFear = v; spell_precast[5782] = v end,
							disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
						},
						PreEntanglingRoots = {
							type = "toggle",
							order = 37,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 339, 4) end,
							name = "|T"..select(3, GetSpellInfo(339))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(339).."|r",
							get = function(i) return spell.PreEntanglingRoots end,
							set = function(i, v) spell.PreEntanglingRoots = v; spell_precast[339] = v end,
							disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
						},
						PreCyclone = {
							type = "toggle",
							order = 40,
							desc = function() return ScanTooltip("spell", 33786, 4) end,
							name = "|T"..select(3, GetSpellInfo(33786))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(33786).."|r",
							get = function(i) return spell.PreCyclone end,
							set = function(i, v) spell.PreCyclone = v; spell_precast[33786] = v end,
							disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
						},
					},
				},
				Silence = {
					type = "group",
					name = GetSpellInfo(15487),
					order = 2,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						Strangulate = {
							type = "toggle",
							order = 1,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 47476, 4) end,
							name = "|T"..select(3, GetSpellInfo(47476))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(47476).."|r",
							get = function(i) return spell[47476] end,
							set = function(i, v) spell[47476] = v; spell_applied[47476] = v end,
						},
						Garrote = {
							type = "toggle",
							order = 2,
							desc = function() return ScanTooltip("spell", 703, 5) end,
							name = "|T"..select(3, GetSpellInfo(703))..":16:16:1:0"..cropped.."|t  |cffFFF569"..GetSpellInfo(703).."|r",
							get = function(i) return spell[703] end,
							set = function(i, v) spell[703] = v; spell_success[703] = v end,
						},
						SilencingShot = {
							type = "toggle",
							order = 3,
							desc = function() return TalentDesc(10, "Marksmanship")..EJ_Desc(7)..ScanTooltip("spell", 34490, 5) end,
							name = "|T"..select(3, GetSpellInfo(34490))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(34490).."|r",
							get = function(i) return spell[34490] end,
							set = function(i, v) spell[34490] = v; spell_success[34490] = v end,
						},
						Silence = {
							type = "toggle",
							order = 4,
							desc = function() return TalentDesc(15, "Shadow")..EJ_Desc(7)..ScanTooltip("spell", 15487, 4) end,
							name = "|T"..select(3, GetSpellInfo(15487))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(15487),
							get = function(i) return spell[15487] end,
							set = function(i, v) spell[15487] = v; spell_success[15487] = v end,
						},
						SolarBeam = {
							type = "toggle",
							order = 5,
							desc = function() return TalentDesc(15, "Balance")..ScanTooltip("spell", 78675, 4) end,
							name = "|T"..select(3, GetSpellInfo(78675))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(78675).."|r",
							get = function(i) return spell[78675] end,
							set = function(i, v) spell[78675] = v; spell_successNT[78675] = v end,
						},
						AvengerShield = {
							type = "toggle",
							order = 6,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Protection.." Specialization|r\n"..EJ_Desc(7)..ScanTooltip("spell", 31935, 5) end,
							name = "|T"..select(3, GetSpellInfo(31935))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(31935).."|r",
							get = function(i) return spell[31935] end,
							set = function(i, v) spell[31935] = v; spell_success[31935] = v end,
						},
						SpellLock = {
							type = "toggle",
							order = 7,
							desc = function() return "|cffADFF2FFelhunter Pet|r\n"..EJ_Desc(7)..ScanTooltip("spell", 19647, 4) end,
							name = "|T"..select(3, GetSpellInfo(19647))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(19647).."|r",
							get = function(i) return spell[24259] end,
							set = function(i, v) spell[24259] = v; spell_applied[24259] = v end,
						},
					},
				},
				Racial = {
					type = "group",
					name = "Racials",
					order = 3,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						PvPTrinket = {
							type = "toggle",
							order = 1,
							desc = function() return ScanTooltip("spell", 42292, 3) end,
							name = "|T"..select(3, GetSpellInfo(42292))..":16:16:1:0"..cropped.."|t  |cff71D5FF"..GetSpellInfo(42292).."|r",
							get = function(i) return spell[42292] end,
							set = function(i, v) spell[42292] = v; spell_successNT[42292] = v end,
						},
						EveryManHimself = {
							type = "toggle",
							order = 4,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Human.."|r\n"..ScanTooltip("spell", 59752, 3) end,
							name = "|T"..select(3, GetSpellInfo(59752))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(59752),
							get = function(i) return spell[59752] end,
							set = function(i, v) spell[59752] = v; spell_successNT[59752] = v end,
						},
						WillForsaken = {
							type = "toggle",
							order = 7,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Undead.."|r\n"..ScanTooltip("spell", 7744, 3) end,
							name = "|T"..select(3, GetSpellInfo(7744))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(7744),
							get = function(i) return spell[7744] end,
							set = function(i, v) spell[7744] = v; spell_successNT[7744] = v end,
						},
						EscapeArtist = {
							type = "toggle",
							order = 10,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Gnome.."|r\n"..ScanTooltip("spell", 20589, 3) end,
							name = "|T"..select(3, GetSpellInfo(20589))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(20589),
							get = function(i) return spell[20589] end,
							set = function(i, v) spell[20589] = v; spell_successNT[20589] = v end,
						},
						Stoneform = {
							type = "toggle",
							order = 13,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Dwarf.."|r\n"..ScanTooltip("spell", 20594, 3) end,
							name = "|T"..select(3, GetSpellInfo(20594))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(20594),
							get = function(i) return spell[65116] end,
							set = function(i, v) spell[65116] = v; spell_appliedNT[65116] = v end,
						},
						Berserking = {
							type = "toggle",
							order = 2,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Troll.."|r\n"..ScanTooltip("spell", 26297, 3) end,
							name = "|T"..select(3, GetSpellInfo(26297))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(26297),
							get = function(i) return spell[26297] end,
							set = function(i, v) spell[26297] = v; spell_appliedNT[26297] = v end,
						},
						BloodFury = {
							type = "toggle",
							order = 5,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Orc.."|r\n"..ScanTooltip("spell", 20572, 3) end,
							name = "|T"..select(3, GetSpellInfo(20572))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(20572),
							get = function(i) return spell.BloodFury end,
							set = function(i, v) spell.BloodFury = v; spell_appliedNT[20572] = v; spell_successNT[33697] = v; spell_successNT[33702] = v end,
						},
						Cannibalize = {
							type = "toggle",
							order = 8,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Undead.."|r\n"..ScanTooltip("spell", 20577, 4) end,
							name = "|T"..select(3, GetSpellInfo(20577))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(20577),
							get = function(i) return spell[20577] end,
							set = function(i, v) spell[20577] = v; spell_successNT[20577] = v end,
						},
						WarStomp = {
							type = "toggle",
							order = 11,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Tauren.."|r\n"..ScanTooltip("spell", 20549, 3) end,
							name = "|T"..select(3, GetSpellInfo(20549))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(20549),
							get = function(i) return spell[20549] end,
							set = function(i, v) spell[20549] = v; spell_successNT[20549] = v end,
						},
						ArcaneTorrent = {
							type = "toggle",
							order = 14,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES["Blood Elf"].."|r\n"..ScanTooltip("spell", 28730, 3) end,
							name = "|T"..select(3, GetSpellInfo(28730))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(28730),
							get = function(i) return spell.ArcaneTorrent end,
							set = function(i, v) spell.ArcaneTorrent = v; spell_successNT[28730] = v; spell_successNT[69179] = v; spell_successNT[25046] = v; spell_successNT[80483] = v; spell_successNT[50613] = v end,
						},
						Shadowmeld = {
							type = "toggle",
							order = 3,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES["Night Elf"].."|r\n"..ScanTooltip("spell", 58984, 3) end,
							name = "|T"..select(3, GetSpellInfo(58984))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(58984),
							get = function(i) return spell[58984] end,
							set = function(i, v) spell[58984] = v; spell_successNT[58984] = v end,
						},
						Darkflight = {
							type = "toggle",
							order = 6,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Worgen.."|r\n"..ScanTooltip("spell", 68992, 3) end,
							name = "|T"..select(3, GetSpellInfo(68992))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(68992),
							get = function(i) return spell[68992] end,
							set = function(i, v) spell[68992] = v; spell_appliedNT[68992] = v end,
						},
						RocketJump = {
							type = "toggle",
							order = 9,
							desc = function() return "|cffADFF2F"..LOCALIZED_RACE_NAMES.Goblin.."|r\n"..ScanTooltip("spell", 69070, 3) end,
							name = "|T"..select(3, GetSpellInfo(69070))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(69070),
							get = function(i) return spell[69070] end,
							set = function(i, v) spell[69070] = v; spell_successNT[69070] = v end,
						},
					},
				},
				SpellAlert = {
					type = "group",
					name = "Spell Alert Procs",
					order = 4,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						Bloodsurge = {
							type = "toggle",
							order = 1,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Fury.."|r\n"..ScanTooltip("spell", 46915, 2) end,
							name = "|T"..select(3, GetSpellInfo(46915))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(46915).."|r",
							get = function(i) return spell[46916] end,
							set = function(i, v) spell[46916] = v; spell_appliedNT[46916] = v end,
						},
						SwordBoard = {
							type = "toggle",
							order = 4,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Protection.."|r\n"..ScanTooltip("spell", 46953, 2) end,
							name = "|T"..select(3, GetSpellInfo(46953))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(46953).."|r",
							get = function(i) return spell[50227] end,
							set = function(i, v) spell[50227] = v; spell_appliedNT[50227] = v end,
						},
						Rime = {
							type = "toggle",
							order = 7,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Frost.."|r\n"..ScanTooltip("spell", 59057, 2) end,
							name = "|T"..select(3, GetSpellInfo(59057))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(59057).." / "..GetSpellInfo(59052).."|r",
							get = function(i) return spell[59052] end,
							set = function(i, v) spell[59052] = v; spell_appliedNT[59052] = v end,
						},
						SuddenDoom = {
							type = "toggle",
							order = 10,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Unholy.."|r\n"..EJ_Desc(7)..ScanTooltip("spell", 49530, 2) end,
							name = "|T"..select(3, GetSpellInfo(49530))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(49530).."|r",
							get = function(i) return spell[81340] end,
							set = function(i, v) spell[81340] = v; spell_appliedNT[81340] = v end,
						},
						GrandCrusader = {
							type = "toggle",
							order = 13,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Protection.."|r\n"..ScanTooltip("spell", 85043, 2) end,
							name = "|T"..select(3, GetSpellInfo(85043))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(85043).."|r",
							get = function(i) return spell[85416] end,
							set = function(i, v) spell[85416] = v; spell_appliedNT[85416] = v end,
						},
						ArtWar = {
							type = "toggle",
							order = 16,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Retribution.."|r\n"..ScanTooltip("spell", 87138, 2) end,
							name = "|T"..select(3, GetSpellInfo(87138))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(87138).."|r",
							get = function(i) return spell[59578] end,
							set = function(i, v) spell[59578] = v; spell_appliedNT[59578] = v end,
						},
						FocusFire = {
							type = "toggle",
							order = 2,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES["Beast Mastery"].."|r\n"..ScanTooltip("spell", 82692, 3) end,
							name = "|T"..select(3, GetSpellInfo(82692))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(82692).."|r",
							get = function(i) return spell[82692] end,
							set = function(i, v) spell[82692] = v; spell_appliedNT[82692] = v end,
						},
						MasterMarksman = {
							type = "toggle",
							order = 5,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Marksmanship.."|r\n"..ScanTooltip("spell", 34487, 2) end,
							name = "|T"..select(3, GetSpellInfo(34487))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(34487).." / "..GetSpellInfo(82925).."|r",
							get = function(i) return spell[82925] end,
							set = function(i, v) spell[82925] = v; spell_appliedNT[82925] = v end,
						},
						LockLoad = {
							type = "toggle",
							order = 8,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Survival.."|r\n"..ScanTooltip("spell", 56343, 2) end,
							name = "|T"..select(3, GetSpellInfo(56343))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(56343).."|r",
							get = function(i) return spell[56453] end,
							set = function(i, v) spell[56453] = v; spell_appliedNT[56453] = v end,
						},
						NatureGrace = {
							type = "toggle",
							order = 11,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Balance.."|r\n"..EJ_Desc(7)..ScanTooltip("spell", 61346, 2) end,
							name = "|T"..select(3, GetSpellInfo(61346))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(61346).."|r",
							get = function(i) return spell[16886] end,
							set = function(i, v) spell[16886] = v; spell_appliedNT[16886] = v end,
						},
						SurgeLight = {
							type = "toggle",
							order = 14,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Holy.."|r\n"..ScanTooltip("spell", 88690, 2) end,
							name = "|T"..select(3, GetSpellInfo(88690))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(88690),
							get = function(i) return spell[88688] end,
							set = function(i, v) spell[88688] = v; spell_appliedNT[88688] = v end,
						},
						HotStreak = {
							type = "toggle",
							order = 3,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Fire.."|r\n"..EJ_Desc(7)..ScanTooltip("spell", 48108, 3) end,
							name = "|T"..select(3, GetSpellInfo(48108))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(48108).."|r",
							get = function(i) return spell[48108] end,
							set = function(i, v) spell[48108] = v; spell_appliedNT[48108] = v end,
						},
						FingersFrost = {
							type = "toggle",
							order = 6,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Frost.."|r\n"..ScanTooltip("spell", 83074, 2) end,
							name = "|T"..select(3, GetSpellInfo(83074))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(83074).."|r",
							get = function(i) return spell[44544] end,
							set = function(i, v) spell[44544] = v; spell_appliedNT[44544] = v end,
						},
						BrainFreeze = {
							type = "toggle",
							order = 9,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Frost.."|r\n"..EJ_Desc(7)..ScanTooltip("spell", 44549, 2) end,
							name = "|T"..select(3, GetSpellInfo(44549))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(44549).."|r",
							get = function(i) return spell[57761] end,
							set = function(i, v) spell[57761] = v; spell_appliedNT[57761] = v end,
						},
						Nightfall = {
							type = "toggle",
							order = 12,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Affliction.."|r\n"..EJ_Desc(7)..ScanTooltip("spell", 18095, 2) end,
							name = "|T"..select(3, GetSpellInfo(18095))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(18095).." / "..GetSpellInfo(17941).."|r",
							get = function(i) return spell[17941] end,
							set = function(i, v) spell[17941] = v; spell_appliedNT[17941] = v end,
						},
						EmpoweredImp = {
							type = "toggle",
							order = 15,
							desc = function() return "|cffADFF2F"..LOCALIZED_TALENT_NAMES.Destruction.."|r\n"..EJ_Desc(7)..ScanTooltip("spell", 47221, 2) end,
							name = "|T"..select(3, GetSpellInfo(47221))..":16:16:1:0"..cropped.."|t  |cff9482C9"..GetSpellInfo(47221).."|r",
							get = function(i) return spell[47283] end,
							set = function(i, v) spell[47283] = v; spell_appliedNT[47283] = v end,
						},
					},
				},
				Buff = {
					type = "group",
					name = "Buffs",
					order = 5,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						PowerWordFortitude = {
							type = "toggle",
							order = 1,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 21562, 4) end,
							name = "|T"..select(3, GetSpellInfo(21562))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(21562),
							get = function(i) return spell[21562] end,
							set = function(i, v) spell[21562] = v; spell_success[21562] = v end,
						},
						ShadowProtection = {
							type = "toggle",
							order = 4,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 27683, 4) end,
							name = "|T"..select(3, GetSpellInfo(27683))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(27683).."|r",
							get = function(i) return spell[27683] end,
							set = function(i, v) spell[27683] = v; spell_success[27683] = v end,
						},
						ArcaneBrilliance = {
							type = "toggle",
							order = 7,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1459, 4) end,
							name = "|T"..select(3, GetSpellInfo(1459))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(1459).."|r",
							get = function(i) return spell.ArcaneBrilliance end,
							set = function(i, v) spell.ArcaneBrilliance = v; spell_success[1459] = v; spell_success[61316] = v end,
						},
						MarkWild = {
							type = "toggle",
							order = 2,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 1126, 4) end,
							name = "|T"..select(3, GetSpellInfo(1126))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(1126).."|r",
							get = function(i) return spell[1126] end,
							set = function(i, v) spell[1126] = v; spell_success[1126] = v end,
						},
						BlessingKings = {
							type = "toggle",
							order = 5,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 20217, 4) end,
							name = "|T"..select(3, GetSpellInfo(20217))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(20217).."|r",
							get = function(i) return spell[20217] end,
							set = function(i, v) spell[20217] = v; spell_success[20217] = v end,
						},
						BlessingMight = {
							type = "toggle",
							order = 8,
							desc = function() return EJ_Desc(7)..ScanTooltip("spell", 19740, 4) end,
							name = "|T"..select(3, GetSpellInfo(19740))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(19740).."|r",
							get = function(i) return spell[19740] end,
							set = function(i, v) spell[19740] = v; spell_success[19740] = v end,
						},
						BattleShout = {
							type = "toggle",
							order = 3,
							desc = function() return ScanTooltip("spell", 6673, 3) end,
							name = "|T"..select(3, GetSpellInfo(6673))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(6673).."|r",
							get = function(i) return spell[6673] end,
							set = function(i, v) spell[6673] = v; spell_successNT[6673] = v end,
						},
						CommandingShout = {
							type = "toggle",
							order = 6,
							desc = function() return ScanTooltip("spell", 469, 3) end,
							name = "|T"..select(3, GetSpellInfo(469))..":16:16:1:0"..cropped.."|t  |cffC79C6E"..GetSpellInfo(469).."|r",
							get = function(i) return spell[469] end,
							set = function(i, v) spell[469] = v; spell_successNT[469] = v end,
						},
						HornWinter = {
							type = "toggle",
							order = 9,
							desc = function() return ScanTooltip("spell", 57330, 3) end,
							name = "|T"..select(3, GetSpellInfo(57330))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(57330).."|r",
							get = function(i) return spell[57330] end,
							set = function(i, v) spell[57330] = v; spell_successNT[57330] = v end,
						},
					},
				},
				Aura = {
					type = "group",
					name = AURAS,
					order = 6,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						DevotionAura = {
							type = "toggle",
							order = 1,
							desc = function() return ScanTooltip("spell", 465, 3) end,
							name = "|T"..select(3, GetSpellInfo(465))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(465).."|r",
							get = function(i) return spell[465] end,
							set = function(i, v) spell[465] = v; spell_successNT[465] = v end,
						},
						RetributionAura = {
							type = "toggle",
							order = 4,
							desc = function() return ScanTooltip("spell", 7294, 3) end,
							name = "|T"..select(3, GetSpellInfo(7294))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(7294).."|r",
							get = function(i) return spell[7294] end,
							set = function(i, v) spell[7294] = v; spell_successNT[7294] = v end,
						},
						ConcentrationAura = {
							type = "toggle",
							order = 7,
							desc = function() return ScanTooltip("spell", 19746, 3) end,
							name = "|T"..select(3, GetSpellInfo(19746))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(19746).."|r",
							get = function(i) return spell[19746] end,
							set = function(i, v) spell[19746] = v; spell_successNT[19746] = v end,
						},
						ResistanceAura = {
							type = "toggle",
							order = 2,
							desc = function() return ScanTooltip("spell", 19891, 3) end,
							name = "|T"..select(3, GetSpellInfo(19891))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(19891).."|r",
							get = function(i) return spell[19891] end,
							set = function(i, v) spell[19891] = v; spell_successNT[19891] = v end,
						},
						CrusaderAura = {
							type = "toggle",
							order = 5,
							desc = function() return ScanTooltip("spell", 32223, 3) end,
							name = "|T"..select(3, GetSpellInfo(32223))..":16:16:1:0"..cropped.."|t  |cffF58CBA"..GetSpellInfo(32223).."|r",
							get = function(i) return spell[32223] end,
							set = function(i, v) spell[32223] = v; spell_successNT[32223] = v end,
						},
						AspectPack = {
							type = "toggle",
							order = 3,
							desc = function() return ScanTooltip("spell", 13159, 3) end,
							name = "|T"..select(3, GetSpellInfo(13159))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(13159).."|r",
							get = function(i) return spell[13159] end,
							set = function(i, v) spell[13159] = v; spell_successNT[13159] = v end,
						},
						AspectWild = {
							type = "toggle",
							order = 6,
							desc = function() return ScanTooltip("spell", 20043, 3) end,
							name = "|T"..select(3, GetSpellInfo(20043))..":16:16:1:0"..cropped.."|t  |cffABD473"..GetSpellInfo(20043).."|r",
							get = function(i) return spell[20043] end,
							set = function(i, v) spell[20043] = v; spell_successNT[20043] = v end,
						},
					},
				},
				Teleport = {
					type = "group",
					name = "Teleports",
					order = 7,
					inline = true,
					disabled = function() return not profile.enableSpell or not KCL:IsEnabled() end,
					args = {
						PortalStormwind = {
							type = "toggle",
							order = 1,
							desc = function() return ScanTooltip("spell", 10059, 5) end,
							name = "|T"..select(3, GetSpellInfo(10059))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(10059).."|r",
							get = function(i) return spell[10059] end,
							set = function(i, v) spell[10059] = v; spell_create[10059] = v end,
						},
						PortalOrgrimmar = {
							type = "toggle",
							order = 4,
							desc = function() return ScanTooltip("spell", 11417, 5) end,
							name = "|T"..select(3, GetSpellInfo(11417))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(11417).."|r",
							get = function(i) return spell[11417] end,
							set = function(i, v) spell[11417] = v; spell_create[11417] = v end,
						},
						PortalTolBarad = {
							type = "toggle",
							order = 7,
							desc = function() return ScanTooltip("spell", 88345, 5) end,
							name = "|T"..select(3, GetSpellInfo(88345))..":16:16:1:0"..cropped.."|t  |cff69CCF0"..GetSpellInfo(88345).."|r",
							get = function(i) return spell.PortalTolBarad end,
							set = function(i, v) spell.PortalTolBarad = v; spell_create[88345] = v; spell_create[88346] = v end,
						},
						Hearthstone = {
							type = "toggle",
							order = 2,
							desc = function() return ScanTooltip("spell", 8690, 3) end,
							name = "|T"..select(3, GetSpellInfo(8690))..":16:16:1:0"..cropped.."|t  "..GetSpellInfo(8690),
							get = function(i) return spell[8690] end,
							set = function(i, v) spell[8690] = v; spell_start[8690] = v end,
						},
						AstralRecall = {
							type = "toggle",
							order = 5,
							desc = function() return ScanTooltip("spell", 556, 4) end,
							name = "|T"..select(3, GetSpellInfo(556))..":16:16:1:0"..cropped.."|t  |cff0070DE"..GetSpellInfo(556).."|r",
							get = function(i) return spell[556] end,
							set = function(i, v) spell[556] = v; spell_start[556] = v end,
						},
						DeathGate = {
							type = "toggle",
							order = 3,
							desc = function() return ScanTooltip("spell", 50977, 4) end,
							name = "|T"..select(3, GetSpellInfo(50977))..":16:16:1:0"..cropped.."|t  |cffC41F3B"..GetSpellInfo(50977).."|r",
							get = function(i) return spell[50977] end,
							set = function(i, v) spell[50977] = v; spell_create[50977] = v end,
						},
						TeleportMoonglade = {
							type = "toggle",
							order = 6,
							desc = function() return ScanTooltip("spell", 18960, 4) end,
							name = "|T"..select(3, GetSpellInfo(18960))..":16:16:1:0"..cropped.."|t  |cffFF7D0A"..GetSpellInfo(18960).."|r",
							get = function(i) return spell[18960] end,
							set = function(i, v) spell[18960] = v; spell_start[18960] = v end,
						},
					},
				},
			},
		},
		--[[
		libsink = {
			type = "group", order = 5,
			name = "LibSink",
			args = {
				blaat = {
					type = "group",
					name = "",
					inline = true,
					args = {},
				},
			},
		},
		]]
	},
}

	-------------------------------
	---- OnInitialize, OnEnable ---
	-------------------------------

local slashCmds = {"kcl", "ket", "ketho", "kethocombat", "kethocombatlog"}

function KCL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("KethoCombatLogDB", defaults, true)

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	self:RefreshConfig()
	
	self.db.global.version = VERSION
	self.db.global.build = BUILD
	
	options.args.libsink = self:GetSinkAce3OptionsDataTable()
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	
	ACR:RegisterOptionsTable("KethoCombatLog_Parent", options)
	ACR:RegisterOptionsTable("KethoCombatLog_Main", options.args.Main)
	ACR:RegisterOptionsTable("KethoCombatLog_Advanced", options.args.Advanced)
	ACR:RegisterOptionsTable("KethoCombatLog_Spell", options.args.Spell1)
	ACR:RegisterOptionsTable("KethoCombatLog_SpellExtra", options.args.Spell2)
	ACR:RegisterOptionsTable("KethoCombatLog_LibSink", options.args.libsink)
	ACR:RegisterOptionsTable("KethoCombatLog_Profiles", options.args.profiles)
	
	options.args.libsink.order = 5
	options.args.libsink.name = "LibSink" -- overwrite "Output"
	options.args.profiles.order = 6
	
	ACD:AddToBlizOptions("KethoCombatLog_Parent", NAME2)
	ACD:AddToBlizOptions("KethoCombatLog_Main", "|TInterface\\AddOns\\Ketho_CombatLog\\Awesome:16:16:2:0|t  Main", NAME2)
	ACD:AddToBlizOptions("KethoCombatLog_Advanced", "|TInterface\\Icons\\Trade_Engineering:16:16:1:0"..cropped.."|t  "..ADVANCED, NAME2)
	ACD:AddToBlizOptions("KethoCombatLog_Spell", "|TInterface\\EncounterJournal\\UI-EJ-Icons:16:16:2:0:64:256:58:62:32:96|t  "..STAT_CATEGORY_SPELL.." (1)", NAME2)
	ACD:AddToBlizOptions("KethoCombatLog_SpellExtra", "|TInterface\\EncounterJournal\\UI-EJ-Icons:16:16:2:0:64:256:50:54:32:96|t  "..STAT_CATEGORY_SPELL.." (2)", NAME2)
	ACD:AddToBlizOptions("KethoCombatLog_LibSink", "|TINTERFACE\\ICONS\\inv_scroll_03:16:16:1:0"..cropped.."|t  LibSink", NAME2)
	ACD:AddToBlizOptions("KethoCombatLog_Profiles", "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:0"..cropped.."|t  "..options.args.profiles.name, NAME2)
	
	ACD:SetDefaultSize("KethoCombatLog_Parent", 700, 600)
	
	for _, v in ipairs(slashCmds) do
		self:RegisterChatCommand(v, "SlashCommand")
	end
end

local instanceType, instanceTypeFilter
local chatType, channel

function KCL:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ADDON_LOADED") -- Check for Blizzard CombatLog

	self:ScheduleRepeatingTimer(function()
		-- zone based, instead of group based "detection"
		instanceType = select(2, IsInInstance())

		if profile.chatChannel == 2 then
			chatType = "SAY"
		elseif profile.chatChannel == 3 then
			chatType = "YELL"
		elseif profile.chatChannel == 4 then
			-- don't want to spam to BATTLEGROUND, if people really want to announce to there, they can still use LibSink
			chatType = (instanceType == "raid" and GetNumRaidMembers() > 0) and "RAID" or ((instanceType == "party" or instanceType == "arena") and GetNumPartyMembers() > 0) and "PARTY"
		else
			chatType, channel = "CHANNEL", profile.chatChannel-4
		end

		if (profile.PvE and (instanceType == "party" or instanceType == "raid")) or
		(profile.PvP and (instanceType == "pvp" or instanceType == "arena")) or
		(profile.World and instanceType == "none") then
			instanceTypeFilter = true
		else
			instanceTypeFilter = false
		end
	end, 3)
end

	--------------------------
	--- Callback Functions ---
	--------------------------

function KCL:RefreshConfig()
	-- table reference lookup shortcuts
	profile, char = self.db.profile, self.db.char
	color, spell = profile.color, profile.spell

	spell_success = profile.spell.success or {}
	spell_successNT = profile.spell.successNT or {}
	spell_applied = profile.spell.applied or {}
	spell_appliedNT = profile.spell.appliedNT or {}
	spell_start = profile.spell.start or {}
	spell_precast = profile.spell.precast or {}
	spell_summon = profile.spell.summon or {}

	-- LibSink
	self:SetSinkStorage(profile)

	-- optimize for CLEU
	iconSize = profile.iconSize

	-- other
	cropped = profile.iconCropped and ":64:64:4:60:4:60" or ""
	if profile.chatWindow > 1 then
		ChatFrame = _G["ChatFrame"..profile.chatWindow-1]
	end

	-- colors
	UnitColor = {
		self:Dec2Hex(unpack(color.Friendly)),
		self:Dec2Hex(unpack(color.Hostile)),
		self:Dec2Hex(unpack(color.Unknown)),
	}
	
	ClassColor = {
		["DEATHKNIGHT"] = self:Dec2Hex(unpack(color.DeathKnight)),
		["DRUID"] = self:Dec2Hex(unpack(color.Druid)),
		["HUNTER"] = self:Dec2Hex(unpack(color.Hunter)),
		["MAGE"] = self:Dec2Hex(unpack(color.Mage)),
		["PALADIN"] = self:Dec2Hex(unpack(color.Paladin)),
		["PRIEST"] = self:Dec2Hex(unpack(color.Priest)),
		["ROGUE"] = self:Dec2Hex(unpack(color.Rogue)),
		["SHAMAN"] = self:Dec2Hex(unpack(color.Shaman)),
		["WARLOCK"] = self:Dec2Hex(unpack(color.Warlock)),
		["WARRIOR"] = self:Dec2Hex(unpack(color.Warrior)),
	}

	SpellSchoolColor = {
		[0x1] = self:Dec2Hex(unpack(color.Physical)),
		[0x2] = self:Dec2Hex(unpack(color.Holy)),
		[0x4] = self:Dec2Hex(unpack(color.Fire)),
		[0x8] = self:Dec2Hex(unpack(color.Nature)),
		[0x10] = self:Dec2Hex(unpack(color.Frost)),
		[0x20] = self:Dec2Hex(unpack(color.Shadow)),
		[0x40] = self:Dec2Hex(unpack(color.Arcane)),
	}

	EventColor = {
		["TAUNT"] = self:Dec2Hex(unpack(color.Taunt)),
		["INTERRUPT"] = self:Dec2Hex(unpack(color.Interrupt)),
		["DISPEL"] = self:Dec2Hex(unpack(color.Dispel)),
		["REFLECT"] = self:Dec2Hex(unpack(color.Reflect)),
		["CROWDCONTROL"] = self:Dec2Hex(unpack(color.CrowdControl)),
		["CC_BREAK"] = self:Dec2Hex(unpack(color.CC_Break)),
		["DEATH"] = self:Dec2Hex(unpack(color.Death)),
		["RESURRECTION"] = self:Dec2Hex(unpack(color.Resurrection)),
	}

	-- Wowhead I love you!
	spell_success = {
		[633] = spell[633], -- Lay on Hands (Holy)
		[703] = spell[703], -- Garrote (Assassination)
		[1044] = spell[1044], -- Hand of Freedom
		[1126] = spell[1126], -- Mark of the Wild (Restoration)
		[2096] = spell[2096], -- Mind Vision
		[3411] = spell[3411], -- Intervene (Protection)
		[5211] = spell[5211], -- Bash (Feral)
		[11129] = spell[11129], -- Combustion (Fire, Talent)
		[14177] = spell[14177], -- Cold Blood (Assassination, Talent)
		[14183] = spell[14183], -- Preparation (Subtlety, Talent)
		[15487] = spell[15487], -- Silence (Shadow, Talent)
		[19574] = spell[19574], -- Bestial Wrath (Beast Mastery)
		[19740] = spell[19740], -- Blessing of Might (Retribution)
		[20217] = spell[20217], -- Blessing of Kings (Protection)
		[21562] = spell[21562], -- Power Word: Fortitude (Discipline)
		[27683] = spell[27683], -- Shadow Protection (Shadow)
		[31935] = spell[31935], -- Avenger's Shield (Protection, Specialization)
		[34428] = spell[34428], -- Victory Rush (Fury)
		[34490] = spell[34490], -- Silencing Shot (Marksmanship)
		[34477] = spell[34477], -- Misdirection
		[36554] = spell[36554], -- Shadowstep (Subtlety, Specialization)
		[44572] = spell[44572], -- Deep Freeze (Frost, Talent)
		[47476] = spell[47476], -- Strangulate (Blood)
		[57934] = spell[57934], -- Tricks of the Trade
		[73325] = spell[73325], -- Leap of Faith
		[71521] = spell[71521], -- Hand of Gul'dan (Demonology, Talent)
		[77575] = spell[77575], -- Outbreak (Unholy)
		[82731] = spell[82731], -- Flame Orb (Fire)
		[86121] = spell.SoulSwap, -- Soul Swap (Affliction, Talent)
		[86213] = spell.SoulSwap, -- Soul Swap Exhale (Affliction, Talent)
	-- Fun, technically also falls under Spell
		[1459] = spell.ArcaneBrilliance, -- Arcane Brilliance (Arcane)
		[61316] = spell.ArcaneBrilliance, -- Dalaran Brilliance (Arcane)
		[23135] = spell.HeavyLeatherBall, -- Heavy Leather Ball
		[23065] = spell.HeavyLeatherBall, -- Happy spell Rock
		[42383] = spell.HeavyLeatherBall, -- Voodoo Skull
		[45129] = spell.HeavyLeatherBall, -- Paper Zeppelin
		[45133] = spell.HeavyLeatherBall, -- Paper Flying Machine
	}

	spell_successNT = {
		[66] = spell[66], -- Invisibility
		[465] = spell[465], -- Devotion Aura (Protection)
		[469] = spell[469], -- Commanding Shout (Fury)
		[642] = spell[642], -- Divine Shield
		[698] = spell[698], -- Ritual of Summoning
		[740] = spell[740], -- Tranquility
		[781] = spell[781], -- Disengage
		[1543] = spell[1543], -- Flare (Marksmanship)
		[1725] = spell[1725], -- Distract
		[1856] = spell[1856], -- Vanish
		[1953] = spell[1953], -- Blink (Arcane)
		[2983] = spell[2983], -- Sprint
		[3714] = spell[3714], -- Path of Frost
		[5277] = spell[5277], -- Evasion
		[5384] = spell[5384], -- Feign Death
		[6673] = spell[6673], -- Battle Shout (Fury)
		[7294] = spell[7294], -- Retribution Aura (Retribution)
		[7744] = spell[7744], -- Will of the Forsaken (Undead, Racial)
		[11958] = spell[11958], -- Cold Snap (Frost, Talent)
		[12043] = spell[12043], -- Presence of Mind (Arcane, Talent)
		[12975] = spell[12975], -- Last Stand (Protection, Talent)
		[13809] = spell[13809], -- Ice Trap (Survival)
		[14185] = spell[14185], -- Preparation (Subtlety, Talent)
		[16188] = spell[16188], -- Nature's Swiftness (Restoration)
		[19236] = spell[19236], -- Desperate Prayer (Holy, Talent)
		[19263] = spell[19263], -- Deterrence (Survival)
		[19746] = spell[19746], -- Concentration Aura (Holy
		[19883] = spell[19883], -- Track Humanoids (Survival)
		[19891] = spell[19891], -- Resistance Aura (Protection)
		[19577] = spell[19577], -- Intimidation (Beast Mastery, Specialization)
		[20043] = spell[20043], -- Aspect of the Wild (Beast Mastery)
		[20549] = spell[20549], -- War Stomp (Tauren, Racial)
		[20577] = spell[20577], -- Cannibalize (Undead, Racial)
		[20589] = spell[20589], -- Escape Artist (Gnome, Racial)
		[23989] = spell[23989], -- Readiness (Marksmanship, Talent)
		[29858] = spell[29858], -- Soulshatter (Demonology)
		[29893] = spell[29893], -- Ritual of Souls (Demonology)
		[30283] = spell[30283], -- Shadowfury (Destruction, Talent)
		[31821] = spell[31821], -- Divine Favor (Holy, Talent)
		[32223] = spell[32223], -- Crusader Aura (Retribution)
		[33831] = spell[33831], -- Force of Nature (Balance, Talent)
		[42292] = spell[42292], -- PvP Trinket
		[42650] = spell[42650], -- Army of the Dead (Unholy)
		[43265] = spell[43265], -- Death and Decay (Unholy)
		[43987] = spell[43987], -- Ritual of Refreshment (Arcane)
		[45438] = spell[45438], -- Ice Block (Frost)
		[46968] = spell[46968], -- Shockwave (Protection)
		[47193] = spell[47193], -- Demonic Empowerment (Demonology, Talent)
		[47568] = spell[47568], -- Empower Rune Weapon (Frost)
		[48020] = spell[48020], -- Demonic Circle: Teleport
		[48505] = spell[48505], -- Starfall (Balance, Ultimate)
		[48707] = spell[48707], -- Anti-Magic Shell (Unholy)
		[48743] = spell[48743], -- Death Pact (Blood)
		[49028] = spell[49028], -- Dancing Rune Weapon (Blood)
		[49206] = spell[49206], -- Summon Gargoyle (Unholy)
		[50334] = spell[50334], -- Berserk (Feral, Talent, Ultimate)
		[50516] = spell[50516], -- Typhoon (Balance, Talent)
		[51052] = spell[51052], -- Anti-Magic Zone (Unholy)
		[51490] = spell[51490], -- Thunderstorm (Elemental, Specialization)
		[51533] = spell[51533], -- Feral Spirit (Enhancement)
		[51690] = spell[51690], -- Killing Spree (Combat, Ultimate)
		[51713] = spell[51713], -- Shadow Dance (Subtlety, Ultimate)
		[52174] = spell[52174], -- Heroic Leap (Fury)
		[53271] = spell[53271], -- Master's Call (Beast Mastery)
		[54785] = spell[54785], -- Demon Leap (Demonology, Metamorphosis)
		[55342] = spell[55342], -- Mirror Image (Arcane)
		[57330] = spell[57330], -- Horn of Winter (Frost)
		[58984] = spell[58984], -- Shadowmeld (Night Elf, Racial)
		[59752] = spell[59752], -- Every Man for Himself (Human, Racial)
		[62618] = spell[62618], -- Power Word: Barrier (Discipline, Talent, Ultimate)
		[64843] = spell[64843], -- Divine Hymn (Holy)
		[64901] = spell[64901], -- Hymn of Hope (Holy)
		[69070] = spell[69070], -- Rocket Jump (Goblin, Racial)
		[70940] = spell[70940], -- Divine Guardian (Protection, Talent)
		[74434] = spell[74434], -- Soulburn (Demonology)
		[76577] = spell[76577], -- Smoke Bomb (Subtlety)
		[77801] = spell[77801], -- Demon Soul (Demonology)
		[78675] = spell[78675], -- Solar Beam (Balance, Talent)
		[82327] = spell[82327], -- Holy Radiance (Holy)
		[82726] = spell[82726], -- Fervor (Beast Mastery, Talent)
		[82941] = spell[82941], -- Trap Launcher - Ice Trap (Survival)
		[85222] = spell[85222], -- Light of Dawn (Holy, Talent, Ultimate)
		[87151] = spell[87151], -- Archangel (Discipline)
		[88751] = spell[88751], -- Wild Mushroom: Detonate (Balance)
		[89485] = spell[89485], -- Inner Focus (Discipline, Talent)
		[97462] = spell[97462], -- Rallying Cry (Fury)
		[14751] = spell.Chakra, -- Chakra (Holy, Talent)
		[77761] = spell.StampedingRoar, -- Stampeding Roar (Bear Form)
		[77764] = spell.StampedingRoar, -- Stampeding Roar (Cat Form)
		[2825] = spell.BloodlustHeroism, -- Bloodlust
		[32182] = spell.BloodlustHeroism, -- Heroism
		[80353] = spell.BloodlustHeroism, -- Time Warp
		[25046] = spell.ArcaneTorrent, -- Blood Elf, Racial, Rogue
		[28730] = spell.ArcaneTorrent, -- Blood Elf, Racial, Mana Classes
		[50613] = spell.ArcaneTorrent, -- Blood Elf, Racial, Death Knight
		[69179] = spell.ArcaneTorrent, -- Blood Elf, Racial, Warrior
		[80483] = spell.ArcaneTorrent, -- Blood Elf, Racial, Hunter
	}
	
	spell_applied = {
		[130] = spell[130], -- Slow Fall
		[131] = spell[131], -- Water Breathing
		[453] = spell[453], -- Mind Soothe (Shadow)
		[546] = spell[546], -- Water Walking
		[605] = spell[605], -- Mind Control
		[676] = spell[676], -- Disarm
		[1022] = spell[1022], -- Hand of Protection
		[1038] = spell[1038], -- Hand of Salvation
		[1098] = spell[1098], -- Enslave Demon (Demonology)
		[1706] = spell[1706], -- Levitate
		[3674] = spell[3674], -- Black Arrow (Survival, Talent, Ultimate)
		[5697] = spell[5697], -- Unending Breath
		[6346] = spell[6346], -- Fear Ward
		[6940] = spell[6940], -- Hand of Sacrifice
		[10060] = spell[10060], -- Power Infusion (Discipline, Talent)
		[12809] = spell[12809], -- Concussion Blow (Protection)
		[20707] = spell[20707], -- Soulstone Resurrection (Demonology)
		[24259] = spell[24259], -- Spell Lock (Felhunter)
		[29166] = spell[29166], -- Innervate (Balance)
		[33206] = spell[33206], -- Inner Focus (Discipline, Talent)
		[47788] = spell[47788], -- Guardian Spirit (Holy)
		[49016] = spell[49016], -- Unholy Frenzy (Unholy)
		[50720] = spell[50720], -- Vigilance (Protection, Talent)
		[51722] = spell[51722], -- Dismantle (Assassination, Talent)
		[54646] = spell[54646], -- Focus Magic (Arcane, Talent)
		[64058] = spell[64058], -- Psychic Horror (Shadow, Talent)
		[77606] = spell[77606], -- Dark Simulacrum (Blood)
		[79268] = spell[79268], -- Soul Harvest (Demonology)
		[85388] = spell[85388], -- Throwdown (Arms, Talent)
		[85388] = spell.RingFrostCC, -- Ring of Frost (Frost)
	}

	-- in most cases, there is no difference between spell_appliedNT and spell_successNT
	-- to play safe, only stuff that is class/unit specific should go here
	spell_appliedNT = {
		[467] = spell[467], -- Thorns (Balance)
		[498] = spell[498], -- Divine Protection (Protection)
		[543] = spell[543], -- Mage Ward (Arcane)
		[586] = spell[586], -- Fade (Holy)
		[588] = spell[588], -- Inner Fire (Holy)
		[871] = spell[871], -- Shield Wall (Protection)
		[1463] = spell[1463], -- Mana Shield (Arcane)
		[1719] = spell[1719], -- Recklessness (Fury)
		[1784] = spell[1784], -- Stealth (Subtlety)
		[1850] = spell[1850], -- Dash (Feral)
		[2565] = spell[2565], -- Shield Block (Protection)
		[2645] = spell[2645], -- Ghost Wolf (Enhancement)
		[3045] = spell[3045], -- Rapid Fire (Marksmanship)
		[5215] = spell[5215], -- Prowl (Feral)
		[5217] = spell[5217], -- Tiger's Fury (Feral)
		[5229] = spell[5229], -- Enrage (Feral)
		[6196] = spell[6196], -- Far Sight (Enhancement)
		[6197] = spell[6197], -- Eagle Eye (Beast Mastery)
		[11426] = spell[11426], -- Ice Barrier (Frost, Talent)
		[12042] = spell[12042], -- Arcane Power (Arcane, Talent, Ultimate)
		[12292] = spell[12292], -- Death Wish (Fury, Talent)
		[12328] = spell[12328], -- Sweeping Strikes (Arms, Talent)
		[12472] = spell[12472], -- Icy Veins (Frost, Talent)
		[13750] = spell[13750], -- Adrenaline Rush (Combat, Talent)
		[16166] = spell[16166], -- Elemental Mastery (Elemental, Talent)
		[16886] = spell[16886], -- Nature's Grace (Balance, SpellAlert)
		[16689] = spell[16689], -- Nature's Grasp (Balance)
		[17941] = spell[17941], -- Shadow Trance (Affliction, SpellAlert)
		[18499] = spell[18499], -- Berserker Rage (Fury)
		[20230] = spell[20230], -- Retaliation (Arms)
		[20925] = spell[20925], -- Holy Shield (Protection, Talent)
		[22812] = spell[22812], -- Barkskin (Balance)
		[22842] = spell[22842], -- Frenzied Regeneration (Feral)
		[23920] = spell[23920], -- Spell Reflection (Protection)
		[26297] = spell[26297], -- Berserking (Troll, Racial)
		[27827] = spell[27827], -- Spirit of Redemption (Holy, Talent)
		[30823] = spell[30823], -- Shamanistic Rage (Enhancement, Talent)
		[31224] = spell[31224], -- Cloak of Shadows (Subtlety)
		[31842] = spell[31842], -- Divine Favor (Holy, Talent)
		[31850] = spell[31850], -- Ardent Defender (Protection, Talent, Ultimate)
		[31884] = spell[31884], -- Avenging Wrath (Retribution)
		[33891] = spell[33891], -- Tree of Life (Restoration, Ultimate)
		[44544] = spell[44544], -- Fingers of Frost (Mage, Frost, SpellAlert)
		[45182] = spell[45182], -- Cheat Death (Subtlety)
		[46924] = spell[46924], -- Bladestorm (Arms, Talent, Ultimate)
		[47241] = spell[47241], -- Metamorphosis (Demonology, Talent, Ultimate)
		[47283] = spell[47283], -- Empowered Imp (Destruction, SpellAlert)
		[47585] = spell[47585], -- Dispersion (Shadow, Talent, Ultimate)
		[48018] = spell[48018], -- Demonic Circle: Summon (Demonology)
		[48108] = spell[48108], -- Hot Streak (Fire, SpellAlert)
		[48792] = spell[48792], -- Icebound Fortitude (Frost)
		[49039] = spell[49039], -- Lichborne (Frost)
		[49222] = spell[49222], -- Bone Shield (Blood, Talent)
		[46916] = spell[46916], -- Bloodsurge (Fury, SpellAlert)
		[50227] = spell[50227], -- Sword and Board (Protection, SpellAlert)
		[51271] = spell[51271], -- Pillar of Frost (Frost, Talent)
		[54428] = spell[54428], -- Divine Plea (Holy)
		[55233] = spell[55233], -- Vampiric Blood (Blood, Talent)
		[55694] = spell[55694], -- Enraged Regeneration (Fury)
		[56453] = spell[56453], -- Lock and Load (Survival, SpellAlert)
		[57761] = spell[57761], -- Brain Freeze (Frost, SpellAlert)
		[59052] = spell[59052], -- Rime / Freezing Fog (Frost, SpellAlert)
		[59578] = spell[59578], -- The Art of War (Retribution, SpellAlert)
		[60970] = spell[60970], -- Heroic Fury (Fury, Talent)
		[61336] = spell[61336], -- Survival Instincts (Feral, Talent)
		[65116] = spell[65116], -- Stoneform (Dwarf, Talent)
		[68992] = spell[68992], -- Darkflight (Worgen, Racial)
		[73413] = spell[73413], -- Inner Will (Holy)
		[79140] = spell[79140], -- Vendetta (Assassination, Ultimate)
		[79206] = spell[79206], -- Spiritwalker's Grace (Elemental)
		[81340] = spell[81340], -- Sudden Doom (Unholy, SpellAlert)
		[82692] = spell[82692], -- Focus Fire (Beast Mastery, SpelLAlert)
		[82925] = spell[82925], -- Master Marksman / Ready, Set, Aim... (Marksmanship, SpelLAlert)
		[85416] = spell[85416], -- Grand Crusader (Protection, SpelLAlert)
		[85696] = spell[85696], -- Zealotry (Retribution, Ultimate)
		[85730] = spell[85730], -- Sweeping Strikes (Arms, Talent)
		[86150] = spell[86150], -- Guardian of Ancient Kings (Protection)
		[87023] = spell[87023], -- Cauterize (Fire, Talent)
		[88688] = spell[88688], -- Surge of Light (Holy, SpellAlert)
		[6229] = spell.ShadowWard, -- Shadow Ward (Demonology)
		[91711] = spell.ShadowWard, -- Nether Ward (Destruction, Talent)
		[81206] = spell.Chakra, -- Chakra: Sanctuary (Holy, Talent)
		[81208] = spell.Chakra, -- Chakra: Serenity (Holy, Talent)
		[81209] = spell.Chakra, -- Chakra: Chastise (Holy, Talent)
		[20572] = spell.BloodFury, -- Orc, Racial, Melee Classes
		[33702] = spell.BloodFury, -- Orc, Racial, Mana Classes
		[33697] = spell.BloodFury, -- Orc, Racial, Shaman
	}

	spell_start = {
		[556] = spell[556], -- Astral Recall (Enhancement)
		[8690] = spell[8690], -- Hearthstone
		[18960] = spell[18960], -- Teleport: Moonglade (Druid)
		[58493] = spell[58493], -- Mohawk Grenade
		[88685] = spell[88685], -- Holy Word: Sanctuary (Holy)
	}

	-- for pvp/arena
	spell_precast = {
		[118] = spell.PrePolymorph, -- Polymorph
		[339] = spell.PreEntanglingRoots, -- Entangling Roots
		[605] = spell.PreMindControl, -- Mind Control
		[5782] = spell.PreFear, -- Fear
		[28271] = spell.PrePolymorph, -- Polymorph: Turtle
		[28272] = spell.PrePolymorph, -- Polymorph: Pig
		[33786] = spell.PreCyclone, -- Cyclone
		[51514] = spell.PreHex, -- Hex
		[61305] = spell.PrePolymorph, -- Polymorph: Black Cat
		[61721] = spell.PrePolymorph, -- Polymorph: Rabbit
		[61780] = spell.PrePolymorph, -- Polymorph: Turkey
	}

	spell_summon = {
		[126] = spell[126], -- Eye of Kilrogg (Demonology)
		[724] = spell[724], -- Lightwell (Holy, Talent)
		[1122] = spell[1122], -- Summon Infernal (Demonology)
		[2062] = spell[2062], -- Earth Elemental Totem (Enhancement)
		[2894] = spell[2894], -- Fire Elemental Totem (Elemental)
		[8143] = spell[8143], -- Tremor Totem (Restoration)
		[8177] = spell[8177], -- Grounding Totem (Enhancement)
		[16190] = spell[16190], -- Mana Tide Totem (Restoration, Talent)
		[18540] = spell[18540], -- Summon Doomguard (Demonology)
		[34433] = spell[34433], -- Shadowfiend (Shadow)
		[62857] = spell[62857], -- Sandbox Tiger
		[82676] = spell[82676], -- Ring of Frost (Frost)
		[98008] = spell[98008], -- Spirit Link Totem (Restoration, Talent)
	}
	
	spell_create = {
		[10059] = spell[10059], -- Portal: Stormwind
		[11417] = spell[11417], -- Portal: Orgrimmar
		[43808] = spell[43808], -- Brewfest Pony Keg
		[49844] = spell[49844], -- Using Direbrew's Remote
		[50977] = spell[50977], -- Death Gate (Unholy)
		[61031] = spell[61031], -- Toy Train Set
		[88345] = spell.PortalTolBarad, -- Alliance
		[88346] = spell.PortalTolBarad, -- Horde
	}

	CrowdControl = {
	-- Hunter
		[1513] = spell[1513], -- Scare Beast
		[3355] = spell[3355], -- Freezing Trap
		[19386] = spell[19386], -- Wyvern Sting (Survival, Talent)
		[19503] = spell[19503], -- Scatter Shot
	-- Mage
		[118] = spell[118], -- Polymorph
		[28271] = spell[28271], -- Polymorph: Turtle
		[28272] = spell[28272], -- Polymorph: Pig
		[61305] = spell[61305], -- Polymorph: Black Cat
		[61721] = spell[61721], -- Polymorph: Rabbit
		[61780] = spell[61780], -- Polymorph: Turkey
	-- Rogue
		[2094] = spell[2094], -- Blind
		[6770] = spell[6770], -- Sap
	-- Shaman
		[51514] = spell[51514], -- Hex
		[76780] = spell[76780], -- Bind Elemental
	-- Priest
		[9484] = spell[9484], -- Shackle Undead
		[8122] = spell[8122], -- Psychic Scream
	-- Warlock
		[710] = spell[710], -- Banish
		[5484] = spell[5484], -- Howl of Terror (Affliction)
		[5782] = spell[5782], -- Fear
		[6358] = spell[6358], -- Seduction (Succubus)
		[6789] = spell[6789], -- Death Coil (Affliction)
	-- Druid
		[339] = spell[339], -- Entangling Roots
		[2637] = spell[2637], -- Hibernate
		[33786] = spell[33786], -- Cyclone
	-- Paladin
		[10326] = spell[10326], -- Turn Evil
		[20066] = spell[20066], -- Repentance
	-- Warrior
		[5246] = spell[5246], -- Intimidating Shout
	-- Death Knight
		[49203] = spell[49203], -- Hungering Cold
	}
end

function KCL:OptionsDisabled()
	return not self:IsEnabled()
end

function KCL:SlashCommand(input)
	if strtrim(input) == "" then
		--InterfaceOptionsFrame_OpenToCategory(NAME2)
		ACD:Open("KethoCombatLog_Parent")

	elseif input == "enable" or input == "on" or input == "1" then
		self:Enable()
		self:Print("|cffADFF2FEnabled|r")
		ACR:NotifyChange("KethoCombatLog_Parent")
	elseif input == "disable" or input == "off" or input == "0" then
		self:Disable()
		self:Print("|cffFF2424Disabled|r")
		ACR:NotifyChange("KethoCombatLog_Parent")
	else
		print("|cff2E9AFE/ket|r: Open Options\n|cff2E9AFE/ket|r |cffB6CA00on|r: Enable AddOn\n|cff2E9AFE/ket|r |cffFF2424off|r: Disable AddOn")
	end
end

-- Blizzard CombatLog is Load-on-Demand
function KCL:ADDON_LOADED(event, addon)
	if addon == "Blizzard_CombatLog" and not profile.BlizzardCombatLog then
		COMBATLOG:UnregisterEvent("COMBAT_LOG_EVENT")
		self:UnregisterEvent("ADDON_LOADED")
	end
end

local function ChatFilter(event)
	if profile.ChatFilters then
		return profile["Chat"..event]
	else
		return profile[event]
	end
end

local function TankFilter(isTank, event)
	if profile["Tank"..event] then
		return true
	else
		return not isTank
	end
end

function KCL:Dec2Hex(R, G, B)
	return format("%02X%02X%02X", R*255, G*255, B*255)
end

-- actually only used just once for playerColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local function GetClassColor(class)
	return format("%02X%02X%02X", RAID_CLASS_COLORS[class].r*255, RAID_CLASS_COLORS[class].g*255, RAID_CLASS_COLORS[class].b*255)
end

local function UnitReaction(unitflags)
	if bit_band(unitflags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
		return 1
	elseif bit_band(unitflags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
		return 2
	else
		return 3
	end
end

-- modified from Blizzard_CombatLog
local function UnitIcon(unitFlags, reaction)
	local iconBit = bit_band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
	if iconBit == 0 then
		return "", ""
	end
	local icon
	local iconString, braces = "", ""
	for i = 1, 8 do
		if iconBit == _G["COMBATLOG_OBJECT_RAIDTARGET"..i] then
			icon = _G["COMBATLOG_ICON_RAIDTARGET"..i]
			braces = "{"..strlower(_G["RAID_TARGET_"..i]).."}"
			break
		end
	end
	if icon then
		iconString = format(STRING_REACTION_ICON[reaction], iconBit, icon)
	end
	return iconString, braces
end

local function SpellSchool(value)
	local str = SpellSchoolString[value] or STRING_SCHOOL_UNKNOWN.." ("..value..")"
	local color = SpellSchoolColor[value] or "71D5FF"
	return "|cff"..color..str.."|r", str, color
end

local function SpellInfo(spellID, spellName, spellSchool)
	local schoolNameLocal, schoolNameChat, schoolColor = SpellSchool(spellSchool)
	local spellIcon = iconSize>1 and "|T"..GetSpellIcon(spellID)..":"..iconSize..":"..iconSize..":0:0"..cropped.."|t" or ""
	local spellLinkLocal = format("|cff%s"..TEXT_MODE_A_STRING_SPELL.."|r", schoolColor, spellID, "", "["..spellName.."]")..spellIcon
	return schoolNameLocal, schoolNameChat, spellLinkLocal, GetSpellLink(spellID)
end

local function ResultString(schoolNameLocal, schoolNameChat, amount, overkill, critical, glancing, crushing)
	local resultStr, resultStringLocal, resultStringChat = "", "", ""

	if overkill and profile.overkillFormat then
		resultStr = resultStr.." "..format(TEXT_MODE_A_STRING_RESULT_OVERKILLING, overkill)
	end
	if critical and profile.criticalFormat then
		resultStr = resultStr.." "..TEXT_MODE_A_STRING_RESULT_CRITICAL
	end
	if glancing and profile.glancingFormat then
		resultStr = resultStr.." "..TEXT_MODE_A_STRING_RESULT_GLANCING 
	end
	if crushing and profile.crushingFormat then
		resultStr = resultStr.." "..TEXT_MODE_A_STRING_RESULT_CRUSHING 
	end
	if amount then
		resultStringLocal = " "..amount.." "..schoolNameLocal..resultStr
		resultStringChat = " "..amount.." "..schoolNameChat..resultStr
	end

	return resultStringLocal, resultStringChat
end

local Time

local function timeUpdater()
	Time = time() 
end
local timeUpdateFrame = CreateFrame("Frame")
timeUpdateFrame:SetScript("OnUpdate", timeUpdater)

local lastDeath
local playerColor = GetClassColor(player.class)

function KCL:COMBAT_LOG_EVENT_UNFILTERED(event, ...)

	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	
	local isDamageEvent = damageEvent[subevent]
	local isReflectEvent = (subevent == "SPELL_MISSED" and select(15, ...) == "REFLECT")
	local isReverseEvent = isDamageEvent or isReflectEvent
	local sourceType = tonumber(strsub(sourceGUID, 5, 5))
	local destType = tonumber(strsub(destGUID, 5, 5))

	---------------
	--- Filters ---
	---------------

	if sourceName == player.name or destName == player.name then
		if not profile.filterSelf then return end
	else
		if not profile.filterEverythingElse then return end
	end

	-- the other way round for for death/reflect events
	if (playerID[sourceType] and not isReverseEvent) or (playerID[destType] and isReverseEvent) then
		if not profile.filterPlayers then return end
	else
		if not profile.filterMonsters then return end
	end

	----------------------
	--- Unit Link/Icon ---
	----------------------
	
	local sourceNameTrim, destNameTrim = "", ""

	local sourceUnitLocal, destUnitLocal = "", ""
	local sourceUnitChat, destUnitChat = "", ""

	local sourceIconLocal, sourceIconChat = UnitIcon(sourceRaidFlags, 1)
	local destIconLocal, destIconChat = UnitIcon(destRaidFlags, 2)

	local sourceReaction = UnitReaction(sourceFlags)
	local destReaction = UnitReaction(destFlags)

	if sourceName then
		-- trim out realm name; exception: only do this for players, to avoid false positives for certain npcs
		sourceNameTrim = (profile.TrimRealmNames and playerID[sourceType]) and strmatch(sourceName, "([^%-]+)%-?.*") or sourceName
		local name, color = sourceNameTrim
		if sourceName == player.name then
			color, name = playerColor, UNIT_YOU_SOURCE
		elseif UnitInParty(sourceName) or UnitInRaid(sourceName) then
			color = ClassColor[select(2,UnitClass(sourceName))]
		elseif sourceType == 0 and (sourceName == UnitName("target") or sourceName == UnitName("focus")) then
			if sourceName == UnitName("target") then
				color = ClassColor[select(2,UnitClass("target"))]
			elseif sourceName == UnitName("focus") then
				color = ClassColor[select(2,UnitClass("focus"))]
			end
		else
			color = UnitColor[sourceReaction]
		end
		sourceUnitLocal = format("|cff%s"..TEXT_MODE_A_STRING_SOURCE_UNIT.."|r", color, sourceIconLocal, sourceGUID, "["..sourceNameTrim.."]", "["..name.."]")
		sourceUnitChat = sourceIconChat.."["..sourceNameTrim.."]"
	end
	if destName then
		destNameTrim = (profile.TrimRealmNames and playerID[destType]) and strmatch(destName, "([^%-]+)%-?.*") or destName
		local name, color = destNameTrim
		if destName == player.name then
			color, name = playerColor, UNIT_YOU_DEST
		elseif UnitInParty(destName) or UnitInRaid(destName) then
			color = ClassColor[select(2,UnitClass(destName))]
		elseif destType == 0 and (destName == UnitName("target") or destName == UnitName("focus")) then
			if destName == UnitName("target") then
				color = ClassColor[select(2,UnitClass("target"))]
			elseif destName == UnitName("focus") then
				color = ClassColor[select(2,UnitClass("focus"))]
			end
		else
			color = UnitColor[destReaction]
		end
		destUnitLocal = format("|cff%s"..TEXT_MODE_A_STRING_DEST_UNIT.."|r", color, destIconLocal, destGUID, "["..destNameTrim.."]", "["..(destName==sourceName and QUICKBUTTON_NAME_SELF or name).."]")
		destUnitChat = destIconChat.."["..destNameTrim.."]"
	end

	local schoolNameLocal, extraschoolNameLocal = "", ""
	local schoolNameChat, extraSchoolNameChat = "", ""

	local spellIcon, extraSpellIcon
	local spellLinkLocal, extraSpellLinkLocal = "", ""
	local spellLinkChat, extraSpellLinkChat = "", ""

	----------------
	--- Suffixes ---
	----------------

	local spellID, spellName, spellSchool
	local SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9

	local prefix = strsub(subevent, 1, 5)
	if prefix == "SWING" then
		SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
	elseif prefix == "SPELL" or prefix == "RANGE" or prefix == "DAMAG" then
		spellID, spellName, spellSchool, SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)

	-----------------------
	--- Spell Link/Icon ---
	-----------------------

		schoolNameLocal, schoolNameChat, spellLinkLocal, spellLinkChat = SpellInfo(spellID, spellName, spellSchool)
		if extraSpellEvent[subevent] then
			extraschoolNameLocal, extraSchoolNameChat, extraSpellLinkLocal, extraSpellLinkChat = SpellInfo(SuffixParam1, SuffixParam2, SuffixParam3)
		end
	end

	-- optionally remove braces again
	if not profile.UnitBracesLocal then
		sourceUnitLocal = sourceUnitLocal:gsub("[%[%]]", "")
		destUnitLocal = destUnitLocal:gsub("[%[%]]", "")
		spellLinkLocal = spellLinkLocal:gsub("[%[%]]", " ")
		extraSpellLinkLocal = extraSpellLinkLocal:gsub("[%[%]]", " ")
	end
	if not profile.UnitBracesChat then
		sourceUnitChat = sourceUnitChat:gsub("[%[%]]", " ")
		destUnitChat = destUnitChat:gsub("[%[%]]", " ")
	end

	-----------------
	--- Timestamp ---
	-----------------

	local timestampLocal, timestampChat = "", ""
	if profile.Timestamp then
		local Date = date(format("[%s]", TEXT_MODE_A_TIMESTAMP))
		timestampLocal = "|cffA9A9A9"..Date.."|r "
		timestampChat = Date.." "
	end

	---------------------
	--- Damage String ---
	---------------------

	local resultStringLocal, resultStringChat = "", ""
	if isDamageEvent or healEvent[subevent] then
		if subevent == "SWING_DAMAGE" then
			schoolNameLocal = "|cff"..SpellSchoolColor[0x1]..ACTION_SWING.."|r"
			schoolNameChat = ACTION_SWING
		end
		resultStringLocal, resultStringChat = ResultString(schoolNameLocal, schoolNameChat, SuffixParam1, SuffixParam2, SuffixParam7, SuffixParam8, SuffixParam9)
	end

	if instanceTypeFilter then

		local isTank = (UnitGroupRolesAssigned(sourceName) == "TANK")
		local textLocal, textChat

	-----------------
	--- Subevents ---
	-----------------

		-- Deaths
		if profile.Death or profile.ChatDeath then
			-- Instagibs; problem: filter DK [Death Pact] deaths, it's not a damage event, so it slips through the filter
			if subevent == "SPELL_INSTAKILL" and spellID ~= 48743 then
				textLocal = profile.Death and destUnitLocal.." |cff"..EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..sourceUnitLocal..spellLinkLocal
				textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat..spellLinkChat
			-- Environmental Deaths; problem: the overkill parameter is always stuck on zero
			elseif subevent == "ENVIRONMENTAL_DAMAGE" then
				local environmentalType, SuffixParam1, _, SuffixParam3 = select(12, ...)
				if UnitHealth(destName) and UnitHealth(destName) == 1 then
					textLocal = profile.Death and destUnitLocal.." |cff"..EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..SuffixParam1.." "..(environmentalDamageType[environmentalType] or environmentalType)
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..SuffixParam1.." "..(environmentalDamageType[environmentalType] or environmentalType)
				end
			elseif isDamageEvent and SuffixParam2 > 0 and (Time > (cd.death or 0) or destName ~= lastDeath) then
				cd.death = Time + 0.2; lastDeath = destName
				if subevent == "SWING_DAMAGE" then
					textLocal = profile.Death and destUnitLocal.." |cff"..EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..sourceUnitLocal
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat
				else
					textLocal = profile.Death and destUnitLocal.." |cff"..EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..sourceUnitLocal..spellLinkLocal
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat..spellLinkChat
				end
			end
		end
		-- Taunts
		if profile.Taunt or profile.ChatTaunt then
			if TankFilter(isTank, "Taunt") then
				if subevent == "SPELL_AURA_APPLIED" and destType >= 3 and Taunt[spellID] then
					textLocal = sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["TAUNT"].."taunted|r "..destUnitLocal
					textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." taunted "..destUnitChat
				elseif subevent == "SPELL_CAST_SUCCESS" and (spellID == 1161 or spellID == 5209) then
					textLocal = profile.Taunt and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["TAUNT"].."AoE "..GetSpellInfo(355).."|r"
					textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." AoE "..GetSpellInfo(355)
				end
			end
			-- Pet 2649[Growl], Voidwalker 3716[Torment]
			if subevent == "SPELL_CAST_SUCCESS" and profile.PetGrowl and destType >= 3 and (spellID == 2649 or spellID == 3716) then
				textLocal = profile.Taunt and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["TAUNT"].."growled|r "..destUnitLocal
				textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." growled "..destUnitChat
			end
		end
		-- CC Breaker
		if (profile.CC_Break or profile.ChatCC_Break) and TankFilter(isTank, "Break") then
			-- broken by a spell
			if subevent == "SPELL_AURA_BROKEN_SPELL" then
				textLocal = profile.CC_Break and sourceUnitLocal..extraSpellLinkLocal.." |cff"..EventColor["CC_BREAK"]..ACTION_SPELL_AURA_BROKEN.."|r "..spellLinkLocal.." on "..destUnitLocal
				textChat = ChatFilter("CC_Break") and sourceUnitChat..extraSpellLinkChat.." "..ACTION_SPELL_AURA_BROKEN.." "..spellLinkChat.." on "..destUnitChat
			-- not broken by a spell; this subevent does not seem to fire for CLEU; 4.0.1 bug?
			elseif subevent == "SPELL_AURA_BROKEN" then
				if sourceName then
					textLocal = profile.CC_Break and sourceUnitLocal.." |cff"..EventColor["CC_BREAK"]..ACTION_SPELL_AURA_BROKEN.."|r "..spellLinkLocal.." on "..destUnitLocal
					textChat = ChatFilter("CC_Break") and sourceUnitChat.." "..ACTION_SPELL_AURA_BROKEN.." "..spellLinkChat.." on "..destUnitChat
				else
					textLocal = profile.CC_Break and spellLinkLocal.." on "..destUnitLocal.." |cff"..EventColor["CC_BREAK"].."broken|r"
					textChat = ChatFilter("CC_Break") and spellLinkChat.." on "..destUnitChat.." broken"
				end
			end
		end
		-- Dispels / Spellsteals
		if subevent == "SPELL_DISPEL" then
			local dispelString
			if (sourceReaction == 1 and destReaction == 1) or (sourceReaction == 2 and destReaction == 2) then
				dispelString = profile.FriendlyDispel and ACTION_SPELL_DISPEL_DEBUFF
			else
				dispelString = profile.HostileDispel and ACTION_SPELL_DISPEL_BUFF
			end
			if dispelString then
				textLocal = profile.Dispel and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["DISPEL"]..dispelString.."|r "..destUnitLocal..extraSpellLinkLocal
				textChat = ChatFilter("Dispel") and sourceUnitChat..spellLinkChat.." "..dispelString.." "..destUnitChat..extraSpellLinkChat
			end
		elseif subevent == "SPELL_STOLEN" then
			textLocal = profile.Dispel and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["DISPEL"]..ACTION_SPELL_STOLEN.."|r "..destUnitLocal..extraSpellLinkLocal
			textChat = ChatFilter("Dispel") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_STOLEN.." "..destUnitChat..extraSpellLinkChat
		-- Reflects / Misses
		elseif subevent == "SPELL_MISSED" then
			if SuffixParam1 == "REFLECT" then
				textLocal = profile.Reflect and destUnitLocal.." |cff"..EventColor["REFLECT"]..ACTION_SPELL_MISSED_REFLECT.."|r "..sourceUnitLocal..spellLinkLocal
				textChat = ChatFilter("Reflect") and destUnitChat.." "..ACTION_SPELL_MISSED_REFLECT.." "..sourceUnitChat..spellLinkChat
			else
				local taunt, interrupt, cc = Taunt[spellID], Interrupt[spellID], CrowdControl[spellID]
				if profile.MissAll or (taunt and profile.Taunt) or (interrupt and profile.Interrupt) or (cc and profile.CrowdControl) then
					textLocal = sourceUnitLocal..spellLinkLocal.." on "..destUnitLocal.." |cffFF7800"..ACTION_SPELL_CAST_FAILED.."|r ("..missType[SuffixParam1]..")"
				end
				if (taunt and ChatFilter("Taunt")) or (interrupt and ChatFilter("Interrupt")) or (cc and ChatFilter("CrowdControl")) then
					textChat = sourceUnitChat..spellLinkChat.." on "..destUnitChat.." "..ACTION_SPELL_CAST_FAILED.." ("..missType[SuffixParam1]..")"
				end
				-- check if the interrupt didn't miss, instead of being wasted
				if interrupt and profile.WastedInterrupt then
					self:IneffectiveInterrupt(...)
				end
			end
		-- Death Prevents; -- Priest 48153[Guardian Spirit], Paladin 66235[Ardent Defender]
		elseif subevent == "SPELL_HEAL" and (spellID == 48153 or spellID == 66235) then
			if profile.Death and profile.DeathPrevent then
				textLocal = sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["RESURRECTION"].."healed "..destUnitLocal
			end
			if ChatFilter("Death") and ChatFilter("DeathPrevent") then
				textChat = sourceUnitChat..spellLinkChat.." healed "..destUnitChat..spellLinkChat
			end
		-- Resurrections
		elseif subevent == "SPELL_RESURRECT" then
			if not profile.BattleRez or (profile.BattleRez and UnitAffectingCombat("player")) then
				textLocal = profile.Resurrection and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["RESURRECTION"]..ACTION_SPELL_RESURRECT.."|r "..destUnitLocal
				textChat = ChatFilter("Resurrection") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_RESURRECT.." "..destUnitChat
			end
		-- Crowd Control
		elseif subevent == "SPELL_AURA_APPLIED" and CrowdControl[spellID] then
			textLocal = profile.CrowdControl and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["CROWDCONTROL"].."CC'ed|r "..destUnitLocal
			textChat = ChatFilter("CrowdControl") and sourceUnitChat..spellLinkChat.." CC'ed "..destUnitChat
		-- "pre-Interrupts"
		elseif subevent == "SPELL_CAST_SUCCESS" and Interrupt[spellID] then
			self:IneffectiveInterrupt(...)
		-- Interrupts
		elseif subevent == "SPELL_INTERRUPT" then
			textLocal = profile.Interrupt and sourceUnitLocal..spellLinkLocal.." |cff"..EventColor["INTERRUPT"]..ACTION_SPELL_INTERRUPT.."|r "..destUnitLocal..extraSpellLinkLocal
			textChat = ChatFilter("Interrupt") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_INTERRUPT.." "..destUnitChat..extraSpellLinkChat
			self:IneffectiveInterrupt(...)
		-- Wasted Interrupt
		elseif subevent == "SPELL_INEFFECTIVE_INTERRUPT" then
			if profile.Interrupt and profile.WastedInterrupt then
				textLocal = sourceUnitLocal.." |cffFF7800wasted|r "..spellLinkLocal.."  on "..destUnitLocal
			end
			if ChatFilter("Interrupt") and ChatFilter("WastedInterrupt") then
				textChat = sourceUnitChat.." wasted "..spellLinkChat.." on "..destUnitChat
			end
		end

		-- Spell
		if profile.enableSpell then
			-- filters
			local spellSelf = profile.SpellSelf and sourceName == player.name
			local spellFriend = profile.SpellFriend and (sourceReaction == 1 and sourceName ~= player.name)
			local spellEnemy = profile.SpellEnemy and sourceReaction >= 2

			if spellSelf or spellFriend or spellEnemy then
				-- hacky, cba about preserving coloring
				if profile.SpellSpellName and strfind(subevent, "SPELL") then
					spellLinkLocal = profile.UnitBracesLocal and "["..spellName.."]" or " "..spellName.." "
					spellLinkChat = profile.UnitBracesChat and "["..spellName.."]" or " "..spellName.." "
				end
				if subevent == "SPELL_CAST_SUCCESS" then
					if spell_success[spellID] or spell_successNT[spellID] then
						-- request: only show MD/TotT on tanks; this feels dirty ..
						if not TankSupport[spellID] or (TankSupport[spellID] and ((profile.TankSupport and UnitGroupRolesAssigned(destName) == "TANK") or not profile.TankSupport)) then
							if (not profile.SelfCast and destName == sourceName) or not destName then
								textLocal = sourceUnitLocal..spellLinkLocal
								textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
							else
								textLocal = sourceUnitLocal..spellLinkLocal.." on "..destUnitLocal
								textChat = profile.SpellChat and sourceUnitChat..spellLinkChat.." on "..destUnitChat
							end
						end
					end
				elseif subevent == "SPELL_AURA_APPLIED" then
					-- change of plans; might've as well combined spell_applied and spell_appliedNT into 1 table now
					if spell_applied[spellID] or spell_appliedNT[spellID] then
						-- Mind Control exception
						if spellID ~= 605 or (spellID == 605 and destName ~= sourceName) then
							if (not profile.SelfCast and destName == sourceName) or not destName then
								textLocal = sourceUnitLocal..spellLinkLocal
								textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
							else
								textLocal = sourceUnitLocal..spellLinkLocal.." on "..destUnitLocal
								textChat = profile.SpellChat and sourceUnitChat..spellLinkChat.." on "..destUnitChat
							end
						end
					end
				elseif subevent == "SPELL_CAST_START" then
					if spell_start[spellID] then
						textLocal = sourceUnitLocal..spellLinkLocal
						textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
					elseif spell_precast[spellID] and sourceName ~= player.name then
						textLocal = sourceUnitLocal.." casting "..spellLinkLocal.." |TInterface\\EncounterJournal\\UI-EJ-Icons:12:12:0:2:64:256:42:46:32:96|t"
						textChat = profile.SpellChat and sourceUnitChat.." casting "..spellLinkChat
					end
				elseif (subevent == "SPELL_SUMMON" and spell_summon[spellID]) or (subevent == "SPELL_CREATE" and spell_create[spellID]) then
					textLocal = sourceUnitLocal..spellLinkLocal
					textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
				end
			end
		end

		-- Feast; Repair Bot; Fun
		if subevent == "SPELL_CAST_SUCCESS" then
			if (profile.Feast and Feast[spellID]) or (profile.RepairBot and RepairBot[spellID]) then
				textLocal = sourceUnitLocal..spellLinkLocal
				textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
			end
		elseif subevent == "SPELL_AURA_APPLIED" then
			if profile.Seasonal and Seasonal[spellID] then
				textLocal = sourceUnitLocal..spellLinkLocal.." on "..destUnitLocal
				textChat = profile.SpellChat and sourceUnitChat..spellLinkChat.." on "..destUnitChat
			end
		end

	--------------
	--- Output ---
	--------------

		if textLocal or textChat then
			if textLocal and profile.chatWindow > 1 then
				textLocal = timestampLocal..textLocal..resultStringLocal
				ChatFrame:AddMessage(textLocal)
			end
			-- don't want to default to "SAY" if chatType is nil
			if textChat and profile.chatChannel > 1 and chatType then
				-- check if not dead
				if not ((chatType == "SAY" or chatType == "YELL") and (UnitIsDead("player") or UnitIsGhost("player"))) then
					textChat = timestampChat..textChat..resultStringChat
					SendChatMessage(textChat, chatType, nil, channel)
				end
			end
			if textChat and profile.sink20OutputSink == "Channel" then
				self:Pour(textChat)
			elseif textLocal and profile.sink20OutputSink ~= "Channel" then
				self:Pour(textLocal)
			end
		end
	end
end

	------------------------------
	--- Ineffective Interrupts ---
	------------------------------

local InterruptCheck = {}
function KCL:IneffectiveInterrupt(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
	if subevent == "SPELL_CAST_SUCCESS" then
		InterruptCheck[sourceGUID] = true
		subevent = "CHECK_INEFFECTIVE_INTERRUPT"
		-- SPELL_INTERRUPT can have around 0.4~ sec delay/lag (in most cases)
		self:ScheduleTimer(function() self:IneffectiveInterrupt(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool) end, 0.4)
	elseif subevent == "SPELL_INTERRUPT" or subevent == "SPELL_MISSED" then
		InterruptCheck[sourceGUID] = false
	elseif subevent == "CHECK_INEFFECTIVE_INTERRUPT" then
		if InterruptCheck[sourceGUID] then
			self:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, "SPELL_INEFFECTIVE_INTERRUPT", hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
		end
		InterruptCheck[sourceGUID] = false
	end
end

	---------------------
	--- LibDataBroker ---
	---------------------

local dataobject = {
	type = "launcher",
	text = "Ketho CombatLog",
	label = "Ketho CombatLog",
	icon = "Interface\\Icons\\INV_Sword_01",
	OnClick = function(clickedframe, button)
		if IsModifierKeyDown() then
			KCL:SlashCommand(KCL:IsEnabled() and "0" or "1")
		else
			if ACD.OpenFrames["KethoCombatLog_Parent"] then
				ACD:Close("KethoCombatLog_Parent")
			else
				ACD:Open("KethoCombatLog_Parent")
			end
		end
	end,
	OnTooltipShow = function(tt)
		tt:AddLine("|cffADFF2FKetho|r |cffFFFFFFCombatLog|r")
		tt:AddLine("|cffFFFFFFClick|r to open the options menu")
		tt:AddLine("|cffFFFFFFShift-click|r to toggle this AddOn")
	end,
}

LDB:NewDataObject("Ketho_CombatLog", dataobject)