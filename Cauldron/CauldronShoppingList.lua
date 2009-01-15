-- $Revision: 1.2 $
-- Cauldron shopping list functions

CauldronShopping = {};

--[[
	list = {
		["<requestor>"] = {
			["<item name>"] = <quantity>,
			["<item name>"] = <quantity>,
			...
		},
		["<requestor>"] = {
			...
		},
	};
--]]

function CauldronShopping:NewList()
	
	local list = {};
	
	return list;
end

function CauldronShopping:AddToList(list, requestor, itemName, quantity)

	-- sanity checks
	if (not list) and (not requestor) and (not itemName) then
		-- TODO: display error
		return;
	end
	
	quantity = math.max(1, tonumber(quantity) or 1);
	
	if not list[requestor] then
		-- initialize the list for the requestor
		list[requestor] = {};
	end
	
	if list[requestor][itemName] then
		list[requestor][itemName] = list[requestor][itemName] + quantity;
	else
		list[requestor][itemName] = quantity;
	end
	
end

function CauldronShopping:RemoveFromList(list, requestor, itemName, quantity)
	-- sanity checks
	if not list then
		-- TODO: display error
		return;
	end
	
	if not list[requestor] then
		-- initialize the list for the requestor
		list[requestor] = {};
	end
	
	if list[requestor][itemName] then
		if quantity then
			list[requestor][itemName] = list[requestor][itemName] - quantity;
			if list[requestor][itemName] < 1 then
				list[requestor][itemName] = nil;
			end
		else
			list[requestor][itemName] = nil;
		end
	end
end

function CauldronShopping:GetRequestors(list)
	
	if not list then
		-- TODO: display error
		return;
	end
	
	local requestors = {};
	
	for name, _ in pairs(list) do
		table.insert(requestors, name);
	end
	
	return requestors;
end

function CauldronShopping:ContainsItems(list)

	if not list then
		-- TODO: display error
		return;
	end
	
	for _, items in pairs(list) do
		for _, amount in pairs(items) do
			if amount > 0 then
				return true;
			end
		end
	end
	
	return false;
end

function CauldronShopping:HasItems(list, requestor)

	if not list then
		-- TODO: display error
		return;
	end
	
	if list[requestor] then
		for _, amount in pairs(list[requestor]) do
			if amount > 0 then
				return true;
			end
		end
	end
	
	return false;
end

function CauldronShopping:GetRequestedItems(list, requestor)
end

function CauldronShopping:EmptyShoppingList(list, requestor)

	if not list then
		-- TODO: display error
		return;
	end
	
	for r, _ in pairs(list) do
		if requestor then
			if requestor == r then
				list[r] = nil;
			end
		else
			list[r] = nil;
		end
	end
	
end
