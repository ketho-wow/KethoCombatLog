local NAME, S = ...
local KCL = KethoCombatLog

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L
local player = S.player
local options = S.options

local profile, char
local color

-- stuff gets called a lot in CLEU addons
local _G = _G
local tonumber = tonumber
local select, unpack = select, unpack
local time = time
local strsub, strmatch = strsub, strmatch
local strsplit = strsplit
local format, gsub, gmatch = format, gsub, gmatch
local wipe, table_maxn = wipe, table.maxn
local bit_band = bit.band

local UnitGUID = UnitGUID
local GetSpellInfo, GetSpellLink = GetSpellInfo, GetSpellLink
local GetPlayerInfoByGUID = GetPlayerInfoByGUID

local UnitAffectingCombat = UnitAffectingCombat
local UnitHealth = UnitHealth
local UnitIsVisible = UnitIsVisible
local UnitIsDead, UnitIsDeadOrGhost = UnitIsDead, UnitIsDeadOrGhost

local AbbreviateLargeNumbers = AbbreviateLargeNumbers

local COMBATLOG_OBJECT_RAIDTARGET_MASK = COMBATLOG_OBJECT_RAIDTARGET_MASK
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local TEXT_MODE_A_TIMESTAMP = TEXT_MODE_A_TIMESTAMP
local TEXT_MODE_A_STRING_SOURCE_UNIT = TEXT_MODE_A_STRING_SOURCE_UNIT
local TEXT_MODE_A_STRING_DEST_UNIT = TEXT_MODE_A_STRING_DEST_UNIT
local TEXT_MODE_A_STRING_SPELL = TEXT_MODE_A_STRING_SPELL
local TEXT_MODE_A_STRING_RESULT_OVERKILLING = gsub(TEXT_MODE_A_STRING_RESULT_OVERKILLING, "%%d", "%%s")
local TEXT_MODE_A_STRING_RESULT_CRITICAL = TEXT_MODE_A_STRING_RESULT_CRITICAL
local TEXT_MODE_A_STRING_RESULT_GLANCING = TEXT_MODE_A_STRING_RESULT_GLANCING
local TEXT_MODE_A_STRING_RESULT_CRUSHING = TEXT_MODE_A_STRING_RESULT_CRUSHING

-- users are free to change this
local latencyThreshold = 1 -- only accept damage that occured within a x seconds time frame before death
local deviation = .02 -- approximation precision for selfres health delta

local death = {
	time = {}, -- unit guids from the UNIT_DIED event; number: timestamp
	overkill = {}, -- unit guids that supposedly died from overkill; table: cleu event
	damage = {}, -- unit guids with their last known dmg event; table: cleu event
	deleted = {}, -- unit guids that got cleaved by High Overlord Saurfang; boolean
	
	cheater = {}, -- unit guids that are cheating death; cleu event
	whosyourdaddy = {}, -- cheaters get to skip the delta check; boolean
}

-- reincarnation never actually shows up in CLEU
local Reincarnation = {20608, GetSpellInfo(20608), 8}

local selfres = {
	soulstone = {}, -- Warlock Soulstone
	soulstone_source = {}, -- merge source args for the original Soulstone caster
	reincarnation = {}, -- Shaman Reincarnation
	
	prevHealth = {}, -- compare to current health for delta
	wasDead = {}, -- double confirm unit was actually dead before selfres
}

local interrupt = {} -- track if interrupts were successful or wasted/juked

local spell = { -- lookup table for currently enabled custom spells
	CAST_START = {},
	CAST_SUCCESS = {},
	AURA_APPLIED = {},
	CREATE = {},
	SUMMON = {},
}

local args = {}
local braces = "[%[%]]"
local white = {1, 1, 1}

local chatType
local isBattleground

	--------------
	--- # Ace3 ---
	--------------

local appKey = {
	"KethoCombatLog_Main",
	"KethoCombatLog_Advanced",
	"KethoCombatLog_Profiles",
}

local appValue = {
	KethoCombatLog_Main = options.args.Main,
	KethoCombatLog_Advanced = options.args.Advanced,
}

function KCL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("KethoCombatLogDB", S.defaults, true)
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
	self:RefreshDB()
	
	self.db.global.version = S.VERSION
	self.db.global.build = S.BUILD
	
	-- parent options table
	ACR:RegisterOptionsTable("KethoCombatLog_Parent", options)
	ACD:AddToBlizOptions("KethoCombatLog_Parent", NAME)
	
	-- profiles
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	appValue.KethoCombatLog_Profiles = profiles
	profiles.order = 6
	profiles.name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:-1"..S.crop.."|t  "..profiles.name
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME)
	end
	
	ACD:SetDefaultSize("KethoCombatLog_Parent", 700, 600)
	
	-- slash command
	for _, v in ipairs({"kcl", "ket", "ketho", "kethocombat", "kethocombatlog"}) do
		self:RegisterChatCommand(v, "SlashCommand")
	end
end

function KCL:OnEnable()
	-- controls COMBAT_LOG_EVENT_UNFILTERED
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:ZONE_CHANGED_NEW_AREA()
	
	-- controls chatType
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:GROUP_ROSTER_UPDATE()
	
	-- support [Class Colors] by Phanx
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback("WipeCache", self)
	end
end

function KCL:OnDisable()
	-- maybe superfluous
	self:UnregisterAllEvents()
	
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:UnregisterCallback("WipeCache", self)
	end
end

function KCL:RefreshDB()
	-- table shortcuts
	profile, char = self.db.profile, self.db.char
	color = profile.color
	
	for i = 1, 2 do -- refresh db in other files
		self["RefreshDB"..i](self)
	end
	self:WipeCache() -- wipe metatables
	self:SetSinkStorage(profile) -- LibSink
	self:RefreshEvent() -- options dependent event
	self:RefreshSpell() -- options dependent spells lookup
	
	-- other
	S.crop = profile.IconCropped and ":64:64:4:60:4:60" or ""
	if profile.ChatWindow > 1 then
		S.ChatFrame = _G["ChatFrame"..profile.ChatWindow-1]
	end
end

-- (un)register according to options
function KCL:RefreshEvent()
	-- for efficiency, RegisterUnitEvent came to mind, but it doesnt fit in with Ace3
	-- it would also only take unit ids, and for some reason, not names
	-- unit ids are kinda hard to get from CLEU and they can change
	local isHealth = (profile.LocalResurrect or profile.ChatResurrect)
	self[isHealth and "RegisterEvent" or "UnregisterEvent"](self, "UNIT_HEALTH")
end

function KCL:RefreshSpell(option)
	if option then
		for k, v in pairs(S.Spell[option]) do
			spell[v][k] = profile[option] and true
		end
	else
		for k1, v1 in pairs(S.Spell) do
			for k2, v2 in pairs(v1) do
				spell[v2][k2] = profile[k1] and true
			end
		end
	end
end

	---------------------
	--- Slash Command ---
	---------------------

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

	--------------
	--- Events ---
	--------------

-- Blizzard CombatLog is Load-on-Demand
function KCL:ADDON_LOADED(event, addon)
	if addon == "Blizzard_CombatLog" and not profile.BlizzardCombatLog then
		COMBATLOG:UnregisterEvent("COMBAT_LOG_EVENT")
		self:UnregisterEvent(addon)
	end
end

function KCL:ZONE_CHANGED_NEW_AREA(event)
	local _, instanceType = IsInInstance()
	
	local pve = profile.PvE and S.PvE[instanceType]
	local pvp = profile.PvP and S.PvP[instanceType]
	local world = profile.World and instanceType == "none"
	isBattleground = (instanceType == "pvp")
	
	self[(pve or pvp or world) and "RegisterEvent" or "UnregisterEvent"](self, "COMBAT_LOG_EVENT_UNFILTERED")
end

function KCL:GROUP_ROSTER_UPDATE(event)
	local p = profile.ChatChannel
	
	if p == 2 then
		chatType = "SAY"
	elseif p == 3 then
		chatType = "YELL"
	elseif p == 4 then
		-- battleground chat is filtered during the output
		local isInstance = IsInRaid(LE_PARTY_CATEGORY_INSTANCE) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
		chatType = isInstance and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY"
	elseif p >= 5 then
		chatType = "CHANNEL"
	end
end

	----------------
	--- Reaction ---
	----------------

local function UnitReaction(flags)
	if bit_band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
		return "Friendly"
	elseif bit_band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
		return "Hostile"
	else
		return "Unknown"
	end
end

	-------------------
	--- Raid Target ---
	-------------------

local function UnitIcon(unitFlags, reaction)
	local raidTarget = bit_band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
	if raidTarget == 0 then return "", "" end
	
	local i = S.COMBATLOG_OBJECT_RAIDTARGET[raidTarget]
	local icon = _G["COMBATLOG_ICON_RAIDTARGET"..i]
	local iconString = format(S.STRING_REACTION_ICON[reaction], raidTarget, icon)
	local chat = "{"..strlower(_G["RAID_TARGET_"..i]).."}"
	return iconString, chat
end

	-------------
	--- Class ---
	-------------

-- only need to look up an units class once
local GetPlayerClass = setmetatable({}, {__index = function(t, k)
	local _, v = GetPlayerInfoByGUID(k)
	rawset(t, k, v)
	return v
end})

	-------------
	--- Spell ---
	-------------

local GetSpellSchool = setmetatable({}, {__index = function(t, k)
	local str = S.SpellSchoolString[k] or STRING_SCHOOL_UNKNOWN
	local color = S.SpellSchoolColor[k]
	local v = {"|cff"..color..str.."|r", str, color}
	rawset(t, k, v)
	return v
end})

local GetSpellIcon = setmetatable({}, {__index = function(t, k)
	-- since 7.2 some spells dont return an icon
	local v = select(3, GetSpellInfo(k)) or 134400 -- "INV_MISC_QUESTIONMARK"
	rawset(t, k, v)
	return v
end})

local _GetSpellLink = setmetatable({}, {__index = function(t, k)
	local v = GetSpellLink(k)
	rawset(t, k, v)
	return v
end})

local function _GetSpellInfo(spellID, spellName, spellSchool)
	local schoolNameLocal, schoolNameChat, schoolColor = unpack(GetSpellSchool[spellSchool])
	local iconSize = profile.IconSize
	local spellIcon = iconSize>1 and format("|T%s:%s:%s:0:0%s|t", GetSpellIcon[spellID], iconSize, iconSize, S.crop) or ""
	local spellLinkLocal = format("|cff%s"..TEXT_MODE_A_STRING_SPELL.."|r", schoolColor, spellID, 0, "", "["..spellName.."]")
	return schoolNameLocal, schoolNameChat, spellLinkLocal..spellIcon, _GetSpellLink[spellID]
end

	--------------
	--- Result ---
	--------------

local function GetResultString(overkill, critical, glancing, crushing)
	local str = ""

	-- overkill can be -1 instead of nil
	if overkill and overkill > 0 and profile.OverkillFormat then
		overkill = profile.AbbreviateNumbers and AbbreviateLargeNumbers(overkill) or overkill
		str = str.." "..format(TEXT_MODE_A_STRING_RESULT_OVERKILLING, overkill)
	end
	if critical and profile.CriticalFormat then
		str = str.." "..TEXT_MODE_A_STRING_RESULT_CRITICAL
	end
	if glancing and profile.GlancingFormat then
		str = str.." "..TEXT_MODE_A_STRING_RESULT_GLANCING 
	end
	if crushing and profile.CrushingFormat then
		str = str.." "..TEXT_MODE_A_STRING_RESULT_CRUSHING 
	end
	
	return str
end

	--------------
	--- Filter ---
	--------------

local function IsOption(event)
	return profile["Local"..event] or profile["Chat"..event]
end

local function TankFilter(event, unit)
	return profile["Tank"..event] or not (UnitGroupRolesAssigned(unit) == "TANK")
end

-- it might be the player is in a bg/arena vs the enemy faction
-- then check if the player is in combat instead; its really not foolproof though
local function UnitInCombat(name)
	return UnitAffectingCombat(name) or UnitAffectingCombat("player")
end

	------------
	--- Args ---
	------------

local function SetMessage(msgtype)
	args.msg = profile.message[msgtype]
	local group = S.EventGroup[msgtype] or msgtype -- fallback
	args.color = color[group]
	args["local"] = profile["Local"..group]
	args.chat = profile[(profile.ChatFilter and "Chat" or "Local")..group]
end

-- only append x for these chatargs
local ChatArgs = {
	src = true,
	dest = true,
	spell = true,
	xspell = true,
	school = true,
	xschool = true,
}

local function ReplaceArgs(args, isChat)
	local msg = args.msg
	for k in gmatch(msg, "%b<>") do
		-- remove <>, make case insensitive
		local s = strlower(gsub(k, "[<>]", ""))
		-- escape special characters
		s = gsub(args[isChat and ChatArgs[s] and s.."x" or s] or "", "(%p)", "%%%1")
		k = gsub(k, "(%p)", "%%%1")
		msg = msg:gsub(k, s)
	end
	msg = msg:gsub("  ", " ") -- remove double spaces
	msg = msg:trim() -- remove leading whitespace
	return msg
end

-- its either higher cpu load, or flipping tables all over the place :x
local function RecycleTable(t, ...)
	t = t or {}
	wipe(t) -- purge old values
	for i = 1, select("#", ...) do
		t[i] = select(i, ...)
	end
	return t
end

-- for gettings selfres args in a more useful order
local function SwitchSourceDest(cleu)
	local t = {}
	for i = 1, 4 do
		t[i] = cleu[i+4]
	end
	for i = 1, 4 do
		cleu[i+4] = cleu[i+8]
	end
	for i = 1, 4 do
		cleu[i+8] = t[i]
	end
end

	--------------
	--- # CLEU ---
	--------------

function KCL:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	
	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	
	wipe(args)
	
	local sourceType = strsplit("-", sourceGUID)
	local destType = strsplit("-", destGUID)
	local sourcePlayer = (sourceType == "Player")
	local destPlayer = (destType == "Player")
	
	-- exceptions to the filter
	local petspell, _, _, miss = select(12, ...)
	local isMissEvent = (S.MissEvent[subevent] and S.MissType[miss])
	local isReverseEvent = S.DamageEvent[subevent] or isMissEvent or subevent == "UNIT_DIED"
	-- pets are not players but we still want to see when they do anything important
	local isPet = S.PetTaunt[petspell] or S.PetInterrupt[petspell]
	
	--------------
	--- Filter ---
	--------------
	
	if sourceGUID == player.guid or destGUID == player.guid then
		if not profile.FilterSelf then return end
	else
		if not profile.FilterOther then return end
	end
	
	-- the other way round for death/reflect events
	if (not isReverseEvent and (sourcePlayer or isPet)) or (isReverseEvent and destPlayer) then
		if not profile.FilterPlayers then return end
	else
		if not profile.FilterMonsters then return end
	end
	
	--------------
	--- Suffix ---
	--------------
	
	local spellID, spellName, spellSchool
	local SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9
	
	local prefix = strsub(subevent, 1, 5)
	if prefix == "SWING" then
		SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
		args.amount = SuffixParam1
	elseif S.SpellPrefix[prefix] then
		-- not sure what happened here in WoD; two same dest units apparently
		if subevent == "SPELL_ABSORBED" then return end
		
		spellID, spellName, spellSchool, SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
		args.amount = SuffixParam1
		
	-------------
	--- Spell ---
	-------------
		
		args.school, args.schoolx, args.spell, args.spellx = _GetSpellInfo(spellID, spellName, spellSchool)
		
		if S.ExtraSpellEvent[subevent] then
			args.xschool, args.xschoolx, args.xspell, args.xspellx = _GetSpellInfo(SuffixParam1, SuffixParam2, SuffixParam3)
		end
	end
	
	-------------
	--- Death ---
	-------------
	
	local delta = (death.time[destGUID] or 0) - timestamp
	local isDeath = (delta>=0 and delta<latencyThreshold) or death.whosyourdaddy[destGUID]
	
	if S.DamageEvent[subevent] then
		if not IsOption("Death") then return end
		
		if isDeath then
			if subevent == "ENVIRONMENTAL_DAMAGE" then
				local environmentalType, amount, _, _, _, _, absorb = select(12, ...)
				if not destName then return end -- sometimes destName is nil
				args.amount = (amount == 0) and absorb or amount -- fix holy priest fatal absorb
				args.type = S.EnvironmentalDamageType[environmentalType] or environmentalType
				SetMessage("Death_Environmental")
			else
				SetMessage(subevent == "SWING_DAMAGE" and "Death_Melee" or "Death")
			end
		else
			-- ignore damage on Death Knight [Purgatory]; Amount is greater than Overkill by exactly 1
			if SuffixParam1 and SuffixParam2 and SuffixParam1-SuffixParam2 == 1 then return end
			-- store last overkill/normal damage event
			death.damage[destGUID] = RecycleTable(death.damage[destGUID], event, ...)
			if SuffixParam2 and SuffixParam2 > 0 then
				death.overkill[destGUID] = RecycleTable(death.overkill[destGUID], event, ...)
			end
		end
	
	-- only announce death after UNIT_DIED fired, since the overkill parameter sometimes gives false positives/negatives
	elseif subevent == "UNIT_DIED" then
		if not IsOption("Death") then return end
		
		-- death handling
		self:ShowDeath(destGUID, timestamp)
		
		-- store cleu event for if the unit possibly resurrects itself; very hacky
		-- soulstone has precedence over reincarnation when cast on a shaman
		if selfres.soulstone_source[destGUID] then -- confirm unit death with soulstone active
			selfres.soulstone[destGUID] = {event, ...}
			selfres.soulstone[destGUID][3] = "SPELL_RESURRECT_SELF"
			for i = 5, 8 do
				selfres.soulstone[destGUID][i] = selfres.soulstone_source[destGUID][i-4] -- copy source
			end
			for i = 13, 15 do
				selfres.soulstone[destGUID][i] = selfres.soulstone_source[destGUID][i-8] -- copy spell
			end
			SwitchSourceDest(selfres.soulstone[destGUID]) -- switch source and dest because if used on self it shows "[Self] used [Player][Soulstone]"
		elseif GetPlayerClass[destGUID] == "SHAMAN" then -- possible reincarnation active
			selfres.reincarnation[destGUID] = {event, ...}
			selfres.reincarnation[destGUID][3] = "SPELL_RESURRECT_SELF"
			for i, v in ipairs(Reincarnation) do
				selfres.reincarnation[destGUID][i+12] = v -- copy spell
			end
			SwitchSourceDest(selfres.reincarnation[destGUID])
		end
		
		return -- avoid double messages (the args from re-fired CLEU werent wiped)
	
	-- SPELL_INSTAKILL can fire on the same OnUpdate as UNIT_DIED, not sure if it can also fire later
	elseif subevent == "SPELL_INSTAKILL" then
		if IsOption("Death") and not S.Blacklist[spellID] then
			SetMessage("Death_Instakill")
			death.deleted[destGUID] = true -- dont announce death a second time
		end
	
	------------
	--- Miss ---
	------------
	
	elseif S.MissEvent[subevent] then
		-- (fatal) absorb event that still counts as damage
		if SuffixParam1 == "ABSORB" then
			if not IsOption("Death") then return end
			if isDeath then
				args.amount = SuffixParam3
				SetMessage("Death")
			else
				death.damage[destGUID] = RecycleTable(death.damage[destGUID], event, ...)
			end
		elseif SuffixParam1 == "REFLECT" then
			if IsOption("Reflect") then
				SetMessage("Reflect")
			end
		else
			local taunt = S.Taunt[spellID] and IsOption("Taunt") 
			local int = S.Interrupt[spellID] and IsOption("Interrupt")
			local cc = S.CrowdControl[spellID] and IsOption("CrowdControl")
			if (taunt or int or cc) and not S.Blacklist[spellID] then
				args.type = S.MissType[SuffixParam1] or SuffixParam1
				SetMessage("Miss")
			end
			-- check if the interrupt failed, instead of being wasted
			if S.Interrupt[spellID] and IsOption("Juke") then
				interrupt[sourceGUID] = false -- failed interrupt
			end
		end
	
	-----------------
	--- Interrupt ---
	-----------------
	
	elseif subevent == "SPELL_CAST_SUCCESS" then
		if S.Interrupt[spellID] and IsOption("Juke") then
			interrupt[sourceGUID] = true -- casted interrupt
			
			S.Timer:New(function()
				if interrupt[sourceGUID] then -- wasted interrupt
					-- need to fire another event since we are now delayed
					self:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, "SPELL_INTERRUPT_WASTED", hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
				end
				interrupt[sourceGUID] = false
			end, .5) -- wait for SPELL_INTERRUPT delay/lag
		end
	
	-- show any and all interrupts
	elseif subevent == "SPELL_INTERRUPT" then
		if IsOption("Interrupt") then
			SetMessage("Interrupt")
		end
		if S.Interrupt[spellID] and IsOption("Juke") then
			interrupt[sourceGUID] = false -- succesful interrupt
		end
	
	elseif subevent == "SPELL_INTERRUPT_WASTED" then
		SetMessage("Juke")
	
	------------
	--- Aura ---
	------------
	
	elseif subevent == "SPELL_AURA_APPLIED" then
		local isTaunt = S.Taunt[spellID] or (S.PetTaunt[spellID] and profile.PetTaunt)
		local destNPC = (destType == "Creature")
		if isTaunt and IsOption("Taunt") and destNPC and TankFilter("Taunt", sourceName) then
			-- guardian is also a npc; hunter pets auto casting taunts on dummies when measuring dps
			local isGuardian = bit_band(destFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0
			local isTrainingDummy = S.TrainingDummy[tonumber((select(6,strsplit("-", destGUID))))]
			if S.PetTaunt[spellID] and (isGuardian or isTrainingDummy) then return end
			SetMessage("Taunt")
		
		-- fatal events can sometimes also happen right after e.g. the SPELL_AURA_APPLIED event
		-- a single OnUpdate iteration later is enough to include those events as well		
		
		-- Holy Priest 27827 [Spirit of Redemption] fix
		elseif spellID == 27827 and IsOption("Death") then
			S.Timer:New(function() self:ShowDeath(destGUID, timestamp) return end, 0)
		-- Death Knight 116888 [Shroud of Purgatory], Mage 87023 [Cauterized] fix
		elseif (spellID == 116888 or spellID == 87023) and IsOption("Death") then
			local dkmagedeath = death.overkill[destGUID] or death.damage[destGUID]
			if dkmagedeath then -- sanity check so CopyTable doesnt choke on empty tables
				S.Timer:New(function() if dkmagedeath then death.cheater[destGUID] = CopyTable(dkmagedeath) end end, 0)
			end
		elseif S.CrowdControl[spellID] and IsOption("CrowdControl") then
			-- 605 Priest [Dominate Mind] fix; applied to both the dest unit and source unit
			if spellID == 605 and destGUID == sourceGUID then return end
			SetMessage("CrowdControl")
		end
	
	elseif subevent == "SPELL_AURA_REMOVED" then
		-- Soulstone
		if spellID == 20707 and IsOption("Resurrect") then
			-- this actually sometimes seems to fire after UNIT_DIED; not sure what to do about it...
			-- possible soulstone active; store source and use that as a flag
			selfres.soulstone_source[destGUID] = {sourceGUID, sourceName, sourceFlags, sourceRaidFlags, spellID, spellName, spellSchool}
			S.Timer:New(function()
				if not selfres.soulstone[destGUID] then
					selfres.soulstone_source[destGUID] = nil -- the unit didnt die yet, so the soulstone must have expired instead
				end
			end, 1)
		-- [Shroud of Purgatory], [Cauterized]
		elseif (spellID == 116888 or spellID == 87023) and IsOption("Death") then
			S.Timer:New(function() death.cheater[destGUID] = nil end, 1) -- in case of survival
		end
	
	elseif subevent == "SPELL_AURA_BROKEN" then
		-- track only for broken crowd control spells
		if IsOption("Break") and S.CrowdControl[spellID] then
			SetMessage(sourceName and "Break" or "Break_NoSource")
		end
	
	elseif subevent == "SPELL_AURA_BROKEN_SPELL" then
		if IsOption("Break") and S.CrowdControl[spellID] then
			SetMessage("Break_Spell")
		end
	
	--------------
	--- Dispel ---
	--------------
	
	elseif subevent == "SPELL_DISPEL" then
		if not IsOption("Dispel") then return end
		
		local sourceReaction = UnitReaction(sourceFlags)
		local destReaction = UnitReaction(destFlags)
		local friendly = (sourceReaction == "Friendly" and destReaction == sourceReaction)
		local hostile = (sourceReaction == "Hostile" and destReaction == sourceReaction)
		-- cleanses between two (friendly/hostile) units
		-- bug: its not possible to see whether 2 friendly units are hostile to each other, e.g. dueling
		if friendly or hostile then
			if profile.FriendlyDispel then
				SetMessage("Cleanse")
			end
		else
			if profile.HostileDispel then
				SetMessage("Dispel")
			end
		end
	
	elseif subevent == "SPELL_STOLEN" then
		if IsOption("Dispel") and profile.Spellsteal then
			SetMessage("Spellsteal")
		end
	
	-----------------
	--- Resurrect ---
	-----------------
	
	elseif subevent == "SPELL_RESURRECT" then
		if IsOption("Resurrect") and (not profile.CombatRes or UnitInCombat(sourceName)) then
			SetMessage("Resurrect")
		end
		-- reset self res data; combat res (60%) can be confused with Soulstone
		-- (which is technically also a combat res)
		for k in pairs(selfres) do
			selfres[k][destGUID] = nil
		end		
	
	elseif subevent == "SPELL_RESURRECT_SELF" then
		SetMessage(S.SelfResRemap[spellID])
	end
	
	--------------------
	--- Custom Spell ---
	--------------------
	
	local suffix = strmatch(subevent, "SPELL_(.+)")
	if spell[suffix] and spell[suffix][spellID] then -- kinda ugly part
		local noDest = (S.SpellRemap[suffix] == "CAST_SUCCESS" and (not destName or S.SpellSummon[suffix])) and "_NO_DEST" or ""
		if sourceGUID == player.guid then
			if profile.SpellFilterSelf then return end
			args.msg = S.SpellMsg.player[S.SpellRemap[suffix]..noDest]
		else -- check whether or not there is a dest unit; dont show superfluous dest unit for SUMMON and CREATE suffix
			args.msg = profile.message[S.SpellRemap[suffix]..noDest]
		end
		args.color = white
		args["local"] = bit_band(profile.SpellOutput, 0x1) > 0
		args.chat = bit_band(profile.SpellOutput, 0x2) > 0
	end
	
	---------------
	--- Message ---
	---------------
	
	-- check if there is any message
	if not args.msg then return end
	
	------------
	--- Unit ---
	------------
	
	if sourceName then -- if no unit, then guid is an empty string and name is nil
		-- trim out (CRZ) realm name; only do this for players
		local name = (sourcePlayer and profile.TrimRealm) and strmatch(sourceName, "(.+)%-.+") or sourceName
		local fname = (sourceGUID == player.guid) and UNIT_YOU_SOURCE or name
		local sourceIconLocal, sourceIconChat = UnitIcon(sourceRaidFlags, 1)
		local sourceReaction = UnitReaction(sourceFlags)
		local color = S.GeneralColor[sourceReaction] -- sometimes early on GetPlayerClass returns nil so we do this first
		if sourcePlayer and (profile.ColorEnemyPlayers or sourceReaction == "Friendly") then
			color = S.ClassColor[GetPlayerClass[sourceGUID]]
		end
		
		args.src = format("|cff%s"..TEXT_MODE_A_STRING_SOURCE_UNIT.."|r", color, sourceIconLocal, sourceGUID, sourceName, "["..fname.."]")
		args.srcx = format("%s[%s]", sourceIconChat, name)
	end
	
	if destName then
		local isSelf = (destGUID == sourceGUID) and not isReverseEvent -- avoid "[Self] died from [Player][Spell]" if a unit died by its own damage
		local name = isSelf and L.SELF or (destPlayer and profile.TrimRealm) and strmatch(destName, "(.+)%-.+") or destName
		local fname = (destGUID == player.guid) and UNIT_YOU_DEST or name
		local destIconLocal, destIconChat = UnitIcon(destRaidFlags, 2)
		local destReaction = UnitReaction(destFlags)
		local color = S.GeneralColor[destReaction] 
		if destPlayer and (profile.ColorEnemyPlayers or destReaction == "Friendly") then
			color = S.ClassColor[GetPlayerClass[destGUID]]
		end
		
		args.dest = format("|cff%s"..TEXT_MODE_A_STRING_DEST_UNIT.."|r", color, destIconLocal, destGUID, destName, "["..fname.."]")
		args.destx = format("%s[%s]", destIconChat, name)
	end
	
	-- timestamp
	local stamplocal, stampchat = S.GetTimestamp()
	
	-- remove braces again
	if not profile.UnitBracesLocal then
		-- src and dest args can be nil in rare cases
		args.src = args.src and args.src:gsub(braces, "")
		args.dest = args.dest and args.dest:gsub(braces, "")
		-- spell strings can be nil
		args.spell = args.spell and args.spell:gsub(braces, " ")
		args.xspell = args.xspell and args.xspell:gsub(braces, " ")
	end
	if not profile.UnitBracesChat then
		args.srcx = args.srcx and args.srcx:gsub(braces, "")
		args.destx = args.destx and args.destx:gsub(braces, "")
	end
	
	-- abbreviate numbers
	if args.amount and type(args.amount) == "number" and profile.AbbreviateNumbers then
		args.amount = AbbreviateLargeNumbers(args.amount)
	end
	
	local resultString = (S.DamageEvent[subevent] or S.HealEvent[subevent]) and GetResultString(SuffixParam2, SuffixParam7, SuffixParam8, SuffixParam9) or ""
	
	local textLocal = stamplocal..ReplaceArgs(args)..resultString
	local textChat = stampchat..ReplaceArgs(args, true)..resultString
	
	--------------
	--- Output ---
	--------------
	
	if args["local"] then
		if profile.ChatWindow > 1 then
			S.ChatFrame:AddMessage(textLocal, unpack(args.color))
		end
		-- LibSink; use local event group; bypass it if the option for combat text is disabled
		if profile.sink20OutputSink == "Blizzard" and SHOW_COMBAT_TEXT == "0" then
			CombatText_AddMessage(textLocal, COMBAT_TEXT_SCROLL_FUNCTION, unpack(args.color))
		else
			self:Pour(profile.sink20OutputSink == "Channel" and textChat or textLocal, unpack(args.color))
		end
	end
	
	-- dont default to "SAY" if chatType is nil
	if args.chat and profile.ChatChannel > 1 and chatType then
		-- avoid ERR_CHAT_WHILE_DEAD
		local iseedeadpeople = UnitIsDeadOrGhost("player") and S.Talk[chatType]
		-- dont ever spam the battleground group
		if not (iseedeadpeople or isBattleground) then
			SendChatMessage(textChat, chatType, nil, profile.ChatChannel-4)
		end
	end
end

	----------------------
	--- Death Handling ---
	----------------------

function KCL:ShowDeath(guid, timestamp)
	-- ignore overkill if its too old (e.g. false positives happened)
	if death.overkill[guid] and timestamp-death.overkill[guid][2] > latencyThreshold then
		death.overkill[guid] = nil
	end
	
	local cleu
	local class = GetPlayerClass[guid]
	if class == "HUNTER" and not guid == player.guid then -- UNIT_DIED is (98% of the time) genuine if the player is a hunter himself and died
		-- dem pussy huntards feigning death; demand them to die from overkill, or not at all!
		-- UnitIsFeignDeath (deprecated) and UnitBuff (5384 spellname) and UNIT_SPELLCAST_SUCCEEDED only partially help if they only work for unit ids
		-- 6.2: they seem to get false positive overkill dmg now too. not sure on any workarounds now
		cleu = death.overkill[guid]
	elseif class == "DEATHKNIGHT" or class == "MAGE" then
		death.whosyourdaddy[guid] = death.cheater[guid] and true
		cleu = death.cheater[guid] or death.overkill[guid] or death.damage[guid]
	else -- prioritize any overkill events over normal dmg events
		cleu = death.overkill[guid] or death.damage[guid]
	end
	
	if cleu and not death.deleted[guid] then -- ignore instagibbed units
		death.time[guid] = timestamp -- set death flag
		-- fire the fatal event again; note that there are nil values in the table (from the environmental_damage event)
		self:COMBAT_LOG_EVENT_UNFILTERED(unpack(cleu, 1, table_maxn(cleu)))
	end
	
	-- reset death flag/data
	for k in pairs(death) do
		death[k][guid] = nil
	end
end

	---------------------------------
	--- Soulstone / Reincarnation ---
	---------------------------------

--[[
	1  track when a shaman or soulstoned unit dies
	2a look if the unit is visible and still in its corpse, and doesnt release spirit to ghost
	2b rule out normal/combat resurrections by other people
	3c rule out ress by the spirit healer or corpse running (already requires release spirit to ghost)
	3  compare sudden health increase from zero to e.g. 60 percent
	
	if health == 0 or UnitIsDead == 1 then unit is in its corpse
	if health == 1 or UnitIsGhost == 1 then unit released spirit and is a ghost
	
	Soulstone = 60% (.5999) health; 100% with [Glyph of Soulstone]
	Reincarnation = 20%
	Normal resurrection = 35%
	Spirit Healer / corpse running = 50%
	(Combat Res) Rebirth, Raise Ally = 60%; can be confused with Soulstone
	[Darkmoon Card: Twisting Nether] = 20%; can be confused with Reincarnation
	
	soulstone has precedence over reincarnation when used on a shaman, only the soulstone will show as an option. reincarnation is not wasted
	a normal resurrection overrides any soulstone/reincarnation for 1 minute, then soulstone/reincarnation will show again as an option
	the soulstone buff on holy priests fades simultaenously with the guardian spirit buff. there are no problems afaik
	* UnitIsVisible already accounts for UnitIsConnected
]]

function KCL:UNIT_HEALTH(event, unit)
	if not unit then return end -- 7.1 bug
	
	local guid = UnitGUID(unit) -- firstly filter out most of the stuff
	if (not selfres.soulstone[guid] and not selfres.reincarnation[guid]) or not UnitIsVisible(unit) then return end
	
	local health = UnitHealth(unit)
	local delta = (health-(selfres.prevHealth[guid] or 0)) / UnitHealthMax(unit)
	selfres.prevHealth[guid] = health
	
	-- confirm unit is dead (again) for the subsequent UNIT_HEALTH event, where it should be alive
	if UnitIsDead(unit) then selfres.wasDead[guid] = true; return end
	
	-- unit is now alive; check if it was previously dead
	if selfres.wasDead[guid] then
		if selfres.soulstone[guid] and (S.Approx(delta, .6, deviation) or S.Approx(delta, 1, deviation)) then
			self:COMBAT_LOG_EVENT_UNFILTERED(unpack(selfres.soulstone[guid]))
		elseif selfres.reincarnation[guid] and S.Approx(delta, .2, deviation) then
			self:COMBAT_LOG_EVENT_UNFILTERED(unpack(selfres.reincarnation[guid]))
		end
	end
	
	-- reset self res data
	for k in pairs(selfres) do
		selfres[k][guid] = nil
	end		
end
