local ADDON_NAME, addonTable = ...;

---@class UtilityHub
UtilityHub = {
  Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0"),
  Libs = {
    LDBIcon = LibStub("LibDBIcon-1.0"),
    AceDB = LibStub("AceDB-3.0"),
    AceConfigDialog = LibStub("AceConfigDialog-3.0"),
    AceConfig = LibStub("AceConfig-3.0"),
    LDB = LibStub:GetLibrary("LibDataBroker-1.1"),
    Utils = LibStub("Utils-1.0"),
  },
  ---@type Constants
  ---@diagnostic disable-next-line: missing-fields
  Constants = {},
  GameOptions = {
    defaults = {
      -- Tooltip
      simpleStatsTooltip = true,
      -- AutoBuy
      autoBuy = false,
      autoBuyList = {},
      -- Cooldowns
      cooldowns = true,
      cooldowsList = {},
      cooldownPlaySound = true,
      cooldownStartCollapsed = false,
      cooldownSync = false,
      cooldownSyncChannel = "",
      -- DailyQuests
      dailyQuests = false,
      -- Trade
      tradeExtraInfo = false,
    },
    ---@type Option[]
    options = {},
    category = nil,
    subcategories = {},
    Register = function() end,
    OpenConfig = function(category)
      if (not category) then
        category = UtilityHub.GameOptions.category;
      end

      if (not category or not category.GetID) then
        return;
      end

      Settings.OpenToCategory(category:GetID());
    end,
  },
  Integration = {},
  ---@type Helpers
  ---@diagnostic disable-next-line: missing-fields
  Helpers = {},
  Flags = {
    ---@type boolean
    addonReady = false,
    ---@type boolean
    tsmLoaded = false,
    ---@type Frame|nil
    tsmMailFrame = nil,
  },
  Database = {},
  Events = CreateFromMixins(CallbackRegistryMixin),
  ---@param version string|nil
  ---@param oldVersion string|nil
  MigrateDB = function(self, version, oldVersion)
    if (version and oldVersion) then
      UtilityHub.Helpers.Notification:ShowNotification("Migrating DB version from " .. oldVersion .. " to " .. version);
    else
      UtilityHub.Helpers.Notification:ShowNotification("Trying to fix DB");
    end

    ---@type Preset
    local presetModule = UtilityHub.Addon:GetModule("Preset");

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

        if (not preset.id) then
          preset.id = presetModule:GetNextID();
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
};

UtilityHub.Addon:SetDefaultModuleState(false);
