---@diagnostic disable-next-line: inject-field
UtilityHub.Integration = {};

function UtilityHub.Integration:FuncOrWaitFrame(addon, func)
  local addons = {};

  if (type(addon) == "string") then
    addons[addon] = C_AddOns.IsAddOnLoaded(addon) or false;
  elseif (type(addon) == "table") then
    for _, addonName in pairs(addon) do
      addons[addonName] = C_AddOns.IsAddOnLoaded(addonName) or false;
    end
  end

  function AllAddonsLoaded()
    for _, loaded in pairs(addons) do
      if (not loaded) then
        return false;
      end
    end

    return true;
  end

  if (AllAddonsLoaded()) then
    func();
    return;
  end

  EventRegistry:RegisterFrameEventAndCallback("ADDON_LOADED", function(addonName)
    if (type(addons[addonName]) == "boolean") then
      addons[addonName] = true;

      if (AllAddonsLoaded()) then
        func();
      end
    end
  end);
end

--- Checks if a frame contains Mail-specific child elements
---@param parentFrame Frame
---@return boolean
local function HasMailSpecificElements(parentFrame)
  -- Check all child frames for Mail-specific elements
  local children = { parentFrame:GetChildren() };
  for _, child in ipairs(children) do
    if (child.GetName) then
      local name = child:GetName();
      if (name) then
        -- Check for Mail-specific frame names (MailsScrollTable is unique to Mail UI)
        if (name:find("MailsScrollTable")) then
          return true;
        end
      end
    end

    -- Recursively check children
    if (HasMailSpecificElements(child)) then
      return true;
    end
  end

  return false;
end

function UtilityHub.Integration:GetTSMMailFrame()
  if (not UtilityHub.Flags.tsmLoaded) then
    return nil;
  end

  -- Cache: if we already found it and it's still visible
  if (UtilityHub.Flags.tsmMailFrame and UtilityHub.Flags.tsmMailFrame:IsVisible()) then
    return UtilityHub.Flags.tsmMailFrame;
  end

  -- TSM frames are not direct children of UIParent
  -- Scan all frames for TSM's mail LargeApplicationFrame
  -- Identify by presence of Mail-specific child elements (Send button, MailsScrollTable)
  local frame = EnumerateFrames();
  while (frame) do
    if (frame:IsVisible() and frame.GetName and frame:GetWidth() > 300) then
      local name = frame:GetName();
      if (name and name:find("^TSM_FRAME") and name:find("LargeApplicationFrame")) then
        -- Verify this is the Mail frame by checking for Mail-specific elements
        if (HasMailSpecificElements(frame)) then
          UtilityHub.Flags.tsmMailFrame = frame;
          return frame;
        end
      end
    end
    frame = EnumerateFrames(frame);
  end

  return nil;
end

function UtilityHub.Integration:GetTSMRecipientField()
  local best = nil;
  local frame = EnumerateFrames();
  while (frame) do
    if (frame:IsVisible() and frame.GetName and frame.SetText) then
      local name = frame:GetName();
      if (name and name:find("^TSM_EDIT_BOX") and name:find("Input")) then
        -- Pick the widest TSM_EDIT_BOX:Input (recipient field is ~424px, gold field is ~160px)
        if (not best or frame:GetWidth() > best:GetWidth()) then
          best = frame;
        end
      end
    end
    frame = EnumerateFrames(frame);
  end

  return best;
end

function UtilityHub.Integration:ClickTSMSendTab()
  local frame = EnumerateFrames();
  while (frame) do
    if (frame:IsVisible() and frame.GetName and frame.Click) then
      local name = frame:GetName();
      if (name and name:find("^TSM_BUTTON") and name:find("FlashingButton")) then
        local text = frame.GetText and frame:GetText();
        if (not text) then
          for _, region in pairs({frame:GetRegions()}) do
            if (region.GetText) then
              text = region:GetText();
              if (text and text ~= "") then break end
            end
          end
        end

        if (text and text == "Send") then
          frame:Click();
          return true;
        end
      end
    end
    frame = EnumerateFrames(frame);
  end

  return false;
end
