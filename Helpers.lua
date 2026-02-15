---@class Helpers
UtilityHub.Helpers = {
  String = {},
  Time = {},
  Notification = {},
  Item = {},
  Color = {},
  Mail = {},
};

-- Time

---@param seconds number
---@return string, boolean
function UtilityHub.Helpers.Time:FormatDuration(seconds)
  local hours = math.floor(seconds / 3600);
  local minutes = math.floor((seconds % 3600) / 60);
  local secs = seconds % 60;
  return string.format("%02d:%02d:%02d", hours, minutes, secs),
      (hours > 24 or (hours == 24 and minutes > 0 and seconds > 0));
end

-- Notification

---@param text string
function UtilityHub.Helpers.Notification:ShowNotification(text)
  UtilityHub.Libs.Utils:ShowChatNotification(text, UtilityHub.Constants.AddonPrefix);
end

-- String

---@param text string
function UtilityHub.Helpers.String:ApplyPrefix(text)
  return UtilityHub.Constants.AddonPrefix .. text;
end

-- Item

---@param item number | string
---@param cb fun(itemLink) | nil
function UtilityHub.Helpers.Item:AsyncGetItemInfo(item, cb)
  local function tryCB(value)
    if (cb) then
      cb(value);
    end

    return value;
  end;

  if (not item) then
    return tryCB(nil);
  end

  local itemID = tonumber(item);

  if (itemID and type(itemID) == "number") then
    local tempItem = Item:CreateFromItemID(itemID);

    tempItem:ContinueOnItemLoad(function()
      tryCB(tempItem:GetItemLink());
    end);
  elseif (type(item) == "string") then
    local _, itemLink = C_Item.GetItemInfo(item);

    if (itemLink) then
      return tryCB(itemLink);
    end
  end

  return tryCB(nil);
end;

-- Color

---@param className string|nil
---@return BasicRGB
function UtilityHub.Helpers.Color:GetRGBFromClassName(className)
  ---@type BasicRGB
  local color = { r = 1, g = 1, b = 1 };

  if (className) then
    color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[className];
  end

  return color;
end

---@class BasicRGB
---@field r number
---@field g number
---@field b number

function UtilityHub.Helpers.Color:AddColorToString(str, color)
  return string.format("|c%s%s|r", color, str);
end

-- Mail

function UtilityHub.Helpers.Mail:AddItemToNextEmptyMailSlot(bag, slot)
  for mailSlot = 1, ATTACHMENTS_MAX_SEND do
    if (not HasSendMailItem(mailSlot)) then
      C_Container.PickupContainerItem(bag, slot);
      ClickSendMailItemButton(mailSlot);

      return true;
    end
  end

  return false;
end

function UtilityHub.Helpers.Mail:ClearAllMailSlots()
  for i = 1, ATTACHMENTS_MAX_SEND do
    ClickSendMailItemButton(i, true);
  end
end

function UtilityHub.Helpers.Mail:OpenSendMailTab(callback)
  if (UtilityHub.Flags.tsmLoaded and not MailFrame:IsVisible()) then
    UtilityHub.Integration:ClickTSMSendTab();
    -- Delay for TSM Send view to render before executing callback
    if (callback) then
      C_Timer.After(0.3, callback);
    end
    return;
  end

  MailFrameTab_OnClick(_G["MailFrameTab2"]);
  if (callback) then
    callback();
  end
end

function UtilityHub.Helpers.Mail:SetRecipient(name)
  -- Always set Blizzard field (backend uses this)
  SendMailNameEditBox:SetText(name);

  -- Also set TSM field if active
  if (UtilityHub.Flags.tsmLoaded and not MailFrame:IsVisible()) then
    C_Timer.After(0.1, function()
      local tsmField = UtilityHub.Integration:GetTSMRecipientField();
      if (tsmField) then
        tsmField:SetFocus();
        tsmField:SetText("");
        tsmField:Insert(name);
      end
    end);
  end
end

-- Item count helper

---@param itemID number
---@param includeBank boolean
---@return number
function UtilityHub.Helpers.Item:GetItemCount(itemID, includeBank)
  return C_Item.GetItemCount(itemID, false, includeBank or false);
end

---@return number
function UtilityHub.Helpers.Item:GetFreeBagSlots()
  local totalFree = 0;
  for i = 0, NUM_BAG_SLOTS do
    local containerInfo = C_Container.GetContainerNumSlots(i);
    if (containerInfo and containerInfo > 0) then
      local freeSlots = C_Container.GetContainerNumFreeSlots(i);
      totalFree = totalFree + freeSlots;
    end
  end
  return totalFree;
end
