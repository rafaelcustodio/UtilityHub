local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local order = 0;

local function GetNextOrder()
  order = order + 1;
  return order;
end

UH.Options = {
  name = ADDON_NAME,
  type = "group",
  args = {
    tooltipGroup = {
      name = "Tooltip",
      type = "group",
      order = GetNextOrder(),
      args = {
        tooltipGroupTitle = {
          type = "description",
          name = "Module: Tooltip",
          fontSize = "large",
          order = GetNextOrder(),
        },
        tooltipGroupSeparator = {
          type = "header",
          name = "",
          order = GetNextOrder(),
        },
        tooltipSimpleStats = {
          type = "toggle",
          name = "Enable",
          desc = "Change the way most stats are shown in the tooltip",
          order = GetNextOrder(),
          get = function() return UH.db.global.options.simpleStatsTooltip end,
          set = function(_, val)
            UH.db.global.options.simpleStatsTooltip = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "simpleStatsTooltip", val);
          end,
        },
      },
    },
    autoBuyGroup = {
      name = "AutoBuy",
      type = "group",
      order = GetNextOrder(),
      args = {
        autoBuyGroupTitle = {
          type = "description",
          name = "Module: AutoBuy",
          fontSize = "large",
          order = GetNextOrder(),
        },
        autoBuyGroupSeparator = {
          type = "header",
          name = "",
          order = GetNextOrder(),
        },
        autoBuy = {
          type = "toggle",
          name = "Enable",
          desc =
          "Enable the functionality to autobuy specific limited stock items from vendors when the window is opened",
          order = GetNextOrder(),
          get = function() return UH.db.global.options.autoBuy end,
          set = function(_, val)
            UH.db.global.options.autoBuy = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuy", val);
          end,
        },
        autoBuyList = {
          type = "input",
          dialogControl = "ItemList",
          name = "AutoBuyItemList",
          order = GetNextOrder(),
          width = "full",
          set = function(_, val)
            UH.db.global.options.autoBuyList = C_EncodingUtil.DeserializeJSON(val);
          end,
          get = function()
            return C_EncodingUtil.SerializeJSON(UH.db.global.options.autoBuyList or {});
          end,
          ---@type ItemListArg
          arg = {
            OnEnterRow = function(self, frame, rowData)
              GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
              GameTooltip:SetHyperlink(rowData);
              GameTooltip:Show();
            end,
            OnLeaveRow = function(self, frame)
              if (not GameTooltip:IsOwned(frame)) then
                return;
              end

              GameTooltip:Hide();
            end,
            CreateNewRow = function(self, text, OnSuccess, OnError)
              UH.Helpers:AsyncGetItemInfo(text, function(itemLink)
                if (itemLink) then
                  OnSuccess(itemLink);
                else
                  OnError();
                end
              end);
            end,
            CustomizeRowElement = function(self, frame, rowData, helpers)
              frame:SetText(rowData);
              frame:GetFontString():SetPoint("LEFT", 6, 0);
              frame:GetFontString():SetPoint("RIGHT", -20, 0);
              helpers.CreateDeleteIconButton(self, frame, rowData);

              return { skipFontStringPoints = true };
            end
          },
        }
      },
    },
    mailGroup = {
      name = "Mail",
      type = "group",
      order = GetNextOrder(),
      args = {
        mailGroupTitle = {
          type = "description",
          name = "Module: Mail",
          fontSize = "large",
          order = GetNextOrder(),
        },
        mailGroupSeparator = {
          type = "header",
          name = "",
          order = GetNextOrder(),
        },
        mailCharacters = {
          type = "input",
          dialogControl = "ItemList",
          name = "ConfigurableItemList",
          order = GetNextOrder(),
          width = "full",
          set = function(_, val)
            UH.db.global.characters = C_EncodingUtil.DeserializeJSON(val);
          end,
          get = function()
            return C_EncodingUtil.SerializeJSON(UH.db.global.characters or {});
          end,
          ---@type ItemListArg
          arg = {
            HideAdd = true,
            ClearCustomComponents = function(self, frame, helpers)
              helpers:ReleaseSimpleFrame(frame.DeleteIconButton);
              helpers:ReleaseSimpleFrame(frame.DropDownGroup);
            end,
            CustomizeRowElement = function(self, frame, rowData, helpers)
              local widget = self;

              function CreateDropDown()
                frame.DropDownGroup = CreateFrame("Frame", string.format("MailCharacters%sDropDownGroup", rowData.name),
                  frame,
                  "UIDropDownMenuTemplate");
                frame.DropDownGroup:SetPoint("TOPRIGHT", -10, 1);

                local options = {
                  { text = "Main/alt",  value = UH.Enums.CHARACTER_GROUP.MAIN_ALT },
                  { text = "Bank",      value = UH.Enums.CHARACTER_GROUP.BANK },
                  { text = "Ungrouped", value = UH.Enums.CHARACTER_GROUP.UNGROUPED },
                };

                local function OnSelect(self, arg1)
                  UIDropDownMenu_SetSelectedValue(frame.DropDownGroup, arg1);
                  rowData.group = arg1 or UH.Enums.CHARACTER_GROUP.UNGROUPED;
                  widget:UpdateList();
                  widget:FireValueChanged();
                end

                local function Init(self, level)
                  for _, item in ipairs(options) do
                    local info = UIDropDownMenu_CreateInfo();
                    info.text = item.text;
                    info.value = item.value;
                    info.arg1 = item.value;
                    info.func = OnSelect;
                    UIDropDownMenu_AddButton(info, level);
                  end
                end

                local selectedValue = rowData.group or UH.Enums.CHARACTER_GROUP.UNGROUPED;
                local selectedOption = options[1];

                for _, option in pairs(options) do
                  if (option.value == selectedValue) then
                    selectedOption = option;
                  end
                end

                UIDropDownMenu_Initialize(frame.DropDownGroup, Init);
                UIDropDownMenu_SetWidth(frame.DropDownGroup, 100);
                UIDropDownMenu_SetSelectedValue(frame.DropDownGroup, selectedOption.value);
                UIDropDownMenu_SetText(frame.DropDownGroup, selectedOption.text);
              end

              frame:SetText(rowData.name);
              frame:GetFontString():SetPoint("LEFT", 6, 0);
              frame:GetFontString():SetPoint("RIGHT", -20, 0);

              local color = UH.Helpers:GetRGBFromClassName(rowData.className);

              frame:GetFontString():SetTextColor(color.r, color.g, color.b);

              if (rowData.name ~= UnitName("player")) then
                helpers.CreateDeleteIconButton(self, frame, rowData);
              end

              CreateDropDown();

              return { skipFontStringPoints = true };
            end
          }
        }
      },
    },
  },
};
