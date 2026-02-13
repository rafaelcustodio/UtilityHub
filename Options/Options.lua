local ADDON_NAME, addonTable = ...;

function addonTable.GenerateOptions()
  local order = {};

  local function GetNextOrder(key)
    order[key] = (order[key] or 0) + 1;
    return order[key];
  end

  local function GenerateSeparator(key, name)
    return {
      type = "header",
      name = name or "",
      order = GetNextOrder(key),
    };
  end

  local function GenerateSpacer(key)
    return {
      type = "description",
      name = " ",
      order = GetNextOrder(key),
      fontSize = "large",
    };
  end

  -- Default
  tinsert(UtilityHub.GameOptions.options, {
    key = ADDON_NAME,
    name = ADDON_NAME,
    root = true,
    group = {
      type = "group",
      order = GetNextOrder("default"),
      args = {
        addonDescription1 = {
          type = "description",
          name =
          "I did this addon because i like to code and to solve problems without WA. If you have any ideas, contact me.",
          order = GetNextOrder("default"),
          fontSize = "medium",
        },
        spacer1 = GenerateSpacer("default"),
        addonTitle = {
          type = "description",
          name = "Author: Cacetinho - Nightslayer",
          order = GetNextOrder("default"),
          fontSize = "medium",
        },
        modulesSeparator = GenerateSeparator("default", "Modules"),
        tooltipToggle = {
          type = "toggle",
          name = "Tooltip - Simplified stats display",
          desc = "Change the way most stats are shown in the tooltip",
          order = GetNextOrder("default"),
          width = "full",
          get = function() return UtilityHub.Database.global.options.simpleStatsTooltip end,
          set = function(_, val)
            UtilityHub.Database.global.options.simpleStatsTooltip = val;
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "simpleStatsTooltip", val);
          end,
        },
        tradeToggle = {
          type = "toggle",
          name = "Trade - Extra info frame",
          desc = "Show extra frame with more info about the person you are trading",
          order = GetNextOrder("default"),
          width = "full",
          get = function() return UtilityHub.Database.global.options.tradeExtraInfo end,
          set = function(_, val)
            UtilityHub.Database.global.options.tradeExtraInfo = val;
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "tradeExtraInfo", val);
          end,
        },
        cooldownsSeparator = GenerateSeparator("default", "Cooldowns"),
        cooldownsToggle = {
          type = "toggle",
          name = "Enable cooldown tracking",
          desc = "Enable tracking and listing of all character cooldowns (with the addon active)",
          order = GetNextOrder("default"),
          width = "full",
          get = function() return UtilityHub.Database.global.options.cooldowns end,
          set = function(_, val)
            UtilityHub.Database.global.options.cooldowns = val;
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldowns", val);
          end,
        },
        cooldownsSoundToggle = {
          type = "toggle",
          name = "Play sound when a cooldown is ready",
          order = GetNextOrder("default"),
          width = "full",
          disabled = function() return not UtilityHub.Database.global.options.cooldowns end,
          get = function() return UtilityHub.Database.global.options.cooldownPlaySound end,
          set = function(_, val)
            UtilityHub.Database.global.options.cooldownPlaySound = val;
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldownPlaySound", val);
          end,
        },
        dailyQuestsSeparator = GenerateSeparator("default", "Daily Quests"),
        dailyQuestsToggle = {
          type = "toggle",
          name = "Enable daily quest tracking",
          desc = "Enable tracking of the daily quests",
          order = GetNextOrder("default"),
          width = "full",
          get = function() return UtilityHub.Database.global.options.dailyQuests end,
          set = function(_, val)
            UtilityHub.Database.global.options.dailyQuests = val;
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "dailyQuests", val);
          end,
        },
      },
    },
  });

  -- AutoBuy
  tinsert(UtilityHub.GameOptions.options, {
    key = ADDON_NAME .. "_AutoBuy",
    name = "AutoBuy",
    root = false,
    group = {
      name = "AutoBuy",
      type = "group",
      order = GetNextOrder("autoBuy"),
      args = {
        autoBuy = {
          type = "toggle",
          name = "Enable",
          desc =
          "Enable the functionality to autobuy specific limited stock items from vendors when the window is opened",
          order = GetNextOrder("autoBuy"),
          get = function() return UtilityHub.Database.global.options.autoBuy end,
          set = function(_, val)
            UtilityHub.Database.global.options.autoBuy = val;
            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuy", val);
          end,
        },
        autoBuyList = {
          type = "input",
          dialogControl = "ItemList",
          name = "AutoBuyItemList",
          order = GetNextOrder("autoBuy"),
          width = "full",
          set = function(_, val)
            UtilityHub.Database.global.options.autoBuyList = C_EncodingUtil.DeserializeJSON(val);
          end,
          get = function()
            return C_EncodingUtil.SerializeJSON(UtilityHub.Database.global.options.autoBuyList or {});
          end,
          ---@type ItemListArg
          arg = {
            widthSizeType = "full",
            heightSizeType = "full",
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
              UtilityHub.Helpers.Item:AsyncGetItemInfo(text, function(itemLink)
                if (itemLink) then
                  OnSuccess(itemLink, function(error)
                    if (error == "ROW_ALREADY_EXISTS") then
                      UtilityHub.Helpers.Notification:ShowNotification("Item already added to the list");
                    end
                  end);
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
        },
      },
    },
  });

  -- Mail

  ---@type Preset
  local presetModule = UtilityHub.Addon:GetModule("Preset");
  UtilityHub.tempPreset = presetModule:GetNewEmptyPreset();

  local function GenerateNewPreset()
    return {
      name = function()
        return UtilityHub.tempPreset and UtilityHub.tempPreset.id and "Editing preset" or "New preset";
      end,
      type = "group",
      order = GetNextOrder("mail"),
      args = {
        newPresetTitle = {
          type = "description",
          name = "New preset",
          fontSize = "large",
          order = GetNextOrder("mail"),
        },
        newPresetNameInput = {
          type = "input",
          name = "Name",
          order = GetNextOrder("mail"),
          width = "double",
          get = function()
            return UtilityHub.tempPreset.name;
          end,
          set = function(_, value)
            UtilityHub.tempPreset.name = value;
          end
        },
        newPresetColorInput = {
          type = "color",
          name = "Color",
          order = GetNextOrder("mail"),
          width = "half",
          get = function()
            return UtilityHub.tempPreset.color.r, UtilityHub.tempPreset.color.g, UtilityHub.tempPreset.color.b,
            UtilityHub.tempPreset.color.a;
          end,
          set = function(_, r, g, b, a)
            UtilityHub.tempPreset.color = { r = r, g = g, b = b, a = a };
          end
        },
        newPresetToInput = {
          type = "input",
          name = "To",
          order = GetNextOrder("mail"),
          width = "double",
          get = function()
            return UtilityHub.tempPreset.to;
          end,
          set = function(_, value)
            UtilityHub.tempPreset.to = value;
          end
        },
        newPresetSeparator = GenerateSeparator("mail", "Items"),
        newPresetItemGroups = {
          name = function()
            local count = 0;

            for _, group in ipairs(UtilityHub.tempPreset.itemGroups) do
              if (group.checked) then
                count = count + 1;
              end
            end

            return string.format("Item groups: %s selected", count);
          end,
          type = "group",
          order = GetNextOrder("mail"),
          inline = true,
          args = {
            presetItemGroupList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetItemGroupList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UtilityHub.tempPreset.itemGroups = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UtilityHub.tempPreset.itemGroups or {});
              end,
              ---@type ItemListArg
              arg = {
                hideAdd = true,
                widthSizeType = "manual",
                heightSizeType = "manual",
                width = 410,
                height = 250,
                GetRowIndex = function(self, rows, rowData)
                  for index, loopItem in ipairs(rows) do
                    if (loopItem.name == rowData.name) then
                      return index;
                    end
                  end

                  return nil;
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  frame:SetText(rowData.name);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 40, 0);
                  frame:GetFontString():SetPoint("RIGHT", -6, 0);

                  helpers.CreateCheckbox(self, frame, rowData);

                  return { skipFontStringPoints = true };
                end
              },
            },
          },
        },
        newPresetManualInclusions = {
          name = function()
            return string.format("Manual inclusions: %s selected", #UtilityHub.tempPreset.custom);
          end,
          type = "group",
          order = GetNextOrder("mail"),
          inline = true,
          args = {
            presetManualInclusionsList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetManualInclusionsList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UtilityHub.tempPreset.custom = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UtilityHub.tempPreset.custom or {});
              end,
              ---@type ItemListArg
              arg = {
                widthSizeType = "manual",
                heightSizeType = "manual",
                width = 400,
                height = 250,
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
                  UtilityHub.Helpers.Item:AsyncGetItemInfo(text, function(itemLink)
                    if (itemLink) then
                      OnSuccess(itemLink, function(error)
                        if (error == "ROW_ALREADY_EXISTS") then
                          UtilityHub.Helpers.Notification:ShowNotification("Item already added to the list");
                        end
                      end);
                    else
                      OnError();
                    end
                  end);
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  frame:SetText(rowData);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  helpers.CreateDeleteIconButton(self, frame, rowData);

                  return { skipFontStringPoints = true };
                end
              },
            },
          },
        },
        newPresetManualExclusions = {
          name = function()
            return string.format("Manual exclusions: %s selected", #UtilityHub.tempPreset.exclusion);
          end,
          type = "group",
          order = GetNextOrder("mail"),
          inline = true,
          args = {
            presetManualExclusionsList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetManualExclusionsList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UtilityHub.tempPreset.exclusion = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UtilityHub.tempPreset.exclusion or {});
              end,
              ---@type ItemListArg
              arg = {
                widthSizeType = "manual",
                heightSizeType = "manual",
                width = 400,
                height = 250,
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
                  UtilityHub.Helpers.Item:AsyncGetItemInfo(text, function(itemLink)
                    if (itemLink) then
                      OnSuccess(itemLink, function(error)
                        if (error == "ROW_ALREADY_EXISTS") then
                          UtilityHub.Helpers.Notification:ShowNotification("Item already added to the list");
                        end
                      end);
                    else
                      OnError();
                    end
                  end);
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  frame:SetText(rowData);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  helpers.CreateDeleteIconButton(self, frame, rowData);

                  return { skipFontStringPoints = true };
                end
              },
            },
          },
        },
        newPresetSave = {
          type = "execute",
          name = "Save",
          order = GetNextOrder("mail"),
          width = 0.8,
          disabled = false,
          func = function(info, value)
            local itemGroups = {};

            for _, group in ipairs(UtilityHub.tempPreset.itemGroups) do
              itemGroups[group.key] = group.checked;
            end

            local result = presetModule:SavePreset({
              name = UtilityHub.tempPreset.name,
              to = UtilityHub.tempPreset.to,
              custom = UtilityHub.tempPreset.custom,
              itemGroups = itemGroups,
              exclusion = UtilityHub.tempPreset.exclusion,
              color = UtilityHub.tempPreset.color,
            }, UtilityHub.tempPreset.id);

            if (result) then
              UtilityHub.tempPreset = presetModule:GetNewEmptyPreset();
              UtilityHub.Libs.AceConfigDialog:SelectGroup(ADDON_NAME .. "_Mail", "mailPresetsGroup");
            end
          end
        },
      }
    };
  end

  tinsert(UtilityHub.GameOptions.options, {
    key = ADDON_NAME .. "_Mail",
    name = "Mail",
    root = false,
    group = {
      name = "Mail",
      type = "group",
      order = GetNextOrder("mail"),
      args = {
        mailCharactersGroup = {
          name = "Characters",
          type = "group",
          order = GetNextOrder("mail"),
          args = {
            mailCharactersTitle = {
              type = "description",
              name = "Module: Mail - Characters",
              fontSize = "large",
              order = GetNextOrder("mail"),
            },
            mailCharactersSeparator = GenerateSeparator("mail"),
            mailCharacters = {
              type = "input",
              dialogControl = "ItemList",
              name = "ConfigurableItemList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UtilityHub.Database.global.characters = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UtilityHub.Database.global.characters or {});
              end,
              ---@type ItemListArg
              arg = {
                hideAdd = true,
                widthSizeType = "side",
                heightSizeType = "full",
                GetRowIndex = function(self, rows, rowData)
                  for index, loopItem in ipairs(rows) do
                    if (loopItem.name == rowData.name) then
                      return index;
                    end
                  end

                  return nil;
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  local widget = self;
                  local options = {
                    { text = "Main/alt",  value = UtilityHub.Enums.CharacterGroup.MAIN_ALT },
                    { text = "Bank",      value = UtilityHub.Enums.CharacterGroup.BANK },
                    { text = "Ungrouped", value = UtilityHub.Enums.CharacterGroup.UNGROUPED },
                  };

                  function CreateDropDown()
                    if (not frame.customElements[widget.name].DropDownGroup) then
                      frame.customElements[widget.name].DropDownGroup = CreateFrame(
                        "Frame",
                        string.format("MailCharacters%sDropDownGroup", rowData.name),
                        frame,
                        "UIDropDownMenuTemplate"
                      );
                      frame.customElements[widget.name].DropDownGroup:SetPoint("TOPRIGHT", -10, 1);

                      local function OnSelect(self, arg1)
                        widget.items[widget:GetRowIndex(widget.items, rowData)].group = arg1 or
                            UtilityHub.Enums.CharacterGroup.UNGROUPED;
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

                      UIDropDownMenu_Initialize(frame.customElements[widget.name].DropDownGroup, Init);
                      UIDropDownMenu_SetWidth(frame.customElements[widget.name].DropDownGroup, 100);
                    end

                    local selectedValue = rowData.group or UtilityHub.Enums.CharacterGroup.UNGROUPED;
                    local selectedOption = options[1];

                    for _, option in pairs(options) do
                      if (option.value == selectedValue) then
                        selectedOption = option;
                      end
                    end

                    UIDropDownMenu_SetSelectedValue(frame.customElements[widget.name].DropDownGroup, selectedOption
                      .value);
                    UIDropDownMenu_SetText(frame.customElements[widget.name].DropDownGroup, selectedOption.text);
                  end

                  frame:SetText(rowData.name);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  local color = UtilityHub.Helpers.Color:GetRGBFromClassName(rowData.className);

                  frame:GetFontString():SetTextColor(color.r, color.g, color.b);

                  if (rowData.name ~= UnitName("player")) then
                    helpers.CreateDeleteIconButton(self, frame, rowData);
                  end

                  CreateDropDown();

                  return { skipFontStringPoints = true };
                end
              }
            },
          },
        },
        mailPresetsGroup = {
          name = "Presets",
          type = "group",
          order = GetNextOrder("mail"),
          args = {
            mailPresetsTitle = {
              type = "description",
              name = "Module: Mail - Presets",
              fontSize = "large",
              order = GetNextOrder("mail"),
            },
            mailPresetsSeparator = GenerateSeparator("mail"),
            presetsList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetsList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UtilityHub.Database.global.presets = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UtilityHub.Database.global.presets or {});
              end,
              ---@type ItemListArg
              arg = {
                hideAdd = true,
                widthSizeType = "side",
                heightSizeType = "full",
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  local widget = self;
                  local color = rowData.color;

                  frame:SetText(rowData.name);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);
                  frame:GetFontString():SetTextColor(
                    color and color.r or 1,
                    color and color.g or 1,
                    color and color.b or 1
                  );

                  local function CreateEditIconButton()
                    frame.customElements[widget.name].EditIconButton = CreateFrame("Button", nil, frame);
                    -- frame.customElements[widget.name].EditIconButton:SetNormalAtlas("common-icon-edit");
                    -- frame.texture = CreateText
                    frame.customElements[widget.name].EditIconButton:SetNormalTexture("Interface\\WorldMap\\GEAR_64GREY");
                    frame.customElements[widget.name].EditIconButton:SetPoint("TOPRIGHT", -28, -4);
                    frame.customElements[widget.name].EditIconButton:SetSize(18, 18);
                    frame.customElements[widget.name].EditIconButton:SetScript("OnClick", function()
                      local index = widget:GetRowIndex(widget.items, rowData);
                      local data = widget.items[index];

                      UtilityHub.tempPreset = {
                        id = index,
                        name = data.name,
                        to = data.to,
                        itemGroups = {},
                        custom = data.custom or {},
                        exclusion = data.exclusion or {},
                        color = data.color or presetModule.defaultPresetColor,
                      };

                      for itemGroupName, itemGroup in UtilityHub.Libs.Utils:OrderedPairs(presetModule.ItemGroupOptions) do
                        tinsert(
                          UtilityHub.tempPreset.itemGroups,
                          {
                            checked = data.itemGroups[itemGroupName] or false,
                            name = itemGroup.label,
                            key = itemGroupName,
                          }
                        );
                      end

                      UtilityHub.Libs.AceConfigDialog:SelectGroup(ADDON_NAME .. "_Mail", "mailPresetsGroup", "newPreset");
                    end);
                    frame.customElements[widget.name].EditIconButton:SetScript("OnEnter", function()
                      local el = frame.customElements[widget.name].EditIconButton;

                      if (el) then
                        GameTooltip:SetOwner(el, "ANCHOR_RIGHT");
                        GameTooltip:SetText("Edit");
                        GameTooltip:Show();
                      end
                    end);
                    frame.customElements[widget.name].EditIconButton:SetScript("OnLeave", function()
                      local el = frame.customElements[widget.name].EditIconButton;

                      if (not GameTooltip:IsOwned(el)) then
                        return;
                      end

                      GameTooltip:Hide();
                    end);

                    return frame.customElements[widget.name].EditIconButton;
                  end

                  helpers.CreateDeleteIconButton(self, frame, rowData);
                  CreateEditIconButton();

                  return { skipFontStringPoints = true };
                end
              },
            },
            newPreset = GenerateNewPreset(),
          },
        },
      },
    },
  });

end
