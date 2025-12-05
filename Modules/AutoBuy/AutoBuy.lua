local ADDON_NAME = ...;
---@type MailDistributionHelper
local MDH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'AutoBuy';
---@class AutoBuy
---@diagnostic disable-next-line: undefined-field
local Module = MDH:NewModule(moduleName);

function Module:SearchAndBuyRares()
    local rareItems = {
        14468,
        14481,
        16224
    };

    for i = 1, GetMerchantNumItems() do
        local itemLink = GetMerchantItemLink(i);

        if (itemLink) then
            local itemID = tonumber(string.match(itemLink, "item:(%d+):"));

            if (MDH.UTILS:ValueInTable(rareItems, itemID)) then
                BuyMerchantItem(i, 1);
                MDH.Helpers:ShowNotification("Bought: " .. itemLink);
            end
        end
    end
end

function Module:OnInitialize()
    EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
        if (not MDH:GetModule("Trade"):IsEnabled()) then
            ---@diagnostic disable-next-line: undefined-field
            MDH:EnableModule("AutoBuy");
        end

        Module:SearchAndBuyRares();
    end);
end
