--[[
Name: LibBabble-Faction-3.0
Revision: $Rev: 70 $
Author(s): Daviesh (oma_daviesh@hotmail.com)
Documentation: http://www.wowace.com/wiki/Babble-Faction-3.0
SVN: http://svn.wowace.com/wowace/trunk/LibBabble-Faction-3.0
Dependencies: None
License: MIT
--]]

local MAJOR_VERSION = "LibBabble-Faction-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 1.2 $"):match("%d+"))

-- #AUTODOC_NAMESPACE prototype

local GAME_LOCALE = GetLocale()
do
	-- LibBabble-Core-3.0 is hereby placed in the Public Domain
	-- Credits: ckknight
	local LIBBABBLE_MAJOR, LIBBABBLE_MINOR = "LibBabble-3.0", 2

	local LibBabble = LibStub:NewLibrary(LIBBABBLE_MAJOR, LIBBABBLE_MINOR)
	if LibBabble then
		local data = LibBabble.data or {}
		for k,v in pairs(LibBabble) do
			LibBabble[k] = nil
		end
		LibBabble.data = data

		local tablesToDB = {}
		for namespace, db in pairs(data) do
			for k,v in pairs(db) do
				tablesToDB[v] = db
			end
		end
		
		local function warn(message)
			local _, ret = pcall(error, message, 3)
			geterrorhandler()(ret)
		end

		local lookup_mt = { __index = function(self, key)
			local db = tablesToDB[self]
			local current_key = db.current[key]
			if current_key then
				self[key] = current_key
				return current_key
			end
			local base_key = db.base[key]
			local real_MAJOR_VERSION
			for k,v in pairs(data) do
				if v == db then
					real_MAJOR_VERSION = k
					break
				end
			end
			if not real_MAJOR_VERSION then
				real_MAJOR_VERSION = LIBBABBLE_MAJOR
			end
			if base_key then
				warn(("%s: Translation %q not found for locale %q"):format(real_MAJOR_VERSION, key, GAME_LOCALE))
				rawset(self, key, base_key)
				return base_key
			end
			warn(("%s: Translation %q not found."):format(real_MAJOR_VERSION, key))
			rawset(self, key, key)
			return key
		end }

		local function initLookup(module, lookup)
			local db = tablesToDB[module]
			for k in pairs(lookup) do
				lookup[k] = nil
			end
			setmetatable(lookup, lookup_mt)
			tablesToDB[lookup] = db
			db.lookup = lookup
			return lookup
		end

		local function initReverse(module, reverse)
			local db = tablesToDB[module]
			for k in pairs(reverse) do
				reverse[k] = nil
			end
			for k,v in pairs(db.current) do
				reverse[v] = k
			end
			tablesToDB[reverse] = db
			db.reverse = reverse
			db.reverseIterators = nil
			return reverse
		end

		local prototype = {}
		local prototype_mt = {__index = prototype}

		--[[---------------------------------------------------------------------------
		Notes:
			* If you try to access a nonexistent key, it will warn but allow the code to pass through.
		Returns:
			A lookup table for english to localized words.
		Example:
			local B = LibStub("LibBabble-Module-3.0") -- where Module is what you want.
			local BL = B:GetLookupTable()
			assert(BL["Some english word"] == "Some localized word")
			DoSomething(BL["Some english word that doesn't exist"]) -- warning!
		-----------------------------------------------------------------------------]]
		function prototype:GetLookupTable()
			local db = tablesToDB[self]

			local lookup = db.lookup
			if lookup then
				return lookup
			end
			return initLookup(self, {})
		end
		--[[---------------------------------------------------------------------------
		Notes:
			* If you try to access a nonexistent key, it will return nil.
		Returns:
			A lookup table for english to localized words.
		Example:
			local B = LibStub("LibBabble-Module-3.0") -- where Module is what you want.
			local B_has = B:GetUnstrictLookupTable()
			assert(B_has["Some english word"] == "Some localized word")
			assert(B_has["Some english word that doesn't exist"] == nil)
		-----------------------------------------------------------------------------]]
		function prototype:GetUnstrictLookupTable()
			local db = tablesToDB[self]

			return db.current
		end
		--[[---------------------------------------------------------------------------
		Notes:
			* If you try to access a nonexistent key, it will return nil.
			* This is useful for checking if the base (English) table has a key, even if the localized one does not have it registered.
		Returns:
			A lookup table for english to localized words.
		Example:
			local B = LibStub("LibBabble-Module-3.0") -- where Module is what you want.
			local B_hasBase = B:GetBaseLookupTable()
			assert(B_hasBase["Some english word"] == "Some english word")
			assert(B_hasBase["Some english word that doesn't exist"] == nil)
		-----------------------------------------------------------------------------]]
		function prototype:GetBaseLookupTable()
			local db = tablesToDB[self]

			return db.base
		end
		--[[---------------------------------------------------------------------------
		Notes:
			* If you try to access a nonexistent key, it will return nil.
			* This will return only one English word that it maps to, if there are more than one to check, see :GetReverseIterator("word")
		Returns:
			A lookup table for localized to english words.
		Example:
			local B = LibStub("LibBabble-Module-3.0") -- where Module is what you want.
			local BR = B:GetReverseLookupTable()
			assert(BR["Some localized word"] == "Some english word")
			assert(BR["Some localized word that doesn't exist"] == nil)
		-----------------------------------------------------------------------------]]
		function prototype:GetReverseLookupTable()
			local db = tablesToDB[self]

			local reverse = db.reverse
			if reverse then
				return reverse
			end
			return initReverse(self, {})
		end
		local blank = {}
		local weakVal = {__mode='v'}
		--[[---------------------------------------------------------------------------
		Arguments:
			string - the localized word to chek for.
		Returns:
			An iterator to traverse all English words that map to the given key
		Example:
			local B = LibStub("LibBabble-Module-3.0") -- where Module is what you want.
			for word in B:GetReverseIterator("Some localized word") do
				DoSomething(word)
			end
		-----------------------------------------------------------------------------]]
		function prototype:GetReverseIterator(key)
			local db = tablesToDB[self]
			local reverseIterators = db.reverseIterators
			if not reverseIterators then
				reverseIterators = setmetatable({}, weakVal)
				db.reverseIterators = reverseIterators
			elseif reverseIterators[key] then
				return pairs(reverseIterators[key])
			end
			local t
			for k,v in pairs(db.current) do
				if v == key then
					if not t then
						t = {}
					end
					t[k] = true
				end
			end
			reverseIterators[key] = t or blank
			return pairs(reverseIterators[key])
		end
		--[[---------------------------------------------------------------------------
		Returns:
			An iterator to traverse all translations English to localized.
		Example:
			local B = LibStub("LibBabble-Module-3.0") -- where Module is what you want.
			for english, localized in B:Iterate() do
				DoSomething(english, localized)
			end
		-----------------------------------------------------------------------------]]
		function prototype:Iterate()
			local db = tablesToDB[self]

			return pairs(db.current)
		end

		-- #NODOC
		-- modules need to call this to set the base table
		function prototype:SetBaseTranslations(base)
			local db = tablesToDB[self]
			local oldBase = db.base
			if oldBase then
				for k in pairs(oldBase) do
					oldBase[k] = nil
				end
				for k, v in pairs(base) do
					oldBase[k] = v
				end
				base = oldBase
			else
				db.base = base
			end
			for k,v in pairs(base) do
				if v == true then
					base[k] = k
				end
			end
		end

		local function init(module)
			local db = tablesToDB[module]
			if db.lookup then
				initLookup(module, db.lookup)
			end
			if db.reverse then
				initReverse(module, db.reverse)
			end
			db.reverseIterators = nil
		end

		-- #NODOC
		-- modules need to call this to set the current table. if current is true, use the base table.
		function prototype:SetCurrentTranslations(current)
			local db = tablesToDB[self]
			if current == true then
				db.current = db.base
			else
				local oldCurrent = db.current
				if oldCurrent then
					for k in pairs(oldCurrent) do
						oldCurrent[k] = nil
					end
					for k, v in pairs(current) do
						oldCurrent[k] = v
					end
					current = oldCurrent
				else
					db.current = current
				end
			end
			init(self)
		end

		for namespace, db in pairs(data) do
			setmetatable(db.module, prototype_mt)
			init(db.module)
		end

		-- #NODOC
		-- modules need to call this to create a new namespace.
		function LibBabble:New(namespace, minor)
			local module, oldminor = LibStub:NewLibrary(namespace, minor)
			if not module then
				return
			end

			if not oldminor then
				local db = {
					module = module,
				}
				data[namespace] = db
				tablesToDB[module] = db
			else
				for k,v in pairs(module) do
					module[k] = nil
				end
			end

			setmetatable(module, prototype_mt)

			return module
		end
	end
end

local lib = LibStub("LibBabble-3.0"):New(MAJOR_VERSION, MINOR_VERSION)
if not lib then
	return
end

lib:SetBaseTranslations {
	--Player Factions
	["Alliance"] = true,
	["Horde"] = true,

	-- Classic Factions
	["Argent Dawn"] = true,
	["Bloodsail Buccaneers"] = true,
	["Booty Bay"] = true,
	["Brood of Nozdormu"] = true,
	["Cenarion Circle"] = true,
	["Darkmoon Faire"] = true,
	["Darkspear Trolls"] = true,
	["Darnassus"] = true,
	["Everlook"] = true,
	["Frostwolf Clan"] = true,
	["Gadgetzan"] = true,
	["Gelkis Clan Centaur"] = true,
	["Gnomeregan Exiles"] = true,
	["Hydraxian Waterlords"] = true,
	["Ironforge"] = true,
	["Magram Clan Centaur"] = true,
	["Orgrimmar"] = true,
	["Ratchet"] = true,
	["Ravenholdt"] = true,
	["Shen'dralar"] = true,
	["Silverwing Sentinels"] = true,
	["Stormpike Guard"] = true,
	["Stormwind"] = true,
	["Syndicate"] = true,
	["The Defilers"] = true,
	["The League of Arathor"] = true,
	["Thorium Brotherhood"] = true,
	["Thunder Bluff"] = true,
	["Timbermaw Hold"] = true,
	["Undercity"] = true,
	["Warsong Outriders"] = true,
	["Wildhammer Clan"] = true,
	["Wintersaber Trainers"] = true,
	["Zandalar Tribe"] = true,

	-- Burning Crusade Factions
	["Ashtongue Deathsworn"] = true,
	["Cenarion Expedition"] = true,
	["Exodar"] = true,
	["Honor Hold"] = true,
	["Keepers of Time"] = true,
	["Kurenai"] = true,
	["Lower City"] = true,
	["Netherwing"] = true,
	["Ogri'la"] = true,
	["Sha'tari Skyguard"] = true,
	["Shattered Sun Offensive"] = true,
	["Silvermoon City"] = true,
	["Sporeggar"] = true,
	["The Aldor"] = true,
	["The Consortium"] = true,
	["The Mag'har"] = true,
	["The Scale of the Sands"] = true,
	["The Scryers"] = true,
	["The Sha'tar"] = true,
	["The Violet Eye"] = true,
	["Thrallmar"] = true,
	["Tranquillien"] = true,

	--WotLK Factions (Beta data, may change)
	["Alliance Vanguard"] = true,
	["Argent Crusade"] = true,
	["Explorers' League"] = true,
	["Frenzyheart Tribe"] = true,
	["Horde Expedition"] = true,
	["Kirin Tor"] = true,
	["Knights of the Ebon Blade"] = true,
	["The Frostborn"] = true,
	["The Hand of Vengeance"] = true,
	["The Kalu'ak"] = true,
	["The Oracles"] = true,
	["The Silver Covenant"] = true,
	["The Sons of Hodir"] = true,
	["The Sunreavers"] = true,
	["The Taunka"] = true,
	["The Wyrmrest Accord"] = true,
	["Valiance Expedition"] = true,
	["Warsong Offensive"] = true,
	["Winterfin Retreat"] = true,

	--Rep Levels
	["Neutral"] = true,
	["Friendly"] = true,
	["Honored"] = true,
	["Revered"] = true,
	["Exalted"] = true,
}

if GAME_LOCALE == "enUS" then
	lib:SetCurrentTranslations(true)
elseif GAME_LOCALE == "deDE" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "Allianz",
	["Horde"] = "Horde",

	-- Classic Factions
	["Argent Dawn"] = "Argentumdämmerung",
	["Bloodsail Buccaneers"] = "Blutsegelbukaniere",
	["Booty Bay"] = "Beutebucht",
	["Brood of Nozdormu"] = "Nozdormus Brut",
	["Cenarion Circle"] = "Zirkel des Cenarius",
	["Darkmoon Faire"] = "Dunkelmond-Jahrmarkt",
	["Darkspear Trolls"] = "Dunkelspeertrolle",
	["Darnassus"] = "Darnassus",
	["The Defilers"] = "Die Entweihten",
	["Everlook"] = "Ewige Warte",
	["Frostwolf Clan"] = "Frostwolfklan",
	["Gadgetzan"] = "Gadgetzan",
	["Gelkis Clan Centaur"] = "Gelkisklan",
	["Gnomeregan Exiles"] = "Gnomeregangnome",
	["Hydraxian Waterlords"] = "Hydraxianer",
	["Ironforge"] = "Eisenschmiede",
	["The League of Arathor"] = "Der Bund von Arathor",
	["Magram Clan Centaur"] = "Magramklan",
	["Orgrimmar"] = "Orgrimmar",
	["Ratchet"] = "Ratschet",
	["Ravenholdt"] = "Rabenholdt",
	["Silverwing Sentinels"] = "Silberschwingen",
	["Shen'dralar"] = "Shen'dralar",
	["Stormpike Guard"] = "Sturmlanzengarde",
	["Stormwind"] = "Sturmwind",
	["Syndicate"] = "Syndikat",
	["Thorium Brotherhood"] = "Thoriumbruderschaft",
	["Thunder Bluff"] = "Donnerfels",
	["Timbermaw Hold"] = "Holzschlundfeste",
	["Undercity"] = "Unterstadt",
	["Warsong Outriders"] = "Vorhut des Kriegshymnenklan",
	["Wildhammer Clan"] = "Wildhammerklan",
	["Wintersaber Trainers"] = "Wintersäblerausbilder",
	["Zandalar Tribe"] = "Stamm der Zandalar",

	-- Burning Crusade Factions
	["The Aldor"] = "Die Aldor",
	["Ashtongue Deathsworn"] = "Die Todeshörigen",
	["Cenarion Expedition"] = "Expedition des Cenarius",
	["The Consortium"] = "Das Konsortium",
	["Exodar"] = "Die Exodar",
	["Honor Hold"] = "Ehrenfeste",
	["Keepers of Time"] = "Hüter der Zeit",
	["Kurenai"] = "Kurenai",
	["Lower City"] = "Unteres Viertel",
	["The Mag'har"] = "Die Mag'har",
	["Netherwing"] = "Netherschwingen",
	["Ogri'la"] = "Ogri'la",
	["The Scale of the Sands"] = "Die Wächter der Sande",
	["The Scryers"] = "Die Seher",
	["The Sha'tar"] = "Die Sha'tar",
	["Sha'tari Skyguard"] = "Himmelswache der Sha'tari",
	["Shattered Sun Offensive"] = "Offensive der Zerschmetterten Sonne",
	["Silvermoon City"] = "Silbermond",
	["Sporeggar"] = "Sporeggar",
	["Thrallmar"] = "Thrallmar",
	["Tranquillien"] = "Tristessa",
	["The Violet Eye"] = "Das Violette Auge",

	--WotLK Factions (Beta data, may change)
	["Argent Crusade"] = "Argentumkreuzzug",
	["Frenzyheart Tribe"] = "Stamm der Wildherzen",
	["Knights of the Ebon Blade"] = "Ritter der Schwarzen Klinge",
	["Kirin Tor"] = "Kirin Tor",
	["The Sons of Hodir"] = "Die Söhne Hodirs",
	["The Kalu'ak"] = "Die Kalu'ak",
	["The Oracles"] = "Die Orakel",
	["The Wyrmrest Accord"] = "Der Wyrmruhpakt",
	["The Silver Covenant"] = "Der Silberbund",
	["The Sunreavers"] = "Die Sonnenhäscher",
	["Explorers' League"] = "Forscherliga",
	["Valiance Expedition"] = "Expedition Valianz",
	["The Hand of Vengeance"] = "Die Hand der Rache",
	["The Taunka"] = "Die Taunka",
	["Warsong Offensive"] = "Kriegshymnenoffensive",
	["Winterfin Retreat"] = "Winterfin Retreat",
	["Alliance Vanguard"] = "Vorposten der Allianz",
	["Horde Expedition"] = "Expedition der Horde",

	--Rep Levels
	["Neutral"] = "Neutral",
	["Friendly"] = "Freundlich",
	["Honored"] = "Wohlwollend",
	["Revered"] = "Respektvoll",
	["Exalted"] = "Ehrfürchtig",
}
elseif GAME_LOCALE == "frFR" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "Alliance",
	["Horde"] = "Horde",

	-- Classic Factions
	["Argent Dawn"] = "Aube d'argent",
	["Bloodsail Buccaneers"] = "La Voile sanglante",
	["Booty Bay"] = "Baie-du-Butin",
	["Brood of Nozdormu"] = "Progéniture de Nozdormu",
	["Cenarion Circle"] = "Cercle cénarien",
	["Darkmoon Faire"] = "Foire de Sombrelune",
	["Darkspear Trolls"] = "Trolls Sombrelance",
	["Darnassus"] = "Darnassus",
	["Everlook"] = "Long-guet",
	["Frostwolf Clan"] = "Clan Loup-de-givre",
	["Gadgetzan"] = "Gadgetzan",
	["Gelkis Clan Centaur"] = "Centaures (Gelkis)",
	["Gnomeregan Exiles"] = "Exilés de Gnomeregan",
	["Hydraxian Waterlords"] = "Les Hydraxiens",
	["Ironforge"] = "Forgefer",
	["Magram Clan Centaur"] = "Centaures (Magram)",
	["Orgrimmar"] = "Orgrimmar",
	["Ratchet"] = "Cabestan",
	["Ravenholdt"] = "Ravenholdt",
	["Shen'dralar"] = "Shen'dralar",
	["Silverwing Sentinels"] = "Sentinelles d'Aile-argent",
	["Stormpike Guard"] = "Garde Foudrepique",
	["Stormwind"] = "Hurlevent",
	["Syndicate"] = "Syndicat",
	["The Defilers"] = "Les Profanateurs",
	["The League of Arathor"] = "La Ligue d'Arathor",
	["Thorium Brotherhood"] = "Confrérie du thorium",
	["Thunder Bluff"] = "Les Pitons du Tonnerre",
	["Timbermaw Hold"] = "Les Grumegueules",
	["Undercity"] = "Fossoyeuse",
	["Warsong Outriders"] = "Voltigeurs Chanteguerre",
	["Wildhammer Clan"] = "Clan Marteau-hardi",
	["Wintersaber Trainers"] = "Éleveurs de sabres-d'hiver",
	["Zandalar Tribe"] = "Tribu Zandalar",

	-- Burning Crusade Factions
	["Ashtongue Deathsworn"] = "Ligemort cendrelangue",
	["Cenarion Expedition"] = "Expédition cénarienne",
	["Exodar"] = "Exodar",
	["Honor Hold"] = "Bastion de l'Honneur",
	["Keepers of Time"] = "Gardiens du Temps",
	["Kurenai"] = "Kurenaï",
	["Lower City"] = "Ville basse",
	["Netherwing"] = "Aile-du-Néant",
	["Ogri'la"] = "Ogri'la",
	["Sha'tari Skyguard"] = "Garde-ciel sha'tari",
	["Shattered Sun Offensive"] = "Opération Soleil brisé",
	["Silvermoon City"] = "Lune-d'argent",
	["Sporeggar"] = "Sporeggar",
	["The Aldor"] = "L'Aldor",
	["The Consortium"] = "Le Consortium",
	["The Mag'har"] = "Les Mag'har",
	["The Scale of the Sands"] = "La Balance des sables",
	["The Scryers"] = "Les Clairvoyants",
	["The Sha'tar"] = "Les Sha'tar",
	["The Violet Eye"] = "L'Œil pourpre",
	["Thrallmar"] = "Thrallmar",
	["Tranquillien"] = "Tranquillien",

	--WotLK Factions (Beta data, may change)
	["Alliance Vanguard"] = "Avant-garde de l'Alliance",
	["Argent Crusade"] = "La Croisade d'argent",
	["Explorers' League"] = "Ligue des explorateurs",
	["Frenzyheart Tribe"] = "La tribu Frénécœur",
	["Horde Expedition"] = "Expédition de la Horde",
	["Kirin Tor"] = "Kirin Tor",
	["Knights of the Ebon Blade"] = "Chevaliers de la Lame d'ébène",
	["The Hand of Vengeance"] = "La Main de la vengeance",
	["The Kalu'ak"] = "Les Kalu'aks",
	["The Oracles"] = "Les Oracles",
	["The Silver Covenant"] = "Le Concordat argenté",
	["The Sons of Hodir"] = "Les Fils d'Hodir",
	["The Sunreavers"] = "Les Saccage-soleil",
	["The Taunka"] = "Les Taunkas",
	["The Wyrmrest Accord"] = "L'Accord de Repos du ver",
	["Valiance Expedition"] = "Expédition de la Bravoure",
	["Warsong Offensive"] = "Offensive chanteguerre",
	["Winterfin Retreat"] = "Retraite des Ailerons-d'hiver",

	--Rep Levels
	["Neutral"] = "Neutre",
	["Friendly"] = "Amical",
	["Honored"] = "Honoré",
	["Revered"] = "Révéré",
	["Exalted"] = "Exalté",
}
elseif GAME_LOCALE == "zhTW" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "聯盟",
	["Horde"] = "部落",

	-- Classic Factions
	["Argent Dawn"] = "銀色黎明",
	["Bloodsail Buccaneers"] = "血帆海盜",
	["Booty Bay"] = "藏寶海灣",
	["Brood of Nozdormu"] = "諾茲多姆的子嗣",
	["Cenarion Circle"] = "塞納里奧議會",
	["Darkmoon Faire"] = "暗月馬戲團",
	["Darkspear Trolls"] = "暗矛食人妖",
	["Darnassus"] = "達納蘇斯",
	["The Defilers"] = "污染者",
	["Everlook"] = "永望鎮",
	["Frostwolf Clan"] = "霜狼氏族",
	["Gadgetzan"] = "加基森",
	["Gelkis Clan Centaur"] = "吉爾吉斯半人馬",
	["Gnomeregan Exiles"] = "諾姆瑞根流亡者",
	["Hydraxian Waterlords"] = "海達希亞水元素",
	["Ironforge"] = "鐵爐堡",
	["The League of Arathor"] = "阿拉索聯軍",
	["Magram Clan Centaur"] = "瑪格拉姆半人馬",
	["Orgrimmar"] = "奧格瑪",
	["Ratchet"] = "棘齒城",
	["Ravenholdt"] = "拉文霍德",
	["Silverwing Sentinels"] = "銀翼哨兵",
	["Shen'dralar"] = "辛德拉",
	["Stormpike Guard"] = "雷矛衛隊",
	["Stormwind"] = "暴風城",
	["Syndicate"] = "辛迪加",
	["Thorium Brotherhood"] = "瑟銀兄弟會",
	["Thunder Bluff"] = "雷霆崖",
	["Timbermaw Hold"] = "木喉要塞",
	["Undercity"] = "幽暗城",
	["Warsong Outriders"] = "戰歌偵察騎兵",
	["Wildhammer Clan"] = "蠻錘氏族",
	["Wintersaber Trainers"] = "冬刃豹訓練師",
	["Zandalar Tribe"] = "贊達拉部族",

	-- Burning Crusade Factions
	["The Aldor"] = "奧多爾",
	["Ashtongue Deathsworn"] = "灰舌死亡誓言者",
	["Cenarion Expedition"] = "塞納里奧遠征隊",
	["The Consortium"] = "聯合團",
	["Exodar"] = "艾克索達",
	["Honor Hold"] = "榮譽堡",
	["Keepers of Time"] = "時光守望者",
	["Kurenai"] = "卡爾奈",
	["Lower City"] = "陰鬱城",
	["The Mag'har"] = "瑪格哈",
	["Netherwing"] = "虛空之翼",
	["Ogri'la"] = "歐格利拉",
	["The Scale of the Sands"] = "流沙之鱗",
	["The Scryers"] = "占卜者",
	["The Sha'tar"] = "薩塔",
	["Sha'tari Skyguard"] = "薩塔禦天者",
	["Shattered Sun Offensive"] = "破碎之日進攻部隊",
	["Silvermoon City"] = "銀月城",
	["Sporeggar"] = "斯博格爾",
	["Thrallmar"] = "索爾瑪",
	["Tranquillien"] = "安寧地",
	["The Violet Eye"] = "紫羅蘭之眼",

	--WotLK Factions (Beta data, may change)
	["Argent Crusade"] = "銀白十字軍",
	["Frenzyheart Tribe"] = "狂心部族",
	["Knights of the Ebon Blade"] = "黯刃騎士團",
	["Kirin Tor"] = "祈倫托",
	["The Sons of Hodir"] = "霍迪爾之子",
	["The Kalu'ak"] = "卡魯耶克",
	["The Oracles"] = "神諭者",
	["The Wyrmrest Accord"] = "龍眠協調者",
	["The Silver Covenant"] = "白銀誓盟",
	["The Sunreavers"] = "奪日者",
	["Explorers' League"] = "探險者協會",
	["Valiance Expedition"] = "驍勇遠征隊",
	["The Hand of Vengeance"] = "復仇之手",
	["The Taunka"] = "坦卡族",
	["Warsong Offensive"] = "戰歌進攻部隊",
	["Winterfin Retreat"] = "冬鰭避居地",
	["Alliance Vanguard"] = "聯盟先鋒",
	["Horde Expedition"] = "部落遠征軍",

	--Rep Levels
	["Neutral"] = "中立",
	["Friendly"] = "友好",
	["Honored"] = "尊敬",
	["Revered"] = "崇敬",
	["Exalted"] = "崇拜",
}
elseif GAME_LOCALE == "zhCN" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "联盟",
	["Horde"] = "部落",

	-- Classic Factions
	["Argent Dawn"] = "银色黎明",
	["Bloodsail Buccaneers"] = "血帆海盗",
	["Booty Bay"] = "藏宝海湾",
	["Brood of Nozdormu"] = "诺兹多姆的子嗣",
	["Cenarion Circle"] = "塞纳里奥议会",
	["Darkmoon Faire"] = "暗月马戏团",
	["Darkspear Trolls"] = "暗矛巨魔",
	["Darnassus"] = "达纳苏斯",
	["The Defilers"] = "污染者",
	["Everlook"] = "永望镇",
	["Frostwolf Clan"] = "霜狼氏族",
	["Gadgetzan"] = "加基森",
	["Gelkis Clan Centaur"] = "吉尔吉斯半人马",
	["Gnomeregan Exiles"] = "诺莫瑞根流亡者",
	["Hydraxian Waterlords"] = "海达希亚水元素",
	["Ironforge"] = "铁炉堡",
	["The League of Arathor"] = "阿拉索联军",
	["Magram Clan Centaur"] = "玛格拉姆半人马",
	["Orgrimmar"] = "奥格瑞玛",
	["Ratchet"] = "棘齿城",
	["Ravenholdt"] = "拉文霍德",
	["Silverwing Sentinels"] = "银翼哨兵",
	["Shen'dralar"] = "辛德拉",
	["Stormpike Guard"] = "雷矛卫队",
	["Stormwind"] = "暴风城",
	["Syndicate"] = "辛迪加",
	["Thorium Brotherhood"] = "瑟银兄弟会",
	["Thunder Bluff"] = "雷霆崖",
	["Timbermaw Hold"] = "木喉要塞",
	["Undercity"] = "幽暗城",
	["Warsong Outriders"] = "战歌侦察骑兵",
	["Wildhammer Clan"] = "蛮锤部族",
	["Wintersaber Trainers"] = "冬刃豹训练师",
	["Zandalar Tribe"] = "赞达拉部族",

	-- Burning Crusade Factions
	["The Aldor"] = "奥尔多",
	["Ashtongue Deathsworn"] = "灰舌死誓者",
	["Cenarion Expedition"] = "塞纳里奥远征队",
	["The Consortium"] = "星界财团",
	["Exodar"] = "埃索达",
	["Honor Hold"] = "荣耀堡",
	["Keepers of Time"] = "时光守护者",
	["Kurenai"] = "库雷尼",
	["Lower City"] = "贫民窟",
	["The Mag'har"] = "玛格汉",
	["Netherwing"] = "灵翼之龙",
	["Ogri'la"] = "奥格瑞拉",
	["The Scale of the Sands"] = "流沙之鳞",
	["The Scryers"] = "占星者",
	["The Sha'tar"] = "沙塔尔",
	["Sha'tari Skyguard"] = "沙塔尔天空卫士",
	["Shattered Sun Offensive"] = "破碎残阳",
	["Silvermoon City"] = "银月城",
	["Sporeggar"] = "孢子村",
	["Thrallmar"] = "萨尔玛",
	["Tranquillien"] = "塔奎林",
	["The Violet Eye"] = "紫罗兰之眼",

	--WotLK Factions (Beta data, may change)
	["Argent Crusade"] = "银色北伐军",
	["Frenzyheart Tribe"] = "狂心氏族",
	["Knights of the Ebon Blade"] = "黑锋骑士团",
	["Kirin Tor"] = "肯瑞托",
	["The Sons of Hodir"] = "霍迪尔之子",
	["The Kalu'ak"] = "卡鲁亚克",
	["The Oracles"] = "神谕者",
	["The Wyrmrest Accord"] = "龙眠联军",
	["The Silver Covenant"] = "银色盟约",
	["The Sunreavers"] = "夺日者",
	["Explorers' League"] = "探险者协会",
	["Valiance Expedition"] = "无畏远征军",
	["The Hand of Vengeance"] = "复仇之手",
	["The Taunka"] = "牦牛人",
	["Warsong Offensive"] = "战歌远征军",
	["Winterfin Retreat"] = "冬鳞避难所",
	["Alliance Vanguard"] = "联盟先遣军",
	["Horde Expedition"] = "部落先遣军",

	--Rep Levels
	["Neutral"] = "中立",
	["Friendly"] = "友善",
	["Honored"] = "尊敬",
	["Revered"] = "崇敬",
	["Exalted"] = "崇拜",
}
elseif GAME_LOCALE == "esES" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "Alianza",
	["Horde"] = "Horda",

	-- Classic Factions
	["Argent Dawn"] = "Alba Argenta",
	["Bloodsail Buccaneers"] = "Bucaneros Velasangre",
	["Booty Bay"] = "Bahía del Botín",
	["Brood of Nozdormu"] = "Linaje de Nozdormu",
	["Cenarion Circle"] = "Círculo Cenarion",
	["Darkmoon Faire"] = "Feria de la Luna Negra",
	["Darkspear Trolls"] = "Trols Lanza Negra",
	["Darnassus"] = "Darnassus",
	["The Defilers"] = "Los Rapiñadores",
	["Everlook"] = "Vista Eterna",
	["Frostwolf Clan"] = "Clan Lobo Gélido",
	["Gadgetzan"] = "Gadgetzan",
	["Gelkis Clan Centaur"] = "Centauro del clan Gelkis",
	["Gnomeregan Exiles"] = "Exiliados de Gnomeregan",
	["Hydraxian Waterlords"] = "Srs. del Agua de Hydraxis",
	["Ironforge"] = "Forjaz",
	["The League of Arathor"] = "Liga de Arathor",
	["Magram Clan Centaur"] = "Centauro del clan Magram",
	["Orgrimmar"] = "Orgrimmar",
	["Ratchet"] = "Trinquete",
	["Ravenholdt"] = "Ravenholdt",
	["Silverwing Sentinels"] = "Centinelas Ala de Plata",
	["Shen'dralar"] = "Shen'dralar",
	["Stormpike Guard"] = "Guardia Pico Tormenta",
	["Stormwind"] = "Ventormenta",
	["Syndicate"] = "La Hermandad",
	["Thorium Brotherhood"] = "Hermandad del torio",
	["Thunder Bluff"] = "Cima del Trueno",
	["Timbermaw Hold"] = "Bastión Fauces de Madera",
	["Undercity"] = "Entrañas",
	["Warsong Outriders"] = "Escoltas Grito de Guerra",
	["Wildhammer Clan"] = "Clan Martillo Salvaje",
	["Wintersaber Trainers"] = "Instructores de Sableinvernales",
	["Zandalar Tribe"] = "Tribu Zandalar",

	-- Burning Crusade Factions
	["The Aldor"] = "Los Aldor",
	["Ashtongue Deathsworn"] = "Juramorte Lengua de ceniza",
	["Cenarion Expedition"] = "Expedición Cenarion",
	["The Consortium"] = "El Consorcio",
	["Exodar"] = "Exodar",
	["Honor Hold"] = "Bastión del Honor",
	["Keepers of Time"] = "Vigilantes del tiempo",
	["Kurenai"] = "Kurenai",
	["Lower City"] = "Bajo Arrabal",
	["The Mag'har"] = "Los Mag'har",
	["Netherwing"] = "Ala Abisal",
	["Ogri'la"] = "Ogri'la",
	["The Scale of the Sands"] = "La Escama de las Arenas",
	["The Scryers"] = "Los Arúspices",
	["The Sha'tar"] = "Los Sha'tar",
	["Sha'tari Skyguard"] = "Guardia del cielo Sha'tari",
	["Shattered Sun Offensive"] = "Ofensiva Sol Devastado",
	["Silvermoon City"] = "Ciudad de Lunargenta",
	["Sporeggar"] = "Esporaggar",
	["Thrallmar"] = "Thrallmar",
	["Tranquillien"] = "Tranquilien",
	["The Violet Eye"] = "El Ojo Violeta",

	--WotLK Factions (Beta data, may change)
	["Argent Crusade"] = "Argent Crusade", --Check
	["Frenzyheart Tribe"] = "Frenzyheart Tribe", --Check
	["Knights of the Ebon Blade"] = "Knights of the Ebon Blade", --Check
	["Kirin Tor"] = "Kirin Tor", --Check
	["The Sons of Hodir"] = "The Sons of Hodir", --Check
	["The Kalu'ak"] = "The Kalu'ak", --Check
	["The Oracles"] = "The Oracles", --Check
	["The Wyrmrest Accord"] = "The Wyrmrest Accord", --Check
	["The Silver Covenant"] = "The Silver Covenant", --Check
	["The Sunreavers"] = "The Sunreavers", --Check
	["Explorers' League"] = "Explorers' League", --Check
	["Valiance Expedition"] = "Valiance Expedition", --Check
	["The Hand of Vengeance"] = "The Hand of Vengeance", --Check
	["The Taunka"] = "The Taunka", --Check
	["Warsong Offensive"] = "Warsong Offensive", --Check
	["Winterfin Retreat"] = "Winterfin Retreat",
	["Alliance Vanguard"] = "Alliance Vanguard", --Check
	["Horde Expedition"] = "Horde Expedition", --Check

	--Rep Levels
	["Neutral"] = "Neutral",
	["Friendly"] = "Amistoso",
	["Honored"] = "Honorable",
	["Revered"] = "Reverenciado",
	["Exalted"] = "Exaltado",
}
elseif GAME_LOCALE == "esMX" then
	lib:SetCurrentTranslations {
	--Player Factions
	--["Alliance"] = "Alianza",
	--["Horde"] = "Horda",

	-- Classic Factions
	--["Argent Dawn"] = "Alba Argenta",
	--["Bloodsail Buccaneers"] = "Bucaneros Velasangre",
	--["Booty Bay"] = "Bahía del Botín",
	--["Brood of Nozdormu"] = "Linaje de Nozdormu",
	--["Cenarion Circle"] = "Círculo Cenarion",
	--["Darkmoon Faire"] = "Feria de la Luna Negra",
	--["Darkspear Trolls"] = "Trols Lanza Negra",
	--["Darnassus"] = "Darnassus",
	--["The Defilers"] = "Los Rapiñadores",
	--["Everlook"] = "Vista Eterna",
	--["Frostwolf Clan"] = "Clan Lobo Gélido",
	--["Gadgetzan"] = "Gadgetzan",
	--["Gelkis Clan Centaur"] = "Centauro del clan Gelkis",
	--["Gnomeregan Exiles"] = "Exiliados de Gnomeregan",
	--["Hydraxian Waterlords"] = "Srs. del Agua de Hydraxis",
	--["Ironforge"] = "Forjaz",
	--["The League of Arathor"] = "Liga de Arathor",
	--["Magram Clan Centaur"] = "Centauro del clan Magram",
	--["Orgrimmar"] = "Orgrimmar",
	--["Ratchet"] = "Trinquete",
	--["Ravenholdt"] = "Ravenholdt",
	--["Silverwing Sentinels"] = "Centinelas Ala de Plata",
	--["Shen'dralar"] = "Shen'dralar",
	--["Stormpike Guard"] = "Guardia Pico Tormenta",
	--["Stormwind"] = "Ventormenta",
	--["Syndicate"] = "La Hermandad",
	--["Thorium Brotherhood"] = "Hermandad del torio",
	--["Thunder Bluff"] = "Cima del Trueno",
	--["Timbermaw Hold"] = "Bastión Fauces de Madera",
	--["Undercity"] = "Entrañas",
	--["Warsong Outriders"] = "Escoltas Grito de Guerra",
	--["Wildhammer Clan"] = "Clan Martillo Salvaje",
	--["Wintersaber Trainers"] = "Instructores de Sableinvernales",
	--["Zandalar Tribe"] = "Tribu Zandalar",

	-- Burning Crusade Factions
	--["The Aldor"] = "Los Aldor",
	--["Ashtongue Deathsworn"] = "Juramorte Lengua de ceniza",
	--["Cenarion Expedition"] = "Expedición Cenarion",
	--["The Consortium"] = "El Consorcio",
	--["Exodar"] = "Exodar",
	--["Honor Hold"] = "Bastión del Honor",
	--["Keepers of Time"] = "Vigilantes del tiempo",
	--["Kurenai"] = "Kurenai",
	--["Lower City"] = "Bajo Arrabal",
	--["The Mag'har"] = "Los Mag'har",
	--["Netherwing"] = "Ala Abisal",
	--["Ogri'la"] = "Ogri'la",
	--["The Scale of the Sands"] = "La Escama de las Arenas",
	--["The Scryers"] = "Los Arúspices",
	--["The Sha'tar"] = "Los Sha'tar",
	--["Sha'tari Skyguard"] = "Guardia del cielo Sha'tari",
	--["Shattered Sun Offensive"] = "Ofensiva Sol Devastado",
	--["Silvermoon City"] = "Ciudad de Lunargenta",
	--["Sporeggar"] = "Esporaggar",
	--["Thrallmar"] = "Thrallmar",
	--["Tranquillien"] = "Tranquilien",
	--["The Violet Eye"] = "El Ojo Violeta",

	--WotLK Factions (Beta data, may change)
	--["Argent Crusade"] = true,
	--["Frenzyheart Tribe"] = true,
	--["Knights of the Ebon Blade"] = true,
	--["Kirin Tor"] = true,
	--["The Sons of Hodir"] = true,
	--["The Kalu'ak"] = true,
	--["The Oracles"] = true,
	--["The Wyrmrest Accord"] = true,
	--["The Silver Covenant"] = true,
	--["The Sunreavers"] = true,
	--["Explorer's League"] = true,
	--["Valiance Expedition"] = true,
	--["The Hand of Vengeance"] = true,
	--["The Taunka"] = true,
	--["Warsong Offensive"] = true,
	--["Winterfin Retreat"] = true,
	--["Alliance Vanguard"] = true,
	--["Horde Expedition"] = true,

	--Rep Levels
	--["Neutral"] = "Neutral",
	--["Friendly"] = "Amistoso",
	--["Honored"] = "Honorable",
	--["Revered"] = "Reverenciado",
	--["Exalted"] = "Exaltado",
}
elseif GAME_LOCALE == "koKR" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "얼라이언스",
	["Horde"] = "호드",

	-- Classic Factions
	["Argent Dawn"] = "은빛 여명회",
	["Bloodsail Buccaneers"] = "붉은 해적단",
	["Booty Bay"] = "무법항",
	["Brood of Nozdormu"] = "노즈도르무 혈족",
	["Cenarion Circle"] = "세나리온 의회",
	["Darkmoon Faire"] = "다크문 유랑단",
	["Darkspear Trolls"] = "검은창 트롤",
	["Darnassus"] = "다르나서스",
	["The Defilers"] = "포세이큰 파멸단",
	["Everlook"] = "눈망루 마을",
	["Frostwolf Clan"] = "서리늑대 부족",
	["Gadgetzan"] = "가젯잔",
	["Gelkis Clan Centaur"] = "겔키스 부족 켄타로우스",  -- Check
	["Gnomeregan Exiles"] = "놈리건",
	["Hydraxian Waterlords"] = "히드락시안 물의 군주",
	["Ironforge"] = "아이언포지",
	["The League of Arathor"] = "아라소르 연맹",
	["Magram Clan Centaur"] = "마그람 부족 켄타로우스",  -- Check
	["Orgrimmar"] = "오그리마",
	["Ratchet"] = "톱니항",
	["Ravenholdt"] = "라벤홀트",
	["Silverwing Sentinels"] = "은빛날개 파수대",
	["Shen'dralar"] = "센드렐라",
	["Stormpike Guard"] = "스톰파이크 경비대",
	["Stormwind"] = "스톰윈드",
	["Syndicate"] = "비밀결사대",
	["Thorium Brotherhood"] = "토륨 대장조합 ",
	["Thunder Bluff"] = "썬더 블러프",
	["Timbermaw Hold"] = "나무구렁 요새",
	["Undercity"] = "언더시티",
	["Warsong Outriders"] = "전쟁노래 정찰대",
	["Wildhammer Clan"] = "와일드해머 부족",  --?
	["Wintersaber Trainers"] = "눈호랑이 조련사",
	["Zandalar Tribe"] = "잔달라 부족",

	-- Burning Crusade Factions
	["The Aldor"] = "알도르 사제회",
	["Ashtongue Deathsworn"] = "잿빛혓바닥 결사단",
	["Cenarion Expedition"] = "세나리온 원정대",
	["The Consortium"] = "무역연합",
	["Exodar"] = "엑소다르",
	["Honor Hold"] = "명예의 요새",
	["Keepers of Time"] = "시간의 수호자",
	["Kurenai"] = "쿠레나이",
	["Lower City"] = "고난의 거리",
	["The Mag'har"] = "마그하르",
	["Netherwing"] = "황천의 용군단",
	["Ogri'la"] = "오그릴라",
	["The Scale of the Sands"] = "시간의 중재자",
	["The Scryers"] = "점술가 길드",
	["The Sha'tar"] = "샤타르",
	["Sha'tari Skyguard"] = "샤타리 하늘경비대",
	["Shattered Sun Offensive"] = "무너진 태양 공격대",
	["Silvermoon City"] = "실버문",
	["Sporeggar"] = "스포어가르",
	["Thrallmar"] = "스랄마",
	["Tranquillien"] = "트랜퀼리엔",
	["The Violet Eye"] = "보랏빛 눈의 감시자",

	--WotLK Factions (Beta data, may change)
	["Argent Crusade"] = "은빛십자군",
	["Frenzyheart Tribe"] = "광란의심장 일족",
	["Knights of the Ebon Blade"] = "칠흑의 기사단",
	["Kirin Tor"] = "키린 토",
	["The Sons of Hodir"] = "호디르의 후예",
	["The Kalu'ak"] = "칼루아크",
	["The Oracles"] = "점쟁이 조합",
	["The Wyrmrest Accord"] = "고룡쉼터 사원 용군단",
	["The Silver Covenant"] = "은빛 맹약",  --?
	["The Sunreavers"] = "선리버",   --?
	["Explorers' League"] = "탐험가 연맹",
	["Valiance Expedition"] = "용맹의 원정대",
	["The Hand of Vengeance"] = "복수의 수호자",
	["The Taunka"] = "타운카",
	["Warsong Offensive"] = "전쟁노래 공격대",
	["Winterfin Retreat"] = "Winterfin Retreat",
	["Alliance Vanguard"] = "얼라이언스 선봉대",  --?
	["Horde Expedition"] = "호드 원정대",  --?

	--Rep Levels
	["Neutral"] = "중립적",
	["Friendly"] = "약간 우호적",
	["Honored"] = "우호적",
	["Revered"] = "매우 우호적",
	["Exalted"] = "확고한 동맹",
}
elseif GAME_LOCALE == "ruRU" then
	lib:SetCurrentTranslations {
	--Player Factions
	["Alliance"] = "Альянс",
	["Horde"] = "Орда",

	-- Classic Factions
	["Argent Dawn"] = "Серебряный Рассвет",
	["Bloodsail Buccaneers"] = "Пираты Кровавого Паруса",
	["Booty Bay"] = "Пиратская бухта",
	["Brood of Nozdormu"] = "Род Ноздорму",
	["Cenarion Circle"] = "Служители Ценариона",
	["Darkmoon Faire"] = "Ярмарка Новолуния",
	["Darkspear Trolls"] = "Тролли Черного Копья",
	["Darnassus"] = "Дарнасс",
	["The Defilers"] = "Осквернители",
	["Everlook"] = "Круговзор",
	["Frostwolf Clan"] = "Клан Северного Волка",
	["Gadgetzan"] = "Прибамбасск",
	["Gelkis Clan Centaur"] = "Кентавры из племени Гелкис",
	["Gnomeregan Exiles"] = "Изгнанники Гномрегана",
	["Hydraxian Waterlords"] = "Гидраксианские Повелители Вод",
	["Ironforge"] = "Стальгорн",
	["The League of Arathor"] = "Лига Аратора",
	["Magram Clan Centaur"] = "Кентавры племени Маграм",
	["Orgrimmar"] = "Оргриммар",
	["Ratchet"] = "Кабестан",
	["Ravenholdt"] = "Черный Ворон",
	["Silverwing Sentinels"] = "Среброкрылые Часовые",
	["Shen'dralar"] = "Шен'дралар",
	["Stormpike Guard"] = "Стража Грозовой Вершины",
	["Stormwind"] = "Штормград",
	["Syndicate"] = "Синдикат",
	["Thorium Brotherhood"] = "Братство Тория",
	["Thunder Bluff"] = "Громовой Утес",
	["Timbermaw Hold"] = "Древобрюхи",
	["Undercity"] = "Подгород",
	["Warsong Outriders"] = "Всадники Песни Войны",
	["Wildhammer Clan"] = "Неистовый Молот",
	["Wintersaber Trainers"] = "Укротители ледопардов",
	["Zandalar Tribe"] = "Племя Зандалар",

	-- Burning Crusade Factions
	["The Aldor"] = "Алдоры",
	["Ashtongue Deathsworn"] = "Пеплоусты-служители",
	["Cenarion Expedition"] = "Экспедиция Ценариона",
	["The Consortium"] = "Консорциум",
	["Exodar"] = "Экзодар",
	["Honor Hold"] = "Оплот Чести",
	["Keepers of Time"] = "Хранители Времени",
	["Kurenai"] = "Куренай",
	["Lower City"] = "Нижний Город",
	["The Mag'har"] = "Маг'хары",
	["Netherwing"] = "Крылья Пустоверти",
	["Ogri'la"] = "Огри'ла",
	["The Scale of the Sands"] = "Песчаная Чешуя",
	["The Scryers"] = "Провидцы",
	["The Sha'tar"] = "Ша'тар",
	["Sha'tari Skyguard"] = "Стражи Небес Ша'тар",
	["Shattered Sun Offensive"] = "Армия Расколотого Солнца",
	["Silvermoon City"] = "Луносвет",
	["Sporeggar"] = "Спореггар",
	["Thrallmar"] = "Траллмар",
	["Tranquillien"] = "Транквиллион",
	["The Violet Eye"] = "Аметистовое Око",

	--WotLK Factions (Beta data, may change)
	["Argent Crusade"] = "Серебряный Авангард",
	["Frenzyheart Tribe"] = "Племя Мятежного Сердца",
	["Knights of the Ebon Blade"] = "Рыцари Черного Клинка",
	["Kirin Tor"] = "Кирин-Тор",
	["The Sons of Hodir"] = "Сыновья Ходира",
	["The Kalu'ak"] = "Калу'ак",
	["The Oracles"] = "Оракулы",
	["The Wyrmrest Accord"] = "Драконий союз",
	["The Silver Covenant"] = "Серебряный Союз",
	["The Sunreavers"] = "Похитители солнца",
	["Explorers' League"] = "Лига исследователей",
	["Valiance Expedition"] = "Экспедиция Отважных",
	["The Hand of Vengeance"] = "Карающая длань",
	["The Taunka"] = "Таунка",
	["Warsong Offensive"] = "Армия Песни Войны",
	["Winterfin Retreat"] = "Холодный Плавник",
	["Alliance Vanguard"] = "Авангард Альянса",
	["Horde Expedition"] = "Экспедиция Орды",

	--Rep Levels
	["Neutral"] = "Равнодушие",
	["Friendly"] = "Дружелюбие",
	["Honored"] = "Уважение",
	["Revered"] = "Почтение",
	["Exalted"] = "Превознесение",
}
else
	error(("%s: Locale %q not supported"):format(MAJOR_VERSION, GAME_LOCALE))
end
