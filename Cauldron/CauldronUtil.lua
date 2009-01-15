-- $Revision: 1.1 $
-- Cauldron utility functions

function Cauldron:GetAltReagentCount(reagentInfo)
	self:Debug("GetAltReagentCount enter");

	-- TODO

	self:Debug("GetAltReagentCount exit");
end

function Cauldron:GetPotentialCraftCount(skill)
	self:Debug("GetPotentialCraftCount enter");

	local count = 0;
	
	-- TODO

	self:Debug("GetPotentialCraftCount exit");

	return count;
end

function Cauldron:ReagentCount(reagent)
	
	local count = {
		has = 0,
		bank = 0,
		guildBank = 0,
		mail = 0,
		altHas = {},
	}
	
	-- sanity checks
	if not reagent then
		-- TODO: display error
		return count;
	end
	
	count.has = GetItemCount(reagent, false);
	
	
	-- TODO: find in banks, on alts, etc.
	if BankItems_SelfCache then
		-- TODO
		count.bank = BankItems_SelfCache[reagent].bank;
		count.mail = BankItems_SelfCache[reagent].mail;
	end
	
	if BankItems_GuildCache then
--		count.guildBank = BankItems_GuildCache[reagent].
	end
	
	
	return count;
end

function Cauldron:ScanForItem(name)
	-- look through bags
	
end

function Cauldron:SkillContainsText(recipe, text)
	
	-- sanity checks
	if (not recipe) or (not text) then
		-- TODO: display error
		return false;
	end
	
	if string.find(recipe.name, text) then
		return true;
	end
	
	for i, reagent in ipairs(recipe.reagents) do
		if string.find(reagent.name, text) then
			return true;
		end
	end
	
	-- TODO: check flavor text?
	
	return false;
end
