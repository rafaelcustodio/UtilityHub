local moduleName = 'AutoBuy';
---@class AutoBuy
---@diagnostic disable-next-line: undefined-field
local Module = UtilityHub:NewModule(moduleName);

---@type boolean
Module.eventRegistered = false;

function Module:SearchAndBuyRares()
  local autoBuyList = UtilityHub.db.global.options.autoBuyList or {};

  for i = 1, GetMerchantNumItems() do
    local itemID = GetMerchantItemID(i);
    local searchResult = UtilityHub.UTILS:ValueInTable(autoBuyList, function(value)
      return itemID == tonumber(string.match(value, "item:(%d+):"));
    end);

    if (searchResult) then
      local _, _, price, stackCount = GetMerchantItemInfo(i);
      local unitPrice = price / stackCount;
      local canAfford = (GetMoney() - unitPrice) > 0;
      local priceTooHigh = unitPrice >= MERCHANT_HIGH_PRICE_COST;

      if (not canAfford) then
        UtilityHub.Helpers:ShowNotification("Doesn't have enough money for " .. searchResult);
      elseif (not priceTooHigh) then
        UtilityHub.Helpers:ShowNotification("The price of " ..
          searchResult .. " is too high (would give a high price popup warn)");
      end

      if (canAfford and not priceTooHigh) then
        BuyMerchantItem(i, 1);
        UtilityHub.Helpers:ShowNotification("Bought: " .. searchResult);
      end
    end
  end
end

function Module:OnEnable()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
    if (not UtilityHub:GetModule("AutoBuy"):IsEnabled()) then
      return;
    end

    Module:SearchAndBuyRares();
  end);
end
