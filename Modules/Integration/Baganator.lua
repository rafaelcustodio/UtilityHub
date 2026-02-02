function UtilityHub.Integration.Baganator()
  UtilityHub.Integration:FuncOrWaitFrame({ "Baganator", "Dejunk" }, function()
    Baganator.API.RegisterJunkPlugin("Dejunk + Personal", "dejunkcustom", function(bagID, slotID, _, _)
      return DejunkApi:IsJunk(bagID, slotID) or UtilityHub.UTILS:IsItemConjured(C_Container.GetContainerItemLink(bagID, slotID));
    end)
  end);
end
