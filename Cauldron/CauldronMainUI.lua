-- $Revision: 1.3 $
-- Cauldron user interface logic

local L = LibStub("AceLocale-3.0"):GetLocale("Cauldron")

-- CauldronUI = LibStub("AceAddon-3.0"):NewAddon("CauldronUI", "AceEvent-3.0", "AceConsole-3.0", "LibDebugLog-1.0")

function Cauldron:Frame_Show()
 	self:debug("Frame_Show enter");

 	self:debug("Frame_Show: close dropdown menus");
 	CloseDropDownMenus();

--	self:UpdateFramePosition();
--	self:UpdateFrameStrata();

 	self:debug("Frame_Show: show our frame");
 	ShowUIPanel(CauldronFrame);

	if TradeSkillFrame then
		self:debug("Frame_Show: hide the original tradeskill frame");

		-- hide the original tradeskill frame
		TradeSkillFrame:SetAlpha(0);
--		TradeSkillFrame:ClearAllPoints();
--		TradeSkillFrame:SetPoint("TOPLEFT", 0, 900);
		CauldronFrame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 0, 0);
	end

 	self:RegisterMessage("Cauldron_Update", "OnCauldronUpdate");

 	self:debug("Frame_Show: call Frame_Update()");
	self:Frame_Update();

 	self:debug("Frame_Show exit");
end

function Cauldron:Frame_Hide()
 	self:debug("Frame_Hide enter");

 	self:UnregisterEvent("Cauldron_Update")
 	HideUIPanel(CauldronFrame);

 	self:debug("Frame_Hide exit");
end

function Cauldron:Frame_Toggle()
 	self:debug("Frame_Toggle enter");

 	if CauldronFrame:IsVisible() then
		self:debug("Frame_Toggle: call Frame_Hide()");
 		Cauldron:Frame_Hide();
 	else
		self:debug("Frame_Toggle: call Frame_Show()");
 		Cauldron:Frame_Show();
 	end

 	self:debug("Frame_Toggle exit");
end

function Cauldron:Frame_Update()
 	self:debug("Frame_Update enter");

	local numTradeSkills = GetNumTradeSkills();
	self:debug("Frame_Update numTradeSkills: ",numTradeSkills);
--	local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame);
	local name, rank, maxRank = GetTradeSkillLine();
	self:debug("Frame_Update name: ",name,"; rank: ",rank,"; maxRank: ",maxRank);
	
	if name == "UNKNOWN" then
		return;
	end
	
	Cauldron:UpdateSkills();
	
	if CURRENT_TRADESKILL ~= name then
		self:debug("Frame_Update: current skill changed");

		StopTradeSkillRepeat();

		if ( CURRENT_TRADESKILL ~= "" ) then
			-- To fix problem with switching between two tradeskills
--			UIDropDownMenu_Initialize(TradeSkillInvSlotDropDown, TradeSkillInvSlotDropDown_Initialize);
--			UIDropDownMenu_SetSelectedID(TradeSkillInvSlotDropDown, 1);

--			UIDropDownMenu_Initialize(TradeSkillSubClassDropDown, TradeSkillSubClassDropDown_Initialize);
--			UIDropDownMenu_SetSelectedID(TradeSkillSubClassDropDown, 1);
		end
		CURRENT_TRADESKILL = name;
	end
	
	-- update the frame dimensions
    -- <Size x="692" y="465" />
	CauldronFrame:SetHeight(465);
	CauldronFrame:SetWidth(692);
	
	-- display skill name, level/progress
	self:debug("Frame_Update: display skill level/progress");
	self:UpdateSkillInfo(name, rank, maxRank);

	-- update search text box
	self:debug("Frame_Update: display search text");
	self:UpdateSearchText(name);
	
	-- TODO: update dropdowns
	self:debug("Frame_Update: update dropdowns");
	self:UpdateFilterDropDowns();
	
	-- display list of matching skills
	self:debug("Frame_Update: display list of skills");
	self:UpdateSkillList();
	
	-- display queue
	self:debug("Frame_Update: display queue");
	self:UpdateQueue();
	
	-- update buttons
	self:debug("Frame_Update: update buttons");
	self:UpdateButtons();

 	self:debug("Frame_Update exit");
end

function Cauldron:UpdateSkillInfo(skillName, rank, maxRank)
	self:debug("UpdateSkillInfo enter");

	CauldronRankFrameSkillName:SetText(skillName);

	CauldronRankFrame:SetStatusBarColor(0.0, 0.0, 1.0, 0.5);
	CauldronRankFrameBackground:SetVertexColor(0.0, 0.0, 0.75, 0.5);
	CauldronRankFrame:SetMinMaxValues(0, maxRank);
	CauldronRankFrame:SetValue(rank);
	CauldronRankFrameSkillRank:SetText(rank.."/"..maxRank);

	self:debug("UpdateSkillInfo exit");
end

function Cauldron:UpdateSearchText(skillName)
	self:debug("UpdateSearchText enter");

	local searchText = self.db.realm.userdata[self.vars.playername].skills[skillName].window.search;
	if searchText == "" then
		searchText = SEARCH;
	end
	CauldronFiltersSearchEditBox:SetText(searchText);
	
	self:debug("UpdateSearchText exit");
end

function Cauldron:UpdateFilterDropDowns()
	self:debug("UpdateFilterDropDowns enter");

	self:debug("UpdateFilterDropDowns exit");
end

function Cauldron:UpdateSkillList()
	self:debug("UpdateSkillList enter");
	
	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end
	
	local skillList = Cauldron:GetSkillList(self.vars.playername, skillName);
	self:debug("UpdateSkillList: skillList="..#skillList);
	
	local height = 0;
	
	-- iterate over the list of skills
	for i, skillInfo in ipairs(skillList) do
		local skillFrame = _G["CauldronSkillItem"..i];
		
		-- check if we have a frame for this position
		if not skillFrame then
			-- create a new frame for the skill information
			skillFrame = CreateFrame("Button", 
									 "CauldronSkillItem"..i, 
									 CauldronSkillListFrameScrollFrameScrollChild, 
									 "CauldronSkillItemFrameTemplate");
		end
		
		skillFrame:SetID(i);
		skillFrame.skillIndex = skillInfo.index;
		
		-- set selection
		if self.db.realm.userdata[self.vars.playername].skills[skillName].window.selected == skillInfo.index then
			_G["CauldronSkillItem"..i.."Selection"]:Show();
		else
			_G["CauldronSkillItem"..i.."Selection"]:Hide();
		end
		
		-- populate the frame
		local frame = nil;

		-- set name and difficulty color
		frame = _G["CauldronSkillItem"..i.."SkillName"];
		local nameText = skillInfo.name;
		local potentialCount = Cauldron:GetPotentialCraftCount(skillInfo);
		if potentialCount > 0 then
			nameText = nameText.." ["..skillInfo.available.."/"..potentialCount.."]";
		elseif skillInfo.available > 0 then
			nameText = nameText.." ["..skillInfo.available.."]";
		end
		frame:SetText(nameText);
		local color = TradeSkillTypeColor[skillInfo.difficulty];
		if color then
			frame:SetFontObject(color.font);
			frame.r = color.r;
			frame.g = color.g;
			frame.b = color.b;
		end
		
		-- set category
		frame = _G["CauldronSkillItem"..i.."SkillCategory"];
		frame:SetText(skillInfo.defaultCategory);
		frame:SetFontObject(TradeSkillTypeColor.header.font);
		frame.r = TradeSkillTypeColor.header.r;
		frame.g = TradeSkillTypeColor.header.g;
		frame.b = TradeSkillTypeColor.header.b;
		
		-- set cooldown
		frame = _G["CauldronSkillItem"..i.."SkillCooldown"];
		local cooldown = GetTradeSkillCooldown(skillInfo.index);
		if cooldown then
			if not frame:IsVisible() then
				frame:Show();
			end
			frame:SetText(SecondsToTime(cooldown));
		else
			if frame:IsVisible() then
				frame:Hide();
			end
		end

		-- set the icon
		frame = _G["CauldronSkillItem"..i.."SkillIcon"];
		frame:SetNormalTexture(skillInfo.icon);
		frame.skillIndex = skillInfo.index;

		-- set the craft count
		frame = _G["CauldronSkillItem"..i.."SkillIconCount"];
		local minMade, maxMade = skillInfo.minMade, skillInfo.maxMade;
		if maxMade > 1 then
			if minMade == maxMade then
				frame:SetText(minMade);
			else
				frame:SetText(minMade.."-"..maxMade);
			end
			if frame:GetWidth() > 39 then
				frame:SetText("~"..floor((minMade + maxMade)/2));
			end
		else
			frame:SetText("");
		end
		
		-- set the disclosure button texture
		frame = _G["CauldronSkillItem"..i.."DiscloseButton"];
		frame.skillInfo = skillInfo;
		local reagentsExpanded = self.db.realm.userdata[self.vars.playername].skills[skillName].window.skills[skillName][skillInfo.name].expanded;
		self:debug("UpdateSkillList: reagentsExpanded="..tostring(reagentsExpanded));
		if reagentsExpanded then
			frame:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
			
			_G["CauldronSkillItem"..i.."Reagents"]:Show();
			
			-- fill in the tools info
			local spellFocus = BuildColoredListString(GetTradeSkillTools(skillInfo.index));
			local toolsFrame = _G["CauldronSkillItem"..i.."ReagentsToolsInfo"];
			if spellFocus then
				self:debug("UpdateSkillList: skill has a spell focus");

				toolsFrame:Show();
				toolsFrame:SetText(L["Requires"]..": "..spellFocus);
				toolsFrame:SetHeight(15);
			else
				self:debug("UpdateSkillList: skill doesn't have a spell focus");

				toolsFrame:Hide();
				toolsFrame:SetText("");
				toolsFrame:SetHeight(0);
			end

			-- fill in the reagents
			_G["CauldronSkillItem"..i.."Reagents"]:SetScale(0.86);
			local reagentCount = #skillInfo.reagents;

			for j=1,8 do
				self:debug("UpdateSkillList: j="..j);
				
				local reagentFrame = _G["CauldronSkillItem"..i.."ReagentsItemDetail"..j];
				self:debug("UpdateSkillList: reagentFrame="..tostring(reagentFrame));
				local reagentInfo = skillInfo.reagents[j];
				self:debug("UpdateSkillList: reagentInfo="..tostring(reagentInfo));

				reagentFrame.skillIndex = skillInfo.index;
				
				if j > reagentCount then
					self:debug("UpdateSkillList: hide the reagent frame");
					reagentFrame:Hide();
				else
					self:debug("UpdateSkillList: show the reagent info");
					
					local reagentNameFrame = _G["CauldronSkillItem"..i.."ReagentsItemDetail"..j.."Name"];
					self:debug("UpdateSkillList: reagentNameFrame="..tostring(reagentNameFrame));
					local reagentCountFrame = _G["CauldronSkillItem"..i.."ReagentsItemDetail"..j.."Count"];
					self:debug("UpdateSkillList: reagentCountFrame="..tostring(reagentCountFrame));

					self:debug("UpdateSkillList: show the reagent frame");
					reagentFrame:Show();
					self:debug("UpdateSkillList: set the item button texture");
					SetItemButtonTexture(reagentFrame, reagentInfo.icon);
					self:debug("UpdateSkillList: set the reagent name");
					reagentNameFrame:SetText(reagentInfo.name);
					
					local playerReagentCount = reagentInfo.toonHas;
					-- Grayout items
					if playerReagentCount < reagentInfo.numRequired then
						SetItemButtonTextureVertexColor(reagentFrame, 0.5, 0.5, 0.5);
						reagentNameFrame:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					else
						SetItemButtonTextureVertexColor(reagentFrame, 1.0, 1.0, 1.0);
						reagentNameFrame:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					end
					if playerReagentCount >= 100 then
						playerReagentCount = "*";
					end
					reagentCountFrame:SetText(playerReagentCount.." /"..reagentInfo.numRequired);
				end
			end

			local reagentRows = math.floor((reagentCount - 1) / 2) + 1;
			_G["CauldronSkillItem"..i.."Reagents"]:SetHeight(toolsFrame:GetHeight() + (reagentRows * _G["CauldronSkillItem"..i.."ReagentsItemDetail1"]:GetHeight()));
			_G["CauldronSkillItem"..i]:SetHeight(_G["CauldronSkillItem"..i.."SkillIcon"]:GetHeight() + _G["CauldronSkillItem"..i.."Reagents"]:GetHeight());
		else
			self:debug("UpdateSkillList: reagents info not expanded");

			_G["CauldronSkillItem"..i.."Reagents"]:Hide();

			frame:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
			_G["CauldronSkillItem"..i]:SetHeight(_G["CauldronSkillItem"..i.."SkillIcon"]:GetHeight());
		end

		-- place the frame in the scroll view
		if i > 1 then
			-- anchor to the frame above
			self:debug("UpdateSkillList: anchor frame to top left of frame above");
			skillFrame:SetPoint("TOPLEFT", _G["CauldronSkillItem"..(i-1)], "BOTTOMLEFT", 0, -2);
		else
			-- anchor to the parent
			self:debug("UpdateSkillList: anchor frame to parent");
			skillFrame:SetPoint("TOPLEFT", 0, 0);
		end
		
		-- adjust the scroll child size
		height = height + skillFrame:GetHeight();
		self:debug("UpdateSkillList: height="..height);
		CauldronSkillListFrameScrollFrameScrollChild:SetHeight(height);

		-- show the frame
		self:debug("UpdateSkillList: show the frame");
		skillFrame:Show();
	end
	
	-- hide any remaining frames
	local j = #skillList + 1;
	while true do
		local frame = _G["CauldronSkillItem"..j];
		if not frame then
			break;
		end
		
		frame:Hide();
		frame:SetHeight(0);
		
		j = j + 1;
	end
	
	self:debug("UpdateSkillList exit");
end

function Cauldron:UpdateButtons()
	self:debug("UpdateButtons enter");
	
	local skillInfo = Cauldron:GetSelectedSkill();
	
	if skillInfo then
		CauldronQueueAllButton:Enable();
		CauldronQueueButton:Enable();
		
		if skillInfo.available then
			CauldronCreateAllButton:Enable();
			CauldronCreateButton:Enable();
		end
	else
		CauldronQueueAllButton:Disable();
		CauldronQueueButton:Disable();
		CauldronCreateAllButton:Disable();
		CauldronCreateButton:Disable();
	end
	
	if #CauldronQueue:GetItems(self.db.realm.userdata[self.vars.playername].queue, CURRENT_TRADESKILL) > 0 then
		CauldronProcessButton:Enable();
		CauldronClearQueueButton:Enable();
	else
		CauldronProcessButton:Disable();
		CauldronClearQueueButton:Disable();
	end
	
	self:debug("UpdateButtons exit");
end

function Cauldron:UpdateQueue()
	self:debug("UpdateQueue enter");
	
	if not CauldronFrame:IsShown() then
		return;
	end
	
	local queue = self.db.realm.userdata[self.vars.playername].queue;
	local itemQueue = {};

	local skillName = CURRENT_TRADESKILL;
	if not IsTradeSkillLinked() then
		itemQueue = CauldronQueue:GetItems(queue);
	end

	if #itemQueue == 0 then
		self:debug("UpdateQueue: display empty queue");

		-- queue is empty, display the empty message
		CauldronQueueFrameQueueEmpty:Show();
		CauldronQueueFrameScrollFrame:Hide();
		
		if IsTradeSkillLinked() then
			CauldronQueueFrameQueueEmptyText:SetText("No queue for linked tradeskills.");
		else
			CauldronQueueFrameQueueEmptyText:SetText("The queue is empty!\nMake something.");
		end
		
		return;
	end

	self:debug("UpdateQueue: display queue");

	-- queue has items, show them
	CauldronQueueFrameQueueEmpty:Hide();
	CauldronQueueFrameScrollFrame:Show();

	local height = 0;
	
	CauldronQueueFrameScrollFrameQueueSectionsMainItemsHeaderText:SetText(L["In order to make:"]);
	
	for i, queueInfo in ipairs(itemQueue) do
		local queueItemFrame = _G["CauldronQueueItem"..i];
		
		-- check if we have a frame for this position
		if not queueItemFrame then
			-- create a new frame for the skill information
			queueItemFrame = CreateFrame("Button", 
									 	 "CauldronQueueItem"..i, 
									 	 CauldronQueueFrameScrollFrameQueueSectionsMainItems, 
									 	 "CauldronQueueItemFrameTemplate");
		end
		
		queueItemFrame:SetID(i);
		queueItemFrame.itemName = queueInfo.name;
		queueItemFrame.removeable = true;
		queueItemFrame.shoppable = false;
		queueItemFrame.inHoverButtons = false;
		
		_G["CauldronQueueItem"..i.."RemoveItem"]:Hide();
		_G["CauldronQueueItem"..i.."RemoveItem"]:SetScale(0.75);
		_G["CauldronQueueItem"..i.."IncreasePriority"]:Hide();
		_G["CauldronQueueItem"..i.."DecreasePriority"]:Hide();
		_G["CauldronQueueItem"..i.."DecrementCount"]:Hide();
		_G["CauldronQueueItem"..i.."AddToShoppingList"]:Hide();
		
		local skillInfo = Cauldron:GetSkillInfo(queueInfo.tradeskill, queueInfo.name);
		if not skillInfo then
			-- the skill isn't available (character doesn't know it?)
			-- TODO
		end
		
		-- initialize the frame object
		local frame = nil;

		-- set name and difficulty color
		frame = _G["CauldronQueueItem"..i.."ItemName"];
		frame:SetText(queueInfo.name);
		if skillInfo then
			local color = TradeSkillTypeColor[skillInfo.difficulty];
			if color then
				frame:SetFontObject(color.font);
				frame:SetTextColor(color.r, color.g, color.b, 1.0);
				frame.r = color.r;
				frame.g = color.g;
				frame.b = color.b;
			end
		else
			-- TODO: default color info
		end
		
		-- set quantity info
		frame = _G["CauldronQueueItem"..i.."Info"];
		local infoText = queueInfo.tradeskill;
		-- TODO: alts/bank/etc.
		frame:SetText(infoText);
--		frame:SetTextColor(1.0, 1.0, 0.2, 1.0);
--		frame:SetShadowOffset(0, 0);
		
		-- set the icon
		frame = _G["CauldronQueueItem"..i.."Icon"];
		frame:SetNormalTexture(queueInfo.icon);
		if skillInfo then
			frame.skillIndex = skillInfo.index;
		end

		-- set the amount
		frame = _G["CauldronQueueItem"..i.."IconCount"];
		frame:SetText(queueInfo.amount);

		-- place the frame in the scroll view
		if i > 1 then
			-- anchor to the frame above
			self:debug("UpdateQueue: anchor frame to top left of frame above");
			queueItemFrame:SetPoint("TOPLEFT", _G["CauldronQueueItem"..(i-1)], "BOTTOMLEFT", 0, -2);
		else
			-- anchor to the parent
			self:debug("UpdateQueue: anchor frame to parent");
			queueItemFrame:SetPoint("TOPLEFT", CauldronQueueFrameScrollFrameQueueSectionsMainItems, "TOPLEFT", 0, 0);
		end
		
		height = height + queueItemFrame:GetHeight() + 2;
		self:debug("UpdateQueue: height="..height);

		-- show the frame
		self:debug("UpdateQueue: show the frame");
		queueItemFrame:Show();
	end

	-- adjust the scroll child size
	CauldronQueueFrameScrollFrameQueueSectionsMainItems:SetHeight(height);
	
	-- hide any remaining frames
	local j = #itemQueue + 1;
	while true do
		local frame = _G["CauldronQueueItem"..j];
		if not frame then
			break;
		end
		
		frame:Hide();
		frame:SetHeight(0);
		
		j = j + 1;
	end	

	-- display intermediate queue, maybe
	local intQueue = CauldronQueue:GetIntermediates(queue);
	local reagentList = CauldronQueue:GetReagents(queue);
	
	-- store the intermediate queue and the reagent list
--	self.db.realm.userdata[self.vars.playername].intQueue = intQueue;
--	self.db.realm.userdata[self.vars.playername].reagentList = reagentList;
	
	if #intQueue == 0 then
		CauldronQueueFrameScrollFrameQueueSectionsSecondaryItemsHeader:SetHeight(1);
		CauldronQueueFrameScrollFrameQueueSectionsSecondaryItemsHeaderText:SetText("");
		CauldronQueueFrameScrollFrameQueueSectionsSecondaryItems:SetHeight(1);
	else
		CauldronQueueFrameScrollFrameQueueSectionsSecondaryItemsHeader:SetHeight(12);
		CauldronQueueFrameScrollFrameQueueSectionsSecondaryItemsHeaderText:SetText(L["You first have to make:"]);
		
		local intHeight = 0;
		
		for i, queueInfo in ipairs(intQueue) do
			local queueItemFrame = _G["CauldronQueueIntItem"..i];
			
			-- check if we have a frame for this position
			if not queueItemFrame then
				-- create a new frame for the skill information
				queueItemFrame = CreateFrame("Button", 
											 "CauldronQueueIntItem"..i, 
											 CauldronQueueFrameScrollFrameQueueSectionsSecondaryItems, 
											 "CauldronQueueItemFrameTemplate");
			end
			
			queueItemFrame:SetID(i);
			queueItemFrame.itemName = queueInfo.name;
			queueItemFrame.removeable = false;
			queueItemFrame.shoppable = false;
			queueItemFrame.inHoverButtons = false;
			
			-- don't show the remove button
			_G["CauldronQueueIntItem"..i.."RemoveItem"]:Hide();
			_G["CauldronQueueIntItem"..i.."RemoveItem"]:SetScale(0.75);
			_G["CauldronQueueIntItem"..i.."IncreasePriority"]:Hide();
			_G["CauldronQueueIntItem"..i.."DecreasePriority"]:Hide();
			_G["CauldronQueueIntItem"..i.."DecrementCount"]:Hide();
			_G["CauldronQueueIntItem"..i.."AddToShoppingList"]:Hide();
			
			local skillInfo = Cauldron:GetSkillInfo(queueInfo.tradeskill, queueInfo.name);
			if not skillInfo then
				-- the skill isn't available (character doesn't know it?)
				-- TODO
			end
			
			-- populate the frame
			local frame = nil;
	
			-- set name and difficulty color
			frame = _G["CauldronQueueIntItem"..i.."ItemName"];
			frame:SetText(queueInfo.name);
			if skillInfo then
				local color = TradeSkillTypeColor[skillInfo.difficulty];
				if color then
					frame:SetFontObject(color.font);
					frame:SetTextColor(color.r, color.g, color.b, 1.0);
					frame.r = color.r;
					frame.g = color.g;
					frame.b = color.b;
				end
			else
				frame:SetFont("GameFontNormal", 12);
--				frame:SetTextColor(1.0, 1.0, 1.0, 1.0);
				frame.r = 1.0;
				frame.g = 1.0;
				frame.b = 1.0;
			end
			
			-- set quantity info
			frame = _G["CauldronQueueIntItem"..i.."Info"];
			local countInfo = Cauldron:ReagentCount(queueInfo.name);
			local infoText = string.format(queueInfo.tradeskill.."; "..L["Have %d"], countInfo.has);
			local need = math.max(0, queueInfo.amount - countInfo.has);
			if need > 0 then
				infoText = infoText..string.format(L[", need %d"], need);
			end
			-- alts/bank/etc.
			frame:SetText(infoText);
			frame:SetTextColor(0.1, 0.1, 0.1, 1.0);
			frame:SetShadowOffset(0, 0);
			
			-- set the icon
			frame = _G["CauldronQueueIntItem"..i.."Icon"];
			frame:SetNormalTexture(queueInfo.icon);
			if skillInfo then
				frame.skillIndex = skillInfo.index;
			end

			-- set the amount
			frame = _G["CauldronQueueIntItem"..i.."IconCount"];
			frame:SetText(queueInfo.amount);
	
			-- place the frame in the scroll view
			if i > 1 then
				-- anchor to the frame above
				self:debug("UpdateQueue: anchor frame to top left of frame above");
				queueItemFrame:SetPoint("TOPLEFT", _G["CauldronQueueIntItem"..(i-1)], "BOTTOMLEFT", 0, -2);
			else
				-- anchor to the parent
				self:debug("UpdateQueue: anchor frame to parent");
				queueItemFrame:SetPoint("TOPLEFT", CauldronQueueFrameScrollFrameQueueSectionsSecondaryItems, "TOPLEFT", 0, 0);
			end
			
			-- adjust the scroll child size
			intHeight = intHeight + queueItemFrame:GetHeight() + 2;
			self:debug("UpdateQueue: height="..height);
			CauldronQueueFrameScrollFrameQueueSectionsSecondaryItems:SetHeight(intHeight);
	
			-- show the frame
			self:debug("UpdateQueue: show the frame");
			queueItemFrame:Show();
		end
	end

	-- hide any remaining frames
	local j = #intQueue + 1;
	while true do
		local frame = _G["CauldronQueueIntItem"..j];
		if not frame then
			break;
		end
		
		frame:Hide();
		frame:SetHeight(0);
		
		j = j + 1;
	end	
	
	-- display reagent list
	
	CauldronQueueFrameScrollFrameQueueSectionsReagentsHeaderText:SetText(L["You will need:"]);

	local reagentHeight = 0;
	
	for i, queueInfo in ipairs(reagentList) do
		local queueItemFrame = _G["CauldronQueueReagentItem"..i];
		
		-- check if we have a frame for this position
		if not queueItemFrame then
			-- create a new frame for the skill information
			queueItemFrame = CreateFrame("Button", 
										 "CauldronQueueReagentItem"..i, 
										 CauldronQueueFrameScrollFrameQueueSectionsReagents, 
										 "CauldronQueueItemFrameTemplate");
		end
		
		local countInfo = Cauldron:ReagentCount(queueInfo.name);
		local need = math.max(0, queueInfo.amount - countInfo.has);

		queueItemFrame:SetID(i);
		queueItemFrame.skillIndex = queueInfo.skillIndex;
		queueItemFrame.index = queueInfo.index;
		queueItemFrame.itemName = queueInfo.name;
		queueItemFrame.removeable = false;
		queueItemFrame.shoppable = true;
		queueItemFrame.inHoverButtons = false;
		queueItemFrame.needAmount = need;
		
		-- don't show the remove button
		_G["CauldronQueueReagentItem"..i.."RemoveItem"]:Hide();
		_G["CauldronQueueReagentItem"..i.."RemoveItem"]:SetScale(0.75);
		_G["CauldronQueueReagentItem"..i.."IncreasePriority"]:Hide();
		_G["CauldronQueueReagentItem"..i.."DecreasePriority"]:Hide();
		_G["CauldronQueueReagentItem"..i.."DecrementCount"]:Hide();
		_G["CauldronQueueReagentItem"..i.."AddToShoppingList"]:Hide();
		_G["CauldronQueueReagentItem"..i.."AddToShoppingList"]:SetScale(0.5);

		local skillInfo = Cauldron:GetSkillInfo(queueInfo.tradeskill, queueInfo.name);
		if not skillInfo then
			-- TODO
		end
		
		-- populate the frame
		local frame = nil;

		-- set name and difficulty color
		frame = _G["CauldronQueueReagentItem"..i.."ItemName"];
		frame:SetText(queueInfo.name);
		frame:SetShadowOffset(0, 0);
		frame:SetFont("GameFontNormal", 12);
		frame:SetTextColor(0.1, 0.1, 0.1, 1.0);
		frame.r = 1.0;
		frame.g = 1.0;
		frame.b = 1.0;
		
		-- set quantity info
		frame = _G["CauldronQueueReagentItem"..i.."Info"];
		local countInfo = Cauldron:ReagentCount(queueInfo.name);
		local qtyText = string.format(L["Have %d"], countInfo.has);
		if need > 0 then
			qtyText = qtyText..string.format(L[", need %d"], need);
		end
		-- TODO: alts/bank/etc.
		frame:SetText(qtyText);
		frame:SetTextColor(0.4, 0.4, 0.4, 1.0);
		frame:SetShadowOffset(0, 0);
		
		-- set the icon
		frame = _G["CauldronQueueReagentItem"..i.."Icon"];
		frame:SetNormalTexture(queueInfo.icon);
		if skillInfo then
			frame.skillIndex = queueInfo.skillIndex;
			frame.reagentIndex = queueInfo.index;
		end
--		local playerReagentCount = 0; -- TODO
--		if playerReagentCount < queueInfo.amount then
--			frame:SetVertexColor(0.5, 0.5, 0.5, 1.0);
--			frame:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
--		else
--			frame:SetVertexColor(1.0, 1.0, 1.0, 1.0);
--			frame:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
--		end

		-- set the amount
		frame = _G["CauldronQueueReagentItem"..i.."IconCount"];
		frame:SetText(queueInfo.amount);

		-- place the frame in the scroll view
		if i > 1 then
			-- anchor to the frame above
			self:debug("UpdateQueue: anchor frame to top left of frame above");
			queueItemFrame:SetPoint("TOPLEFT", _G["CauldronQueueReagentItem"..(i-1)], "BOTTOMLEFT", 0, -2);
		else
			-- anchor to the parent
			self:debug("UpdateQueue: anchor frame to parent");
			queueItemFrame:SetPoint("TOPLEFT", CauldronQueueFrameScrollFrameQueueSectionsReagents, "TOPLEFT", 0, 0);
		end
		
		-- adjust the scroll child size
		reagentHeight = reagentHeight + queueItemFrame:GetHeight() + 2;
		self:debug("UpdateQueue: height="..height);
		CauldronQueueFrameScrollFrameQueueSectionsReagents:SetHeight(reagentHeight);

		-- show the frame
		self:debug("UpdateQueue: show the frame");
		queueItemFrame:Show();
	end

	-- hide any remaining frames
	local j = #reagentList + 1;
	while true do
		local frame = _G["CauldronQueueReagentItem"..j];
		if not frame then
			break;
		end
		
		frame:Hide();
		frame:SetHeight(0);
		
		j = j + 1;
	end	
--]]
	-- adjust the height of the scroll frame	
	local h = CauldronQueueFrameScrollFrameQueueSectionsMainItemsHeader:GetHeight() +
			CauldronQueueFrameScrollFrameQueueSectionsMainItems:GetHeight() +
			CauldronQueueFrameScrollFrameQueueSectionsSecondaryItemsHeader:GetHeight() +
			CauldronQueueFrameScrollFrameQueueSectionsSecondaryItems:GetHeight() +
			CauldronQueueFrameScrollFrameQueueSectionsReagentsHeader:GetHeight() +
			CauldronQueueFrameScrollFrameQueueSectionsReagents:GetHeight();
	CauldronQueueFrameScrollFrameQueueSections:SetHeight(h);
	CauldronQueueFrameScrollFrame:UpdateScrollChildRect();

	self:debug("UpdateQueue exit");
end

function Cauldron:SaveFramePosition()
 	self:debug("SaveFramePosition enter");

-- TODO

 	self:debug("SaveFramePosition exit");
end

function Cauldron:OnCauldronUpdate()
	self:debug("OnCauldronUpdate enter");
	
--	self:Search();
 	local selectionIndex
 	if self.vars.selectionIndex == 0 then
 		selectionIndex = self:GetFirstTradeSkill();
 	else
 		selectionIndex = self.vars.selectionIndex;
 	end

	self:debug("OnCauldronUpdate exit"); 
end

function Cauldron:FilterDropDown_OnLoad(dropdown)
	self:debug("FilterDropDown_OnLoad enter");

--[[	
	if CURRENT_TRADESKILL == "" or CURRENT_TRADESKILL == "UNKNOWN" then
		return;
	end
--]]

	UIDropDownMenu_Initialize(dropdown, Cauldron.FilterDropDown_Initialize);
	UIDropDownMenu_SetText(CauldronFiltersFilterDropDown, L["Filters"]);

	self:debug("FilterDropDown_OnLoad exit");
end

function Cauldron:InvSlotDropDown_OnLoad(dropdown)
	self:debug("InvSlotDropDown_OnLoad enter");
	
--[[	
	if CURRENT_TRADESKILL == "" or CURRENT_TRADESKILL == "UNKNOWN" then
		return;
	end
--]]

	UIDropDownMenu_Initialize(dropdown, Cauldron.InvSlotDropDown_Initialize);
	UIDropDownMenu_SetText(CauldronFiltersInvSlotDropDown, L["Slots"]);

	self:debug("InvSlotDropDown_OnLoad exit");
end

function Cauldron:CategoryDropDown_OnLoad(dropdown)
	self:debug("CategoryDropDown_OnLoad enter");
	
--[[	
	if CURRENT_TRADESKILL == "" or CURRENT_TRADESKILL == "UNKNOWN" then
		return;
	end
--]]

	UIDropDownMenu_Initialize(dropdown, Cauldron.CategoryDropDown_Initialize);
	UIDropDownMenu_SetText(CauldronFiltersCategoryDropDown, L["Categories"]);

	self:debug("CategoryDropDown_OnLoad exit");
end

function Cauldron:FilterDropDown_Initialize(level)
	Cauldron:debug("FilterDropDown_Initialize enter");
	
--[[
	if CURRENT_TRADESKILL == "" or CURRENT_TRADESKILL == "UNKNOWN" then
		return;
	end
--]]

	if not Cauldron.db then
		return;
	end

	UIDropDownMenu_SetText(CauldronFiltersFilterDropDown, L["Filters"]);

	-- sorting
	
	local sortingTitle = {
		text = L["Sort"],
		isTitle = true,
		tooltipTitle = "",
		tooltipText = "",
	};
	UIDropDownMenu_AddButton(sortingTitle);

	local sortAlpha = {
		text = L["Alphabetically"],
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortAlpha,
		tooltipTitle = L["Alphabetically"],
		tooltipText = L["Set the sorting method to use on the skills list"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetSort(arg1) end,
		arg1 = "alpha",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(sortAlpha);

	local sortDifficulty = {
		text = L["By difficulty"],
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortDifficulty,
		tooltipTitle = L["By difficulty"],
		tooltipText = L["Set the sorting method to use on the skills list"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetSort(arg1) end,
		arg1 = "difficulty",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(sortDifficulty);

	--[[
	local sortBenefit = {
		text = L["By benefit"],
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortBenefit,
		tooltipTitle = L["By benefit"],
		tooltipText = L["Set the sorting method to use on the skills list"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetSort(arg1) end,
		arg1 = "benefit",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(sortBenefit);
	--]]
	
	-- spacer	
	UIDropDownMenu_AddButton({
		text = "",
		notClickable = true,
	});
	
	-- skill difficulty

	local difficultyTitle = {
		text = L["Difficulty"],
		isTitle = true,
		tooltipTitle = "",
		tooltipText = "",
	};
	UIDropDownMenu_AddButton(difficultyTitle);

	local difficultyOptimal = {
		text = L["Optimal"],
--		textR = 1.0,
--		textG = 1.0,
--		textB = 1.0,
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.optimal,
--		keepShownOnClick = true,
		tooltipTitle = L["Optimal"],
		tooltipText = L["Set whether items of this difficulty level should be shown"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_ToggleDifficulty(arg1) end,
		arg1 = "optimal",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(difficultyOptimal);

	local difficultyMedium = {
		text = L["Medium"],
--		textR = 1.0,
--		textG = 1.0,
--		textB = 1.0,
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.medium,
--		keepShownOnClick = true,
		tooltipTitle = L["Medium"],
		tooltipText = L["Set whether items of this difficulty level should be shown"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_ToggleDifficulty(arg1) end,
		arg1 = "medium",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(difficultyMedium);
	
	local difficultyEasy = {
		text = L["Easy"],
--		textR = 1.0,
--		textG = 1.0,
--		textB = 1.0,
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.easy,
--		keepShownOnClick = true,
		tooltipTitle = L["Easy"],
		tooltipText = L["Set whether items of this difficulty level should be shown"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_ToggleDifficulty(arg1) end,
		arg1 = "easy",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(difficultyEasy);
	
	local difficultyTrivial = {
		text = L["Trivial"],
--		textR = 1.0,
--		textG = 1.0,
--		textB = 1.0,
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.trivial,
--		keepShownOnClick = true,
		tooltipTitle = L["Trivial"],
		tooltipText = L["Set whether items of this difficulty level should be shown"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_ToggleDifficulty(arg1) end,
		arg1 = "trivial",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(difficultyTrivial);

	-- spacer	
	UIDropDownMenu_AddButton({
		text = "",
		notClickable = true,
	});
	
	-- reagents availability
	
	local reagentsTitle = {
		text = L["Reagents"],
		isTitle = true,
		tooltipTitle = "",
		tooltipText = "",
	};
	UIDropDownMenu_AddButton(reagentsTitle);

	local normal = {
		text = L["Normal"],
		checked = Cauldron:ReagentsFilterNormalCheck(),
		tooltipTitle = L["Reagents"],
		tooltipText = L["Display the normal list of skills"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetReagentFilter(arg1) end,
		arg1 = "normal",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(normal);
	
	local haveAllReagents = {
		text = L["Have all"],
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAllReagents,
		tooltipTitle = L["Reagents"],
		tooltipText = L["Set whether skills for which you have all the required reagents are shown in the list"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetReagentFilter(arg1) end,
		arg1 = "all",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(haveAllReagents);
	
	local haveKeyReagents = {
		text = L["Have key"],
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveKeyReagents,
		tooltipTitle = L["Reagents"],
		tooltipText = L["Set whether skills for which you have all key reagents (non-vendor available) are shown in the list"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetReagentFilter(arg1) end,
		arg1 = "key",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(haveKeyReagents);
	
	local haveAnyReagents = {
		text = L["Have any"],
		checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAnyReagents,
		tooltipTitle = L["Reagents"],
		tooltipText = L["Set whether skills for which you have any reagents are shown in the list"],
		func = function(arg1, arg2) Cauldron:FilterDropDown_SetReagentFilter(arg1) end,
		arg1 = "any",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(haveAnyReagents);
	
	Cauldron:debug("FilterDropDown_Initialize exit");
end

function Cauldron:FilterDropDown_SetSort(info)
	self:debug("FilterDropDown_SetSort enter");
	
	local sort = info.arg1;
	
	if sort == "alpha" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortAlpha = true;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortDifficulty = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortBenefit = false;
	elseif sort == "difficulty" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortAlpha = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortDifficulty = true;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortBenefit = false;
	elseif sort == "benefit" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortAlpha = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortDifficulty = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.sortBenefit = true;
	end

	-- update the UI
	Cauldron:UpdateSkillList();

	self:debug("FilterDropDown_SetSort exit");
end

function Cauldron:ReagentsFilterNormalCheck()
	self:debug("ReagentsFilterNormalCheck enter");
	
	local checked = true;
	
	if Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAllReagents or
	   Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveKeyReagents or
	   Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAnyReagents then
	   	checked = false;
	end
	
	self:debug("ReagentsFilterNormalCheck exit");
	
	return checked;
end

function Cauldron:FilterDropDown_SetReagentFilter(info)
	self:debug("FilterDropDown_SetReagentFilter enter");
	
	local reagents = info.arg1;
	
	if reagents == "normal" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAllReagents = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveKeyReagents = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAnyReagents = false;
	elseif reagents == "all" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAllReagents = true;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveKeyReagents = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAnyReagents = false;
	elseif reagents == "key" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAllReagents = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveKeyReagents = true;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAnyReagents = false;
	elseif reagents == "any" then
		Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAllReagents = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveKeyReagents = false;
	   	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter.haveAnyReagents = true;
	end

	-- update the UI
	Cauldron:UpdateSkillList();

	self:debug("FilterDropDown_SetReagentFilter exit");
end

function Cauldron:FilterDropDown_ToggleDifficulty(info)
	self:debug("FilterDropDown_ToggleDifficulty enter");
	
	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter[info.arg1] = not Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.filter[info.arg1];
	
	-- update the UI
	Cauldron:UpdateSkillList();

	self:debug("FilterDropDown_ToggleDifficulty exit");
end

function Cauldron:InvSlotDropDown_Initialize(level)
	Cauldron:debug("InvSlotDropDown_Initialize enter");

--[[
	if CURRENT_TRADESKILL == "" or CURRENT_TRADESKILL == "UNKNOWN" then
		return;
	end
--]]

	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	UIDropDownMenu_SetText(CauldronFiltersInvSlotDropDown, L["Slots"]);
	
	local all = {
		text = L["All slots"],
		checked = false,
		tooltipTitle = L["All slots"],
		func = function(arg1, arg2) Cauldron:InvSlotDropDown_SetSlot(arg1) end,
		arg1 = "all",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(all);
	
	local slots = Cauldron:GetSlots(Cauldron.vars.playername, skillName);
	
	for name, _ in pairs(slots) do
		local slot = {
			text = _G[name],
			checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[name],
			tooltipTitle = _G[name],
			func = function(arg1, arg2) Cauldron:InvSlotDropDown_SetSlot(arg1) end,
			arg1 = name,
			arg2 = "",
		};
		UIDropDownMenu_AddButton(slot);
	end

	Cauldron:debug("InvSlotDropDown_Initialize exit");
end

function Cauldron:SlotsFilterAllCheck()
	self:debug("SlotsFilterAllCheck enter");
	
	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	local checked = true;

	if Cauldron.db then	
		for name, _ in pairs(Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots) do
			if Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[name] then
				checked = false;
				break;
			end
		end
	end

	self:debug("SlotsFilterAllCheck exit");
	
	return checked;
end

function Cauldron:InvSlotDropDown_SetSlot(info)
	self:debug("InvSlotDropDown_SetSlot enter");
	
	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end
	
	self:debug("InvSlotDropDown_SetSlot: info.arg1="..info.arg1);

	if info.arg1 == "all" then
		self:debug("InvSlotDropDown_SetSlot: selecting all slots...");
		for name, _ in pairs(Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots) do
			self:debug("InvSlotDropDown_SetSlot: name="..name);
			Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[name] = true;
		end
	else
		self:debug("InvSlotDropDown_SetSlot: select a specific slot: "..info.arg1);
		if not Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[info.arg1] then
			Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[info.arg1] = true;
		else
			Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[info.arg1] = not Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.slots[info.arg1];
		end
	end

	self:debug("InvSlotDropDown_SetSlot exit");
end

function Cauldron:CategoryDropDown_Initialize(level)
	Cauldron:debug("CategoryDropDown_Initialize enter");

--[[
	if CURRENT_TRADESKILL == "" or CURRENT_TRADESKILL == "UNKNOWN" then
		return;
	end
--]]

	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	UIDropDownMenu_SetText(CauldronFiltersCategoryDropDown, L["Categories"]);

	local all = {
		text = L["All categories"],
		checked = false, -- Cauldron:CategoriesFilterAllCheck(),
		tooltipTitle = L["All categories"],
		func = function(arg1, arg2) Cauldron:CategoryDropDown_SetCategory(arg1) end,
		arg1 = "all",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(all);

	local none = {
		text = L["No categories"],
		checked = false, -- Cauldron:CategoriesFilterAllCheck(),
		tooltipTitle = L["No categories"],
		func = function(arg1, arg2) Cauldron:CategoryDropDown_SetCategory(arg1) end,
		arg1 = "none",
		arg2 = "",
	};
	UIDropDownMenu_AddButton(none);
	
	local categories = Cauldron:GetDefaultCategories(Cauldron.vars.playername, skillName);
	
	for i, name in ipairs(categories) do
		local category = {
			text = name,
			checked = Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories[name].shown,
			tooltipTitle = name,
			func = function(arg1, arg2) Cauldron:CategoryDropDown_SetCategory(arg1) end,
			arg1 = name,
			arg2 = "",
		};
		UIDropDownMenu_AddButton(category);
	end

	Cauldron:debug("CategoryDropDown_Initialize exit");
end

--[[
function Cauldron:CategoriesFilterAllCheck()
	self:debug("CategoriesFilterAllCheck enter");
	
	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	local checked = true;
	
	for name, _ in pairs(Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories) do
		if Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories[name] then
			checked = false;
			break;
		end
	end

	self:debug("CategoriesFilterAllCheck exit");
	
	return checked;
end
--]]

function Cauldron:CategoryDropDown_SetCategory(info)
	self:debug("CategoryDropDown_SetCategory enter");
	
	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	if info.arg1 == "all" or info.arg1 == "none" then
		for name, _ in pairs(Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories) do
			local checked = (info.arg1 == "all");
			Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories[name].shown = checked;
		end
	else
		if IsShiftKeyDown() then
			-- uncheck everything
			for name, _ in pairs(Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories) do
				Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.categories[name].shown = false;
			end

			-- check the clicked item
			Cauldron.db.realm.userdata[self.vars.playername].skills[skillName].window.categories[info.arg1].shown = true;
		else
			Cauldron.db.realm.userdata[self.vars.playername].skills[skillName].window.categories[info.arg1].shown = not Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[CURRENT_TRADESKILL].window.categories[info.arg1].shown;
		end
	end

	-- update the UI
	Cauldron:UpdateSkillList();

	self:debug("CategoryDropDown_SetCategory exit");
end

function Cauldron:CollapseAllButton_OnClick(button)
	self:debug("CollapseAllButton_OnClick enter");
	
	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	-- reset all the expanded fields to false
	for name, info in pairs(Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.skills[skillName]) do
		info.expanded = false;
	end

	-- update the UI
	Cauldron:UpdateSkillList();
	
	self:debug("CollapseAllButton_OnClick exit");
end

function Cauldron:CollapseItemButton_OnClick(button)
	self:debug("CollapseItemButton_OnClick enter");

	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	local skillInfo = button.skillInfo;

	Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.skills[skillName][skillInfo.name].expanded = not Cauldron.db.realm.userdata[Cauldron.vars.playername].skills[skillName].window.skills[skillName][skillInfo.name].expanded
	
	-- update the UI
	Cauldron:UpdateSkillList();
	
	self:debug("CollapseItemButton_OnClick exit");
end

function Cauldron:SkillItem_OnEnter(frame)
	self:debug("SkillItem_OnEnter enter");

	local id = frame:GetID();
	self:debug("SkillItem_OnEnter: id="..id);
	
	local name = _G["CauldronSkillItem"..id.."SkillName"];
	if name then
--		name:
	end
	
	-- TODO

	self:debug("SkillItem_OnEnter exit");
end

function Cauldron:SkillItem_OnLeave(frame)
	self:debug("SkillItem_OnLeave enter");



	self:debug("SkillItem_OnLeave exit");
end

function Cauldron:SkillItem_OnClick(frame, button, down)
	self:debug("SkillItem_OnClick enter");

	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end
	self:debug("SkillItem_OnClick: skillName="..skillName);

	-- select this frame
	Cauldron.db.realm.userdata[self.vars.playername].skills[skillName].window.selected = frame.skillIndex;
	
	-- update the UI
	Cauldron:UpdateSkillList();
	Cauldron:UpdateButtons();
	
	self:debug("SkillItem_OnClick exit");
end

function Cauldron:TradeSkillFilter_OnTextChanged(frame)
	self:debug("TradeSkillFilter_OnTextChanged enter");
	
	-- update the UI
	Cauldron:UpdateSkillList();

	self:debug("TradeSkillFilter_OnTextChanged exit");
end

function Cauldron:AmountDecrement_OnClick()
	self:debug("AmountDecrement_OnClick enter");
	
	local num = CauldronAmountInputBox:GetNumber();
	num = math.max(1, num - 1);
	CauldronAmountInputBox:SetNumber(num);

	self:debug("AmountDecrement_OnClick exit");
end

function Cauldron:AmountIncrement_OnClick()
	self:debug("AmountIncrement_OnClick enter");
	
	local num = CauldronAmountInputBox:GetNumber();
	num = math.min(999, num + 1);
	CauldronAmountInputBox:SetNumber(num);

	self:debug("AmountIncrement_OnClick exit");
end
