local NAME, S = ...
local KCL = KethoCombatLog

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L
local options = S.options

local profile, char
local color, spell

local player = S.Player

local cd = {}
local args = {}

local _G = _G
local unpack = unpack
local tonumber = tonumber
local strsub, format = strsub, format
local bit_band = bit.band

local GetSpellInfo, GetSpellLink = GetSpellInfo, GetSpellLink

local COMBATLOG_OBJECT_RAIDTARGET_MASK = COMBATLOG_OBJECT_RAIDTARGET_MASK
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local TEXT_MODE_A_TIMESTAMP = TEXT_MODE_A_TIMESTAMP
local TEXT_MODE_A_STRING_SOURCE_UNIT = TEXT_MODE_A_STRING_SOURCE_UNIT
local TEXT_MODE_A_STRING_DEST_UNIT = TEXT_MODE_A_STRING_DEST_UNIT
local TEXT_MODE_A_STRING_SPELL = TEXT_MODE_A_STRING_SPELL
local TEXT_MODE_A_STRING_RESULT_OVERKILLING = TEXT_MODE_A_STRING_RESULT_OVERKILLING
local TEXT_MODE_A_STRING_RESULT_CRITICAL = TEXT_MODE_A_STRING_RESULT_CRITICAL
local TEXT_MODE_A_STRING_RESULT_GLANCING = TEXT_MODE_A_STRING_RESULT_GLANCING
local TEXT_MODE_A_STRING_RESULT_CRUSHING = TEXT_MODE_A_STRING_RESULT_CRUSHING

local lastDeath
local braces = "[%[%]]"

	------------
	--- Ace3 ---
	------------

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
	local NAME2 = "Ketho CombatLog"
	ACR:RegisterOptionsTable("KethoCombatLog_Parent", options)
	ACD:AddToBlizOptions("KethoCombatLog_Parent", NAME2)
	
	-- profiles
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	appValue.KethoCombatLog_Profiles = profiles
	profiles.order = 6
	profiles.name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:-1"..S.crop.."|t  "..profiles.name
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME2)
	end
	
	ACD:SetDefaultSize("KethoCombatLog_Parent", 700, 600)
	
	-- slash command
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
		
		if profile.ChatChannel == 2 then
			chatType = "SAY"
		elseif profile.ChatChannel == 3 then
			chatType = "YELL"
		elseif profile.ChatChannel == 4 then
			-- don't want to spam to BATTLEGROUND, if people really want to announce to there, they can still use LibSink
			chatType = IsPartyLFG() and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY"
		else
			chatType, channel = "CHANNEL", profile.ChatChannel-4
		end
		
		if (profile.PvE and (instanceType == "party" or instanceType == "raid"))
			or (profile.PvP and (instanceType == "pvp" or instanceType == "arena"))
			or (profile.World and instanceType == "none" or not instanceType) then -- Scenario
			instanceTypeFilter = true
		else
			instanceTypeFilter = false
		end
	end, 5)
end

function KCL:RefreshDB()
	-- table shortcuts
	profile, char = self.db.profile, self.db.char
	color, spell = profile.color, profile.spell
	
	for i = 1, 2 do -- refresh db in other files
		self["RefreshDB"..i](self)
	end
	self:WipeCache() -- wipe metatables
	self:SetSinkStorage(profile) -- LibSink
	
	-- other
	S.crop = profile.IconCropped and ":64:64:4:60:4:60" or ""
	if profile.ChatWindow > 1 then
		S.ChatFrame = _G["ChatFrame"..profile.ChatWindow-1]
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

-- Blizzard CombatLog is Load-on-Demand
function KCL:ADDON_LOADED(event, addon)
	if addon == "Blizzard_CombatLog" and not profile.BlizzardCombatLog then
		COMBATLOG:UnregisterEvent("COMBAT_LOG_EVENT")
		self:UnregisterEvent(addon)
	end
end

	----------------
	--- Reaction ---
	----------------

local function UnitReaction(unitflags)
	if bit_band(unitflags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
		return "Friendly"
	elseif bit_band(unitflags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
		return "Hostile"
	else
		return "Unknown"
	end
end

	-------------------
	--- Raid Target ---
	-------------------

-- modified from Blizzard_CombatLog
local function UnitIcon(unitFlags, reaction)
	local iconBit = bit_band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
	if iconBit == 0 then return "", "" end
	
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
		iconString = format(S.STRING_REACTION_ICON[reaction], iconBit, icon)
	end
	return iconString, braces
end

	-------------
	--- Spell ---
	-------------

local GetSpellSchool = setmetatable({}, {__index = function(t, k)
	local str = S.SpellSchoolString[k] or STRING_SCHOOL_UNKNOWN.." ("..k..")"
	local color = S.SpellSchoolColor[k]
	local v = {"|cff"..color..str.."|r", str, color}
	rawset(t, k, v)
	return v
end})

local GetSpellIcon = setmetatable({}, {__index = function(t, k)
	local v = select(3, GetSpellInfo(k))
	rawset(t, k, v)
	return v
end})

local _GetSpellLink = setmetatable({}, {__index = function(t, k)
	local v = GetSpellLink(k)
	rawset(t, k, v)
	return v
end})

local function GetSpellInfo(spellID, spellName, spellSchool)
	local schoolNameLocal, schoolNameChat, schoolColor = unpack(GetSpellSchool[spellSchool])
	local iconSize = profile.IconSize
	local spellIcon = iconSize>1 and format("|T%s:%s:%s:0:0%s|t", GetSpellIcon[spellID], iconSize, iconSize, S.crop) or ""
	local spellLinkLocal = format("|cff%s"..TEXT_MODE_A_STRING_SPELL.."|r", schoolColor, spellID, "", "["..spellName.."]")
	return schoolNameLocal, schoolNameChat, spellLinkLocal, _GetSpellLink[spellID], spellIcon
end

	--------------
	--- Result ---
	--------------

local function GetResultString(overkill, critical, glancing, crushing)
	local str = ""

	if overkill and profile.OverkillFormat then
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

local function IsEvent(event)
	return profile["Local"..event] or profile["Chat"..event]
end

local function IsChatEvent(event)
	return profile[(profile.ChatFilter and "Chat" or "Local")..event]
end

local function TankFilter(event, isTank)
	return not isTank or profile["Tank"..event]
end

	------------
	--- Args ---
	------------

local function SetMessageArgs(msgtype)
	args.msg = profile.message[msgtype]
	local group = S.EventGroup[msgtype] or msgtype -- fallback
	args.color = color[group]
	args.chat = IsChatEvent(group) -- whether to output to chat
end

-- only append x for these chatargs
local ChatArgs = {
	src = true,
	dest = true,
	spell = true,
	xspell = true,
	school = true,
	xschool = true,
	icon = true, -- exception
	xicon = true,
}
local function ReplaceArgs(args, isChat)
	local msg = args.msg
	for k in gmatch(msg, "%b<>") do
		-- remove <>, make case insensitive
		local s = strlower(gsub(k, "[<>]", ""))
		-- escape special characters
		s = gsub(args[isChat and ChatArgs[s] and s.."x" or s] or s, "(%p)", "%%%1")
		k = gsub(k, "(%p)", "%%%1")
		msg = msg:gsub(k, s)
	end
	return msg
end

	------------
	--- CLEU ---
	------------

function KCL:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	
	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	
	wipe(args)
	
	local isDamageEvent = S.DamageEvent[subevent]
	local isReflectEvent = (subevent == "SPELL_MISSED" and select(15, ...) == "Reflect")
	local isReverseEvent = isDamageEvent or isReflectEvent
	local sourceType = tonumber(strsub(sourceGUID, 5, 5))
	local destType = tonumber(strsub(destGUID, 5, 5))
	
	--------------
	--- Filter ---
	--------------
	
	if sourceName == player.name or destName == player.name then
		if not profile.FilterSelf then return end
	else
		if not profile.FilterOther then return end
	end
	
	-- the other way round for for death/reflect events
	if (isReverseEvent and S.PlayerID[destType]) or (not isReverseEvent and S.PlayerID[sourceType]) then
		if not profile.FilterPlayers then return end
	else
		if not profile.FilterMonsters then return end
	end
	
	------------
	--- Unit ---
	------------
	
	local sourceNameTrim, destNameTrim = "", ""
	
	local sourceIconLocal, sourceIconChat = UnitIcon(sourceRaidFlags, 1)
	local destIconLocal, destIconChat = UnitIcon(destRaidFlags, 2)
	
	local sourceReaction = UnitReaction(sourceFlags)
	local destReaction = UnitReaction(destFlags)
	
	if sourceName then
		-- trim out realm name; only do this for players, to avoid false positives for certain npcs
		sourceNameTrim = (profile.TrimRealmName and S.PlayerID[sourceType]) and strmatch(sourceName, "([^%-]+)%-?.*") or sourceName
		local name, color = sourceNameTrim
		if sourceName == player.name then
			color, name = player.color, UNIT_YOU_SOURCE
		elseif UnitInParty(sourceName) or UnitInRaid(sourceName) then
			color = S.ClassColor[select(2,UnitClass(sourceName))]
		-- CRZ source/destName include the realm name
		elseif sourceType == 0 and (sourceNameTrim == UnitName("target") or sourceNameTrim == UnitName("focus")) then
			if sourceNameTrim == UnitName("target") then
				color = S.ClassColor[select(2,UnitClass("target"))]
			elseif sourceNameTrim == UnitName("focus") then
				color = S.ClassColor[select(2,UnitClass("focus"))]
			end
		else
			color = S.GeneralColor[sourceReaction]
		end
		args.src = format("|cff%s"..TEXT_MODE_A_STRING_SOURCE_UNIT.."|r", color, sourceIconLocal, sourceGUID, "["..sourceNameTrim.."]", "["..name.."]")
		args.srcx = format("%s[%s]", sourceIconChat, sourceNameTrim)
	end
	
	if destName then
		destNameTrim = (profile.TrimRealmName and S.PlayerID[destType]) and strmatch(destName, "([^%-]+)%-?.*") or destName
		local name, color = destNameTrim
		if destName == player.name then
			color, name = player.color, UNIT_YOU_DEST
		elseif UnitInParty(destName) or UnitInRaid(destName) then
			color = S.ClassColor[select(2,UnitClass(destName))]
		elseif destType == 0 and (destNameTrim == UnitName("target") or destNameTrim == UnitName("focus")) then
			if destNameTrim == UnitName("target") then
				color = S.ClassColor[select(2,UnitClass("target"))]
			elseif destNameTrim == UnitName("focus") then
				color = S.ClassColor[select(2,UnitClass("focus"))]
			end
		else
			color = S.GeneralColor[destReaction]
		end
		args.dest = format("|cff%s"..TEXT_MODE_A_STRING_DEST_UNIT.."|r", color, destIconLocal, destGUID, "["..destNameTrim.."]", "["..(destName==sourceName and "Self" or name).."]")
		args.destx = format("%s[%s]", destIconChat, destNameTrim)
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
	elseif prefix == "SPELL" or prefix == "RANGE" or prefix == "DAMAG" then
		spellID, spellName, spellSchool, SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
		args.amount = SuffixParam1
		
	-------------
	--- Spell ---
	-------------
		
		args.school, args.schoolx, args.spell, args.spellx, args.icon = GetSpellInfo(spellID, spellName, spellSchool)
		args.iconx = "" -- fix
		
		if S.ExtraSpellEvent[subevent] then
			args.xschool, args.xschoolx, args.xspell, args.xspellx, args.xicon = GetSpellInfo(SuffixParam1, SuffixParam2, SuffixParam3)
			args.xiconx = ""
		end
	end
	
	
	if instanceTypeFilter then
		
		local isTank = (UnitGroupRolesAssigned(sourceName) == "TANK")
		
	----------------
	--- Subevent ---
	----------------
		
		if isDamageEvent and SuffixParam2 > 0 and (destName ~= lastDeath or time() > (cd.death or 0)) then
			cd.death = time() + 1
			lastDeath = destName
			SetMessageArgs(subevent == "SWING_DAMAGE" and "Death_Melee" or "Death")
		end
		
		if subevent == "SPELL_CAST_SUCCESS" then
			if S.Taunt_AoE[spellID] and IsEvent("Taunt") and TankFilter("Taunt", isTank) then
				SetMessageArgs("Taunt_AoE")
			elseif S.Growl[spellID] and S.NPCID[destType] and profile.PetGrowl then
				SetMessageArgs("Growl")
			elseif S.Interrupt[spellID] and IsEvent("Juke") then
				self:IneffectiveInterrupt(...)
			end
		elseif subevent == "SPELL_AURA_APPLIED" then
			if S.Taunt[spellID] and S.NPCID[destType] and IsEvent("Taunt") and TankFilter("Taunt", isTank) then
				SetMessageArgs("Taunt")
			elseif S.CrowdControl[spellID] and IsEvent("CrowdControl") then
				SetMessageArgs("CrowdControl")
			end
		elseif subevent == "SPELL_INTERRUPT" then
			if IsEvent("Interrupt") then
				SetMessageArgs("Interrupt")
			end
			if IsEvent("Juke") then
				self:IneffectiveInterrupt(...)
			end
		elseif subevent == "SPELL_INEFFECTIVE_INTERRUPT" then
			-- not needed to check event options
			SetMessageArgs("Juke")
		elseif subevent == "SPELL_DISPEL" then
			if IsEvent("Dispel") then
				local friendly = (sourceReaction == "Friendly" and destReaction == sourceReaction)
				local hostile = (sourceReaction == "Hostile" and destReaction == sourceReaction)
				-- cleanses between two (friendly/hostile) units
				-- bug: its not possible to see whether 2 friendly units are hostile to each other, ie dueling
				if friendly or hostile then
					if profile.FriendlyDispel then
						SetMessageArgs("Cleanse")
					end
				else
					if profile.HostileDispel then
						SetMessageArgs("Dispel")
					end
				end
			end
		elseif subevent == "SPELL_STOLEN" then
			if IsEvent("Dispel") and profile.Spellsteal then
				SetMessageArgs("Spellsteal")
			end
		elseif subevent == "SPELL_MISSED" then
			if SuffixParam1 == "Reflect" then
				if IsEvent("Reflect") then
					SetMessageArgs("Reflect")
				end
			else
				local taunt = S.Taunt[spellID] and IsEvent("Taunt")
				local isDeathGripPlayer = (spellID == 49560 and destType == 0) -- dat spam
				local interrupt = S.Interrupt[spellID] and IsEvent("Interrupt")
				local crowdcontrol = S.CrowdControl[spellID] and IsEvent("CrowdControl")
				if profile.MissAll or (taunt and not isDeathGripPlayer) or interrupt or crowdcontrol then
					args.type = S.MissType[SuffixParam1] or SuffixParam1
					SetMessageArgs("Miss")
				end
				-- check if the interrupt failed, instead of being wasted
				if S.Interrupt[spellID] and IsEvent("Juke") then
					self:IneffectiveInterrupt(...)
				end
			end
		elseif subevent == "SPELL_AURA_BROKEN" then
			if IsEvent("Break") then
				SetMessageArgs(sourceName and "Break_NoSource" or "Break")
			end
		elseif subevent == "SPELL_AURA_BROKEN_SPELL" then
			if IsEvent("Break") then
				SetMessageArgs("Break_Spell")
			end
		elseif subevent == "SPELL_INSTAKILL" then
			if spellID ~= 48743 and IsEvent("Death") then -- Death Knight [Death Pact] 
				SetMessageArgs("Death_Instakill")
			end
		elseif subevent == "ENVIRONMENTAL_DAMAGE" then
			local environmentalType, amount = select(12, ...)
			-- sometimes destName is nil; overkill never exceeds 0, workaround with UnitHealth
			if destName and UnitHealth(destName) == 1 and IsEvent("Death") then
				args.amount = amount
				args.type = S.EnvironmentalDamageType[environmentalType] or environmentalType
				SetMessageArgs("Death_Environmental")
			end
		elseif subevent == "SPELL_HEAL" then
			if S.Save[spellID] and IsEvent("Save") then
				SetMessageArgs("Save")
			end
		elseif subevent == "SPELL_RESURRECT" then
			-- todo: add better check, this is kinda lazy
			if IsEvent("Resurrect") and not profile.BattleRez or (profile.BattleRez and UnitAffectingCombat("player")) then
				SetMessageArgs("Resurrect")
			end
		end
		
		-- check if there is any message
		if args.msg then
			
	--------------
	--- Output ---
	--------------
	
			-- timestamp; possibility to also use as an arg
			args.time, args.timex = S.GetTimestamp()
			
			local resultString = ""
			if isDamageEvent or S.HealEvent[subevent] then
				resultString = GetResultString(SuffixParam2, SuffixParam7, SuffixParam8, SuffixParam9)
			end
			
			-- remove braces again; except timestamp
			if not profile.UnitBracesLocal then
				args.src = args.src:gsub(braces, "")
				args.dest = args.dest:gsub(braces, "")
				-- spell strings can be nil
				args.spell = args.spell and args.spell:gsub(braces, " ")
				args.xspell = args.xspell and args.xspell:gsub(braces, " ")
			end
			if not profile.UnitBracesChat then
				args.srcx = args.srcx:gsub(braces, "")
				args.destx = args.destx:gsub(braces, "")
			end
			
			local textLocal = ReplaceArgs(args)
			local textChat = ReplaceArgs(args, true)
			textLocal = args.time..textLocal..resultString
			textChat = args.timex..textChat..resultString
			
			if profile.ChatWindow > 1 then
				S.ChatFrame:AddMessage(textLocal, unpack(args.color))
			end
			
			-- don't default to "SAY" if chatType is nil
			if args.chat and profile.ChatChannel > 1 and chatType then
				local isTalk = S.Talk[chatType]
				local isDead = UnitIsDead("player") or UnitIsGhost("player")
				
				if not (isDead and isTalk) then -- avoid ERR_CHAT_WHILE_DEAD
					SendChatMessage(textChat, chatType, nil, channel)
				end
			end
			
			-- LibSink
			self:Pour(profile.sink20OutputSink == "Channel" and textChat or textLocal, unpack(args.color))
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
		self:ScheduleTimer(function()
			self:IneffectiveInterrupt(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
		end, 0.4)
	elseif subevent == "SPELL_INTERRUPT" or subevent == "SPELL_MISSED" then
		InterruptCheck[sourceGUID] = false
	elseif subevent == "CHECK_INEFFECTIVE_INTERRUPT" then
		if InterruptCheck[sourceGUID] then
			self:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, "SPELL_INEFFECTIVE_INTERRUPT", hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
		end
		InterruptCheck[sourceGUID] = false
	end
end
