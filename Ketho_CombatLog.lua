-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2009.09.01					---
--- Version: 1.09 [2013.03.22]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/ketho-combatlog
--- WoWInterface	http://www.wowinterface.com/downloads/info18901-KethoCombatLog.html

--- To Do:
-- Custom Message Strings
-- Support for Localization
-- Improve Crowd Control checking
-- DevTools style debugging, and similar way to easily announce a chatlog entry

--- To Do 20130321:
-- better CUSTOM_CLASS_COLORS implementation
-- clean up ... redo stuff

local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.BUILD = "Alpha"

KethoCombatLog = LibStub("AceAddon-3.0"):NewAddon("KethoCombatLog", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibSink-2.0")
local KCL = KethoCombatLog
KethoCombatLog.S = S -- debug purpose
--X = KethoCombatLog --debug

local profile

function KCL:RefreshDB1()
	profile = self.db.profile
end

S.crop = ":64:64:4:60:4:60"

S.Player = {
	name = UnitName("player"),
	class = select(2, UnitClass("player")),
}
local player = S.Player

S.SpellName = {
	Taunt = GetSpellInfo(355),
	Dispel = GetSpellInfo(25808),
	Resurrect = GetSpellInfo(2006),
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

S.Taunt = {
	[355] = true, -- Warrior: Taunt
	[6795] = true, -- Druid: Growl
	[17735] = true, -- Warlock: Suffering [Voidwalker]
	[20736] = true, -- Hunter: Distracting Shot
	[116189] = true, -- Monk: Provoke; 115546
-- Death Knight
	[49560] = true, -- Death Grip
	[51399] = true, -- Death Grip (melee range)
	[56222] = true, -- Dark Command
-- Paladin
	[31790] = true, -- Righteous Defense
	[62124] = true, -- Hand of Reckoning
}

S.Interrupt = {
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
}

S.RepairBot = {
	[22700] = true, -- [Field Repair Bot 74A]
	[44389] = true, -- [Field Repair Bot 110G]
	[54710] = true, -- [MOLL-E]
	[54711] = true, -- [Scrapbot]
	[67826] = true, -- [Jeeves]
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

S.CrowdControl = { -- to do
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
}

--[[
S.TankSupport = {
	[34477] = true, -- Misdirection
	[57934] = true, -- Tricks of the Trade
}
]]
-- in rare cases some players have 8 as the Unit Type
S.PlayerID = {
	[0] = true,
	[8] = true,
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
	MISS = COMBAT_TEXT_MISS,
	PARRY = COMBAT_TEXT_PARRY,
	Reflect = COMBAT_TEXT_REFLECT,
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

S.STRING_REACTION_ICON = {
	TEXT_MODE_A_STRING_SOURCE_ICON,
	TEXT_MODE_A_STRING_DEST_ICON,
}

-- check if a Combat Text addon is available
S.LibSinkCombatText = {
	Blizzard = true,
	MikSBT = true,
	Parrot = true,
	SCT = true,
}

	--------------------
	--- Color Caches ---
	--------------------

-- only for class colors
S.ClassColor = setmetatable({}, {__index = function(t, k)
	local color, v
	if CUSTOM_CLASS_COLORS then
		color = CUSTOM_CLASS_COLORS[k]
		v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	else
		color = profile.color[k] -- hardcoded instead of RAID_CLASS_COLORS
		v = format("%02X%02X%02X", color[1]*255, color[2]*255, color[3]*255)
	end
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

	--------------
	--- Remaps ---
	--------------

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

	------------------------
	--- Helper functions ---
	------------------------

function S.Dec2Hex(r, g, b)
	return format("%02X%02X%02X", r*255, g*255, b*255)
end

function S.GetClassColor(class)
	local color = RAID_CLASS_COLORS[class]
	return format("%02X%02X%02X",color.r*255, color.g*255, color.b*255)
end
player.color = S.GetClassColor(player.class)

	--[[
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
		[20707] = spell[20707], -- Soulstone Resurrect (Demonology)
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
		--[85730] = spell[85730], -- Sweeping Strikes (Arms, Talent)
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
	]]