local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);

function UH.Integration.Baganator()
  UH.Integration:FuncOrWaitFrame({ "Baganator", "Dejunk" }, function()
    Baganator.API.RegisterJunkPlugin("Dejunk + Personal", "dejunkcustom", function(bagID, slotID, _, _)
      return DejunkApi:IsJunk(bagID, slotID) or UH.UTILS:IsItemConjured(C_Container.GetContainerItemLink(bagID, slotID));
    end)
  end);
end
