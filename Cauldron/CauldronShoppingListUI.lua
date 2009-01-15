-- $Revision: 1.1 $
-- Cauldron shopping list UI functions

function Cauldron:ShoppingList_Toggle()
	
	if CauldronShoppingListFrame then
		if CauldronShoppingListFrame:IsShown() then
			Cauldron:HideShoppingList();
		else
			Cauldron:ShowShoppingList();
		end
	end
	
end

function Cauldron:ShowShoppingList()

	if CauldronShoppingListFrame then
		CauldronShoppingListFrame:Show();

		--[[		
		local s = CauldronShoppingListFrame:GetEffectiveScale();
		
		if self.db.profile.ShoppingListPositionX and self.db.profile.ShoppingListPositionY then
			CauldronShoppingListFrame:SetPoint("TOPLEFT",
											   self.db.profile.ShoppingListPositionX,
											   self.db.profile.ShoppingListPositionY);
		end
		
		if self.db.profile.ShoppingListWidth then
			CauldronShoppingListFrame:SetWidth(self.db.profile.ShoppingListWidth);
		end
		if self.db.profile.ShoppingListHeight then
			CauldronShoppingListFrame:SetHeight(self.db.profile.ShoppingListHeight);
		end
		--]]
		
		self.db.profile.showShoppingList = true;
	end
	
	Cauldron:UpdateShoppingList();

end

function Cauldron:HideShoppingList()

	if CauldronShoppingListFrame then
		CauldronShoppingListFrame:Hide();
		self.db.profile.showShoppingList = false;
	end

end

function Cauldron:UpdateShoppingList()

	if not CauldronShoppingListFrame:IsShown() then
		return;
	end

	local list = self.db.realm.shopping;
	
	local reqIndex = 1;
	local itemIndex = 1;
	
	local width = CauldronShoppingListFrame:GetWidth();
	local height = CauldronShoppingListFrame:GetHeight();
	
	-- adjust inner frame sizes
	CauldronShoppingListFrameItemsScrollFrame:SetWidth(width - 10);
	CauldronShoppingListFrameItemsScrollFrame:SetHeight(height - 20);
	CauldronShoppingListFrameItemsScrollFrameScrollChild:SetWidth(width - 10);
	
	local frameAbove = nil;
	
	-- iterate over the requestors
	for requestor, items in pairs(list) do
	
		if CauldronShopping:HasItems(list, requestor) then
			
			local shoppingListRequestor = _G["CauldronShoppingListRequestor"..reqIndex];
			
			-- create a frame for the requestor
			if not shoppingListRequestor then
				-- create a new frame for the skill information
				shoppingListRequestor = CreateFrame("Button", 
													"CauldronShoppingListRequestor"..reqIndex, 
													CauldronShoppingListFrameItemsScrollFrameScrollChild,
													"CauldronShoppingListRequestorTemplate");
			end
			
			_G["CauldronShoppingListRequestor"..reqIndex.."Name"]:SetText(requestor);
			_G["CauldronShoppingListRequestor"..reqIndex.."Name"]:SetWidth(width - 10);
			
			_G["CauldronShoppingListRequestor"..reqIndex]:SetWidth(width - 10);
			
			-- place the frame in the scroll view
			if frameAbove then
				-- anchor to the frame above
				self:Debug("UpdateShoppingList: anchor frame to top left of frame above");
				shoppingListRequestor:SetPoint("TOPLEFT", frameAbove, "BOTTOMLEFT", 0, -2);
			else
				-- anchor to the parent
				self:Debug("UpdateShoppingList: anchor frame to parent");
				shoppingListRequestor:SetPoint("TOPLEFT", CauldronShoppingListFrameItemsScrollFrameScrollChild, "TOPLEFT", 0, 0);
			end
	
			shoppingListRequestor:Show();
			
			frameAbove = shoppingListRequestor;
			
			-- add items for the requestor
			for item, amount in pairs(items) do
	
				local shoppingListItem = _G["CauldronShoppingListItem"..itemIndex];
	
				-- create a frame for the item
				if not shoppingListItem then
					-- create a new frame for the skill information
					shoppingListItem = CreateFrame("Button", 
												   "CauldronShoppingListItem"..itemIndex, 
												   CauldronShoppingListFrameItemsScrollFrameScrollChild,
												   "CauldronShoppingListItemTemplate");
				end
				
				local str = string.format("%s, %d", item, amount);
				
				shoppingListItem.itemName = item;
				shoppingListItem.requestor = requestor;
				
				_G["CauldronShoppingListItem"..itemIndex.."Item"]:SetText(str);
				_G["CauldronShoppingListItem"..itemIndex.."Item"]:SetWidth(width - 25);
				
				-- place the frame in the scroll view
				if frameAbove then
					-- anchor to the frame above
					self:Debug("UpdateShoppingList: anchor frame to top left of frame above");
					shoppingListItem:SetPoint("TOPLEFT", frameAbove, "BOTTOMLEFT", 0, 0);
				end
		
				shoppingListItem:Show();
				
				frameAbove = shoppingListItem;
				
				itemIndex = itemIndex + 1;
				
			end
	
			reqIndex = reqIndex + 1;
	
		end
	end
	
	-- set scroll child frame height
	CauldronShoppingListFrameItemsScrollFrameScrollChild:SetHeight((reqIndex - 1) * 12 + (itemIndex - 1) * 12);
	
	while true do
		local frame = _G["CauldronShoppingListRequestor"..reqIndex];
		if not frame then
			break;
		end
		
		frame:Hide();
		frame:SetHeight(0);
		
		reqIndex = reqIndex + 1;
	end	
	while true do
		local frame = _G["CauldronShoppingListItem"..itemIndex];
		if not frame then
			break;
		end
		
		frame:Hide();
		frame:SetHeight(0);
		
		itemIndex = itemIndex + 1;
	end	
	
end
