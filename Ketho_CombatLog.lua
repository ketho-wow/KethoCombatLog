-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2009.09.01					---
--- Version: 1.08 [2013.03.08]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/ketho-combatlog
--- WoWInterface	http://www.wowinterface.com/downloads/info18901-KethoCombatLog.html

--- To Do:
-- Custom Message Strings
-- Support for Localization
-- Improve Crowd Control checking
-- DevTools style debugging, and similar way to easily announce a chatlog entry

local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.BUILD = "Alpha"

KethoCombatLog = LibStub("AceAddon-3.0"):NewAddon("KethoCombatLog", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibSink-2.0")
local KCL = KethoCombatLog
KethoCombatLog.S = S -- debug purpose

S.crop = ":64:64:4:60:4:60"

S.player = {
	name = UnitName("player"),
	class = select(2, UnitClass("player")),
}

S.SpellSchoolString = {
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

