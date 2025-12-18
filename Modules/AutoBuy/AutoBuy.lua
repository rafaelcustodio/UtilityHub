local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'AutoBuy';
---@class AutoBuy
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

Module.eventRegistered = false;

function Module:SearchAndBuyRares()
  local autoBuyList = UH.db.global.options.autoBuyList or {};

  for i = 1, GetMerchantNumItems() do
    local itemLink = GetMerchantItemLink(i);

    if (itemLink) then
      local itemID = tonumber(string.match(itemLink, "item:(%d+):"));
      local searchResult = UH.UTILS:ValueInTable(autoBuyList, function(value)
        return itemID == tonumber(string.match(value, "item:(%d+):"));
      end);

      if (searchResult) then
        BuyMerchantItem(i, 1);
        UH.Helpers:ShowNotification("Bought: " .. itemLink);
      end
    end
  end
end

function Module:OnEnable()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
    if (not UH:GetModule("AutoBuy"):IsEnabled()) then
      return;
    end

    Module:SearchAndBuyRares();
  end);
end