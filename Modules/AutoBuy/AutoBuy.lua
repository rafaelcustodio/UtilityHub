local moduleName = 'AutoBuy';
---@class AutoBuy
local Module = UtilityHub.Addon:NewModule(moduleName);

---@type boolean
Module.eventRegistered = false;

function Module:SearchAndBuyItems()
  local autoBuyList = UtilityHub.Database.global.options.autoBuyList or {};

  if (#autoBuyList == 0) then
    return;
  end

  local freeBagSlots = UtilityHub.Helpers.Item:GetFreeBagSlots();
  local purchasedItems = {};
  local playerName = UnitName("player");
  local _, playerClass = UnitClass("player");

  -- Iterate through autoBuyList in order
  for _, buyItem in ipairs(autoBuyList) do
    if (type(buyItem) == "table" and buyItem.itemLink) then
      -- Check scope
      local scope = buyItem.scope or UtilityHub.Enums.AutoBuyScope.ACCOUNT;
      local inScope = true;

      if (scope == UtilityHub.Enums.AutoBuyScope.CHARACTER) then
        inScope = (buyItem.scopeValue == playerName);
      elseif (scope == UtilityHub.Enums.AutoBuyScope.CLASS) then
        inScope = (buyItem.scopeValue == playerClass);
      end

      local itemID = inScope and tonumber(string.match(buyItem.itemLink, "item:(%d+):")) or nil;

      if (itemID) then
        -- Search for item in merchant
        for i = 1, GetMerchantNumItems() do
          local merchantItemID = GetMerchantItemID(i);

          if (merchantItemID == itemID) then
          local _, _, price, stackCount = GetMerchantItemInfo(i);
          local unitPrice = price / stackCount;

          -- Determine how many to buy
          local quantityToBuy = 0;

          if (buyItem.quantity == 1) then
            -- Buy once mode: just buy 1
            quantityToBuy = 1;
          else
            -- Restock mode: calculate deficit
            local currentCount = UtilityHub.Helpers.Item:GetItemCount(itemID, true);
            local deficit = buyItem.quantity - currentCount;

            if (deficit > 0) then
              quantityToBuy = deficit;
            end
          end

          -- If we need to buy something
          if (quantityToBuy > 0) then
            local totalCost = unitPrice * quantityToBuy;
            local slotsNeeded = math.ceil(quantityToBuy / stackCount);

            -- Safety checks
            local canAfford = (GetMoney() >= totalCost);
            local priceTooHigh = unitPrice >= MERCHANT_HIGH_PRICE_COST;
            local hasSpace = freeBagSlots >= slotsNeeded;

            local itemName = C_Item.GetItemInfo(buyItem.itemLink) or buyItem.itemLink;

            if (not hasSpace) then
              UtilityHub.Helpers.Notification:ShowNotification(
                string.format("Insufficient bag space for %s", itemName)
              );
            elseif (priceTooHigh) then
              UtilityHub.Helpers.Notification:ShowNotification(
                string.format("Price of %s is too high", itemName)
              );
            elseif (not canAfford) then
              -- Partial buy: buy maximum possible (only for restock mode)
              if (buyItem.quantity > 1) then
                local maxAffordable = math.floor(GetMoney() / unitPrice);
                if (maxAffordable > 0 and maxAffordable < quantityToBuy) then
                  BuyMerchantItem(i, maxAffordable);
                  tinsert(purchasedItems, string.format("%s x%d (partial)", itemName, maxAffordable));
                  freeBagSlots = freeBagSlots - math.ceil(maxAffordable / stackCount);
                else
                  UtilityHub.Helpers.Notification:ShowNotification(
                    string.format("Insufficient gold for %s", itemName)
                  );
                end
              else
                UtilityHub.Helpers.Notification:ShowNotification(
                  string.format("Insufficient gold for %s", itemName)
                );
              end
            else
              -- Buy full quantity
              BuyMerchantItem(i, quantityToBuy);

              if (buyItem.quantity == 1) then
                tinsert(purchasedItems, itemName);
              else
                tinsert(purchasedItems, string.format("%s x%d", itemName, quantityToBuy));
              end

              freeBagSlots = freeBagSlots - slotsNeeded;
            end
          end

          break; -- Item found, next in list
        end
      end
      end
    end
  end

  -- Consolidated notification
  if (#purchasedItems > 0) then
    if (#purchasedItems == 1) then
      UtilityHub.Helpers.Notification:ShowNotification("Bought: " .. purchasedItems[1]);
    else
      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Bought %d items", #purchasedItems)
      );
    end
  end
end

function Module:OnEnable()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
    if (not UtilityHub.Addon:GetModule("AutoBuy"):IsEnabled()) then
      return;
    end

    Module:SearchAndBuyItems();
  end);
end
