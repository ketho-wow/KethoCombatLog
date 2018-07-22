local _, S = ...

-- there is no real support yet for custom spells, just part of the framework
-- the current spell groups can be modified though to your liking. Dont forget to backup your file (or use a separate work doc) when updating
-- for adding new spell groups, you would still have to change the other source code as well 
S.Spell = {
	Feast = {
		[56245] = "CREATE", -- [Chocolate Celebration Cake]
		[56255] = "CREATE", -- [Lovely Cake]
		[57301] = "CREATE", -- [Great Feast]
		[57426] = "CREATE", -- [Fish Feast]
		[58465] = "CREATE", -- [Gigantic Feast]
		[58474] = "CREATE", -- [Small Feast]
		[66476] = "CREATE", -- [Bountiful Feast]
		[87644] = "CREATE", -- [Seafood Magnifique Feast]
		[87643] = "CREATE", -- [Broiled Dragon Feast]
		[87915] = "CREATE", -- [Goblin Barbecue Feast]
		[92649] = "CREATE", -- [Cauldron of Battle]
		[92712] = "CREATE", -- [Big Cauldron of Battle]
		
		[104958] = "CREATE", -- Pandaren Banquet, 275 primary stat or 375 stamina
		[126503] = "CREATE", -- Banquet of the Brew, 250 primary stat or 375 stamina
		[126501] = "CREATE", -- Banquet of the Oven, 250 primary stat or 415 stamina
		[126492] = "CREATE", -- Banquet of the Grill, 250 primary stat or 275 strength or 375 stamina
		[126497] = "CREATE", -- Banquet of the Pot, 250 primary stat or 275 intellect or 375 stamina
		[126499] = "CREATE", -- Banquet of the Steamer, 250 primary stat or 275 spirit or 375 stamina
		[126495] = "CREATE", -- Banquet of the Wok, 250 primary stat or 275 agility or 375 stamina
		-- "Great" Banquets have 25 charges, otherwise identical
		[105193] = "CREATE", -- Great Pandaren Banquet, 275 primary stat or 375 stamina
		[126504] = "CREATE", -- Great Banquet of the Brew, 250 primary stat or 375 stamina
		[126494] = "CREATE", -- Great Banquet of the Oven, 250 primary stat or 415 stamina
		[126502] = "CREATE", -- Great Banquet of the Grill, 250 primary stat or 275 strength or 375 stamina
		[126498] = "CREATE", -- Great Banquet of the Pot, 250 primary stat or 275 intellect or 375 stamina
		[126498] = "CREATE", -- Great Banquet of the Steamer, 250 primary stat or 275 spirit or 375 stamina
		[126496] = "CREATE", -- Great Banquet of the Wok, 250 primary stat or 275 agility or 375 stamina
		
		[146933] = "SUMMON", -- Noodle Cart
		[146934] = "SUMMON", -- Deluxe Noodle Cart
		[146935] = "SUMMON", -- Pandaren Treasure Noodle Cart
		
		[175215] = "CREATE", -- Savage Feast
	},
	RepairBot = {
		[22700] = "SUMMON", -- [Field Repair Bot 74A]
		[44389] = "SUMMON", -- [Field Repair Bot 110G]
		[54710] = "CREATE", -- [MOLL-E]
		[54711] = "SUMMON", -- [Scrapbot]
		[67826] = "SUMMON", -- [Jeeves]
		[126459] = "SUMMON", -- [Blingtron 4000]
		[161414] = "SUMMON", -- [Blingtron 5000]
		[126462] = "CAST_SUCCESS", -- [Thermal Anvil] CREATE fires twice (Forge and Anvil)
		[200061] = "CAST_SUCCESS", -- [Summon Reaves]
	},
	Bloodlust = {
		[2825] = "CAST_SUCCESS", -- Bloodlust
		[32182] = "CAST_SUCCESS", -- Heroism
		[80353] = "CAST_SUCCESS", -- Time Warp
		[90355] = "CAST_SUCCESS", -- Core Hound: Ancient Hysteria
		[160452] = "CAST_SUCCESS", -- Nether Ray: Netherwinds
		[178207] = "CAST_SUCCESS", -- Drums of Fury
	},
	Portal = {
		[10059] = "CREATE", -- "Portal: Stormwind"
		[11416] = "CREATE", -- "Portal: Ironforge"
		[49360] = "CREATE", -- "Portal: Theramore"
		[32266] = "CREATE", -- "Portal: Exodar"
		[11419] = "CREATE", -- "Portal: Darnassus"
		[33691] = "CREATE", -- "Portal: Shattrath" (Alliance)
		[88345] = "CREATE", -- "Portal: Tol Barad" (Alliance)
		[132620] = "CREATE", -- "Portal: Vale of Eternal Blossoms" (Alliance)
		
		[11417] = "CREATE", -- "Portal: Orgrimmar"
		[35717] = "CREATE", -- "Portal: Shattrath" (Horde)
		[49361] = "CREATE", -- "Portal: Stonard"
		[32267] = "CREATE", -- "Portal: Silvermoon"
		[11420] = "CREATE", -- "Portal: Thunder Bluff"
		[11418] = "CREATE", -- "Portal: Undercity"
		[88346] = "CREATE", -- "Portal: Tol Barad" (Horde)
		[132626] = "CREATE", -- "Portal: Vale of Eternal Blossoms" (Horde)
		
		[53142] = "CREATE", -- "Portal: Dalaran - Northrend"
		[224871] = "CREATE", -- "Portal: Dalaran - Broken Isles"
		[120146] = "CREATE", -- "Ancient Portal: Dalaran"
		[67833] = "SUMMON", -- "Wormhole" [Wormhole Generator: Northrend]
	},
	Holiday = {
	-- Hallow's End
		[24717] = "AURA_APPLIED", -- [Pirate Costume]
		[24718] = "AURA_APPLIED", -- [Ninja Costume]
		[24719] = "AURA_APPLIED", -- [Leper Gnome Costume]
		[24720] = "AURA_APPLIED", -- [Random Costume]
		[24724] = "AURA_APPLIED", -- [Skeleton Costume]
		[24733] = "AURA_APPLIED", -- [Bat Costume]
		[24737] = "AURA_APPLIED", -- [Ghost Costume]
		[24741] = "AURA_APPLIED", -- [Wisp Costume]
		[44212] = "AURA_APPLIED", -- [Jack-o'-Lanterned!]
	-- Feast of Winter Veil
		[25677] = "CAST_SUCCESS", -- [Hardpacked Snowball] 
		[26004] = "AURA_APPLIED", -- [Mistletoe]
		[44755] = "AURA_APPLIED", -- [Snowflakes]
	-- Midsummer Fire Festival
		[45417] = "AURA_APPLIED", -- [Handful of Summer Petals]
		[46661] = "CAST_SUCCESS", -- [Huge Snowball]
	-- Love is in the Air
		[61415] = "AURA_APPLIED", -- [Bouquet of Ebon Roses] [Cascade of Ebon Petals]
		[27571] = "AURA_APPLIED", -- [Bouquet of Red Roses] [Cascade of Roses]
	-- Noblegarden
		[61717] = "AURA_APPLIED", -- [Blossoming Branch]
		[61815] = "AURA_APPLIED", -- [Sprung!]
	-- Pilgrim's Bounty
		[61781] = "AURA_APPLIED", -- [Turkey Feathers]
	},
	Fun = {
		[8690] = "CAST_START", -- Hearthstone aka Homerock :)
		[58493] = "CAST_START", -- Mohawk Grenade
		
		[23135] = "CAST_SUCCESS", -- Heavy Leather Ball
		[23065] = "CAST_SUCCESS", -- Happy Fun Rock
		[42383] = "CAST_SUCCESS", -- Voodoo Skull
		[45129] = "CAST_SUCCESS", -- Paper Zeppelin
		[45133] = "CAST_SUCCESS", -- Paper Flying Machine
		
		[43808] = "CREATE", -- Brewfest Pony Keg
		[45426] = "SUMMON", -- "Brazier of Dancing Flames"
		[49844] = "CREATE", -- Using Direbrew's Remote
		[61031] = "CREATE", -- Toy Train Set
		[107926] = "SUMMON", -- Sandbox Tiger
		
		[135007] = "SUMMON", -- Sandbox Tiger
		[135008] = "SUMMON", -- Sandbox Tiger
		[135009] = "SUMMON", -- Sandbox Tiger
		[107926] = "SUMMON", -- Sandbox Tiger
		
		[6405] = "CAST_SUCCESS", -- "Furbolg Form"
		[58501] = "CAST_SUCCESS", -- "Iron Boot Flask"
		[75531] = "CAST_SUCCESS", -- "Gnomeregan Pride"
		[127207] = "CAST_SUCCESS", -- "Memory of Mr. Smite" -- no cleu event
		[127315] = "CAST_SUCCESS", -- "Skymirror Image" -- no cleu event
		[127323] = "CAST_SUCCESS", -- "Beach Bum" -- no cleu event
		[131493] = "AURA_APPLIED", -- "B.F.F."
		[145255] = "CAST_SUCCESS", -- "Aspect of Moonfang"
		
		[126] = "SUMMON", -- Eye of Kilrogg (Demonology)
		[130] = "AURA_APPLIED", -- Slow Fall
		[2096] = "CAST_SUCCESS", -- Mind Vision -- for AURA_APPLIED its also cast on self
		[6196] = "CAST_SUCCESS", -- Far Sight (Enhancement)
		[6197] = "CAST_SUCCESS", -- Eagle Eye (Beast Mastery)
		[111759] = "AURA_APPLIED", -- Levitate
	},
	Misdirection = {[34477] = "AURA_APPLIED"}, -- 35079 for self
	TricksTrade = {[57934] = "CAST_SUCCESS"}, -- for AURA_APPLIED its also cast on self
}


S.Taunt = {
	[355] = true, -- Warrior: [Taunt]
	[6795] = true, -- Druid: [Growl]
	[20736] = true, -- Hunter: [Distracting Shot]
	[116189] = true, -- Monk: [Provoke]; 115546
	[185245] = true, -- Demon Hunter: [Torment]
-- Death Knight
	[49560] = true, -- [Death Grip]
	[51399] = true, -- [Death Grip] (melee range)
	[56222] = true, -- [Dark Command]
-- Paladin
	[31790] = true, -- [Righteous Defense]
	[62124] = true, -- [Hand of Reckoning]
-- Pet
	[2649] = true, -- Hunter: Pet: [Growl]
	[17735] = true, -- Warlock: Voidwalker: [Suffering]
	[36213] = true, -- Shaman: Greater Earth Elemental: [Angered Earth]
}

-- actually used only for jukes
S.Interrupt = {
	[1766] = true, -- Rogue: [Kick]
	[2139] = true, -- Mage: [Counterspell]
	[6552] = true, -- Warrior: [Pummel]
	--[15487] = true, -- Priest: [Silence]
	[47528] = true, -- Death Knight: [Mind Freeze]
	--[47476] = true, -- Death Knight: [Strangulate]
	[183752] = true, -- Demon Hunter: [Consume Magic]
	[147362] = true, -- Hunter: [Counter Shot]
	--[34490] = true, -- Hunter: [Silencing Shot]
	[57994] = true, -- Shaman: [Wind Shear]
	[96231] = true, -- Paladin: [Rebuke]
	[116705] = true, -- Monk: [Spear Hand Strike] (silence)
-- Druid
	[80964] = true, -- [Skull Bash] (Bear); pre-interrupt
	[80965] = true, -- [Skull Bash] (Cat); pre-interrupt
	[93985] = true, -- [Skull Bash; Interrupt
	--[78675] = true, -- [Solar Beam]
}

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

S.Blacklist = {
	[48743] = true, -- SPELL_INSTAKILL, Death Knight: [Death Pact] 
	[49560] = true, -- SPELL_MISSED, Death Knight: [Death Grip] 
	[81280] = true, -- SPELL_INSTAKILL, Death Knight: Bloodworm: [Blood Burst]
	[108503] = true, -- SPELL_INSTAKILL, Warlock: [Grimoire of Sacrifice]
	[123982] = true, -- SPELL_INSTAKILL, Death Knight: [Purgatory]
	[196278] = true, -- SPELL_INSTAKILL, Warlock: [Implosion]
}

-- ignore dummies
S.TrainingDummy = {
	[32666] = true, -- [Training Dummy] (Level 60)
	[32667] = true, -- [Training Dummy] (Level 70)
	[31144] = true, -- [Training Dummy] (Level 80)
	[46647] = true, -- [Training Dummy] (Level 85)
	[67127] = true, -- [Training Dummy] (Level 90)
	[31146] = true, -- [Raider's Training Dummy]
	[114832] = true, -- PvP Training Dummy
	-- wod
	[87318] = true, -- "Dungeoneer's Training Dummy" (Damage)
	[88314] = true, -- "Dungeoneer's Training Dummy" (Tanking)
}
