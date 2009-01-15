-- $Revision: 1.1 $
-- Cauldron queue management functions

CauldronQueue = {};

--[[
	The following table describes a queue item in the "main" and "intermediate"
	sections of the queue:
	
	queueItem = {
		["name"] = "<name of item>",
		["icon"] = "<icon path>",
		["tradeskill"] = "<name of tradeskill>",
		["index"] = <index of skill>,
		["amount"] = <amount>,
		["priority"] = <priority>,
	};
	
	The following table describes a reagent needed by items in the queue.
	
	reagent = {
		["name"] = "<name of item>",
		["icon"] = "<icon path>",
		["amount"] = <amount>,
		["tradeskill"] = "<tradeskill that caused this reagent to be listed>",
	};
--]]

function CauldronQueue:NewQueue()
	local queue = {
		["main"] = {},
		["intermediate"] = {},
		["reagents"] = {},
	};
	
	return queue;
end

function CauldronQueue:NewItem(name, icon, tradeskill, index, amount, priority)

	local queueItem = {
		["name"] = name or "",
		["icon"] = icon or "",
		["tradeskill"] = tradeskill or "",
		["index"] = index,
		["amount"] = amount or 1,
		["priority"] = priority or 0,
	};
	
	return queueItem;
end

function CauldronQueue:NewReagent(name, icon, amount, tradeskill, index, skillIndex)

	local reagent = {
		["name"] = name or "",
		["icon"] = icon or "",
		["amount"] = amount or 1,
		["tradeskill"] = tradeskill,
		["skillIndex"] = skillIndex,
		["index"] = index,
	};
	
	return reagent;
end

function CauldronQueue:GetItems(queue)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return nil;
	end
	
	local items = {};
	
	for _, item in pairs(queue.main) do
--		if tradeskill then
--			if tradeskill == item.tradeskill then
--				table.insert(items, item);
--			end
--		else
			table.insert(items, item);
--		end
	end
	
	-- sort the list
	table.sort(items, function(r1, r2) return r2.priority < r1.priority; end);

	return items;
end

function CauldronQueue:GetIntermediates(queue)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return nil;
	end
	
	local items = {};
	
	for _, item in pairs(queue.intermediate) do
--		if tradeskill then
--			if tradeskill == item.tradeskill then
--				table.insert(items, item);
--			end
--		else
			table.insert(items, item);
--		end
	end
	
	-- sort the list
--	table.sort(items, function(r1, r2) return r2.priority < r1.priority; end);

	return items;
end

function CauldronQueue:GetReagents(queue)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return nil;
	end
	
	local items = {};
	
	for _, item in pairs(queue.reagents) do
--		if tradeskill then
--			if tradeskill == item.tradeskill then
--				table.insert(items, item);
--			end
--		else
			table.insert(items, item);
--		end
	end
	
	return items;
end

function CauldronQueue:AddItem(queue, skillInfo, amount, suppressCalc)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end
	
	if not queue.main then
		queue.main = {};
	end

	-- look for the item in the "main" section
	local item = queue.main[skillInfo.name];
	if item then
		-- it's there, so increase the amount
		item.amount = item.amount + amount;
	else
		-- it's not there, so create a new instance
		queue.main[skillInfo.name] = CauldronQueue:NewItem(skillInfo.name, skillInfo.icon, skillInfo.tradeskill, skillInfo.index, amount);
	end
	
	if not suppressCalc then
		CauldronQueue:CalculateAllRequiredItems(queue);
	end
end

function CauldronQueue:CalculateAllRequiredItems(queue)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end
	
	-- reset the intermediate and reagent lists
	queue.intermediate = {};
	queue.reagents = {};
	
	-- iterate over the queued items
	for name, queueInfo in pairs(queue.main) do
		local skillInfo = Cauldron:GetSkillInfo(queueInfo.tradeskill, queueInfo.name);
		CauldronQueue:CalculateRequiredItems(queue, skillInfo, queueInfo.amount);
	end

end

function CauldronQueue:CalculateRequiredItems(queue, skillInfo, amount)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end
	
	-- get the intermediates and reagents for the item
	local intermediates, reagents = Cauldron:GetRequiredItems(skillInfo, amount);

	-- check the intermediate list; if the item is available somewhere (inventory, bank, alt, etc.)
	-- then move it to the reagent list; otherwise, update the intermediate list in the queue
	
	-- update the intermediate and reagent lists
	for i, reagent in ipairs(intermediates) do
		local count = Cauldron:ReagentCount(reagent.name);
		
		if count.has >= reagent.numRequired then
			-- add the item to the reagent list if the character has all the required amount
			table.insert(reagents, reagent);
		else
			local amount = reagent.numRequired;
			
			-- if the character has some, add that amount to the reagent list
			if count.has > 0 then
				-- create a reagent copy of the item
				local newItem = CopyTable(reagent);
				newItem.numRequired = count.has;
			
				table.insert(reagents, newItem);
				
				-- adjust item count to how many need to be crafted
				amount = reagent.numRequired - count.has;
			end
			
			-- add the remaining amount to the intermediate list
			if amount > 0 then
				-- adjust the amount if the item produces more than one per execution
				local intSkillInfo = Cauldron:GetSkillInfoForItem(reagent.name);
				if intSkillInfo then
					if intSkillInfo.minMade > 1 then
						-- we ignore maxMade, since if it is greater than minMade, then the amount
						-- produced is variable, so we err on the side of caution and account for
						-- only ever making the minimum possible; besides, each execution of the
						-- skill will cause the reagent list to be reassessed, so producing more
						-- will be handled appropriately
						amount = math.ceil(amount / intSkillInfo.minMade);
					end
				end
				
				CauldronQueue:AddIntermediate(queue, reagent, amount);
				
				-- add the intermediate's reagents also
				CauldronQueue:CalculateRequiredItems(queue, intSkillInfo, amount);
			end
		end
	end
	
	for i, reagent in ipairs(reagents) do
		CauldronQueue:AddReagent(queue, reagent, reagent.numRequired, skillInfo.tradeskill);
	end

end

function CauldronQueue:AddIntermediate(queue, reagent, amount)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end
	
	amount = math.max(0, tonumber(amount) or 0);
	
	if not queue.intermediate then
		queue.intermediate = {};
	end

	-- look for the item in the "intermediate" section
	local item = queue.intermediate[reagent.name];
	if item then
		-- it's there, so increase the amount
		item.amount = item.amount + amount;
	else
		local skillInfo = Cauldron:GetSkillInfoForItem(reagent.name);

		-- it's not there, so create a new instance
		queue.intermediate[reagent.name] = CauldronQueue:NewItem(reagent.name, reagent.icon, skillInfo.tradeskill, skillInfo.index, amount);
	end
	
end

function CauldronQueue:AddReagent(queue, reagent, amount, tradeskill)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end
	
	amount = math.max(1, tonumber(amount) or 1);
	
	if not queue.reagents then
		queue.reagents = {};
	end

	-- look for the item in the "reagents" section
	local item = queue.reagents[reagent.name];
	if item then
		-- it's there, so increase the amount
		item.amount = (tonumber(item.amount) or 0) + amount;
	else
		-- it's not there, so create a new instance
		queue.reagents[reagent.name] = CauldronQueue:NewReagent(reagent.name, reagent.icon, amount, tradeskill, reagent.index, reagent.skillIndex);
	end
	
end

function CauldronQueue:AdjustItemCount(queue, name, delta)

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end
	
	local item = queue.main[itemName];
	if item then
		item.amount = item.amount + delta;
		
		if item.amount < 1 then
			queue.main[itemName] = nil;
		end
	end

	CauldronQueue:CalculateAllRequiredItems(queue);
	
end

function CauldronQueue:RemoveItem(queue, itemName)
	Cauldron:Debug("RemoveItem enter");
	
	-- sanity checks
	if (not queue) and (not itemName) then
		-- TODO: display error
		return;
	end
	
	if queue.main[itemName] then
		queue.main[itemName] = nil;
		
		CauldronQueue:CalculateAllRequiredItems(queue);
	end
	
	Cauldron:Debug("RemoveItem exit");
end

function CauldronQueue:IncreasePriority(queue, itemName, top)
	Cauldron:Debug("IncreasePriority enter");
	
	-- sanity checks
	if (not queue) and (not itemName) then
		-- TODO: display error
		return;
	end
	
	local item = queue.main[itemName];
	if item then
		local priority = item.priority + 1;
		local highest = 0;
		
		if top then
			for _, info in pairs(queue.main) do
				if info.priority > highest then
					highest = info.priority;
				end
			end
			
			priority = highest + 1;
		end
		
		item.priority = priority;
	end
	
	Cauldron:Debug("IncreasePriority exit");
end

function CauldronQueue:DecreasePriority(queue, itemName, bottom)
	Cauldron:Debug("DecreasePriority enter");
	
	-- sanity checks
	if (not queue) and (not itemName) then
		-- TODO: display error
		return;
	end
	
	local item = queue.main[itemName];
	if item then
		local priority = item.priority - 1;
		local lowest = 0;
		
		if top then
			for _, info in pairs(queue.main) do
				if info.priority < lowest then
					lowest = info.priority;
				end
			end
			
			priority = lowest - 1;
		end
		
		item.priority = priority;
	end
	
	Cauldron:Debug("DecreasePriority exit");
end

function CauldronQueue:ClearQueue(queue)
	Cauldron:Debug("ClearQueue enter");

	-- sanity checks
	if not queue then
		-- TODO: display error
		return;
	end

	--[[	
	if tradeskill then
		Cauldron:Debug("ClearQueue: clearing tradeskill: "..tradeskill);

		-- set aside the current main queue
		Cauldron:Debug("ClearQueue: set aside main table");
		local main = queue.main;
		
		-- clear out the tables
		Cauldron:Debug("ClearQueue: clear out tables");
		queue.main = {};
		
		-- iterate over the items and re-add the ones not for the specified tradeskill
		Cauldron:Debug("ClearQueue: iterate over items");
		for i, item in ipairs(main) do
			Cauldron:Debug("ClearQueue: item: "..i);
			if item.tradeskill ~= tradeskill then
				-- get the skill for the item
				Cauldron:Debug("ClearQueue: item.tradeskill: "..item.tradeskill);
				local skillInfo = Cauldron:GetSkillInfo(item.tradeskill, item.name);
				
				-- recalculate
				Cauldron:Debug("ClearQueue: recalculate");
				CauldronQueue:AddItem(queue, skillInfo, item.amount, true);
			end
		end
		
		CauldronQueue:CalculateAllRequiredItems(queue);
	else
	--]]

	queue.main = {};
	queue.intermediate = {};
	queue.reagents = {};
	
	Cauldron:Debug("ClearQueue exit");
end


