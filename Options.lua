local NAME, S = ...
local KCL = KethoCombatLog

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L

local profile, char
local color

function KCL:RefreshDB2()
	profile, char = self.db.profile, self.db.char
	color = profile.color
end

local _G = _G
local unpack = unpack
local select = select
local format = format

local numberExample = random(1e5, 1e6)
local parentheses = "[()]"
-- Show Time Warp for Mage, Bloodlust for Horde, Heroism for Alliance; Naming the variable Bloodlust because of the original Warcraft 3
local Bloodlust = (S.player.class == "MAGE") and {GetSpellInfo(80353)} or (UnitFactionGroup("player") == "Horde") and {GetSpellInfo(2825)} or {GetSpellInfo(32182)}

local function IsNotEvent(event)
	return not (profile["Local"..event] or profile["Chat"..event])
end

	----------------
	--- Defaults ---
	----------------

S.defaults = { -- KethoCombatLog.db.defaults
	profile = {
		LocalTaunt = true,
		LocalInterrupt = true,
		LocalDeath = true,
		
		PvE = true,
		PvP = true,
		World = true,
		
		ChatWindow = 2, -- ChatFrame1
		ChatChannel = 1, -- Disabled
		
		TrimRealm = true,
		Timestamp = 1, -- None
		IconSize = 16,
		IconCropped = true,
		UnitBracesChat = true,
		CriticalFormat = true,
		AbbreviateNumbers = true,
		BlizzardCombatLog = true,
		
		FilterPlayers = true, -- inclusive filtering
		TankTaunt = true,
		PetTaunt = true,
		FriendlyDispel = true,
		HostileDispel = true,
		Spellsteal = true,
		
		SpellOutput = 1,
		SpellFilterSelf = true, -- exclusive filtering
		
		color = {
			Taunt = {1, 0, 0}, -- #FF0000 (Red)
			Interrupt = {0, 110/255, 1}, -- #006EFF (something Blue)
			Juke = {1, 1, 1},
			Dispel = {1, 1, 1},
			Reflect = {1, 1, 1},
			CrowdControl = {1, 1, 1},
			Break = {1, 1, 1},
			Death = {1, 1, 1},
			Save = {1, 1, 1},
			Resurrect = {175/255, 1, 47/255}, -- #ADFF2F (GreenYellow)
			-- Constants.lua: SCHOOL_MASK_PHYSICAL, ...
			Physical = {1.00, 1.00, 0.00}, -- #FFFF00
			Holy = {1.00, 0.90, 0.50}, -- #FFE680
			Fire = {1.00, 0.50, 0.00}, -- #FF8000
			Nature = {0.30, 1.00, 0.30}, -- #4DFF4D
			Frost = {0.50, 1.00, 1.00}, -- #80FFFF
			Shadow = {0.50, 0.50, 1.00}, -- #8080FF
			Arcane = {1.00, 0.50, 1.00}, -- #FF80FF
			-- /dump COMBATLOG_DEFAULT_COLORS.unitColoring[COMBATLOG_FILTER_FRIENDLY_UNITS]
			Friendly = {0.34, 0.64, 1.00}, -- #57A3FF
			Hostile = {0.75, 0.05, 0.05}, -- #BF0D0D
			Unknown = {191/255, 191/255, 191/255}, -- #BFBFBF
			Timestamp = {0.67, 0.67, 0.67},
		},
		
		message = {
			Taunt = L.MSG_TAUNT,
			
			Interrupt = L.MSG_INTERRUPT,
			Juke = L.MSG_JUKE,
			
			Dispel = L.MSG_DISPEL,
			Cleanse = L.MSG_CLEANSE,
			Spellsteal = L.MSG_SPELLSTEAL,
			
			Reflect = L.MSG_REFLECT,
			Miss = L.MSG_MISS,
			
			CrowdControl = L.MSG_CROWDCONTROL,
			Break = L.MSG_BREAK,
			Break_NoSource = L.MSG_BREAK_NOSOURCE,
			Break_Spell = L.MSG_BREAK_SPELL,
			
			Death = L.MSG_DEATH,
			Death_Melee = L.MSG_DEATH_MELEE,
			Death_Environmental = L.MSG_DEATH_ENVIRONMENTAL,
			Death_Instakill = L.MSG_DEATH_INSTAKILL,
			
			Save = L.MSG_SAVE,
			Resurrect = L.MSG_RESURRECT,
			Soulstone = L.MSG_SELFRES_SOULSTONE,
			Reincarnation = L.MSG_SELFRES_REINCARNATION,
			
			CAST_START = S.SpellMsg.unit.CAST_START,
			CAST_SUCCESS_NO_DEST = S.SpellMsg.unit.CAST_SUCCESS_NO_DEST,
			CAST_SUCCESS = S.SpellMsg.unit.CAST_SUCCESS,
		},
		
		sink20OutputSink = "None",
	},
}

for k, v in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
	S.defaults.profile.color[k] = CopyTable(v)
end

	---------------
	--- Options ---
	---------------

S.options = {
	type = "group",
	childGroups = "tab",
	name = format("%s |cffADFF2F%s|r", "Ketho |cffFFFFFFCombatLog|r", GetAddOnMetadata(NAME, "Version")),
	args = {
		Main = {
			type = "group", order = 1,
			name = "|TInterface\\Icons\\INV_Sword_01:16:16:0:-1"..S.crop.."|t  Main",
			handler = KCL,
			get = "GetValue", set = "SetValue",
			disabled = "OptionsDisabled",
			args = {
				Local = {
					type = "group", order = 1,
					inline = true,
					name = " ",
					args = {}, -- populated later
				},
				spacing = {type = "description", order = 3, name = ""},
				PvE = {
					type = "toggle", order = 4, width = "half", descStyle = "",
					name = " |cffA8A8FF"..COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATEPVE.."|r", -- /dump ChatTypeInfo.PARTY {r = 0.666, g = 0.666, b = 1.000}
					set = "SetValue_Instance",
				},
				PvP = {
					type = "toggle", order = 5, width = "half", descStyle = "",
					name = " |cffFF7F00"..PVP.."|r", -- /dump ChatTypeInfo.RAID {r = 1.000, g = 0.498, b = 0.000}
					set = "SetValue_Instance",
				},
				World = {
					type = "toggle", order = 6, width = "half", descStyle = "",
					name = " "..CHANNEL_CATEGORY_WORLD,
					set = "SetValue_Instance",
				},
				newline1 = {type = "description", order = 8, name = ""},
				ChatWindow = {
					type = "select", order = 10, descStyle = "",
					name = "   |cffFFFFFF"..CHAT.." Window|r",
					values = function()
						local ChatWindowList = {"|cffFF0000<"..ADDON_DISABLED..">|r"}
						for i = 1, NUM_CHAT_WINDOWS do
							local window = GetChatWindowInfo(i)
							if window ~= "" then
								ChatWindowList[i+1] = "|cff2E9AFE"..i..".|r  "..window
							end
						end
						return ChatWindowList end,
					set = function(i, v)
						profile.ChatWindow = v
						if v > 1 then
							S.ChatFrame = _G["ChatFrame"..v-1]
							S.ChatFrame:AddMessage("|cffADFF2F"..NAME.."|r: Chat Frame |cff57A3FF"..(v-1)..".|r |cffADFF2F"..GetChatWindowInfo(v-1).."|r")
						end
					end,
				},
				ChatChannel = {
					type = "select", order = 9, descStyle = "",
					name = "   |cffFFFFFF"..CHAT.." "..CHANNEL.."|r",
					values = function()
						local ChatChannelList = {
							"|cffFF0000<"..ADDON_DISABLED..">|r",
							"|cff2E9AFE#|r   "..CHAT_MSG_SAY,
							"|cff2E9AFE#|r   |cffFF4040"..CHAT_MSG_YELL.."|r",
							"|cff2E9AFE#|r   |cffA8A8FF"..GROUP.."|r",
						}
						for i = 1, 10 do
							local channelID = select((i*2)-1, GetChannelList())
							if channelID then
								ChatChannelList[channelID+4] = "|cff2E9AFE"..channelID..".|r  "..select(i*2,GetChannelList())
							end
						end
						return ChatChannelList
					end,
					set = function(i, v)
						profile.ChatChannel = v
						KCL:GROUP_ROSTER_UPDATE() -- update channel
					end,
				},
				descEnable = {
					type = "description", order = 13,
					fontSize = "large",
					name = function() return not KCL:IsEnabled() and " Type |cff2E9AFE/ket on|r to enable" or "" end,
				},
			},
		},
		Advanced = {
			type = "group", order = 2,
			name = "|TInterface\\Icons\\Trade_Engineering:16:16:0:-1"..S.crop.."|t  "..ADVANCED_LABEL,
			handler = KCL,
			get = "GetValue", set = "SetValue",
			args = {
				Advanced = {
					type = "group", order = 1,
					name = "|TINTERFACE\\ICONS\\inv_misc_orb_05:14:14:1:0"..S.crop.."|t  |cffFFFFFF"..ADVANCED_LABEL.."|r",
					args = {
						header1 = {type = "header", order = 1, name = "Icons"},
						IconCropped = {
							type = "toggle", order = 2, descStyle = "",
							name = "|TInterface\\Icons\\inv_misc_orb_05:20:20:1:0|t -> |TInterface\\Icons\\inv_misc_orb_05:20:20:1:0:64:64:4:60:4:60|t  Crop",
							disabled = function() return profile.IconSize == 1 end,
							set = function(i, v) profile.IconCropped = v
								S.crop = v and ":64:64:4:60:4:60" or ""
							end,
						},
						IconSize = {
							type = "select", order = 3, descStyle = "", 
							name = "|cffFFFFFF"..EMBLEM_SYMBOL.." Size|r",
							values = S.IconValues,
						},
						header2 = {type = "header", order = 5, name = "Message "..FORMATTING},
						Timestamp = {
							type = "select", order = 6,
							desc = OPTION_TOOLTIP_TIMESTAMPS,
							values = S.xmpl_timestamps,
							name = " "..TIMESTAMPS_LABEL,
						},
						spacing = {type = "description", order = 10, name = ""},
						TrimRealm = {
							type = "toggle", order = 11,
							desc = S.player.name.."|cffFF0000-"..GetRealmName().."|r",
							name = "|cff71D5FFTrim Realm Names|r",
						},
						SpellNotClickable = {
							type = "toggle", order = 13,
							desc = "Use spell names instead of spell links",
							name = "|cff71D5FF"..STAT_CATEGORY_SPELL.." Not Clickable",
						},
						UnitBracesLocal = {
							type = "toggle", order = 12,
							desc = UNIT_NAMES_SHOW_BRACES_COMBATLOG_TOOLTIP,
							name = "|cff71D5FF"..SHOW_BRACES.."|r (Local)",
						},
						UnitBracesChat = {
							type = "toggle", order = 14,
							desc = UNIT_NAMES_SHOW_BRACES_COMBATLOG_TOOLTIP,
							name = "|cff71D5FF"..SHOW_BRACES.."|r ("..CHAT..")",
						},
						header3 = {type = "header", order = 20, name = DAMAGE.." "..FORMATTING},
						OverkillFormat = {
							type = "toggle", order = 21,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_OVERKILLING.."|r",
							name = gsub(TEXT_MODE_A_STRING_RESULT_OVERKILLING, "[%%s ()]", ""),
						},
						CriticalFormat = {
							type = "toggle", order = 22,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_CRITICAL.."|r",
							name = gsub(TEXT_MODE_A_STRING_RESULT_CRITICAL, parentheses, ""),
						},
						GlancingFormat = {
							type = "toggle", order = 23,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_GLANCING .."|r",
							name = gsub(TEXT_MODE_A_STRING_RESULT_GLANCING, parentheses, ""),
						},
						CrushingFormat = {
							type = "toggle", order = 24,
							desc = "<message> |cff71D5FF"..TEXT_MODE_A_STRING_RESULT_CRUSHING.."|r",
							name = gsub(TEXT_MODE_A_STRING_RESULT_CRUSHING, parentheses, ""),
						},
						AbbreviateNumbers = {
							type = "toggle", order = 25, width = "full",
							desc = numberExample.." -> "..AbbreviateLargeNumbers(numberExample),
							name = L.ABBREVIATE_LARGE_NUMBERS,
						},
					},
				},
				Filter = {
					type = "group", order = 2,
					name = "|TInterface\\Icons\\Spell_Holy_Silence:14:14:1:0"..S.crop.."|t  |cffFFFFFF"..FILTERS.."|r",
					args = {
						header1 = {type = "header", order = 1, name = BY_SOURCE.." "..TYPE},
						FilterPlayers = {
							type = "toggle", order = 2, width = "full", descStyle = "",
							name = "|cff57A3FF"..TUTORIAL_TITLE19.."|r",
						},
						FilterPets = {
							type = "toggle", order = 3, width = "full", descStyle = "",
							name = "|cffFFFF00"..PETS.."|r",
						},
						FilterMonsters = {
							type = "toggle", order = 4, width = "full", descStyle = "",
							name = "|cff3FBF3FNPCs|r",
						},
						header2 = {type = "header", order = 5, name = "|TInterface\\Icons\\Spell_Holy_DispelMagic:16:16:1:0"..S.crop.."|t  "..DISPELS},
						FriendlyDispel = {
							type = "toggle", order = 6, width = "full", descStyle = "",
							name = " |TInterface\\Icons\\Spell_Holy_Purify:16:16:1:0"..S.crop.."|t  "..FRIENDLY.." (|cff71D5FF"..ACTION_SPELL_DISPEL_DEBUFF.."|r)",
							disabled = function() return IsNotEvent("Dispel") end,
						},
						HostileDispel = {
							type = "toggle", order = 7, width = "full", descStyle = "",
							name = " |TInterface\\Icons\\Spell_Nature_Purge:16:16:1:0"..S.crop.."|t  "..HOSTILE.." (|cff71D5FF"..ACTION_SPELL_DISPEL_BUFF.."|r)",
							disabled = function() return IsNotEvent("Dispel") end,
						},
						Spellsteal = {
							type = "toggle", order = 8, width = "full", descStyle = "",
							name = " |TInterface\\Icons\\Spell_Arcane_Arcane02:16:16:1:0"..S.crop.."|t  "..S.EventString.Spellsteal[1],
							disabled = function() return IsNotEvent("Dispel") end,
						},
						header3 = {type = "header", order = 9, name = "|TInterface\\Icons\\Spell_Holy_Resurrection:14:14:1:0"..S.crop.."|t  "..RESURRECT},
						CombatRes = {
							type = "toggle", order = 10, width = "full", descStyle = "",
							name = " |TInterface\\Icons\\spell_nature_reincarnation:16:16:1:0"..S.crop.."|t  "..COMBAT.." "..FILTER,
							disabled = function() return IsNotEvent("Resurrect") end,
						},
					},
				},
				Spell = {
					type = "group", order = 3,
					name = "|TInterface\\EncounterJournal\\UI-EJ-Icons:14:14:1:0:64:256:58:62:32:96|t  |cffFFFFFF"..STAT_CATEGORY_SPELL.."|r",
					set = function(i, v) profile[i[#i]] = v; KCL:RefreshSpell(i[#i]) end,
					args = {
						Feast = {
							type = "toggle", order = 2, descStyle = "",
							name = " |TInterface\\Icons\\inv_misc_food_cooked_pabanquet_general:16:16:1:0"..S.crop.."|t  Feast",
						},
						RepairBot = {
							type = "toggle", order = 4, descStyle = "",
							name = " |TInterface\\Icons\\Achievement_Boss_Mimiron_01:16:16:1:0"..S.crop.."|t  Repair Bot",
						},
						Bloodlust = {
							type = "toggle", order = 6, desc = UnitFactionGroup("player") == "Horde" and GetSpellDescription(2825) or GetSpellDescription(32182),
							name = format(" |T%s:16:16:1:0%s|t  |cff71D5FF%s|r", Bloodlust[3], S.crop, Bloodlust[1]),
						},
						Portal = {
							type = "toggle", order = 3, descStyle = "",
							name = " |TInterface\\Icons\\Spell_Arcane_PortalIronForge:16:16:1:0"..S.crop.."|t  Portal",
						},
						Holiday = {
							type = "toggle", order = 5, descStyle = "",
							name = " |TInterface\\Icons\\INV_Misc_Herb_09:16:16:1:0"..S.crop.."|t  |cffF6ADC6Holiday|r",
						},
						Fun = {
							type = "toggle", order = 7, descStyle = "",
							name = " |TInterface\\Icons\\INV_Misc_Bomb_04:16:16:1:0"..S.crop.."|t  |cffF6ADC6Fun|r",
						},
						Misdirection = {
							type = "toggle", order = 8, desc = GetSpellDescription(34477),
							name = " |TInterface\\Icons\\ability_hunter_misdirection:16:16:1:0"..S.crop.."|t  |c"..RAID_CLASS_COLORS.HUNTER.colorStr..GetSpellInfo(34477).."|r",
						},
						TricksTrade = {
							type = "toggle", order = 9, desc = GetSpellDescription(57934),
							name = " |TInterface\\Icons\\ability_rogue_tricksofthetrade:16:16:1:0"..S.crop.."|t  |c"..RAID_CLASS_COLORS.ROGUE.colorStr..GetSpellInfo(57934).."|r",
						},
						header1 = {type = "header", order = 20, name = ""},
						SpellOutput = {
							type = "select", order = 21, descStyle = "",
							name = "Output "..CHANNEL,
							values = {
								L.LOCAL,
								CHAT,
								L.LOCAL.." & "..CHAT,
							},
							get = "GetValue", set = "SetValue",
						},
						ShowSpells = {
							type = "execute", order = 22, descStyle = "",
							name = SHOW.." "..SPELLS,
							func = "DataFrame",
						},
						SpellFilterSelf = {
							type = "toggle", order = 23, descStyle = "",
							name = " |TInterface\\Icons\\Spell_Holy_Silence:16:16:1:0"..S.crop.."|t  |cffFF8000"..FILTER.." "..L.SELF.."|r",
							get = "GetValue", set = "SetValue",
						},
						header2 = {type = "header", order = 24, name = SPELL_MESSAGES},
					},
				},
				Message = {
					type = "group", order = 4,
					name = "|TInterface\\Icons\\INV_Misc_Book_07:14:14:1:0"..S.crop.."|t  |cffFFFFFF"..MESSAGE_TYPES.."|r",
					get = "GetMessage", set = "SetMessage",
					args = {}, -- populated later
				},
				Coloring = {
					type = "group", order = 5,
					name = "|TInterface\\Icons\\INV_Misc_Gem_Variety_02:14:14:1:0"..S.crop.."|t  |cffFFFFFF"..COLORS.."|r",
					get = "GetColor",
					args = { -- populated later
						ColorEnemyPlayers = {
							type = "toggle", order = 1, width = "full",
							desc = L.ENEMY_PLAYERS_CLASS_COLORS,
							name = UNIT_NAME_ENEMY.." "..CLASS_COLORS,
							get = "GetValue", set = "SetValue",
						},
						Physical = {
							type = "color", order = 41, width = .9,
							name = "|TInterface\\Icons\\Spell_Nature_Strength:16:16:1:0"..S.crop.."|t  "..STRING_SCHOOL_PHYSICAL,
							set = "SetSchoolColor",
						},
						Friendly = {
							type = "color", order = 51, width = "full",
							name = "|TInterface\\Icons\\Spell_ChargePositive:16:16:1:0"..S.crop.."|t  "..FRIENDLY,
							set = "SetGeneralColor",
						},
						Hostile = {
							type = "color", order = 52, width = "full",
							name = "|TInterface\\Icons\\Spell_ChargeNegative:16:16:1:0"..S.crop.."|t  "..HOSTILE,
							set = "SetGeneralColor",
						},
						Unknown = {
							type = "color", order = 53, width = "full",
							name = "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:1:0"..S.crop.."|t  "..UNKNOWN,
							set = "SetGeneralColor",
						},
						Timestamp = {
							type = "color", order = 55, width = "full",
							name = "|TInterface\\Icons\\Spell_Holy_BorrowedTime:16:16:1:0"..S.crop.."|t  "..TIMESTAMPS_LABEL,
							set = "SetGeneralColor",
						},
						spacing = {type = "description", order = 60, name = ""},
						Reset = {
							type = "execute", order = 61,
							name = RESET, descStyle = "",
							confirm = true, confirmText = RESET_TO_DEFAULT.."?",
							func = function()
								for k1, v1 in pairs(S.defaults.profile.color) do
									for k2, v2 in pairs(v1) do -- class colors not sequential
										profile.color[k1][k2] = v2
									end
								end
								KCL:WipeCache()
							end,
						},
					},
				},
				LibSink = KCL:GetSinkAce3OptionsDataTable(),
			},
		},
	},
}

local options = S.options

	---------------
	--- Methods ---
	---------------

function KCL:OptionsDisabled()
	return not self:IsEnabled()
end

function KCL:GetValue(i)
	return profile[i[#i]]
end

function KCL:SetValue(i, v)
	profile[i[#i]] = v
end

function KCL:SetValue_Instance(i, v)
	profile[i[#i]] = v
	self:ZONE_CHANGED_NEW_AREA() -- update CLEU
end

function KCL:GetMessage(i)
	return profile.message[i[#i]]
end

function KCL:SetMessage(i, v)
	profile.message[i[#i]] = (v:trim() == "") and S.defaults.profile.message[i[#i]] or v
end

function KCL:GetColor(i)
	return unpack(color[i[#i]])
end

function KCL:GetClassColor(i)
	local c = color[i[#i]]
	return c.r, c.g, c.b
end

function KCL:SetColor(i, r, g, b)
	local c = color[i[#i]]
	c[1] = r
	c[2] = g
	c[3] = b
end

function KCL:SetGeneralColor(i, r, g, b)
	self:SetColor(i, r,g,b)
	S.GeneralColor[i[#i]] = nil
end

function KCL:SetClassColor(i, r, g, b)
	local c = color[i[#i]]
	c.r = r
	c.g = g
	c.b = b
	S.ClassColor[i[#i]] = nil
end

function KCL:SetSchoolColor(i, r, g, b)
	self:SetColor(i, r,g,b)
	S.SpellSchoolColor[S.RemapSchoolColorRev[i[#i]]] = nil
end

	------------
	--- Main ---
	------------

do
	local o = options.args.Main.args.Local.args
	
	for i, v in ipairs(S.Event) do
		o["Chat"..v] = {
			type = "toggle", order = i*2, width = .12,
			desc = CHAT.." "..CHANNEL,
			name = " ",
		}
		
		o["Local"..v] = {
			type = "toggle", order = i*2,
			desc = CHAT.." Window",
			name = function() return format("|TInterface\\Icons\\%s:16:16:1:0%s|t  |cff%s%s|r", S.EventString[v][2], S.crop, S.GeneralColor[v], S.EventString[v][1]) end,
		}
	end
	
	-- (un)register UNIT_HEALTH according to options 
	local function SetResurrect(i, v)
		profile[i[#i]] = v
		KCL:RefreshEvent()
	end
	o.LocalResurrect.set = SetResurrect
	o.ChatResurrect.set = SetResurrect
	
	for i = 1, 4 do
		o["newline"..i] = {type = "description", order = 1+i*4, name = ""}
	end
end

	----------------
	--- Advanced ---
	----------------

do
	local o = options.args.Advanced.args.Spell.args
	
	for i, v in ipairs(S.SpellMsgOptionKey) do
		o[v] = {
			type = "input", order = i+30,
			width = "full", descStyle = "",
			name = "  "..S.SpellMsgOptionValue[v],
			get = "GetMessage", set = "SetMessage",
		}
	end
end

do
	local o = options.args.Advanced.args.Message.args
	
	for i, v in ipairs(S.EventMsg) do
		o[v] = {
			type = "input", order = i,
			width = "full", descStyle = "",
			name = format("  |TInterface\\Icons\\%s:16:16:1:0%s|t  %s", S.EventString[v][2], S.crop, S.EventString[v][1]),
		}
	end
end

do
	local o = options.args.Advanced.args.Coloring.args
	local colorWidth = .9
	
	for i, v in ipairs(S.Event) do
		o[v] = {
			type = "color", order = 2+i, -- 3-12
			width = colorWidth,
			name = format("|TInterface\\Icons\\%s:16:16:1:0%s|t  %s", S.EventString[v][2], S.crop, S.EventString[v][1]),
			set = "SetGeneralColor",
		}
	end
	
	if CUSTOM_CLASS_COLORS then
		o.notification = {
			type = "description", order = 21,
			fontSize = "large",
			name = L.USE_CLASS_COLORS,
		}
	else
		for i, v in ipairs(S.Class) do
			o[v] = {
				type = "color", order = 20+i, -- 21-31
				width = colorWidth,
				name = format("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:1:0:%s|t  %s", S.ClassCoords[v], LOCALIZED_CLASS_NAMES_MALE[v]),
				get = "GetClassColor",
				set = "SetClassColor",
			}
		end
	end
	
	for i, v in pairs(S.School) do
		o[v] = {
			type = "color", order = 40+i, -- 41-47
			width = colorWidth,
			name = format("|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon%s:16:16:1:0%s|t  %s", S.SchoolRemap[v], S.crop, S.SchoolString[v]),
			set = "SetClassColor",
		}
	end
	
	for i, v in ipairs{2, 20, 40, 50, 54} do
		o["header"..i] = {type = "header", order = v, name = ""}
	end
end

	---------------
	--- LibSink ---
	---------------

local libsink = options.args.Advanced.args.LibSink
libsink.name = "|TInterface\\Icons\\INV_Elemental_Primal_Water:14:14:1:0"..S.crop.."|t  |cffFFFFFFLibSink|r"
libsink.order = 6

	-----------------
	--- DataFrame ---
	-----------------

local SpellDataString

-- I peeked into Prat's CopyChat code for the ScrollFrame & EditBox <.<
-- and FloatingChatFrameTemplate for the ResizeButton >.>
function KCL:DataFrame()
	if not KethoCombatLogData then
		local f = CreateFrame("Frame", "KethoCombatLogData", UIParent, "DialogBoxFrame")
		f:SetPoint("CENTER"); f:SetSize(600, 500)
		
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
			edgeSize = 16,
			insets = { left = 8, right = 6, top = 8, bottom = 8 },
		})
		f:SetBackdropBorderColor(0, .44, .87, 0.5)
		
	---------------
	--- Movable ---
	---------------
		
		f:EnableMouse(true) -- also seems to be automatically enabled when setting the OnMouseDown script
		f:SetMovable(true); f:SetClampedToScreen(true)
		f:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				self:StartMoving()
			end
		end)
		f:SetScript("OnMouseUp", f.StopMovingOrSizing)
		
	-------------------
	--- ScrollFrame ---
	-------------------
		
		local sf = CreateFrame("ScrollFrame", "KethoCombatLogDataScrollFrame", KethoCombatLogData, "UIPanelScrollFrameTemplate")
		sf:SetPoint("LEFT", 16, 0)
		sf:SetPoint("RIGHT", -32, 0)
		sf:SetPoint("TOP", 0, -16)
		sf:SetPoint("BOTTOM", KethoCombatLogDataButton, "TOP", 0, 0)
		
	---------------
	--- EditBox ---
	---------------
		
		local eb = CreateFrame("EditBox", "KethoCombatLogDataEditBox", KethoCombatLogDataScrollFrame)
		eb:SetSize(sf:GetSize()) -- seems inheriting the points won't automatically set the width/size
		
		eb:SetMultiLine(true)
		eb:SetFontObject("ChatFontNormal")
		eb:SetAutoFocus(false) -- make keyboard not automatically focused to this editbox
		eb:SetScript("OnEscapePressed", function(self)
			--self:ClearFocus()
			f:Hide() -- rather hide, since we only use it for copying to clipboard
		end)
		
		sf:SetScrollChild(eb)
		
	-----------------
	--- Resizable ---
	-----------------
		
		f:SetResizable(true)
		f:SetMinResize(150, 100) -- at least show the "okay" button
		
		local rb = CreateFrame("Button", "KethoCombatLogDataResizeButton", KethoCombatLogData)
		rb:SetPoint("BOTTOMRIGHT", -6, 7); rb:SetSize(16, 16)
		
		rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		
		rb:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				f:StartSizing("BOTTOMRIGHT")
				self:GetHighlightTexture():Hide() -- we only want to see the PushedTexture now 
			end
		end)
		rb:SetScript("OnMouseUp", function(self, button)
			f:StopMovingOrSizing()
			self:GetHighlightTexture():Show()
			eb:SetWidth(sf:GetWidth()) -- update editbox to the new scrollframe width
		end)
		
		f:Show()
	else
		KethoCombatLogData:Show()
	end
	
	if ACD.OpenFrames.KethoCombatLog_Parent then
		-- the ACD window's Strata is "FULLSCREEN_DIALOG", and changing FrameLevels seems troublesome
		KethoCombatLogData:SetFrameStrata("TOOLTIP")
	end
	GameTooltip:Hide() -- most likely the popup frame will prevent the GameTooltip's OnLeave script from firing
	
	SpellDataString = SpellDataString or self:GetSpellData() -- around 6500 string length
	KethoCombatLogDataEditBox:SetText(SpellDataString)
end

-- just want to have a way to show the user the spell data
function KCL:GetSpellData()
	local s = "|cffFF0000Note:|r This is |cffFFFF00Read-only|r information, nothing here can be actually changed or saved. I don't know how to do that...\n"
	for _, v1 in pairs(S.SpellGroupOrder) do
		s = s..format("\n%s = {\n", v1)
		-- sort spells by id so it looks nice
		for _, v2 in ipairs(S.SortTable(S.Spell[v1])) do
			-- tab characters are not supported in a widget, have to do with 6 spaces to make it look indented :(
			s = s..format('      [%d] = "%s", |cff509F00-- [%s]|r\n', v2, S.Spell[v1][v2], GetSpellInfo(v2) or "")
		end
		s = s.."},\n" -- not actually correct Lua table syntax since I omitted the parent table
	end
	return s
end
