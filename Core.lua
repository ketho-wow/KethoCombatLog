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

local _G = _G
local bit_band = bit.band

local GetSpellInfo, oldGetSpellLink = GetSpellInfo, GetSpellLink

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
local TEXT_MODE_A_STRING_RESULT_CRUSHING = TEXT_MODE_A_STRING_RESULT_CRUSHIN

	---------------------------
	--- Ace3 Initialization ---
	---------------------------

local appKey = {
	"KethoCombatLog_Main",
	"KethoCombatLog_Advanced",
	--"KethoCombatLog_Spell",
	--"KethoCombatLog_SpellExtra",
	"KethoCombatLog_Profiles",
}

local appValue = {
	KethoCombatLog_Main = options.args.Main,
	KethoCombatLog_Advanced = options.args.Advanced,
	--KethoCombatLog_Spell = options.args.Spell1,
	--KethoCombatLog_SpellExtra = options.args.Spell2,
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
		
		if profile.chatChannel == 2 then
			chatType = "SAY"
		elseif profile.chatChannel == 3 then
			chatType = "YELL"
		elseif profile.chatChannel == 4 then
			-- don't want to spam to BATTLEGROUND, if people really want to announce to there, they can still use LibSink
			chatType = IsPartyLFG() and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY"
		else
			chatType, channel = "CHANNEL", profile.chatChannel-4
		end
		
		if (profile.PvE and (instanceType == "party" or instanceType == "raid"))
			or (profile.PvP and (instanceType == "pvp" or instanceType == "arena"))
			or (profile.World and instanceType == "none" or not instanceType) then -- Scenario
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
	-- table shortcuts
	profile, char = self.db.profile, self.db.char
	color, spell = profile.color, profile.spell
	
	for i = 1, 2 do -- refresh db in other files
		self["RefreshDB"..i](self)
	end
	
	self:WipeCache()
	
	-- LibSink
	self:SetSinkStorage(profile)
	
	-- other
	S.crop = profile.iconCropped and ":64:64:4:60:4:60" or ""
	if profile.chatWindow > 1 then
		S.ChatFrame = _G["ChatFrame"..profile.chatWindow-1]
	end
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
	return profile[(profile.ChatFilters and "Chat" or "Local")..event]
end

local function TankFilter(isTank, event)
	if profile["Tank"..event] then
		return true
	else
		return not isTank
	end
end

local function UnitReaction(unitflags)
	if bit_band(unitflags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
		return "Friendly"
	elseif bit_band(unitflags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
		return "Hostile"
	else
		return "Unknown"
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
		iconString = format(S.STRING_REACTION_ICON[reaction], iconBit, icon)
	end
	return iconString, braces
end

local function SpellSchool(value)
	local str = S.SpellSchoolString[value] or STRING_SCHOOL_UNKNOWN.." ("..value..")"
	local color = S.SpellSchoolColor[value]
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
	local iconSize = profile.iconSize
	local spellIcon = iconSize>1 and "|T"..GetSpellIcon(spellID)..":"..iconSize..":"..iconSize..":0:0"..S.crop.."|t" or ""
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

function KCL:COMBAT_LOG_EVENT_UNFILTERED(event, ...)

	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	
	local isDamageEvent = S.DamageEvent[subevent]
	local isReflectEvent = (subevent == "SPELL_MISSED" and select(15, ...) == "Reflect")
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
	if (S.PlayerID[sourceType] and not isReverseEvent) or (S.PlayerID[destType] and isReverseEvent) then
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
		sourceNameTrim = (profile.TrimRealmNames and S.PlayerID[sourceType]) and strmatch(sourceName, "([^%-]+)%-?.*") or sourceName
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
		sourceUnitLocal = format("|cff%s"..TEXT_MODE_A_STRING_SOURCE_UNIT.."|r", color, sourceIconLocal, sourceGUID, "["..sourceNameTrim.."]", "["..name.."]")
		sourceUnitChat = sourceIconChat.."["..sourceNameTrim.."]"
	end
	if destName then
		destNameTrim = (profile.TrimRealmNames and S.PlayerID[destType]) and strmatch(destName, "([^%-]+)%-?.*") or destName
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
		if S.ExtraSpellEvent[subevent] then
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
	if isDamageEvent or S.HealEvent[subevent] then
		if subevent == "SWING_DAMAGE" then
			schoolNameLocal = "|cff"..S.GeneralColor.Physical..ACTION_SWING.."|r"
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
		if profile.LocalDeath or profile.ChatDeath then
			-- Instagibs; problem: filter DK [Death Pact] deaths, it's not a damage event, so it slips through the filter
			if subevent == "SPELL_INSTAKILL" and spellID ~= 48743 then
				textLocal = profile.LocalDeath and destUnitLocal.." |cff"..S.GeneralColor.Death..ACTION_UNIT_DIED.."|r "..sourceUnitLocal..spellLinkLocal
				textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat..spellLinkChat
			-- Environmental Deaths; problem: the overkill parameter is always stuck on zero
			elseif subevent == "ENVIRONMENTAL_DAMAGE" then
				local environmentalType, SuffixParam1, _, SuffixParam3 = select(12, ...)
				-- bug: sometimes destName is nil?
				if destName and UnitHealth(destName) and UnitHealth(destName) == 1 then
					textLocal = profile.LocalDeath and destUnitLocal.." |cff"..S.GeneralColor.Death..ACTION_UNIT_DIED.."|r "..SuffixParam1.." "..(S.EnvironmentalDamageType[environmentalType] or environmentalType)
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..SuffixParam1.." "..(S.EnvironmentalDamageType[environmentalType] or environmentalType)
				end
			elseif isDamageEvent and SuffixParam2 > 0 and (Time > (cd.death or 0) or destName ~= lastDeath) then
				cd.death = Time + 0.2; lastDeath = destName
				if subevent == "SWING_DAMAGE" then
					textLocal = profile.LocalDeath and destUnitLocal.." |cff"..S.GeneralColor.Death..ACTION_UNIT_DIED.."|r "..sourceUnitLocal
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat
				else
					textLocal = profile.LocalDeath and destUnitLocal.." |cff"..S.GeneralColor.Death..ACTION_UNIT_DIED.."|r "..sourceUnitLocal..spellLinkLocal
					textChat = ChatFilter("Death") and destUnitChat.." "..ACTION_UNIT_DIED.." "..sourceUnitChat..spellLinkChat
				end
			end
		end
		-- Taunts
		if profile.LocalTaunt or profile.ChatTaunt then
			if TankFilter(isTank, "Taunt") then
				if subevent == "SPELL_AURA_APPLIED" and destType >= 3 and S.Taunt[spellID] then
					textLocal = sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.Taunt.."taunted|r "..destUnitLocal
					textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." taunted "..destUnitChat
				elseif subevent == "SPELL_CAST_SUCCESS" and (spellID == 1161 or spellID == 5209) then
					textLocal = profile.LocalTaunt and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor["Taunt"].."AoE "..GetSpellInfo(355).."|r"
					textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." AoE "..GetSpellInfo(355)
				end
			end
			-- Pet 2649[Growl], Voidwalker 3716[Torment], Greater Earth Elemental 36213[Angered Earth]
			if subevent == "SPELL_CAST_SUCCESS" and profile.PetGrowl and destType >= 3 and (spellID == 2649 or spellID == 3716 or spellID == 36213) then
				textLocal = profile.LocalTaunt and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor["Taunt"].."growled|r "..destUnitLocal
				textChat = ChatFilter("Taunt") and sourceUnitChat..spellLinkChat.." growled "..destUnitChat
			end
		end
		-- CC Breaker
		if (profile.LocalBreak or profile.ChatBreak) then
			-- broken by a spell
			if subevent == "SPELL_AURA_BROKEN_SPELL" then
				textLocal = profile.LocalBreak and sourceUnitLocal..extraSpellLinkLocal.." |cff"..S.GeneralColor.Break..ACTION_SPELL_AURA_BROKEN.."|r "..spellLinkLocal.." on "..destUnitLocal
				textChat = ChatFilter("Break") and sourceUnitChat..extraSpellLinkChat.." "..ACTION_SPELL_AURA_BROKEN.." "..spellLinkChat.." on "..destUnitChat
			-- not broken by a spell; this subevent does not seem to fire for CLEU; 4.0.1 bug?
			elseif subevent == "SPELL_AURA_BROKEN" then
				if sourceName then
					textLocal = profile.LocalBreak and sourceUnitLocal.." |cff"..S.GeneralColor.Break..ACTION_SPELL_AURA_BROKEN.."|r "..spellLinkLocal.." on "..destUnitLocal
					textChat = ChatFilter("Break") and sourceUnitChat.." "..ACTION_SPELL_AURA_BROKEN.." "..spellLinkChat.." on "..destUnitChat
				else
					textLocal = profile.LocalBreak and spellLinkLocal.." on "..destUnitLocal.." |cff"..S.GeneralColor["Break"].."broken|r"
					textChat = ChatFilter("Break") and spellLinkChat.." on "..destUnitChat.." broken"
				end
			end
		end
		-- Dispels / Spellsteals
		if subevent == "SPELL_DISPEL" then
			local dispelString
			if (sourceReaction == "Friendly" and destReaction == sourceReaction) or (sourceReaction == "Hostile" and destReaction == sourceReaction) then
				dispelString = profile.FriendlyDispel and ACTION_SPELL_DISPEL_DEBUFF
			else
				dispelString = profile.HostileDispel and ACTION_SPELL_DISPEL_BUFF
			end
			if dispelString then
				textLocal = profile.LocalDispel and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.Dispel..dispelString.."|r "..destUnitLocal..extraSpellLinkLocal
				textChat = ChatFilter("Dispel") and sourceUnitChat..spellLinkChat.." "..dispelString.." "..destUnitChat..extraSpellLinkChat
			end
		elseif subevent == "SPELL_STOLEN" then
			textLocal = profile.LocalDispel and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.Dispel..ACTION_SPELL_STOLEN.."|r "..destUnitLocal..extraSpellLinkLocal
			textChat = ChatFilter("Dispel") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_STOLEN.." "..destUnitChat..extraSpellLinkChat
		-- Reflects / Misses
		elseif subevent == "SPELL_MISSED" then
			if SuffixParam1 == "Reflect" then
				textLocal = profile.LocalReflect and destUnitLocal.." |cff"..S.EventColo.Reflect..ACTION_SPELL_MISSED_REFLECT.."|r "..sourceUnitLocal..spellLinkLocal
				textChat = ChatFilter("Reflect") and destUnitChat.." "..ACTION_SPELL_MISSED_REFLECT.." "..sourceUnitChat..spellLinkChat
			else
				local taunt, interrupt, cc = S.Taunt[spellID], S.Interrupt[spellID], S.CrowdControl[spellID]
				if profile.MissAll or (taunt and profile.LocalTaunt) or (interrupt and profile.LocalInterrupt) or (cc and profile.LocalCrowdControl) then
					--if not S.MissType[SuffixParam1] then Spew("", SuffixParam1) end --debug
					textLocal = sourceUnitLocal..spellLinkLocal.." on "..destUnitLocal.." |cffFF7800"..ACTION_SPELL_CAST_FAILED.."|r ("..S.MissType[SuffixParam1]..")"
				end
				if (taunt and ChatFilter("Taunt")) or (interrupt and ChatFilter("Interrupt")) or (cc and ChatFilter("CrowdControl")) then
					textChat = sourceUnitChat..spellLinkChat.." on "..destUnitChat.." "..ACTION_SPELL_CAST_FAILED.." ("..S.MissType[SuffixParam1]..")"
				end
				-- check if the interrupt didn't miss, instead of being wasted
				if interrupt and profile.Juke then
					self:IneffectiveInterrupt(...)
				end
			end
		-- Death Prevents; -- Priest 48153[Guardian Spirit], Paladin 66235[Ardent Defender]
		elseif subevent == "SPELL_HEAL" and (spellID == 48153 or spellID == 66235) then
			if profile.LocalDeath and profile.LocalSave then
				textLocal = sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.Resurrect.."healed "..destUnitLocal
			end
			if ChatFilter("Death") and ChatFilter("Save") then
				textChat = sourceUnitChat..spellLinkChat.." healed "..destUnitChat..spellLinkChat
			end
		-- Resurrects
		elseif subevent == "SPELL_RESURRECT" then
			--if not profile.BattleRez or (profile.BattleRez and UnitAffectingCombat("player")) then
				textLocal = profile.LocalResurrect and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.Resurrect..ACTION_SPELL_RESURRECT.."|r "..destUnitLocal
				textChat = ChatFilter("Resurrect") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_RESURRECT.." "..destUnitChat
			--end
		-- todo; dependent on options
		-- Crowd Control
		elseif subevent == "SPELL_AURA_APPLIED" and S.CrowdControl[spellID] then
			textLocal = profile.LocalCrowdControl and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.CrowdControl.."CC'ed|r "..destUnitLocal
			textChat = ChatFilter("CrowdControl") and sourceUnitChat..spellLinkChat.." CC'ed "..destUnitChat
		-- "pre-Interrupts"
		elseif subevent == "SPELL_CAST_SUCCESS" and S.Interrupt[spellID] then
			self:IneffectiveInterrupt(...)
		-- Interrupts
		elseif subevent == "SPELL_INTERRUPT" then
			textLocal = profile.LocalInterrupt and sourceUnitLocal..spellLinkLocal.." |cff"..S.GeneralColor.Interrupt..ACTION_SPELL_INTERRUPT.."|r "..destUnitLocal..extraSpellLinkLocal
			textChat = ChatFilter("Interrupt") and sourceUnitChat..spellLinkChat.." "..ACTION_SPELL_INTERRUPT.." "..destUnitChat..extraSpellLinkChat
			self:IneffectiveInterrupt(...)
		-- Wasted Interrupt
		elseif subevent == "SPELL_INEFFECTIVE_INTERRUPT" then
			if profile.LocalInterrupt and profile.Juke then
				textLocal = sourceUnitLocal.." |cffFF7800wasted|r "..spellLinkLocal.."  on "..destUnitLocal
			end
			if ChatFilter("Interrupt") and ChatFilter("Juke") then
				textChat = sourceUnitChat.." wasted "..spellLinkChat.." on "..destUnitChat
			end
		end

		--[=[
		-- Spell
		if profile.enableSpell then
			-- filters
			local spellSelf = profile.SpellSelf and sourceName == player.name
			local spellFriend = profile.SpellFriend and (sourceReaction == "Friendly" and sourceName ~= player.name)
			local spellEnemy = profile.SpellEnemy and sourceReaction >= "Hostile"

			if spellSelf or spellFriend or spellEnemy then
				-- hacky, cba about preserving coloring
				--[[
				if profile.SpellSpellName and strfind(subevent, "SPELL") then
					spellLinkLocal = profile.UnitBracesLocal and "["..spellName.."]" or " "..spellName.." "
					spellLinkChat = profile.UnitBracesChat and "["..spellName.."]" or " "..spellName.." "
				end
				]]
				if subevent == "SPELL_CAST_SUCCESS" then
					if spell.success[spellID] or spell.successNT[spellID] then
						-- request: only show MD/TotT on tanks; this feels dirty ..
						--if not TankSupport[spellID] or (TankSupport[spellID] and ((profile.TankSupport and UnitGroupRolesAssigned(destName) == "TANK") or not profile.TankSupport)) then
							if (not profile.SelfCast and destName == sourceName) or not destName then
								textLocal = sourceUnitLocal..spellLinkLocal
								textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
							else
								textLocal = sourceUnitLocal..spellLinkLocal.." on "..destUnitLocal
								textChat = profile.SpellChat and sourceUnitChat..spellLinkChat.." on "..destUnitChat
							end
						--end
					end
				elseif subevent == "SPELL_AURA_APPLIED" then
					-- change of plans; might've as well combined spell_applied and spell_appliedNT into 1 table now
					if spell.applied[spellID] or spell.appliedNT[spellID] then
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
					if spell.start[spellID] then
						textLocal = sourceUnitLocal..spellLinkLocal
						textChat = profile.SpellChat and sourceUnitChat..spellLinkChat
					elseif spell.precast[spellID] and sourceName ~= player.name then
						textLocal = sourceUnitLocal.." casting "..spellLinkLocal.." |TInterface\\EncounterJournal\\UI-EJ-Icons:12:12:0:2:64:256:42:46:32:96|t"
						textChat = profile.SpellChat and sourceUnitChat.." casting "..spellLinkChat
					end
				elseif (subevent == "SPELL_SUMMON" and spell.summon[spellID]) or (subevent == "SPELL_CREATE" and spell.create[spellID]) then
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
		]=]

	--------------
	--- Output ---
	--------------

		if textLocal or textChat then
			if textLocal and profile.chatWindow > 1 then
				textLocal = timestampLocal..textLocal..resultStringLocal
				S.ChatFrame:AddMessage(textLocal)
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