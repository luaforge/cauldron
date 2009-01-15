-- $Revision: 1.1 $
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
	self:Debug("UpdateSkills enter");
	
	local skillName = GetTradeSkillLine();
	local baseSkillName = skillName;
	self:Debug("UpdateSkills: skillName="..skillName);
	
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
--		self:Debug("UpdateSkills: name="..name.."; difficulty="..difficulty.."; avail="..avail);
		
		if name and difficulty ~= "header" then
			local link = GetTradeSkillItemLink(i);
			local minMade, maxMade = GetTradeSkillNumMade(i);
			local _, _, _, _, _, _, _, _, slot, _ = GetItemInfo(link);

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
			end
	    else
	    	-- save the header name
	    	category = name;
	    		
	    	-- expand the header, so we get all the skills
	    	if not expanded then
	    		ExpandTradeSkillSubClass(i);
	    	end
		end
	end

	self:Debug("UpdateSkills exit");
end

function Cauldron:GetDefaultCategories(player, skillName)
	self:Debug("GetDefaultCategories enter");

	local categories = {};
	
	for name, info in pairs(self.db.realm.userdata[self.vars.playername].skills[skillName].recipes) do
		categories[info.defaultCategory] = true;
	end

	self:Debug("GetDefaultCategories exit");
	
	return categories;
end

function Cauldron:GetCategories(skillList)
	self:Debug("GetCategories enter");

	local categories = {};
	
	for _, info in ipairs(skillList) do
		categories[info.defaultCategory] = true;
	end

	self:Debug("GetCategories exit");
	
	return categories;
end

function Cauldron:GetSlots(player, skillName)
	self:Debug("GetSlots enter");
	
	local slots = {};

	for name, info in pairs(self.db.realm.userdata[self.vars.playername].skills[skillName].recipes) do
		if info.slot ~= "" then
			slots[info.slot] = true;
		end
	end

	self:Debug("GetSlots exit");
	
	return slots;
end

function Cauldron:GetSkillList(playername, skillName)
	self:Debug("GetSkillList enter");
	
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
				if not Cauldron:SkillContainsText(recipe, search) then
					self:Debug("skipping recipe: "..name.." (difficulty: "..recipe.difficulty..")");
					add = false;
				end
			end

		end
	
		-- check difficulty filter
		if not self.db.realm.userdata[playername].skills[skillName].window.filter[recipe.difficulty] then
			self:Debug("skipping recipe: "..name.." (difficulty: "..recipe.difficulty..")");
			add = false;
		end
		
		-- check categories
		local catInfo = self.db.realm.userdata[playername].skills[skillName].window.categories[recipe.defaultCategory];
		if catInfo and (not catInfo.shown) then
			self:Debug("skipping recipe: "..name.." (category: "..recipe.defaultCategory..")");
			add = false;
		end
		
		-- check slot
		local slotInfo = self.db.realm.userdata[playername].skills[skillName].window.slots[recipe.slot];
		if slotInfo then -- more
			self:Debug("skipping recipe: "..name.." (slot: "..recipe.slot..")");
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
			if self.db.realm.userdata[playername].skills[skillName].window.filter.sortAlpha then
				return r1.name < r2.name;
			elseif self.db.realm.userdata[playername].skills[skillName].window.filter.sortDifficulty then
				local difficulty = {
					optimal = 4,
					medium = 3,
					easy = 2,
					trivial = 1,
				};
				
				return difficulty[r2.difficulty] < difficulty[r1.difficulty];
			elseif self.db.realm.userdata[playername].skills[skillName].window.filter.sortBenefit then
				return 0; -- TODO
			end
			
			return 0;
		end);

	self:Debug("GetSkillList exit");
	
	return skills;
end

function Cauldron:GetSkillInfo(tradeskill, skill)
	self:Debug("GetSkillInfo enter");
	
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
	
	self:Debug("GetSkillInfo exit");
	
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

