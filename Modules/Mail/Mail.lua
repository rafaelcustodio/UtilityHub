local ADDON_NAME = ...;
local moduleName = 'Mail';
local Module = UtilityHub.Addon:NewModule(moduleName);
---@type Preset
local PresetModule;
---@type Characters
local CharactersModule;
---@type Item
local ItemModule;

UtilityHub.Events:RegisterCallback("PLAYER_GUILD_UPDATE", function(_, name)
  Module:UpdateMailButtons();
end);

function Module:CreateMailIconButtons()
  local previousFrame = nil;

  local function SetPosition(frame)
    if (previousFrame) then
      frame:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    else
      frame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 2, -60);
    end

    previousFrame = frame;
  end

  local function CreateLoadPresetButton()
    -- Load
    MailFrame.LoadPresetButton = UtilityHub.Libs.Utils:CreateIconButton(MailFrame,
      UtilityHub.Helpers.String:ApplyPrefix("LoadPresetButton"));
    SetPosition(MailFrame.LoadPresetButton);

    local iconTexture = MailFrame.LoadPresetButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Calendar\\MoreArrow.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(30, 30);
    iconTexture:SetPoint("CENTER", MailFrame.LoadPresetButton, "CENTER", 1, -5);
    MailFrame.LoadPresetButton:SetFrameLevel(MailFrame.LoadPresetButton:GetFrameLevel() + 1);

    MailFrame.LoadPresetButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.LoadPresetButton.menuMixin = MenuStyle2Mixin;
    MailFrame.LoadPresetButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.LoadPresetButton.menuPoint,
      MailFrame.LoadPresetButton, MailFrame.LoadPresetButton.menuRelativePoint, MailFrame.LoadPresetButton.menuPointX,
      MailFrame.LoadPresetButton.menuPointY));

    -- Events
    MailFrame.LoadPresetButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Load preset", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.LoadPresetButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.LoadPresetButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.LoadPresetButton:SetupMenu(PresetModule:GetLoadPresetGeneratorFunction());

    return MailFrame.LoadPresetButton;
  end

  local function CreateCharactersButton()
    MailFrame.CharactersButton = UtilityHub.Libs.Utils:CreateIconButton(MailFrame,
      UtilityHub.Helpers.String:ApplyPrefix("CharactersButton"));
    SetPosition(MailFrame.CharactersButton);

    local iconTexture = MailFrame.CharactersButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetAtlas("UI-HUD-MicroMenu-Housing-Mouseover");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(24, 24);
    iconTexture:SetPoint("CENTER", MailFrame.CharactersButton, "CENTER", 0, 0);
    MailFrame.CharactersButton:SetFrameLevel(MailFrame.CharactersButton:GetFrameLevel() + 1);

    MailFrame.CharactersButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.CharactersButton.menuMixin = MenuStyle2Mixin;
    MailFrame.CharactersButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.CharactersButton.menuPoint,
      MailFrame.CharactersButton, MailFrame.CharactersButton.menuRelativePoint,
      MailFrame.CharactersButton.menuPointX, MailFrame.CharactersButton.menuPointY));

    -- Events
    MailFrame.CharactersButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Account characters", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.CharactersButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.CharactersButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.CharactersButton:SetupMenu(CharactersModule:GetAccountCharactersGeneratorFunction());

    return MailFrame.CharactersButton;
  end

  local function CreateConfigEmailButton()
    MailFrame.OpenConfigEmailButton = UtilityHub.Libs.Utils:CreateIconButton(MailFrame,
      UtilityHub.Helpers.String:ApplyPrefix("OpenConfigEmailButton"));
    SetPosition(MailFrame.OpenConfigEmailButton);

    local iconTexture = MailFrame.OpenConfigEmailButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Buttons\\UI-OptionsButton.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", MailFrame.OpenConfigEmailButton, "CENTER", 0, 0);
    MailFrame.OpenConfigEmailButton:SetFrameLevel(MailFrame.OpenConfigEmailButton:GetFrameLevel() + 1);

    -- Events
    MailFrame.OpenConfigEmailButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Open configuration", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.OpenConfigEmailButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.OpenConfigEmailButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);

      if (UtilityHub.Libs.AceConfigDialog.OpenFrames[ADDON_NAME .. "_Mail"]) then
        UtilityHub.Libs.AceConfigDialog:Close(ADDON_NAME .. "_Mail");
      else
        UtilityHub.Libs.AceConfigDialog:Open(ADDON_NAME .. "_Mail");
      end
    end);

    return MailFrame.OpenConfigEmailButton;
  end

  local function CreateGuildButton()
    MailFrame.GuildButton = UtilityHub.Libs.Utils:CreateIconButton(MailFrame,
      UtilityHub.Helpers.String:ApplyPrefix("GuildButton"));
    SetPosition(MailFrame.GuildButton);

    local iconTexture = MailFrame.GuildButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\CHATFRAME\\UI-ChatConversationIcon.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", MailFrame.GuildButton, "CENTER", 0, 0);
    MailFrame.GuildButton:SetFrameLevel(MailFrame.GuildButton:GetFrameLevel() + 1);

    MailFrame.GuildButton.menuMixin = MenuStyle2Mixin;
    MailFrame.GuildButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.GuildButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.GuildButton.menuPoint,
      MailFrame.GuildButton, MailFrame.GuildButton.menuRelativePoint,
      MailFrame.GuildButton.menuPointX, MailFrame.GuildButton.menuPointY));

    -- Events
    MailFrame.GuildButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Guild characters", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.GuildButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.GuildButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.GuildButton:SetupMenu(CharactersModule:GetGuildCharactersGeneratorFunction());

    return MailFrame.GuildButton;
  end

  local function CreateItemClassButton()
    -- Load
    MailFrame.ItemTypesButton = UtilityHub.Libs.Utils:CreateIconButton(MailFrame,
      UtilityHub.Helpers.String:ApplyPrefix("ItemTypesButton"));
    SetPosition(MailFrame.ItemTypesButton);

    local iconTexture = MailFrame.ItemTypesButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetAtlas("legionmission-icon-currency");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(30, 30);
    iconTexture:SetPoint("CENTER", MailFrame.ItemTypesButton, "CENTER", 1, 0);
    MailFrame.ItemTypesButton:SetFrameLevel(MailFrame.ItemTypesButton:GetFrameLevel() + 1);

    MailFrame.ItemTypesButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.ItemTypesButton.menuMixin = MenuStyle2Mixin;
    MailFrame.ItemTypesButton:SetMenuAnchor(
      AnchorUtil.CreateAnchor(
        MailFrame.ItemTypesButton.menuPoint,
        MailFrame.ItemTypesButton,
        MailFrame.ItemTypesButton.menuRelativePoint,
        MailFrame.ItemTypesButton.menuPointX,
        MailFrame.ItemTypesButton.menuPointY
      )
    );

    -- Events
    MailFrame.ItemTypesButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Item class/subclass", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.ItemTypesButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.ItemTypesButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.ItemTypesButton:SetupMenu(ItemModule:GetLoadItemGeneratorFunction());

    return MailFrame.ItemTypesButton;
  end

  CreateLoadPresetButton();
  CreateItemClassButton();
  CreateCharactersButton();
  CreateGuildButton();
  CreateConfigEmailButton();

  Module:UpdateMailButtons();
end

function Module:UpdateMailButtons()
  if (MailFrame.GuildButton) then
    if (IsInGuild()) then
      MailFrame.GuildButton:Enable();
    else
      MailFrame.GuildButton:Disable();
    end
  end
end

function Module:OnInitialize()
  EventRegistry:RegisterFrameEventAndCallback("MAIL_SHOW", function()
    if (not UtilityHub.Addon:GetModule("Mail"):IsEnabled()) then
      UtilityHub.Addon:EnableModule("Mail");
    end
  end);
end

function Module:OnEnable()
  PresetModule = UtilityHub.Addon:GetModule("Preset");
  CharactersModule = UtilityHub.Addon:GetModule("Characters");
  ItemModule = UtilityHub.Addon:GetModule("Item");
  Module:CreateMailIconButtons();
end
