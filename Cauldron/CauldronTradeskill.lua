-- $Revision: 1.3 $
-- Cauldron tradeskill functions

--[[
	The following table describes a skill:
	
	skillInfo = {
		['index'] = <index from GetTradeSkillInfo(i)>,
		['name'] = "<name>",
		['link'] = <link>,
		['icon'] = GetTradeSkillIcon(i),
		['difficulty'] = "<difficulty>",
		['available'] = <avail>,
		['minMade'] = <minMade>,
		['maxMade'] = <maxMade>,
		['tradeskill'] = "<tradeskill>",
		
		-- levels of difficulty change
		['trivial'] = 0,
		['easy'] = 0,
		['medium'] = 0,
		['optimal'] = 0,
		
		-- filter information
		['slot'] = "<slot>",
		['defaultCategory'] = "<category>",
		['categories'] = {}, -- TODO
		['benefit'] = {}, -- TODO
		['keywords'] = "",
	};
	
	The following table describes a skill's reagent:
	
	reagents = {
		['name'] = "<name>",
		['icon'] = "<icon>",
		['numRequired'] = <count>,
		['toonHas'] = <hasCount>,
		['index'] = <reagent index>,
		['skillIndex'] = <skill index>,
	};

--]]

function Cauldron:UpdateSkills()
	self:debug("UpdateSkills enter");
	
	local skillName = GetTradeSkillLine();
	local baseSkillName = skillName;
	self:debug("UpdateSkills: skillName="..skillName);
	
	if skillName == "UNKNOWN" then
		return; 
	end
	
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	-- initialize the trade skill entry	
	if not self.db.realm.userdata[self.vars.playername].skills[skillName] then
		self.db.realm.userdata[self.vars.playername].skills[skillName] = {
			recipes = {},
		};
	else
		-- reset the recipe list
		self.db.realm.userdata[self.vars.playername].skills[skillName].recipes = {};
	end
	
	-- initialize window information, if necessary
	if not self.db.realm.userdata[self.vars.playername].skills[skillName].window then
		self.db.realm.userdata[self.vars.playername].skills[skillName].window = {
			search = "",
			filter = {
				optimal = true,
				medium = true,
				easy = true,
				trivial = true,
				haveAllReagents = false,
				haveKeyReagents = false,
				haveAnyReagents = false,
				sortDifficulty = true,
				sortAlpha = false,
				sortBenefit = false,
			},
			skills = {},
			slots = {},
			categories = {},
			offset = 0,
			selected = 1,
		};
	end

	-- save the skill entry in a local var	
	local skillDB = self.db.realm.userdata[self.vars.playername].skills[skillName];
	skillDB.recipes = {};
	
	-- make sure we're getting a full list
	SetTradeSkillItemNameFilter(nil);
	SetTradeSkillItemLevelFilter(0, 0);
			
	for i=1,GetNumTradeSkills() do
		local name, difficulty, avail, expanded = GetTradeSkillInfo(i);
--		self:debug("UpdateSkills: name="..name.."; difficulty="..difficulty.."; avail="..avail);
		
		if name and difficulty ~= "header" then
			local link = GetTradeSkillItemLink(i);
			local minMade, maxMade = GetTradeSkillNumMade(i);
			local _, _, _, _, _, _, _, _, slot, _ = GetItemInfo(link);
			
			local keywords = name;

			-- fill in the db entry
			skillDB.recipes[name] = {
				['index'] = i,
				['name'] = name,
				['link'] = link,
				['icon'] = GetTradeSkillIcon(i),
				['tradeskill'] = baseSkillName,
				['difficulty'] = difficulty,
				['available'] = avail,
				['minMade'] = minMade,
				['maxMade'] = maxMade,
				
				-- levels of difficulty change
				['trivial'] = 0,
				['easy'] = 0,
				['medium'] = 0,
				['optimal'] = 0,
				
				-- filter information
				['slot'] = slot,
				['defaultCategory'] = category,
				['categories'] = {}, -- TODO
				['benefit'] = {}, -- TODO
			};
			
			-- make sure the skill window info is initialized
			if not skillDB.window.skills[skillName] then
				skillDB.window.skills[skillName] = {};
			end
				
			if not skillDB.window.skills[skillName][name] then
				skillDB.window.skills[skillName][name] = {
					['expanded'] = false,
				};
			end
			
			-- make sure the category for the window is initialized
			if not skillDB.window.categories[category] then
				skillDB.window.categories[category] = {
					['shown'] = true,
					['expanded'] = true,
				};
			end
			
			-- clear the reagent list
			skillDB.recipes[name].reagents = {};
			
			for j=1,GetTradeSkillNumReagents(i) do
				local rname, rtex, rcount, hasCount = GetTradeSkillReagentInfo(i,j);
				
				table.insert(skillDB.recipes[name].reagents, {
					['name'] = rname,
					['icon'] = rtex,
					['numRequired'] = rcount,
					['toonHas'] = hasCount,
					['index'] = j,
					['skillIndex'] = i,
				});
				
				keywords = keywords..","..rname;
			end

			-- fill in the db entry
			skillDB.recipes[name].keywords = keywords;
	    else
	    	-- save the header name
	    	category = name;
	    		
	    	-- expand the header, so we get all the skills
	    	if not expanded then
	    		ExpandTradeSkillSubClass(i);
	    	end
		end
	end

	self:debug("UpdateSkills exit");
end

function Cauldron:GetDefaultCategories(player, skillName)
	self:debug("GetDefaultCategories enter");

	local categories = {};
	
	if self.db then
		for name, info in pairs(self.db.realm.userdata[player].skills[skillName].recipes) do
			table.insert(categories, info.defaultCategory);
		end
	end

	table.sort(categories);

	self:debug("GetDefaultCategories exit");
	
	return categories;
end

function Cauldron:GetCategories(skillList)
	self:debug("GetCategories enter");

	local categories = {};
	
	if not skillList then
		return categories;
	end
	
	for _, info in ipairs(skillList) do
		table.insert(categories, info.defaultCategory);
	end
	
	table.sort(categories);

	self:debug("GetCategories exit");
	
	return categories;
end

function Cauldron:GetSlots(player, skillName)
	self:debug("GetSlots enter");
	
	local slots = {};
	
	if self.db then
		for name, info in pairs(self.db.realm.userdata[player].skills[skillName].recipes) do
			if info.slot ~= "" then
				slots[info.slot] = true;
			end
		end
	end

	self:debug("GetSlots exit");
	
	return slots;
end

function Cauldron:GetSkillList(playername, skillName)
	self:debug("GetSkillList enter");
	
	if (not playername) or (not skillName) then
		-- TODO: display error
		return;
	end

	local skills = {};
	
	for name, recipe in pairs(self.db.realm.userdata[playername].skills[skillName].recipes) do
	
		local add = true;
		
		-- check the search text
		local search = self.db.realm.userdata[playername].skills[skillName].window.search or "";
		if #search > 0 then
			-- check for numbers
			local minLevel, maxLevel;
			local approxLevel = strmatch(text, "^~(%d+)");
			if ( approxLevel ) then
				minLevel = approxLevel - 2;
				maxLevel = approxLevel + 2;
			else
				minLevel, maxLevel = strmatch(text, "^(%d+)%s*-*%s*(%d*)$");
			end
			if ( minLevel ) then
				if ( maxLevel == "" or maxLevel < minLevel ) then
					maxLevel = minLevel;
				end
				
				-- TODO
--				SetTradeSkillItemNameFilter(nil);
--				SetTradeSkillItemLevelFilter(minLevel, maxLevel);
			else
				-- match name or reagents
				if not string.find(recipe.keywords, search) then
					self:debug("skipping recipe: "..name.." (keywords: "..recipe.keywords..")");
					add = false;
				end
			end

		end
	
		-- check difficulty filter
		if not self.db.realm.userdata[playername].skills[skillName].window.filter[recipe.difficulty] then
			self:debug("skipping recipe: "..name.." (difficulty: "..recipe.difficulty..")");
			add = false;
		end
		
		-- check categories
		local catInfo = self.db.realm.userdata[playername].skills[skillName].window.categories[recipe.defaultCategory];
		if catInfo and (not catInfo.shown) then
			self:debug("skipping recipe: "..name.." (category: "..recipe.defaultCategory..")");
			add = false;
		end
		
		-- check slot
		local slotInfo = self.db.realm.userdata[playername].skills[skillName].window.slots[recipe.slot];
		self:debug("slotInfo: "..tostring(slotInfo));
		if slotInfo then -- more
			self:debug("skipping recipe: "..name.." (slot: "..recipe.slot..")");
			add = false;
		end
		
		-- check reagent filter
		if self.db.realm.userdata[playername].skills[skillName].window.filter.haveAllReagents then
			-- check if the available count is 0
			if recipe.available == 0 then
				add = false;
			end
		elseif self.db.realm.userdata[playername].skills[skillName].window.filter.haveKeyReagents then
			-- check if the reagent count for key reagents is 0
		elseif self.db.realm.userdata[playername].skills[skillName].window.filter.haveAnyReagents then
			-- check if the reagent count for any reagent is 0
			for rname, rinfo in pairs(recipe.reagents) do
				-- check possession count
				if rinfo.toonHas == 0 then
--					if Cauldron:GetAltReagentCount(rinfo) == 0 then
						add = false;
--					end
				end
			end
		end
		
		-- we got here, add the recipe to the list
		if add then
			table.insert(skills, recipe);
		end
	end
	
	-- sort the list
	table.sort(skills, function(r1, r2)
			if (not r1) or (not r2) then
				return true;
			end
			
			self:debug("GetSkillList: sorting: r1.name="..r1.name.."; r2.name="..r2.name);
			if self.db.realm.userdata[playername].skills[skillName].window.filter.sortAlpha then
				self:debug("GetSkillList: sorting by alpha");
				return r1.name < r2.name;
			elseif self.db.realm.userdata[playername].skills[skillName].window.filter.sortDifficulty then
				self:debug("GetSkillList: sorting by difficulty");
				local difficulty = {
					optimal = 4,
					medium = 3,
					easy = 2,
					trivial = 1,
				};
				
				self:debug("GetSkillList: r1.difficulty="..r1.difficulty);
				self:debug("GetSkillList: r2.difficulty="..r2.difficulty);
				return difficulty[r1.difficulty] > difficulty[r2.difficulty];
			elseif self.db.realm.userdata[playername].skills[skillName].window.filter.sortBenefit then
				self:debug("GetSkillList: returning true for benefit sorting");
				return true; -- TODO
			end
			
			self:debug("GetSkillList: returning default true");
			return true;
		end);

	self:debug("GetSkillList exit");
	
	return skills;
end

function Cauldron:GetSkillInfo(tradeskill, skill)
	self:debug("GetSkillInfo enter");
	
	-- sanity checks
	if (not tradeskill) or (not skill) then
		self:Print("Missing tradeskill ("..tostring(tradeskill)..") or skill ("..tostring(skill)..")!");
		return nil;
	end

	if not self.db.realm.userdata[self.vars.playername].skills[tradeskill] then
		return nil;
	end
	
	local skillInfo = self.db.realm.userdata[self.vars.playername].skills[tradeskill].recipes[skill];
	if not skillInfo then
		-- couldn't find a skill with the item name, so scan the list for skills that craft
		-- the item
		for _, recipe in pairs(self.db.realm.userdata[self.vars.playername].skills[tradeskill].recipes) do
			local name, _ = GetItemInfo(recipe.link);
			if name == skill then
				return recipe;
			end
		end
	end
	
	self:debug("GetSkillInfo exit");
	
	return skillInfo;
end

function Cauldron:GetSkillInfoForItem(item)

	for tradeskill, list in pairs(self.db.realm.userdata[self.vars.playername].skills) do
		-- skip linked skills
		if not (string.find(tradeskill, "Linked-")) then
			for _, recipeInfo in pairs(list.recipes) do
				local name, _ = GetItemInfo(recipeInfo.link);
				if name == item then
					return recipeInfo;
				end
			end
		end
	end

	return nil;
end

function Cauldron:GetRequiredItems(skillInfo, amount)

	local intermediates = {};
	local reagents = {};
	
	-- sanity checks
	if not skillInfo then
		-- TODO: display error
		return intermediates, reagents;
	end

	amount = math.max(1, tonumber(amount) or 1);
	
	-- find out what the reagents are
	for i, reagent in ipairs(skillInfo.reagents) do
	
		-- copy the reagent info so we can modify the amounts
		local r = CopyTable(reagent);
		r.numRequired = r.numRequired * amount;

		-- see if the character can make the item
		local si = Cauldron:GetSkillInfoForItem(r.name);
		if si then
			table.insert(intermediates, r);
		else
			table.insert(reagents, r);
		end
	end
	
	return intermediates, reagents;
end

