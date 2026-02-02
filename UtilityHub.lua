local ADDON_NAME, addonTable = ...;
---@class UtilityHub
UtilityHub = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0");
local interfaceVersion = select(4, GetBuildInfo());

UtilityHub:SetDefaultModuleState(false);
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
UtilityHub.LDBIcon = LibStub("LibDBIcon-1.0");
UtilityHub.UTILS = LibStub("Utils-1.0");
UtilityHub.AceConfigDialog = LibStub("AceConfigDialog-3.0");
UtilityHub.Integration = {};
UtilityHub.Helpers = {};
UtilityHub.prefix = "UH";
UtilityHub.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and (interfaceVersion < 20000);
UtilityHub.IsTBC = (interfaceVersion >= 20505) and (interfaceVersion < 30000);
UtilityHub.IsTBCorLater = interfaceVersion >= 20505;

---@type boolean
UtilityHub.addonReady = false;
UtilityHub.Options = setmetatable({}, {
  __index = {
    GetCategoryID = function(self, key)
      for _, value in ipairs(self) do
        if (value.key == key) then
          return value.categoryID;
        end
      end

      return nil;
    end,
  }
});
UtilityHub.tempPreset = {};
UtilityHub.lastCountReadyCooldowns = nil;

-- Defaults
UtilityHub.defaultOptions = {
  -- Tooltip
  simpleStatsTooltip = true,
  -- AutoBuy
  autoBuy = false,
  autoBuyList = {},
  -- Cooldowns
  cooldowns = false,
  cooldowsList = {},
  cooldownPlaySound = false,
  -- DailyQuests
  dailyQuests = false,
};

-- Enums
UtilityHub.Enums = {};
UtilityHub.Enums.CHARACTER_GROUP = {
  UNGROUPED = 0,
  MAIN_ALT = 1,
  BANK = 2,
  CD = 3,
};
UtilityHub.Enums.CHARACTER_GROUP_TEXT = {
  [UtilityHub.Enums.CHARACTER_GROUP.UNGROUPED] = "Ungrouped",
  [UtilityHub.Enums.CHARACTER_GROUP.MAIN_ALT] = "Main/alt",
  [UtilityHub.Enums.CHARACTER_GROUP.BANK] = "Bank",
  [UtilityHub.Enums.CHARACTER_GROUP.CD] = "CD",
};
UtilityHub.Enums.MINIMAP_ICON = {
  NORMAL = "Interface\\Addons\\UtilityHub\\Assets\\Icons\\addon.blp",
  NOTIFICATION = "Interface\\ICONS\\INV_Enchant_FormulaEpic_01.blp",
};

---@enum EnumQuestType
UtilityHub.Enums.QUEST_TYPE = {
  DUNGEON_NORMAL = 0,
  DUNGEON_HEROIC = 1,
  PROFESSION_COOKING = 2,
  PROFESSION_FISHING = 3,
  CONSORTIUM = 4,
  SHATARI_SKYGUARD = 5,
  OGRILA = 6,
  SHATARI_SKYGUARD_AND_OGRILA = 7,
  NETHERWING = 8,
  PVP = 9,
}
---@enum EnumExpansion
UtilityHub.Enums.EXPANSIONS = {
  CLASSIC = 0,
  TBC = 1,
};
UtilityHub.Enums.REPUTATION_STANDING = {
  HATED = 1,
  HOSTILE = 2,
  UNFRIENDLY = 3,
  NEUTRAL = 4,
  FRIENDLY = 5,
  HONORED = 6,
  REVERED = 7,
  EXALTED = 8,
};
UtilityHub.Enums.PERIODICITY = {
  DAILY = 1,
  WEEKLY = 2,
  MONTHLY = 3,
};
---@enum EnumSide
UtilityHub.Enums.SIDE = {
  ALLIANCE = "Alliance",
  HORDE = "Horde",
};

function UtilityHub:InitVariables()
  local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version");
  local oldVersion = nil;

  if (UHdatabase and UHdatabase.global and UHdatabase.global.oldVersion) then
    oldVersion = UHdatabase.global.oldVersion;
  end

  self.db = LibStub("AceDB-3.0"):New("UHdatabase", {
    global = {
      version = version,
      debugMode = false,
      minimapIcon = {
        hide = false,
      },
      options = UtilityHub.defaultOptions,
      presets = {},
      whispers = {},
      ---@type Character[]
      characters = {},
    },
    char = {},
  }, "Default");
  self.db.global.oldVersion = version;

  if (oldVersion and oldVersion ~= version) then
    UtilityHub:MigrateDB(version, oldVersion);
  end
end

function UtilityHub:MigrateDB(version, oldVersion)
  if (version and oldVersion) then
    self.Helpers:ShowNotification("Migrating DB version from " .. oldVersion .. " to " .. version);
  else
    self.Helpers:ShowNotification("Migrating DB version - Forced action without any version change");
  end

  if (#self.db.global.presets > 0) then
    for _, preset in pairs(self.db.global.presets) do
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

  if (not self.db.global.options) then
    self.db.global.options = UtilityHub.defaultOptions;
  end

  if (not self.db.global.options.autoBuyList) then
    self.db.global.options.autoBuyList = UtilityHub.defaultOptions.autoBuyList;
  end

  if (self.db.global.characters) then
    for index, value in ipairs(self.db.global.characters) do
      if (type(value) == "string") then
        local name = self.db.global.characters[index];

        if (name == UnitName("player")) then
          local race = select(2, UnitRace("player"));
          local className = select(2, UnitClass("player"));

          self.db.global.characters[index] = {
            name = name,
            race = race,
            className = className,
            group = nil,
          };
        else
          self.db.global.characters[index] = {
            name = name,
            race = nil,
            className = nil,
            group = nil,
          };
        end
      end
    end
  end

  if (not self.db.global.options.cooldowns) then
    self.db.global.options.cooldowns = false;
  end

  if (not self.db.global.options.cooldowsList) then
    self.db.global.options.cooldowsList = {};
  end
end

function UtilityHub:SetupSlashCommands()
  SLASH_UtilityHub1 = "/UH"
  SLASH_UtilityHub2 = "/uh"
  SlashCmdList.UtilityHub = function(strParam)
    local fragments = {};

    for word in string.gmatch(strParam, "%S+") do
      table.insert(fragments, word);
    end

    local command = (fragments[1] or ""):trim();

    if (command == "") then
      UtilityHub.Helpers:ShowNotification("Type /UH help for commands");
    elseif (command == "help") then
      UtilityHub.Helpers:ShowNotification("Use the following parameters with /UH");
      print("- |cffddff00debug|r");
      print("  Toggle the debug mode");
      print("- |cffddff00options|r");
      print("  Open the options");
      print("- |cffddff00cd or cds|r");
      print("  Toggle cooldowns frame");
      print("- |cffddff00daily or dailies|r");
      print("  Toggle daily frame");
    elseif (command == "debug") then
      UtilityHub.db.global.debugMode = (not UtilityHub.db.global.debugMode);
      local debugText = UtilityHub.db.global.debugMode and "ON" or "OFF";
      UtilityHub.Helpers:ShowNotification("Debug mode " .. debugText);
    elseif (command == "options") then
      Settings.OpenToCategory(ADDON_NAME);
    elseif (command == "cd" or command == "cds") then
      UtilityHub.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
    elseif (command == "daily" or command == "dailies") then
      UtilityHub.Events:TriggerEvent("TOGGLE_DAILY_FRAME");
    elseif (command == "migrate") then
      UtilityHub:MigrateDB();
    elseif (command == "update-quest-flags") then
      UtilityHub.Events:TriggerEvent("FORCE_DAILY_QUESTS_FLAG_UPDATE", fragments[2]);
    elseif (command == "execute") then
      local functionName = fragments[3];
      local arg = fragments[4];
      local module = UtilityHub:GetModule(fragments[2]);
      module[functionName](module, arg);
    else
      UtilityHub.Helpers:ShowNotification("Command not found");
    end
  end
end

function UtilityHub:RegisterOptions()
  local parent = nil;
  addonTable.GenerateOptions();

  for _, option in ipairs(UtilityHub.Options) do
    LibStub("AceConfig-3.0"):RegisterOptionsTable(option.key, option.group);
    local frame, categoryID = UtilityHub.AceConfigDialog:AddToBlizOptions(option.key, option.name, parent);
    option.categoryID = categoryID;

    if (option.root) then
      parent = option.name;
    end
  end
end

function UtilityHub:CreateMinimapIcon()
  LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "0",
    icon = UtilityHub.Enums.MINIMAP_ICON.NORMAL,
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
        UtilityHub.Helpers:AddColorToString("Version " .. C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"), "FFB1B1B1"));

      if (UtilityHub.db.global.options.cooldowns) then
        local textCount;

        if (UtilityHub.lastCountReadyCooldowns and UtilityHub.lastCountReadyCooldowns > 0) then
          textCount = UtilityHub.Helpers:AddColorToString(
            UtilityHub.lastCountReadyCooldowns ..
            " cooldown" .. (UtilityHub.lastCountReadyCooldowns > 1 and "s" or "") .. " READY",
            "FF27BD34");
        else
          textCount = "No cooldowns ready";
        end

        self:AddLine(" ");
        self:AddLine(textCount);
      end

      self:AddLine(" ");
      self:AddLine(UtilityHub.Helpers:AddColorToString("[Left Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers:AddColorToString("to open the options", "FFDDFF00"));
      self:AddLine(UtilityHub.Helpers:AddColorToString("[Right Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers:AddColorToString("to open/close cooldowns", "FFDDFF00"));
      self:AddLine(UtilityHub.Helpers:AddColorToString("[Shift + Right Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers:AddColorToString("to open/close daily quests", "FFDDFF00"));
    end
  });
  UtilityHub.LDBIcon:Register(ADDON_NAME, LDB:GetDataObjectByName(ADDON_NAME), UtilityHub.db.global.minimapIcon);

  local frame = UtilityHub.LDBIcon:GetMinimapButton(ADDON_NAME);
  if (frame) then
    frame:SetFrameLevel(9);
  end
end

function UtilityHub:OnInitialize()
  -- Migration code from the old name, should be
  if (MDHdatabase) then
    UHdatabase = MDHdatabase;
    MDHdatabase = nil;
  end

  UtilityHub:InitVariables();
  UtilityHub:SetupSlashCommands();
  UtilityHub:RegisterOptions();
  UtilityHub:CreateMinimapIcon();

  UtilityHub.Integration.Baganator();
  UtilityHub.Integration.Auctionator();

  if (UtilityHub.db.global.options.simpleStatsTooltip) then
    UtilityHub:EnableModule("Tooltip");
  end

  if (UtilityHub.db.global.options.autoBuy) then
    UtilityHub:EnableModule("AutoBuy");
  end

  if (UtilityHub.db.global.options.cooldowns) then
    UtilityHub:EnableModule("Cooldowns");
  end

  if (UtilityHub.db.global.options.dailyQuests) then
    UtilityHub:EnableModule("DailyQuests");
  end

  if (UtilityHub.db.global.options.tradeExtraInfo) then
    UtilityHub:EnableModule("Trade");
  end
end

function UtilityHub:UpdateCharacter()
  function GetPlayerIndex(name)
    for index, value in pairs(UtilityHub.db.global.characters) do
      if (value.name == name) then
        return index;
      end
    end
  end

  local name = UnitName("player");
  ---@type Character
  local playerTable = {
    name = name,
    race = select(1, UnitRace("player")),
    className = select(2, UnitClass("player")),
    group = UtilityHub.Enums.CHARACTER_GROUP.UNGROUPED,
    cooldownGroup = UtilityHub:GetModule("Cooldowns"):UpdateCurrentCharacterCooldowns(),
  };

  local playerIndex = GetPlayerIndex(name);

  if (playerIndex) then
    playerTable.group = UtilityHub.db.global.characters[playerIndex].group;
    UtilityHub.db.global.characters[playerIndex] = playerTable;
  else
    tinsert(UtilityHub.db.global.characters, playerTable);
  end

  UtilityHub.Events:TriggerEvent("CHARACTER_UPDATED");
end

function UtilityHub:UpdateMinimapIcon(hasNotification)
  local data = LDB:GetDataObjectByName(ADDON_NAME);
  data.icon = hasNotification and UtilityHub.Enums.MINIMAP_ICON.NOTIFICATION or UtilityHub.Enums.MINIMAP_ICON.NORMAL;
  UtilityHub.LDBIcon:Refresh(ADDON_NAME);
end

-- Events
UtilityHub.Events = CreateFromMixins(CallbackRegistryMixin);
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
});

UtilityHub.Events:RegisterCallback("CHARACTER_UPDATE_NEEDED", function(_, name)
  UtilityHub:UpdateCharacter();
end);

UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "autoBuy") then
    if (UtilityHub.db.global.options.autoBuy) then
      UtilityHub:EnableModule("AutoBuy");
    else
      UtilityHub:DisableModule("AutoBuy");
    end
  end

  if (name == "cooldowns") then
    if (UtilityHub.db.global.options.cooldowns) then
      UtilityHub:EnableModule("Cooldowns");
    else
      UtilityHub:DisableModule("Cooldowns");
    end
  end

  if (name == "dailyQuests") then
    if (UtilityHub.db.global.options.dailyQuests) then
      UtilityHub:EnableModule("DailyQuests");
    else
      UtilityHub:DisableModule("DailyQuests");
    end
  end

  if (name == "tradeExtraInfo") then
    if (UtilityHub.db.global.options.tradeExtraInfo) then
      UtilityHub:EnableModule("Trade");
    else
      UtilityHub:DisableModule("Trade");
    end
  end
end);

UtilityHub.Events:RegisterCallback("COUNT_READY_COOLDOWNS_CHANGED", function(_, count, first)
  UtilityHub:UpdateMinimapIcon(count > 0);

  if (not first and count > 0 and UtilityHub.db.global.options.cooldownPlaySound) then
    PlaySoundFile("Interface\\AddOns\\" .. ADDON_NAME .. "\\Assets\\Sounds\\Cooldown_Ready.ogg", "Master");
  end
end);

EventRegistry:RegisterFrameEventAndCallback("LOADING_SCREEN_DISABLED", function()
  C_Timer.After(2, function()
    UtilityHub.addonReady = true;
    UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
  end);
end);

---@class Character
---@field name string
---@field race number
---@field className number
---@field group number
---@field cooldownGroup table<string, CurrentCooldown[]>
