local ADDON_NAME = ...;
---@type MailDistributionHelper
local MDH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Compatibility';
---@class Compatibility
---@diagnostic disable-next-line: undefined-field
local Module = MDH:NewModule(moduleName);

function MDH.Compatibility.Baganator()
  MDH.Compatibility:FuncOrWaitFrame({ "Baganator", "Dejunk" }, function()
    Baganator.API.RegisterJunkPlugin("Dejunk + Personal", "dejunkcustom", function(bagID, slotID, _, _)
      return DejunkApi:IsJunk(bagID, slotID) or MDH.UTILS:IsItemConjured(C_Container.GetContainerItemLink(bagID, slotID));
    end)
  end);
end
