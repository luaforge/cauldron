-- $Revision: 1.1 $
-- Cauldron main file

Cauldron = LibStub("AceAddon-3.0"):NewAddon("Cauldron", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceHook-3.0", "LibDebugLog-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cauldron")

Cauldron.version = "0.1." .. string.sub("$Revision: 1.1 $", 12, -3);
Cauldron.date = string.sub("$Date: 2009-01-15 18:09:33 $", 8, 17);

-- key binding names
BINDING_HEADER_CAULDRON = "Cauldron";
BINDING_NAME_TOGGLE_CAULDRONSHOPPINGLIST = "Toggle Shopping List Window";
-- BINDING_NAME_TOGGLE_CAULDRONCONFIG = "Toggle Config Window";

Cauldron.options = {};
Cauldron.options.buttons = {};

Cauldron.vars = {};

Cauldron.libs = {};
Cauldron.libs.Abacus = LibStub("LibAbacus-3.0");

Cauldron:ToggleDebugLog(false);

CURRENT_TRADESKILL = "";

function Cauldron:OnInitialize()
	local dbDefaults = {
		profile = {
		},		
		realm = {
			userdata = {}, -- Stores all known characters
		},
		global = {
			difficulty = {}, -- Stores at what level difficulty is changed for all recipes.
		}
	}

	self.db = LibStub("AceDB-3.0"):New("CauldronDB", dbDefaults)

	-- set up slash command options
	local options = {
		desc = L["Cauldron"],
		handler = Cauldron,
		type = 'group',
		args = {
			shoppinglist = {
				name = L["Shopping list"],
				desc = L["Open shopping list window"],
				type = 'toggle',
			},
--			debug = LibStub('LibLogDebug-1.0'):GetAce3OptionTable(self, 110),
		},
	}

	-- register slash command with options
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Cauldron", options, {"cauldron"})

	-- let the user know the addon is loaded
	self:Print(L["Cauldron loaded; version "],Cauldron.version);
end

function Cauldron:InitPlayer()
	self:Debug("InitPlayer enter");
	
	if not self.vars.playername then
		self.vars.playername = UnitName("player");
		if not self.db.realm.userdata[self.vars.playername] then
			self.db.realm.userdata[self.vars.playername] = {};
		end
--		if not self.db.realm.userdata[self.vars.playername].knownRecipes then
--			self.db.realm.userdata[self.vars.playername].knownRecipes = {};
--		end
		if not self.db.realm.userdata[self.vars.playername].skills then
			self.db.realm.userdata[self.vars.playername].skills = {};
		end
		if not self.db.realm.userdata[self.vars.playername].queue then
			self.db.realm.userdata[self.vars.playername].queue = CauldronQueue:NewQueue();
		end
		if not self.db.realm.shopping then
			self.db.realm.shopping = CauldronShopping:NewList();
		end
	end
	
	self:Debug("InitPlayer exit");
end

function Cauldron:OnEnable()
	self:Debug("OnEnable enter");

	self:InitPlayer();
	self:RegisterEvent("TRADE_SKILL_SHOW", "OnTradeShow");
	self:RegisterEvent("TRADE_SKILL_UPDATE", "OnTradeUpdate");
	self:RegisterEvent("TRADE_SKILL_CLOSE", "OnTradeClose");
	self:RegisterEvent("SKILL_LINES_CHANGED", "OnSkillUpdate");
	self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded");
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE", "OnEvent");
	self:RegisterEvent("UPDATE_TRADESKILL_RECAST", "OnTradeSkillRecast");
--	self:RegisterEvent("BANKFRAME_OPENED");
--	self:RegisterEvent("BANKFRAME_CLOSED");
--	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
--	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED");
--	self:RegisterEvent("MERCHANT_SHOW");
--	self:RegisterEvent("MERCHANT_UPDATE");
--	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("BAG_UPDATE", "OnBagUpdate");
--	self:RegisterEvent("TRAINER_CLOSED");
--	self:RegisterEvent("PLAYER_REGEN_DISABLED");
--	self:RegisterEvent("PLAYER_REGEN_ENABLED");
--	self:RegisterEvent("AUCTION_HOUSE_CLOSED");
--	self:RegisterEvent("AUCTION_HOUSE_SHOW");
	self:RegisterEvent("CRAFT_SHOW", "OnCraftShow");
	self:RegisterEvent("CRAFT_CLOSE", "OnCraftClose");
--	self:RegisterEvent("PLAYER_LOGOUT");
	self:RegisterEvent("UI_ERROR_MESSAGE", "OnError");
	self:HookTooltips();

	self:Debug("OnEnable exit");
end

function Cauldron:OnDisable()
	self:Debug("OnDisable enter");
	
	self:Debug("OnDisable exit");
end

function Cauldron:OnAddonLoaded(event, addon)
	self:Debug("OnAddonLoaded enter");
	
	-- show the shopping list?
	if self.db.profile.showShoppingList then
		Cauldron:ShowShoppingList();
	else
		if CauldronShopping:ContainsItems(self.db.realm.shopping) then
			Cauldron:ShowShoppingList();
		end
	end
	
	self:Debug("OnAddonLoaded exit");
end

function Cauldron:OnEvent(event, ...)
	self:Debug("OnEvent enter");
	
	if ( event == "UNIT_PORTRAIT_UPDATE" ) then
		local arg1 = ...;
		if ( arg1 == "player" ) then
			SetPortraitTexture(CauldronFramePortrait, "player");
		end
	end

	self:Debug("OnEvent exit");
end

function Cauldron:OnTradeShow()
	self:Debug("OnTradeShow enter");

	-- update our known skills	
	self:Debug("OnTradeShow: update known skills");
	self:UpdateSkills();

	-- show the UI frame
	self:Debug("OnTradeShow: show the UI");
	self:Frame_Show();
	
	self:Debug("OnTradeShow exit");
end

function Cauldron:OnTradeUpdate()
	self:Debug("OnTradeUpdate enter");

--	TODO	
	
	self:Debug("OnTradeUpdate exit");
end

function Cauldron:OnTradeClose()
	self:Debug("OnTradeClose enter");
	
	self:Frame_Hide();
	
	self:Debug("OnTradeClose exit");
end

function Cauldron:OnSkillUpdate()
	self:Debug("OnSkillUpdate enter");

	self:UpdateSkills();
--	self:UpdateSpecializations();

--	if not IsTradeSkillLinked() then
--		if (GetTradeSkillLine() ~= "UNKNOWN") then
--			self:ScheduleTimer(self.UpdateKnownRecipes, 1, self);
--		end
--	end

	self:Debug("OnSkillUpdate exit");
end

function Cauldron:OnTradeSkillRecast()
	self:Debug("OnTradeSkillRecast enter");

	self:UpdateSkills();
	
	self:Frame_Update();
	
	self:Debug("OnTradeSkillRecast exit");
end

function Cauldron:OnBagUpdate()
	self:Debug("OnBagUpdate enter");
	
	if not CauldronFrame:IsShown() then
		return;
	end

	if self.makingItem then
		local count = GetItemCount(self.makingItem);
		if count ~= self.itemCurrentCount then
			local delta = self.itemCurrentCount - count;
			CauldronQueue:AdjustItemCount(Cauldron:GetQueue(), self.makingItem, delta);
		end
	else
		--
	end
	
	Cauldron:UpdateSkills();
	
	self:Frame_Update();
	
	self:Debug("OnBagUpdate exit");
end

function Cauldron:OnCraftShow()
	self:Debug("OnCraftShow enter");

--	TODO	
	
	self:Debug("OnCraftShow exit");
end

function Cauldron:OnCraftClose()
	self:Debug("OnCraftClose enter");

--	TODO	
	
	self:Debug("OnCraftClose exit");
end

function Cauldron:OnError()
	self:Debug("OnError enter");

--	TODO	
	
	self:Debug("OnError exit");
end

function Cauldron:TradeSkillFrame_SetSelection(id)
	self:Debug("TradeSkillFrame_SetSelection enter");

	-- TODO

	self:Debug("TradeSkillFrame_SetSelection exit");
end

function Cauldron:GetSelectedSkill()
	self:Debug("GetSelectedSkill enter");

	local skillName = CURRENT_TRADESKILL;
	if IsTradeSkillLinked() then
		skillName = "Linked-"..skillName;
	end

	local selected = self.db.realm.userdata[self.vars.playername].skills[skillName].window.selected;

	for name, info in pairs(self.db.realm.userdata[self.vars.playername].skills[skillName].recipes) do
		if selected == info.index then
			return info;
		end
	end

	self:Debug("GetSelectedSkill exit");
	
	return nil;
end

function Cauldron:QueueAllTradeSkillItem()
	self:Debug("QueueAllTradeSkillItem enter");
	
	local skillInfo = Cauldron:GetSelectedSkill();
	
	if skillInfo then
		local amount = skillInfo.available;
		if amount > 0 then
			CauldronQueue:AddItem(self.db.realm.userdata[self.vars.playername].queue, skillInfo, amount);
			
			Cauldron:UpdateQueue();
		else
			-- TODO: notify player?
		end
	end

	self:Debug("QueueAllTradeSkillItem exit");
end

function Cauldron:QueueTradeSkillItem()
	self:Debug("QueueTradeSkillItem enter");

	local skillInfo = Cauldron:GetSelectedSkill();
	
	if skillInfo then
		local amount = CauldronAmountInputBox:GetNumber();
		if not amount or amount < 1 then
			amount = 1;
		end
		CauldronQueue:AddItem(self.db.realm.userdata[self.vars.playername].queue, skillInfo, amount);
	end

	self:Debug("QueueTradeSkillItem exit");
end

function Cauldron:CreateAllTradeSkillItem()
	self:Debug("CreateAllTradeSkillItem enter");

	if ( (not PartialPlayTime()) and (not NoPlayTime()) ) then
		CauldronAmountInputBox:ClearFocus();

		local skillInfo = Cauldron:GetSelectedSkill();

		CauldronAmountInputBox:SetNumber(skillInfo.available);

		DoTradeSkill(skillInfo.index, skillInfo.available);
	end

	self:Debug("CreateAllTradeSkillItem exit");
end

function Cauldron:CreateTradeSkillItem()
	self:Debug("CreateTradeSkillItem enter");

	if ( (not PartialPlayTime()) and (not NoPlayTime()) ) then
		CauldronAmountInputBox:ClearFocus();
		
		local skillInfo = Cauldron:GetSelectedSkill();
		local amount = CauldronAmountInputBox:GetNumber();
		
		DoTradeSkill(skillInfo.index, amount);
	end

	self:Debug("CreateTradeSkillItem exit");
end

function Cauldron:ProcessQueue()
	self:Debug("ProcessQueue enter");

	if IsTradeSkillLinked() then
		-- TODO: display error/warning
		return;
	end

	-- find intermediate items that need to be crafted
	local intQueue = CauldronQueue:GetIntermediates(self.db.realm.userdata[self.vars.playername].queue);
	self:Debug("ProcessQueue: intQueue="..#intQueue);
	
	local queueInfo = nil;
	local skillInfo = nil;
	
	if #intQueue > 0 then
		self:Debug("ProcessQueue: processing intermediate queue items");
		
	 	queueInfo = intQueue[1];
		self:Debug("ProcessQueue: queueInfo="..queueInfo.name);
		skillInfo = Cauldron:GetSkillInfo(queueInfo.tradeskill, queueInfo.name);
		self:Debug("ProcessQueue: skillInfo="..tostring(skillInfo));
	else
		local queue = CauldronQueue:GetItems(self.db.realm.userdata[self.vars.playername].queue);
		self:Debug("ProcessQueue: queue="..#queue);
		
		if #queue > 0 then
			self:Debug("ProcessQueue: processing main queue items");
		
			queueInfo = queue[1];
			self:Debug("ProcessQueue: queueInfo="..queueInfo.name);
			skillInfo = Cauldron:GetSkillInfo(queueInfo.tradeskill, queueInfo.name);
			self:Debug("ProcessQueue: skillInfo="..tostring(skillInfo));
		end
	end
	
	if queueInfo and skillInfo then
		self:Debug("ProcessQueue: queueInfo="..queueInfo.name);
		
		if queueInfo.tradeskill ~= CURRENT_TRADESKILL then
			local msg = string.format(L["Crafting %1$s requires the %2$s skill."], queueInfo.name, queueInfo.tradeskill);
			UIErrorsFrame:AddMessage(msg, 1.0, 0.0, 0.0);
			return;
		end
		
		self:Debug("ProcessQueue: process item: "..queueInfo.name);
		Cauldron:ProcessItem(skillInfo, queueInfo.amount);
	else
		if not queueInfo then
			self:Print("Missing queue info!");
		end
		if not skillInfo then
			self:Print("Missing skill info!");
		end
	end

	self:Debug("ProcessQueue exit");
end


function Cauldron:ProcessItem(skillInfo, amount)
	self:Debug("ProcessItem enter");
	
	if (not skillInfo) or (amount < 1) then
		self:Print("Missing skill info!");
		return;
	end
	
	if ((not PartialPlayTime()) and (not NoPlayTime())) then
		-- record the item we're making
		self.makingItem, _ = GetItemInfo(skillInfo.link);
		self.itemCurrentCount = GetItemCount(skillInfo.link);
		
		-- tell the user what we're doing
		self:Print(string.format(L["Crafting %s, quantity: %d..."], self.makingItem, amount));
		
		-- do it
		DoTradeSkill(skillInfo.index, amount);
	else
		-- TODO: notify player?
	end
	
	self:Debug("ProcessItem exit");
end

function Cauldron:RemoveQueueItem(name)
	CauldronQueue:RemoveItem(Cauldron:GetQueue(), name);
end

function Cauldron:IncreaseItemPriority(name, top)
	CauldronQueue:IncreasePriority(Cauldron:GetQueue(), name, top);
end

function Cauldron:DecreaseItemPriority(name, bottom)
	CauldronQueue:DecreasePriority(Cauldron:GetQueue(), name, bottom);
end

function Cauldron:DecreaseItemCount(name)
	CauldronQueue:AdjustItemCount(Cauldron:GetQueue(), name, -1);
end

function Cauldron:GetQueue(player)
	self:Debug("GetQueue enter");

	if not player then
		player = self.vars.playername;
	end
	
	local queue = self.db.realm.userdata[player].queue;
	if not queue then
		queue = CauldronQueue:NewQueue();
		self.db.realm.userdata[player].queue = queue;
	end
	
	self:Debug("GetQueue enter");

	return queue;
end

function Cauldron:AddItemToShoppingList(itemName, amount)
	CauldronShopping:AddToList(self.db.realm.shopping, self.vars.playername, itemName, amount);
	Cauldron:ShowShoppingList();
end

function Cauldron:RemoveShoppingListItem(requestor, itemName)
	CauldronShopping:RemoveFromList(self.db.realm.shopping, requestor, itemName, nil);
	
--	if not CauldronShopping:ContainsItems(self.db.realm.shopping) then
--		Cauldron:HideShoppingList();
--	end
end

function Cauldron:LocaleString(str)
	return L[str];
end

function Cauldron:SaveShoppingListFramePosition()
	if CauldronShoppingListFrame then
		local s = CauldronShoppingListFrame:GetEffectiveScale();
		self.db.profile.ShoppingListPositionX = CauldronShoppingListFrame:GetLeft();
		self.db.profile.ShoppingListPositionY = CauldronShoppingListFrame:GetTop();
		self.db.profile.ShoppingListWidth = CauldronShoppingListFrame:GetWidth();
		self.db.profile.ShoppingListHeight = CauldronShoppingListFrame:GetHeight();
	end
end

----------------------------------------------------------------
--  Tooltip Functions
----------------------------------------------------------------

function Cauldron:HookTooltips()
	self:Debug("HookTooltips enter");

--	self:SecureHook(GameTooltip, "SetBagItem");
--	self:SecureHook(GameTooltip, "SetInventoryItem");
--	self:SecureHook(GameTooltip, "SetLootItem");
--	self:SecureHook(GameTooltip, "SetHyperlink");
--	self:SecureHook(GameTooltip, "SetTradeSkillItem");
--	self:SecureHook(GameTooltip, "SetMerchantItem");
--	self:SecureHook(GameTooltip, "SetAuctionItem");
--	self:SecureHook(GameTooltip, "SetTrainerService");
--	self:SecureHook(GameTooltip, "SetGuildBankItem");
--	self:SecureHook("SetItemRef");

	self:Debug("HookTooltips exit");
end

----------------------------------------------------------------------
-- Property functions
----------------------------------------------------------------------

--[[ Databroker Stuff --]]

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if ldb then 
	ldb:NewDataObject("Cauldron", {
		type = "launcher",
		text = "Cauldron",
		icon = "Interface\\Icons\\INV_Elemental_Mote_Nether",
		OnClick = function(frame, button)
			if button == "LeftButton" then
				Cauldron:UI_Toggle()
			elseif button == "RightButton" then
				Cauldron:Config_Toggle()
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("Cauldron " .. Cauldron.version)
		end,
	})
end


