local NAME, S = ...
local KCL = KethoCombatLog

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L
local options = S.options

local profile, char
local color, spell

local crop = S.crop
local player = S.player
local iconSize = S.iconSize
local ChatFrame = S.ChatFrame

local cd = {}

local _G = _G
local bit_band = bit.band

local GetSpellInfo, oldGetSpellLink = GetSpellInfo, GetSpellLink

--local UnitColor, ClassColor
--local SpellSchoolColor, EventColor

local spell_success, spell_successNT
local spell_applied, spell_appliedNT
local spell_summon, spell_create
local spell_start, spell_precast
local CrowdControl

--[[
local COMBATLOG_OBJECT_RAIDTARGET_MASK = COMBATLOG_OBJECT_RAIDTARGET_MASK

local TEXT_MODE_A_STRING_SOURCE_UNIT = TEXT_MODE_A_STRING_SOURCE_UNIT
local TEXT_MODE_A_STRING_DEST_UNIT = TEXT_MODE_A_STRING_DEST_UNIT

local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local TEXT_MODE_A_STRING_SPELL = TEXT_MODE_A_STRING_SPELL
local TEXT_MODE_A_TIMESTAMP = TEXT_MODE_A_TIMESTAMP

local TEXT_MODE_A_STRING_RESULT_OVERKILLING = TEXT_MODE_A_STRING_RESULT_OVERKILLING
local TEXT_MODE_A_STRING_RESULT_CRITICAL = TEXT_MODE_A_STRING_RESULT_CRITICAL
local TEXT_MODE_A_STRING_RESULT_GLANCING = TEXT_MODE_A_STRING_RESULT_GLANCING
local TEXT_MODE_A_STRING_RESULT_CRUSHING = TEXT_MODE_A_STRING_RESULT_CRUSHIN
]]

local Taunt = {
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

-- in rare cases some players have 8 as the Unit Type
local playerID = {
	[0] = true,
	[8] = true,
}

local extraSpellEvent = {
	SPELL_INTERRUPT = true,
	SPELL_DISPEL = true,
	SPELL_DISPEL_FAILED = true,
	SPELL_STOLEN = true,
	SPELL_AURA_BROKEN_SPELL = true,
}

local missType = {
	ABSORB = COMBAT_TEXT_ABSORB,
	BLOCK = COMBAT_TEXT_BLOCK,
	DEFLECT = COMBAT_TEXT_DEFLECT,
	DODGE = COMBAT_TEXT_DODGE,
	EVADE = COMBAT_TEXT_EVADE,
	IMMUNE = COMBAT_TEXT_IMMUNE,
	MISS = COMBAT_TEXT_MISS,
	PARRY = COMBAT_TEXT_PARRY,
	REFLECT = COMBAT_TEXT_REFLECT,
	RESIST = COMBAT_TEXT_RESIST,
}

local environmentalDamageType = {
	DROWNING = ACTION_ENVIRONMENTAL_DAMAGE_DROWNING,
	FALLING = ACTION_ENVIRONMENTAL_DAMAGE_FALLING,
	FATIGUE = ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE,
	FIRE = ACTION_ENVIRONMENTAL_DAMAGE_FIRE,
	LAVA = ACTION_ENVIRONMENTAL_DAMAGE_LAVA,
	SLIME = ACTION_ENVIRONMENTAL_DAMAGE_SLIME,
}

local damageEvent = {
	SWING_DAMAGE = true,
	RANGE_DAMAGE = true,
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
}

local healEvent = {
	SPELL_HEAL = true,
	SPELL_PERIODIC_HEAL = true,
}

local STRING_REACTION_ICON = {
	TEXT_MODE_A_STRING_SOURCE_ICON,
	TEXT_MODE_A_STRING_DEST_ICON,
}

	---------------------------
	--- Ace3 Initialization ---
	---------------------------

local appKey = {
	"KethoCombatLog_Main",
	"KethoCombatLog_Advanced",
	"KethoCombatLog_Spell",
	"KethoCombatLog_SpellExtra",
	"KethoCombatLog_LibSink",
	"KethoCombatLog_Profiles",
}

local appValue = {
	KethoCombatLog_Main = options.args.Main,
	KethoCombatLog_Advanced = options.args.Advanced,
	KethoCombatLog_Spell = options.args.Spell1,
	KethoCombatLog_SpellExtra = options.args.Spell2,
}

function KCL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("KethoCombatLogDB", S.defaults, true)
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
	self:RefreshDB()
	
	self.db.global.version = S.VERSION
	self.db.global.build = S.BUILD
	
	-- Parent
	local NAME2 = "Ketho CombatLog"
	ACR:RegisterOptionsTable("KethoCombatLog_Parent", options)
	ACD:AddToBlizOptions("KethoCombatLog_Parent", NAME2)
	
	-- LibSink
	options.args.libsink = self:GetSinkAce3OptionsDataTable()
	local libsink = options.args.libsink
	appValue.KethoCombatLog_LibSink = libsink
	libsink.order = 5
	libsink.name = "|TInterface\\Icons\\ability_priest_angelicfeather:16:16:0:0"..crop.."|t  "..libsink.name
	
	-- Profiles
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	appValue.KethoCombatLog_Profiles = profiles
	profiles.order = 6
	profiles.name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0"..crop.."|t  "..profiles.name
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME2)
	end
	
	ACD:SetDefaultSize("KethoCombatLog_Parent", 700, 600)
	
	for _, v in ipairs({"kcl", "ket", "ketho", "kethocombat", "kethocombatlog"}) do
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
			chatType = (instanceType == "raid" and GetNumGroupMembers() > 0) and "RAID" or ((instanceType == "party" or instanceType == "arena") and GetNumSubgroupMembers() > 0) and "PARTY"
		else
			chatType, channel = "CHANNEL", profile.chatChannel-4
		end
		
		if (profile.PvE and (instanceType == "party" or instanceType == "raid")) or
		(profile.PvP and (instanceType == "pvp" or instanceType == "arena")) or
		(profile.World and instanceType == "none" or not instanceType) then -- Scenario
			instanceTypeFilter = true
		else
			instanceTypeFilter = false
		end
	end, 3)
end

	--------------------------
	--- Callback Functions ---
	--------------------------

function KCL:RefreshDB()
	-- table reference lookup shortcuts
	profile, char = self.db.profile, self.db.char
	color, spell = profile.color, profile.spell
	
	self:RefreshDB1()
	
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
	crop = profile.iconCropped and ":64:64:4:60:4:60" or ""
	if profile.chatWindow > 1 then
		ChatFrame = _G["ChatFrame"..profile.chatWindow-1]
	end

	-- colors
	S.UnitColor = {
		self:Dec2Hex(unpack(color.Friendly)),
		self:Dec2Hex(unpack(color.Hostile)),
		self:Dec2Hex(unpack(color.Unknown)),
	}
	
	S.ClassColor = {
		WARRIOR = self:Dec2Hex(unpack(color.Warrior)), -- 1
		PALADIN = self:Dec2Hex(unpack(color.Paladin)), -- 2
		HUNTER = self:Dec2Hex(unpack(color.Hunter)), -- 3
		ROGUE = self:Dec2Hex(unpack(color.Rogue)), -- 4
		PRIEST = self:Dec2Hex(unpack(color.Priest)), -- 5
		DEATHKNIGHT = self:Dec2Hex(unpack(color.DeathKnight)), -- 6
		SHAMAN = self:Dec2Hex(unpack(color.Shaman)), -- 7
		MAGE = self:Dec2Hex(unpack(color.Mage)), -- 8
		WARLOCK = self:Dec2Hex(unpack(color.Warlock)), -- 9
		MONK = self:Dec2Hex(unpack(color.Monk)), -- 10
		DRUID = self:Dec2Hex(unpack(color.Druid)), -- 11
	}
	
	S.SpellSchoolColor = {
		[0x1] = self:Dec2Hex(unpack(color.Physical)),
		[0x2] = self:Dec2Hex(unpack(color.Holy)),
		[0x4] = self:Dec2Hex(unpack(color.Fire)),
		[0x8] = self:Dec2Hex(unpack(color.Nature)),
		[0x10] = self:Dec2Hex(unpack(color.Frost)),
		[0x20] = self:Dec2Hex(unpack(color.Shadow)),
		[0x40] = self:Dec2Hex(unpack(color.Arcane)),
	}

	S.EventColor = {
		TAUNT = self:Dec2Hex(unpack(color.Taunt)),
		INTERRUPT = self:Dec2Hex(unpack(color.Interrupt)),
		DISPEL = self:Dec2Hex(unpack(color.Dispel)),
		REFLECT = self:Dec2Hex(unpack(color.Reflect)),
		CROWDCONTROL = self:Dec2Hex(unpack(color.CrowdControl)),
		CC_BREAK = self:Dec2Hex(unpack(color.CC_Break)),
		DEATH = self:Dec2Hex(unpack(color.Death)),
		RESURRECTION = self:Dec2Hex(unpack(color.Resurrection)),
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
end

function KCL:OptionsDisabled()
	return not self:IsEnabled()
end

	----------------------
	--- Slash Commands ---
	----------------------

local enable = {
	["1"] = true,
	on = true,
	enable = true,
	load = true,
}

local disable = {
	["0"] = true,
	off = true,
	disable = true,
	unload = true,
}

function KCL:SlashCommand(input)
	if enable[input] then
		self:Enable()
		self:Print("|cffADFF2F"..VIDEO_OPTIONS_ENABLED.."|r")
	elseif disable[input] then
		self:Disable()
		self:Print("|cffFF2424"..VIDEO_OPTIONS_DISABLED.."|r")
	elseif input == "toggle" then
		self:SlashCommand(self:IsEnabled() and "0" or "1")
	else
		ACD:Open("KethoCombatLog_Parent")
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
	local str = S.SpellSchoolString[value] or STRING_SCHOOL_UNKNOWN.." ("..value..")"
	local color = S.SpellSchoolColor[value] or "71D5FF"
	return "|cff"..color..str.."|r", str, color
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

local function SpellInfo(spellID, spellName, spellSchool)
	local schoolNameLocal, schoolNameChat, schoolColor = SpellSchool(spellSchool)
	local spellIcon = iconSize>1 and "|T"..GetSpellIcon(spellID)..":"..iconSize..":"..iconSize..":0:0"..crop.."|t" or ""
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

local Time = time() 
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
			color = S.ClassColor[select(2,UnitClass(sourceName))]
		elseif sourceType == 0 and (sourceName == UnitName("target") or sourceName == UnitName("focus")) then
			if sourceName == UnitName("target") then
				color = S.ClassColor[select(2,UnitClass("target"))]
			elseif sourceName == UnitName("focus") then
				color = S.ClassColor[select(2,UnitClass("focus"))]
			end
		else
			color = S.UnitColor[sourceReaction]
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
			color = S.ClassColor[select(2,UnitClass(destName))]
		elseif destType == 0 and (destName == UnitName("target") or destName == UnitName("focus")) then
			if destName == UnitName("target") then
				color = S.ClassColor[select(2,UnitClass("target"))]
			elseif destName == UnitName("focus") then
				color = S.ClassColor[select(2,UnitClass("focus"))]
			end
		else
			color = S.UnitColor[destReaction]
		end
		destUnitLocal = format("|cff%s"..TEXT_MODE_A_STRING_DEST_UNIT.."|r", color, destIconLocal, destGUID, "["..destNameTrim.."]", "["..(destName==sourceName and "Self" or name).."]")
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
	
	-- throttle
	if Time > (cd.time or 0) then
		Time = time() 
		cd.time = Time + 0.1
	end
	
	---------------------
	--- Damage String ---
	---------------------

	local resultStringLocal, resultStringChat = "", ""
	if isDamageEvent or healEvent[subevent] then
		if subevent == "SWING_DAMAGE" then
			schoolNameLocal = "|cff"..S.SpellSchoolColor[0x1]..ACTION_SWING.."|r"
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
				textLocal = profile.Death and destUnitLocal.." |cff"..S.EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..sourceUnitLocal..spellLinkLocal
				textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat..spellLinkChat
			-- Environmental Deaths; problem: the overkill parameter is always stuck on zero
			elseif subevent == "ENVIRONMENTAL_DAMAGE" then
				local environmentalType, SuffixParam1, _, SuffixParam3 = select(12, ...)
				if UnitHealth(destName) and UnitHealth(destName) == 1 then
					textLocal = profile.Death and destUnitLocal.." |cff"..S.EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..SuffixParam1.." "..(environmentalDamageType[environmentalType] or environmentalType)
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..SuffixParam1.." "..(environmentalDamageType[environmentalType] or environmentalType)
				end
			elseif isDamageEvent and SuffixParam2 > 0 and (Time > (cd.death or 0) or destName ~= lastDeath) then
				cd.death = Time + 0.2; lastDeath = destName
				if subevent == "SWING_DAMAGE" then
					textLocal = profile.Death and destUnitLocal.." |cff"..S.EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..sourceUnitLocal
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat
				else
					textLocal = profile.Death and destUnitLocal.." |cff"..S.EventColor["DEATH"]..ACTION_UNIT_DIED.."|r "..sourceUnitLocal..spellLinkLocal
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat..spellLinkChat
				end
			end
		end
		-- Taunts
		if profile.Taunt or profile.ChatTaunt then
			if TankFilter(isTank, "Taunt") then
				if subevent == "SPELL_AURA_APPLIED" and destType >= 3 and Taunt[spellID] then
					textLocal = sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["TAUNT"].."taunted|r "..destUnitLocal
					textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." taunted "..destUnitChat
				elseif subevent == "SPELL_CAST_SUCCESS" and (spellID == 1161 or spellID == 5209) then
					textLocal = profile.Taunt and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["TAUNT"].."AoE "..GetSpellInfo(355).."|r"
					textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." AoE "..GetSpellInfo(355)
				end
			end
			-- Pet 2649[Growl], Voidwalker 3716[Torment], Greater Earth Elemental 36213[Angered Earth]
			if subevent == "SPELL_CAST_SUCCESS" and profile.PetGrowl and destType >= 3 and (spellID == 2649 or spellID == 3716 or spellID == 36213) then
				textLocal = profile.Taunt and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["TAUNT"].."growled|r "..destUnitLocal
				textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." growled "..destUnitChat
			end
		end
		-- CC Breaker
		if (profile.CC_Break or profile.ChatCC_Break) and TankFilter(isTank, "Break") then
			-- broken by a spell
			if subevent == "SPELL_AURA_BROKEN_SPELL" then
				textLocal = profile.CC_Break and sourceUnitLocal..extraSpellLinkLocal.." |cff"..S.EventColor["CC_BREAK"]..ACTION_SPELL_AURA_BROKEN.."|r "..spellLinkLocal.." on "..destUnitLocal
				textChat = ChatFilter("CC_Break") and sourceUnitChat..extraSpellLinkChat.." "..ACTION_SPELL_AURA_BROKEN.." "..spellLinkChat.." on "..destUnitChat
			-- not broken by a spell; this subevent does not seem to fire for CLEU; 4.0.1 bug?
			elseif subevent == "SPELL_AURA_BROKEN" then
				if sourceName then
					textLocal = profile.CC_Break and sourceUnitLocal.." |cff"..S.EventColor["CC_BREAK"]..ACTION_SPELL_AURA_BROKEN.."|r "..spellLinkLocal.." on "..destUnitLocal
					textChat = ChatFilter("CC_Break") and sourceUnitChat.." "..ACTION_SPELL_AURA_BROKEN.." "..spellLinkChat.." on "..destUnitChat
				else
					textLocal = profile.CC_Break and spellLinkLocal.." on "..destUnitLocal.." |cff"..S.EventColor["CC_BREAK"].."broken|r"
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
				textLocal = profile.Dispel and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["DISPEL"]..dispelString.."|r "..destUnitLocal..extraSpellLinkLocal
				textChat = ChatFilter("Dispel") and sourceUnitChat..spellLinkChat.." "..dispelString.." "..destUnitChat..extraSpellLinkChat
			end
		elseif subevent == "SPELL_STOLEN" then
			textLocal = profile.Dispel and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["DISPEL"]..ACTION_SPELL_STOLEN.."|r "..destUnitLocal..extraSpellLinkLocal
			textChat = ChatFilter("Dispel") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_STOLEN.." "..destUnitChat..extraSpellLinkChat
		-- Reflects / Misses
		elseif subevent == "SPELL_MISSED" then
			if SuffixParam1 == "REFLECT" then
				textLocal = profile.Reflect and destUnitLocal.." |cff"..S.EventColor["REFLECT"]..ACTION_SPELL_MISSED_REFLECT.."|r "..sourceUnitLocal..spellLinkLocal
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
				textLocal = sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["RESURRECTION"].."healed "..destUnitLocal
			end
			if ChatFilter("Death") and ChatFilter("DeathPrevent") then
				textChat = sourceUnitChat..spellLinkChat.." healed "..destUnitChat..spellLinkChat
			end
		-- Resurrections
		elseif subevent == "SPELL_RESURRECT" then
			if not profile.BattleRez or (profile.BattleRez and UnitAffectingCombat("player")) then
				textLocal = profile.Resurrection and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["RESURRECTION"]..ACTION_SPELL_RESURRECT.."|r "..destUnitLocal
				textChat = ChatFilter("Resurrection") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_RESURRECT.." "..destUnitChat
			end
		-- Crowd Control
		elseif subevent == "SPELL_AURA_APPLIED" and CrowdControl[spellID] then
			textLocal = profile.CrowdControl and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["CROWDCONTROL"].."CC'ed|r "..destUnitLocal
			textChat = ChatFilter("CrowdControl") and sourceUnitChat..spellLinkChat.." CC'ed "..destUnitChat
		-- "pre-Interrupts"
		elseif subevent == "SPELL_CAST_SUCCESS" and Interrupt[spellID] then
			self:IneffectiveInterrupt(...)
		-- Interrupts
		elseif subevent == "SPELL_INTERRUPT" then
			textLocal = profile.Interrupt and sourceUnitLocal..spellLinkLocal.." |cff"..S.EventColor["INTERRUPT"]..ACTION_SPELL_INTERRUPT.."|r "..destUnitLocal..extraSpellLinkLocal
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