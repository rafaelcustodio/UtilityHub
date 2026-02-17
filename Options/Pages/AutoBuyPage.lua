local ADDON_NAME = ...;

---@class AutoBuyPage
local AutoBuyPage = {};

---@type table|nil
local selectedAutoBuyItem = nil;
---@type Frame|nil
local autoBuyListFrame = nil;

---@param parent Frame
---@return Frame
function AutoBuyPage:Create(parent)
  local frame = CreateFrame("Frame", "UtilityHubAutoBuyPage", parent);

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("AutoBuy Settings");

  -- Enable checkbox
  local enableCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
  enableCheckbox:SetSize(24, 24);
  enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20);
  enableCheckbox:SetChecked(UtilityHub.Database.global.options.autoBuy);

  local enableLabel = enableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 5, 0);
  enableLabel:SetText("Enabled");

  enableCheckbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked();
    UtilityHub.Database.global.options.autoBuy = checked;
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuy", checked);
  end);

  enableCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("AutoBuy", 1, 1, 1);
    GameTooltip:AddLine("Enable the functionality to autobuy specific limited stock items from vendors when the window is opened", nil, nil, nil, true);
    GameTooltip:Show();
  end);

  enableCheckbox:SetScript("OnLeave", function(self)
    if (GameTooltip:IsOwned(self)) then
      GameTooltip:Hide();
    end
  end);

  -- Items list label
  local itemsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  itemsLabel:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20);
  itemsLabel:SetText("Items:");

  -- Helper function to refresh the list
  local function RefreshList()
    if (autoBuyListFrame) then
      local list = UtilityHub.Database.global.options.autoBuyList or {};
      autoBuyListFrame:ReplaceData(list);
    end
  end

  -- Add item input
  local framesHelper = UtilityHub.GameOptions.framesHelper;
  local addInput = framesHelper:CreateCustomListAdd(
    frame,
    function(text)
      local list = UtilityHub.Database.global.options.autoBuyList or {};

      -- Check if item already exists
      local itemID = tonumber(string.match(text, "item:(%d+):"));
      if (itemID) then
        for _, existingItem in ipairs(list) do
          local existingID = tonumber(string.match(existingItem.itemLink, "item:(%d+):"));
          if (existingID == itemID) then
            return; -- Item already exists
          end
        end
      end

      -- Add new item
      local newItem = {
        itemLink = text,
        quantity = 1,
      };

      tinsert(list, newItem);
      UtilityHub.Database.global.options.autoBuyList = list;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", list);

      -- Show quantity dialog
      C_Timer.After(0.1, function()
        StaticPopupDialogs["UTILITYHUB_AUTOBUY_SET_QUANTITY"] = {
          text = "Set quantity for " .. text,
          button1 = "Save",
          button2 = "Cancel",
          hasEditBox = true,
          editBoxWidth = 200,
          OnShow = function(self)
            self.editBox:SetText("1");
            self.editBox:SetFocus();
            self.editBox:HighlightText();
          end,
          OnAccept = function(self)
            local editBox = self.editBox or self.wideEditBox;
            if (not editBox) then
              local dialogName = self:GetName();
              editBox = _G[dialogName .. "EditBox"] or _G[dialogName .. "WideEditBox"];
            end

            if (not editBox) then
              return;
            end

            local newQty = tonumber(editBox:GetText());
            if (not newQty or newQty <= 0) then
              return;
            end

            -- Update database directly
            local currentList = UtilityHub.Database.global.options.autoBuyList or {};

            for i, item in ipairs(currentList) do
              if (type(item) == "table" and item.itemLink == text) then
                currentList[i].quantity = newQty;
                break;
              end
            end

            -- Trigger event
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", currentList);

            -- Refresh UI
            RefreshList();

            -- Close dialog
            StaticPopup_Hide("UTILITYHUB_AUTOBUY_SET_QUANTITY");
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        };
        StaticPopup_Show("UTILITYHUB_AUTOBUY_SET_QUANTITY");
      end);

      -- Refresh list
      RefreshList();
    end
  );

  addInput:SetPoint("TOPLEFT", itemsLabel, "BOTTOMLEFT", 0, -10);

  -- Create items list
  autoBuyListFrame = framesHelper:CreateCustomList(
    frame,
    addInput,
    {
      SortComparator = function(a, b)
        local itemLinkA = type(a) == "table" and a.itemLink or a;
        local itemLinkB = type(b) == "table" and b.itemLink or b;

        local itemNameA = itemLinkA and select(3, strfind(itemLinkA, "|H(.+)|h")) or "";
        local itemNameB = itemLinkB and select(3, strfind(itemLinkB, "|H(.+)|h")) or "";

        if (not itemNameA) then itemNameA = tostring(itemLinkA or ""); end
        if (not itemNameB) then itemNameB = tostring(itemLinkB or ""); end

        return itemNameA < itemNameB;
      end,
      Predicate = function(rowData)
        if (type(rowData) == "table") then
          return rowData.itemLink;
        end
        return rowData;
      end,
      GetText = function(rowData)
        if (type(rowData) == "table" and rowData.itemLink) then
          local itemName = select(3, strfind(rowData.itemLink, "%[(.+)%]")) or rowData.itemLink;
          local qty = rowData.quantity or 1;
          if (qty == 1) then
            return string.format("%s (Buy once)", itemName);
          else
            return string.format("%s (Restock: %d)", itemName, qty);
          end
        end
        return tostring(rowData);
      end,
      GetHyperlink = function(rowData)
        if (type(rowData) == "table") then
          return rowData.itemLink;
        end
        return rowData;
      end,
      OnRemove = function(rowData, configuration)
        local list = UtilityHub.Database.global.options.autoBuyList or {};
        local itemID = tonumber(string.match(rowData.itemLink, "item:(%d+):"));

        for i = #list, 1, -1 do
          local existingID = tonumber(string.match(list[i].itemLink, "item:(%d+):"));
          if (existingID == itemID) then
            tremove(list, i);
            break;
          end
        end

        UtilityHub.Database.global.options.autoBuyList = list;
        UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", list);

        -- Refresh list
        RefreshList();
      end,
      CustomizeRow = function(frame, rowData, helpers)
        -- Add edit button (gear icon)
        if (not frame.customElements) then
          frame.customElements = {};
        end

        if (not frame.customElements.EditButton) then
          local editButton = CreateFrame("Button", nil, frame);
          frame.customElements.EditButton = editButton;
          editButton:SetSize(16, 16);
          editButton:SetNormalAtlas("transmog-icon-chat");
          editButton:SetPoint("TOPRIGHT", -25, -5);

          editButton:SetScript("OnClick", function(self)
            selectedAutoBuyItem = CopyTable(rowData);

            StaticPopupDialogs["UTILITYHUB_AUTOBUY_EDIT_QUANTITY"] = {
              text = "Edit quantity for " .. (rowData.itemLink or "item"),
              button1 = "Save",
              button2 = "Cancel",
              hasEditBox = true,
              editBoxWidth = 200,
              OnShow = function(self)
                self.editBox:SetText(tostring(selectedAutoBuyItem.quantity or 1));
                self.editBox:SetFocus();
                self.editBox:HighlightText();
              end,
              OnAccept = function(self)
                local editBox = self.editBox or self.wideEditBox;
                if (not editBox) then
                  local dialogName = self:GetName();
                  editBox = _G[dialogName .. "EditBox"] or _G[dialogName .. "WideEditBox"];
                end

                if (not editBox) then
                  return;
                end

                local newQty = tonumber(editBox:GetText());
                if (not newQty or newQty <= 0) then
                  return;
                end

                -- Update database directly
                local list = UtilityHub.Database.global.options.autoBuyList or {};

                for i, item in ipairs(list) do
                  if (type(item) == "table" and item.itemLink == selectedAutoBuyItem.itemLink) then
                    list[i].quantity = newQty;
                    break;
                  end
                end

                -- Trigger event
                UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", list);

                -- Refresh UI
                RefreshList();

                -- Close dialog
                StaticPopup_Hide("UTILITYHUB_AUTOBUY_EDIT_QUANTITY");
              end,
              timeout = 0,
              whileDead = true,
              hideOnEscape = true,
              preferredIndex = 3,
            };
            StaticPopup_Show("UTILITYHUB_AUTOBUY_EDIT_QUANTITY");
          end);

          editButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText("Edit Quantity");
            GameTooltip:Show();
          end);

          editButton:SetScript("OnLeave", function(self)
            if (GameTooltip:IsOwned(self)) then
              GameTooltip:Hide();
            end
          end);
        end
      end,
      showRemoveIcon = true,
      hasHyperlink = true,
    },
    "InsetFrameTemplate"
  );

  autoBuyListFrame:SetPoint("TOPLEFT", addInput, "BOTTOMLEFT", 0, -10);
  autoBuyListFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20);

  -- Load initial data
  local initialList = UtilityHub.Database.global.options.autoBuyList or {};
  autoBuyListFrame:ReplaceData(initialList);

  return frame;
end

-- Register page
UtilityHub.OptionsPages.AutoBuy = AutoBuyPage;
