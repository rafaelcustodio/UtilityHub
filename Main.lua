local ADDON_NAME, addonTable = ...;

local minimapIcons = {
  NORMAL = "Interface\\Addons\\UtilityHub\\Assets\\Icons\\addon.blp",
  NOTIFICATION = "Interface\\ICONS\\INV_Enchant_FormulaEpic_01.blp",
};
---@type number|nil
local lastCountReadyCooldowns = nil;

---@param version string|nil
---@param oldVersion string|nil
local function MigrateDB(version, oldVersion)
  if (version and oldVersion) then
    UtilityHub.Helpers.Notification:ShowNotification("Migrating DB version from " .. oldVersion .. " to " .. version);
  else
    UtilityHub.Helpers.Notification:ShowNotification("Migrating DB version - Forced action without any version change");
  end

  if (#UtilityHub.Database.global.presets > 0) then
    for _, preset in pairs(UtilityHub.Database.global.presets) do
      local shouldFixEssenceElemental = false;

      for j, _ in pairs(preset.itemGroups) do
        if (j == "Essence") then
          shouldFixEssenceElemental = true;
        end
      end

      if (shouldFixEssenceElemental) then
        local newItemGroups = {};

        for key, value in pairs(preset.itemGroups) do
          if (key == "Essence") then
            newItemGroups["EssenceElemental"] = value;
          else
            newItemGroups[key] = value;
          end
        end

        preset.itemGroups = newItemGroups;
      end
    end
  end

  if (not UtilityHub.Database.global.options) then
    UtilityHub.Database.global.options = UtilityHub.GameOptions.defaults;
  end

  if (not UtilityHub.Database.global.options.autoBuyList) then
    UtilityHub.Database.global.options.autoBuyList = UtilityHub.GameOptions.defaults.autoBuyList;
  end

  if (UtilityHub.Database.global.characters) then
    for index, value in ipairs(UtilityHub.Database.global.characters) do
      if (type(value) == "string") then
        local name = UtilityHub.Database.global.characters[index];

        if (name == UnitName("player")) then
          local race = select(2, UnitRace("player"));
          local className = select(2, UnitClass("player"));

          UtilityHub.Database.global.characters[index] = {
            name = name,
            race = race,
            className = className,
            group = nil,
          };
        else
          UtilityHub.Database.global.characters[index] = {
            name = name,
            race = nil,
            className = nil,
            group = nil,
          };
        end
      end
    end
  end

  if (not UtilityHub.Database.global.options.cooldowns) then
    UtilityHub.Database.global.options.cooldowns = false;
  end

  if (not UtilityHub.Database.global.options.cooldowsList) then
    UtilityHub.Database.global.options.cooldowsList = {};
  end
end

local function InitVariables()
  ---@type string|nil
  local version = UtilityHub.Constants.AddonVersion;
  ---@type string|nil
  local oldVersion = nil;

  if (UHdatabase) then
    oldVersion = UHdatabase.global.oldVersion;
  end

  UtilityHub.Database = LibStub("AceDB-3.0"):New("UHdatabase", {
    global = {
      version = version,
      debugMode = false,
      minimapIcon = {
        hide = false,
      },
      options = UtilityHub.GameOptions.defaults,
      presets = {},
      whispers = {},
      ---@type Character[]
      characters = {},
    },
    char = {},
  }, "Default");
  UtilityHub.Database.global.oldVersion = version;

  if (oldVersion and oldVersion ~= version) then
    MigrateDB(version, oldVersion);
  end
end

local function SetupSlashCommands()
  SLASH_UtilityHub1 = "/UH"
  SLASH_UtilityHub2 = "/uh"
  SlashCmdList.UtilityHub = function(strParam)
    local fragments = {};

    for word in string.gmatch(strParam, "%S+") do
      table.insert(fragments, word);
    end

    local command = (fragments[1] or ""):trim();

    if (command == "") then
      UtilityHub.Helpers.Notification:ShowNotification("Type /UH help for commands");
    elseif (command == "help") then
      UtilityHub.Helpers.Notification:ShowNotification("Use the following parameters with /UH");
      print("- |cffddff00debug|r");
      print("  Toggle the debug mode");
      print("- |cffddff00options|r");
      print("  Open the options");
      print("- |cffddff00cd or cds|r");
      print("  Toggle cooldowns frame");
      print("- |cffddff00daily or dailies|r");
      print("  Toggle daily frame");
      print("- |cffddff00testcd|r");
      print("  Test cooldown notifications");
    elseif (command == "debug") then
      UtilityHub.Database.global.debugMode = (not UtilityHub.Database.global.debugMode);
      local debugText = UtilityHub.Database.global.debugMode and "ON" or "OFF";
      UtilityHub.Helpers.Notification:ShowNotification("Debug mode " .. debugText);
    elseif (command == "options") then
      Settings.OpenToCategory(ADDON_NAME);
    elseif (command == "cd" or command == "cds") then
      UtilityHub.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
    elseif (command == "daily" or command == "dailies") then
      UtilityHub.Events:TriggerEvent("TOGGLE_DAILY_FRAME");
    elseif (command == "testcd") then
      ---@type Cooldowns
      local cooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");
      cooldownsModule:TestNotification();
    elseif (command == "migrate") then
      UtilityHub:MigrateDB();
    elseif (command == "update-quest-flags") then
      UtilityHub.Events:TriggerEvent("FORCE_DAILY_QUESTS_FLAG_UPDATE", fragments[2]);
    elseif (command == "execute") then
      local functionName = fragments[3];
      local arg = fragments[4];
      local module = UtilityHub.Addon:GetModule(fragments[2]);
      module[functionName](module, arg);
    else
      UtilityHub.Helpers.Notification:ShowNotification("Command not found");
    end
  end
end

local function RegisterOptions()
  ---@type string|nil
  local parent = nil;
  addonTable.GenerateOptions();

  for _, option in ipairs(UtilityHub.GameOptions.options) do
    UtilityHub.Libs.AceConfig:RegisterOptionsTable(option.key, option.group);
    local _, categoryID = UtilityHub.Libs.AceConfigDialog:AddToBlizOptions(option.key, option.name, parent);
    option.categoryID = categoryID;

    if (option.root) then
      parent = option.name;
    end
  end
end

local function CreateMinimapIcon()
  UtilityHub.Libs.LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "0",
    icon = minimapIcons.NORMAL,
    OnClick = function(self, button)
      if (button == "LeftButton") then
        if (IsShiftKeyDown()) then
          -- UtilityHub.Events:TriggerEvent("TOGGLE_DATA_FRAME");
        else
          if (SettingsPanel:IsShown()) then
            HideUIPanel(SettingsPanel);
          else
            Settings.OpenToCategory(ADDON_NAME);
          end
        end
      elseif (button == "RightButton") then
        if (IsShiftKeyDown()) then
          UtilityHub.Events:TriggerEvent("TOGGLE_DAILY_FRAME");
        else
          UtilityHub.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
        end
      end
    end,
    OnTooltipShow = function(self)
      self:AddDoubleLine(ADDON_NAME,
        UtilityHub.Helpers.Color:AddColorToString("Version " .. UtilityHub.Constants.AddonVersion, "FFB1B1B1"));

      if (UtilityHub.Database.global.options.cooldowns) then
        local textCount;

        if (lastCountReadyCooldowns and lastCountReadyCooldowns > 0) then
          textCount = UtilityHub.Helpers.Color:AddColorToString(
            lastCountReadyCooldowns ..
            " cooldown" .. (lastCountReadyCooldowns > 1 and "s" or "") .. " READY",
            "FF27BD34");
        else
          textCount = "No cooldowns ready";
        end

        self:AddLine(" ");
        self:AddLine(textCount);
      end

      self:AddLine(" ");
      self:AddLine(UtilityHub.Helpers.Color:AddColorToString("[Left Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers.Color:AddColorToString("to open the options", "FFDDFF00"));
      self:AddLine(UtilityHub.Helpers.Color:AddColorToString("[Right Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers.Color:AddColorToString("to open/close cooldowns", "FFDDFF00"));
      self:AddLine(UtilityHub.Helpers.Color:AddColorToString("[Shift + Right Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers.Color:AddColorToString("to open/close daily quests", "FFDDFF00"));
    end
  });
  UtilityHub.Libs.LDBIcon:Register(
    ADDON_NAME,
    UtilityHub.Libs.LDB:GetDataObjectByName(ADDON_NAME),
    UtilityHub.Database.global.minimapIcon
  );

  local frame = UtilityHub.Libs.LDBIcon:GetMinimapButton(ADDON_NAME);
  if (frame) then
    frame:SetFrameLevel(9);
  end
end

local function UpdateCharacter()
  local function GetPlayerIndex(name)
    for index, value in pairs(UtilityHub.Database.global.characters) do
      if (value.name == name) then
        return index;
      end
    end
  end

  ---@type string
  local name = UnitName("player");
  ---@type Cooldowns
  local cooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");
  ---@type Character
  local playerTable = {
    name = name,
    race = select(1, UnitRace("player")),
    className = select(2, UnitClass("player")),
    group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
    cooldownGroup = cooldownsModule:UpdateCurrentCharacterCooldowns(),
  };

  local playerIndex = GetPlayerIndex(name);

  if (playerIndex) then
    playerTable.group = UtilityHub.Database.global.characters[playerIndex].group;
    UtilityHub.Database.global.characters[playerIndex] = playerTable;
  else
    tinsert(UtilityHub.Database.global.characters, playerTable);
  end

  UtilityHub.Events:TriggerEvent("CHARACTER_UPDATED");
end

local function UpdateMinimapIcon(hasNotification)
  local data = UtilityHub.Libs.LDB:GetDataObjectByName(ADDON_NAME);
  data.icon = hasNotification and minimapIcons.NOTIFICATION or minimapIcons.NORMAL;
  UtilityHub.Libs.LDBIcon:Refresh(ADDON_NAME, UtilityHub.Database.global.minimapIcon);
end

-- Events
UtilityHub.Events:OnLoad();
UtilityHub.Events:GenerateCallbackEvents({
  "CHARACTER_UPDATE_NEEDED",
  "CHARACTER_UPDATED",
  "OPTIONS_CHANGED",
  "CHARACTER_DELETED",
  "SHOW_COOLDOWNS_FRAME",
  "HIDE_COOLDOWNS_FRAME",
  "TOGGLE_COOLDOWNS_FRAME",
  "COUNT_READY_COOLDOWNS_CHANGED",
  "TOGGLE_DAILY_FRAME",
  "FORCE_DAILY_QUESTS_FLAG_UPDATE",
  "WHISPER_LIST_UPDATED",
});

UtilityHub.Events:RegisterCallback("CHARACTER_UPDATE_NEEDED", function(_, name)
  UpdateCharacter();
end);

UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "autoBuy") then
    if (UtilityHub.Database.global.options.autoBuy) then
      UtilityHub.Addon:EnableModule("AutoBuy");
    else
      UtilityHub.Addon:DisableModule("AutoBuy");
    end
  end

  if (name == "cooldowns") then
    if (UtilityHub.Database.global.options.cooldowns) then
      UtilityHub.Addon:EnableModule("Cooldowns");
    else
      UtilityHub.Addon:DisableModule("Cooldowns");
    end
  end

  if (name == "dailyQuests") then
    if (UtilityHub.Database.global.options.dailyQuests) then
      UtilityHub.Addon:EnableModule("DailyQuests");
    else
      UtilityHub.Addon:DisableModule("DailyQuests");
    end
  end

  if (name == "tradeExtraInfo") then
    if (UtilityHub.Database.global.options.tradeExtraInfo) then
      UtilityHub.Addon:EnableModule("Trade");
    else
      UtilityHub.Addon:DisableModule("Trade");
    end
  end
end);

UtilityHub.Events:RegisterCallback("COUNT_READY_COOLDOWNS_CHANGED", function(_, count, first)
  UpdateMinimapIcon(count > 0);
end);

EventRegistry:RegisterFrameEventAndCallback("LOADING_SCREEN_DISABLED", function()
  C_Timer.After(2, function()
    UtilityHub.Flags.addonReady = true;
    UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
  end);
end);

EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_WHISPER", function(_, text, name)
  UtilityHub.Database.global.whispers[name] = text;
  UtilityHub.Events:TriggerEvent("WHISPER_LIST_UPDATED", name, text);
end);

function UtilityHub.Addon:OnInitialize()
  InitVariables();
  SetupSlashCommands();
  RegisterOptions();
  CreateMinimapIcon();

  UtilityHub.Integration.Baganator();
  UtilityHub.Integration.Auctionator();
  UtilityHub.Integration.TSM();

  if (UtilityHub.Database.global.options.simpleStatsTooltip) then
    UtilityHub.Addon:EnableModule("Tooltip");
  end

  if (UtilityHub.Database.global.options.autoBuy) then
    UtilityHub.Addon:EnableModule("AutoBuy");
  end

  if (UtilityHub.Database.global.options.cooldowns) then
    UtilityHub.Addon:EnableModule("Cooldowns");
  end

  if (UtilityHub.Database.global.options.dailyQuests) then
    UtilityHub.Addon:EnableModule("DailyQuests");
  end

  if (UtilityHub.Database.global.options.tradeExtraInfo) then
    UtilityHub.Addon:EnableModule("Trade");
  end
end
