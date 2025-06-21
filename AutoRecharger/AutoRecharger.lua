AR = { name = "AutoRecharger" }

AR.defaults = {
	debugMessages = true,
	autoRecharge = true,
	rechargePercentage = 10,
	autoRepair = true,
	autoMerchant = true,
	repairPercentage = 25,
}

local function attemptCharge(weapon, gem)
	if IsItemChargeable(BAG_WORN, weapon) then
		local charges, maxCharges = GetChargeInfoForItem(BAG_WORN, weapon)
		if (charges/maxCharges) < (AR.savedVariables.rechargePercentage/100) then
			ChargeItemWithSoulGem(BAG_WORN, weapon, BAG_BACKPACK, gem)
			if AR.savedVariables.debugMessages then d("Item charged: "..GetItemName(BAG_WORN, weapon)) end
		end
	end
end

local function attemptRepair(armor, kit)
	if DoesItemHaveDurability(BAG_WORN, armor) then
		local condition = GetItemCondition(BAG_WORN, armor)
		if condition < AR.savedVariables.repairPercentage then
			RepairItemWithRepairKit(BAG_WORN, armor, BAG_BACKPACK, kit)
			if AR.savedVariables.debugMessages then d("Item repaired: "..GetItemName(BAG_WORN, armor)) end
		end
	end
end

function AR.ChangePlayerCombatState(event, inCombat)
	
	local backpack = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK) 
	
	
	if AR.savedVariables.autoRecharge then
		local soulGemIndex = -1
		for k, v in pairs(backpack) do
			if IsItemSoulGem(SOUL_GEM_TYPE_FILLED, BAG_BACKPACK, v.slotIndex) then
				soulGemIndex = v.slotIndex
				break
			end
		end
		
		if soulGemIndex == -1 then
			if AR.savedVariables.debugMessages then d("Player does not have any filled soul gems to recharge weapons!") end
		else
			attemptCharge(EQUIP_SLOT_MAIN_HAND, soulGemIndex)
			attemptCharge(EQUIP_SLOT_OFF_HAND, soulGemIndex)
			attemptCharge(EQUIP_SLOT_BACKUP_MAIN, soulGemIndex)
			attemptCharge(EQUIP_SLOT_BACKUP_OFF, soulGemIndex)
		end
	end
	
	if AR.savedVariables.autoRepair then
		local repairKitIndex = -1
		for k, v in pairs(backpack) do
			if  IsItemRepairKit(BAG_BACKPACK, v.slotIndex) and
				IsItemNonCrownRepairKit(BAG_BACKPACK, v.slotIndex) and 
				IsItemNonGroupRepairKit(BAG_BACKPACK, v.slotIndex) then
				
				repairKitIndex = v.slotIndex
				break
			end
		end
		
		if repairKitIndex == -1 then
			if AR.savedVariables.debugMessages then d("Player does not have any repair kits to repair armor!") end
		else
			attemptRepair(EQUIP_SLOT_CHEST, repairKitIndex)
			attemptRepair(EQUIP_SLOT_FEET, repairKitIndex)
			attemptRepair(EQUIP_SLOT_HAND, repairKitIndex)
			attemptRepair(EQUIP_SLOT_HEAD, repairKitIndex)
			attemptRepair(EQUIP_SLOT_LEGS, repairKitIndex)
			attemptRepair(EQUIP_SLOT_SHOULDERS, repairKitIndex)
			attemptRepair(EQUIP_SLOT_WAIST, repairKitIndex)
			attemptRepair(EQUIP_SLOT_BACKUP_OFF, repairKitIndex)
			attemptRepair(EQUIP_SLOT_OFF_HAND, repairKitIndex)
		end
	end
	
end

function AR.merchantRepair(eventCode)
	if AR.savedVariables.autoMerchant and CanStoreRepair() and GetRepairAllCost() > 0 then
		local backpack = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK) 
		local equips = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_WORN)
		
		--TODO: Debug message that tells the player how much they spent.
		
		for k, v in pairs(backpack) do
			if DoesItemHaveDurability(BAG_BACKPACK, v.slotIndex) and GetItemRepairCost(BAG_BACKPACK, v.slotIndex) > 0 then
				RepairItem(BAG_BACKPACK, v.slotIndex)
			end
		end
		
		for k, v in pairs(equips) do
			if DoesItemHaveDurability(BAG_WORN, v.slotIndex) and GetItemRepairCost(BAG_WORN, v.slotIndex) > 0 then
				RepairItem(BAG_WORN, v.slotIndex)
			end
		end
	end
end

function AR.Initialize()
	AR.savedVariables = ZO_SavedVars:NewAccountWide("ARSavedVariables", 1, nil, AR.defaults, GetWorldName())

	--settings
	local settings = LibHarvensAddonSettings:AddAddon("Auto Recharge and Repair")
	local areSettingsDisabled = false
	
	local generalSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "General",}
	local rechargeSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Recharge",}
	local repairSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Repair",}
	
	local resetDefaults = {
        type = LibHarvensAddonSettings.ST_BUTTON,
        label = "Reset Defaults",
        tooltip = "",
        buttonText = "RESET",
        clickHandler = function(control, button)
			AR.savedVariables.debugMessages = AR.defaults.debugMessages
			AR.savedVariables.autoRecharge = AR.defaults.autoRecharge
			AR.savedVariables.autoRepair = AR.defaults.autoRepair
			AR.savedVariables.autoMerchant = AR.defaults.autoMerchant
			AR.savedVariables.rechargePercentage = AR.defaults.rechargePercentage
			AR.savedVariables.repairPercentage = AR.defaults.repairPercentage
		end,
        disable = function() return areSettingsDisabled end,
    }
	
	local toggle_debug = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Toggle Debug Messages", 
        tooltip = "Enabling this will create chat messages notifying you when the addon recharges or repairs on your behalf.",
        default = AR.savedVariables.debugMessages,
        setFunction = function(state) 
            AR.savedVariables.debugMessages = state
        end,
        getFunction = function() 
            return AR.savedVariables.debugMessages
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local toggle_recharge = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Toggle Auto Recharge", 
        tooltip = "Automatically recharge your weapons when you enter/exit combat",
        default = AR.savedVariables.autoRecharge,
        setFunction = function(state) 
            AR.savedVariables.autoRecharge = state
        end,
        getFunction = function() 
            return AR.savedVariables.autoRecharge
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local slider_recharge = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Recharge Percentage",
        tooltip = "Weapons will be recharged when they drop below this percentage of charge.",
        setFunction = function(value)
			AR.savedVariables.rechargePercentage = value
			
			 end,
        getFunction = function()
            return AR.savedVariables.rechargePercentage
        end,
        default = AR.defaults.rechargePercentage,
        min = 1,
        max = 100,
        step = 1,
        unit = "%", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
    }
	
	local toggle_merchant = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Toggle Auto Merchant Repair", 
        tooltip = "Automatically spends gold to repair your gear when you talk to a merchant.",
        default = AR.savedVariables.autoMerchant,
        setFunction = function(state) 
            AR.savedVariables.autoMerchant = state
        end,
        getFunction = function() 
            return AR.savedVariables.autoMerchant
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local toggle_repair = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Toggle Auto Repair", 
        tooltip = "Automatically repairs your armor as you enter/exit combat",
        default = AR.savedVariables.autoRepair,
        setFunction = function(state) 
            AR.savedVariables.autoRepair = state
        end,
        getFunction = function() 
            return AR.savedVariables.autoRepair
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local slider_repair = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Repair Percentage",
        tooltip = "Armor will be repaired when they drop below this percentage of durability",
        setFunction = function(value)
			AR.savedVariables.repairPercentage = value
			
			 end,
        getFunction = function()
            return AR.savedVariables.repairPercentage
        end,
        default = AR.defaults.repairPercentage,
        min = 1,
        max = 100,
        step = 1,
        unit = "%", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
    }
	
	
	settings:AddSettings({generalSection, resetDefaults, toggle_debug})
	settings:AddSettings({rechargeSection, toggle_recharge, slider_recharge})
	settings:AddSettings({repairSection, toggle_merchant, toggle_repair, slider_repair})
	
	
	EVENT_MANAGER:RegisterForEvent(AR.name, EVENT_PLAYER_COMBAT_STATE, AR.ChangePlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(AR.name, EVENT_OPEN_STORE, AR.merchantRepair)
end
	
function AR.OnAddOnLoaded(event, addonName)
	if addonName == AR.name then
		AR.Initialize()
		EVENT_MANAGER:UnregisterForEvent(AR.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(AR.name, EVENT_ADD_ON_LOADED, AR.OnAddOnLoaded)