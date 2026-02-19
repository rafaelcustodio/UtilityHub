local ADDON_NAME = ...;

---@class GraphicsSettingsPage
local GraphicsSettingsPage = {};

---@return table
local function GetDB()
  return UtilityHub.Database.global.options.graphicsSettings;
end

---@return GraphicsSettings
local function GetModule()
  ---@type GraphicsSettings
  return UtilityHub.Addon:GetModule("GraphicsSettings");
end

local function ShowReloadPopup()
  StaticPopupDialogs["UTILITYHUB_GRAPHICS_RELOAD"] = {
    text = "Graphics settings applied.\nReload the UI now for all changes to take effect?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function()
      ReloadUI();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
  StaticPopup_Show("UTILITYHUB_GRAPHICS_RELOAD");
end

---@param parent Frame
---@param text string
---@param onClick fun()
---@param anchor Frame
---@return Button
local function CreatePresetButton(parent, text, onClick, anchor)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
  button:SetSize(130, 26);
  button:SetText(text);
  button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);
  button:SetScript("OnClick", function()
    onClick();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
  end);
  return button;
end

---@param parent Frame
---@return Frame
function GraphicsSettingsPage:Create(parent)
  local outerFrame = CreateFrame("Frame", "UtilityHubGraphicsSettingsPage", parent);

  -- Scrollable content
  local scrollFrame = CreateFrame("ScrollFrame", nil, outerFrame, "UIPanelScrollFrameTemplate");
  scrollFrame:SetPoint("TOPLEFT", 0, 0);
  scrollFrame:SetPoint("BOTTOMRIGHT", -26, 0);

  local content = CreateFrame("Frame", nil, scrollFrame);
  content:SetSize(560, 1);
  scrollFrame:SetScrollChild(content);

  -- Title
  local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("Graphics Settings");

  -- Description
  local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
  desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8);
  desc:SetWidth(480);
  desc:SetJustifyH("LEFT");
  desc:SetText(
    "Apply graphics presets tuned for Classic Anniversary. " ..
    "Original values are saved automatically before the first change."
  );

  -- Section: Presets
  local sectionPresets = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionPresets:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16);
  sectionPresets:SetText("Presets");

  local btnPerformance = CreatePresetButton(
    content,
    "Performance",
    function()
      GetModule():ApplyPreset("performance");
      ShowReloadPopup();
    end,
    sectionPresets
  );

  local btnQuality = CreatePresetButton(
    content,
    "Quality",
    function()
      GetModule():ApplyPreset("quality");
      ShowReloadPopup();
    end,
    sectionPresets
  );
  btnQuality:ClearAllPoints();
  btnQuality:SetPoint("LEFT", btnPerformance, "RIGHT", 8, 0);
  btnQuality:SetPoint("TOP", btnPerformance, "TOP", 0, 0);

  local btnRestore = CreatePresetButton(
    content,
    "Restore Original",
    function()
      GetModule():RestoreOriginal();
      ShowReloadPopup();
    end,
    sectionPresets
  );
  btnRestore:ClearAllPoints();
  btnRestore:SetPoint("LEFT", btnQuality, "RIGHT", 8, 0);
  btnRestore:SetPoint("TOP", btnQuality, "TOP", 0, 0);

  -- Current preset label
  local presetStatus = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
  presetStatus:SetPoint("TOPLEFT", btnPerformance, "BOTTOMLEFT", 0, -8);

  local function UpdatePresetStatus()
    local applied = GetModule():IsPresetApplied();
    if (applied) then
      local label = applied == "performance" and "Performance" or "Quality";
      presetStatus:SetText("|cffffff00Active preset:|r " .. label);
    elseif (GetDB().originalValues and next(GetDB().originalValues) ~= nil) then
      presetStatus:SetText("|cffff9900Original backup exists (no active preset)|r");
    else
      presetStatus:SetText("|cff808080No preset active|r");
    end
  end

  UpdatePresetStatus();

  outerFrame:SetScript("OnShow", function()
    UpdatePresetStatus();
  end);

  -- Section: CVar list
  local sectionCVars = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionCVars:SetPoint("TOPLEFT", presetStatus, "BOTTOMLEFT", 0, -18);
  sectionCVars:SetText("Current Values");

  -- Column headers
  local headerLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
  headerLabel:SetPoint("TOPLEFT", sectionCVars, "BOTTOMLEFT", 0, -8);
  headerLabel:SetText("Setting");
  headerLabel:SetWidth(200);

  local headerCurrent = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
  headerCurrent:SetPoint("LEFT", headerLabel, "RIGHT", 10, 0);
  headerCurrent:SetText("Current");
  headerCurrent:SetWidth(80);

  local headerPerf = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
  headerPerf:SetPoint("LEFT", headerCurrent, "RIGHT", 10, 0);
  headerPerf:SetText("Perf.");
  headerPerf:SetWidth(50);

  local headerQual = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
  headerQual:SetPoint("LEFT", headerPerf, "RIGHT", 10, 0);
  headerQual:SetText("Quality");
  headerQual:SetWidth(50);

  -- Divider line
  local divider = content:CreateTexture(nil, "BACKGROUND");
  divider:SetHeight(1);
  divider:SetPoint("TOPLEFT", headerLabel, "BOTTOMLEFT", 0, -4);
  divider:SetPoint("RIGHT", content, "RIGHT", -20, 0);
  divider:SetColorTexture(0.4, 0.4, 0.4, 0.6);

  -- CVar rows
  local module = GetModule();
  local prevAnchor = divider;
  local rowFrames = {};

  for _, cvar in ipairs(module.CVAR_ORDER) do
    local info = module.CVARS[cvar];
    if (info) then
      local row = CreateFrame("Frame", nil, content);
      row:SetHeight(18);
      row:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -2);
      row:SetPoint("RIGHT", content, "RIGHT", -20, 0);

      local rowBg = row:CreateTexture(nil, "BACKGROUND");
      rowBg:SetAllPoints();
      rowBg:SetColorTexture(0.1, 0.1, 0.1, 0.2);

      local labelFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
      labelFS:SetPoint("LEFT", 0, 0);
      labelFS:SetWidth(200);
      labelFS:SetJustifyH("LEFT");
      labelFS:SetText(info.label);

      local currentFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
      currentFS:SetPoint("LEFT", labelFS, "RIGHT", 10, 0);
      currentFS:SetWidth(80);
      currentFS:SetJustifyH("LEFT");
      currentFS:SetText(module:GetCVarStatus(cvar));

      local perfFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
      perfFS:SetPoint("LEFT", currentFS, "RIGHT", 10, 0);
      perfFS:SetWidth(50);
      perfFS:SetJustifyH("LEFT");
      perfFS:SetText(info.performance);

      local qualFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
      qualFS:SetPoint("LEFT", perfFS, "RIGHT", 10, 0);
      qualFS:SetWidth(50);
      qualFS:SetJustifyH("LEFT");
      qualFS:SetText(info.quality);

      row.currentFS = currentFS;
      row.cvar = cvar;
      tinsert(rowFrames, row);
      prevAnchor = row;
    end
  end

  local rowCount = #module.CVAR_ORDER;
  content:SetHeight(340 + rowCount * 22);

  -- Refresh current values when visible
  outerFrame:HookScript("OnShow", function()
    for _, row in ipairs(rowFrames) do
      row.currentFS:SetText(module:GetCVarStatus(row.cvar));
    end
    UpdatePresetStatus();
  end);

  outerFrame:SetAllPoints(parent);
  return outerFrame;
end

-- Register page
UtilityHub.OptionsPages.GraphicsSettings = GraphicsSettingsPage;
