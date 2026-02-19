local moduleName = "GraphicsSettings";
---@class GraphicsSettings
local Module = UtilityHub.Addon:NewModule(moduleName);

---@class CVarInfo
---@field label string
---@field performance string
---@field quality string

--- All CVars managed by this module
---@type table<string, CVarInfo>
Module.CVARS = {
  graphicsShadowQuality = {
    label = "Shadow Quality",
    performance = "1",
    quality = "3",
  },
  graphicsLiquidDetail = {
    label = "Liquid Detail",
    performance = "1",
    quality = "3",
  },
  graphicsParticleDensity = {
    label = "Particle Density",
    performance = "3",
    quality = "6",
  },
  graphicsSSAO = {
    label = "SSAO",
    performance = "0",
    quality = "1",
  },
  graphicsDepthEffects = {
    label = "Depth Effects",
    performance = "0",
    quality = "1",
  },
  graphicsComputeEffects = {
    label = "Compute Effects",
    performance = "0",
    quality = "1",
  },
  graphicsViewDistance = {
    label = "View Distance",
    performance = "2",
    quality = "5",
  },
  graphicsEnvironmentDetail = {
    label = "Environment Detail",
    performance = "2",
    quality = "5",
  },
  graphicsGroundClutter = {
    label = "Ground Clutter",
    performance = "0",
    quality = "4",
  },
  graphicsProjectedTextures = {
    label = "Projected Textures",
    performance = "1",
    quality = "1",
  },
  textureFilteringMode = {
    label = "Texture Filtering",
    performance = "5",
    quality = "5",
  },
  maxFPSBk = {
    label = "Max FPS (Background)",
    performance = "30",
    quality = "30",
  },
  cameraShake = {
    label = "Camera Shake",
    performance = "0",
    quality = "0",
  },
  gxVSync = {
    label = "VSync",
    performance = "0",
    quality = "0",
  },
};

--- Ordered list of CVar keys for consistent display
Module.CVAR_ORDER = {
  "graphicsShadowQuality",
  "graphicsLiquidDetail",
  "graphicsParticleDensity",
  "graphicsSSAO",
  "graphicsDepthEffects",
  "graphicsComputeEffects",
  "graphicsViewDistance",
  "graphicsEnvironmentDetail",
  "graphicsGroundClutter",
  "graphicsProjectedTextures",
  "textureFilteringMode",
  "maxFPSBk",
  "cameraShake",
  "gxVSync",
};

---@return table|nil
local function GetDB()
  local db = UtilityHub.Database
      and UtilityHub.Database.global
      and UtilityHub.Database.global.options
      and UtilityHub.Database.global.options.graphicsSettings;
  return db;
end

--- Safely get a CVar value via pcall.
---@param cvar string
---@return string|nil
local function SafeGetCVar(cvar)
  local ok, value = pcall(GetCVar, cvar);
  if (ok) then
    return value;
  end
  return nil;
end

--- Safely set a CVar value via pcall.
---@param cvar string
---@param value string
---@return boolean
local function SafeSetCVar(cvar, value)
  local ok = pcall(SetCVar, cvar, value);
  return ok;
end

--- Save current values of all managed CVars to the DB.
function Module:SaveOriginalValues()
  local db = GetDB();
  if (not db) then return end;

  db.originalValues = {};

  for cvar, _ in pairs(self.CVARS) do
    local current = SafeGetCVar(cvar);
    if (current ~= nil) then
      db.originalValues[cvar] = current;
    end
  end
end

--- Apply a preset ("performance" or "quality").
--- Saves original values first if no backup exists yet.
---@param preset string
function Module:ApplyPreset(preset)
  local db = GetDB();
  if (not db) then return end;

  if (not db.originalValues or next(db.originalValues) == nil) then
    self:SaveOriginalValues();
  end

  for cvar, info in pairs(self.CVARS) do
    local value = info[preset];
    if (value) then
      SafeSetCVar(cvar, value);
    end
  end

  db.presetApplied = preset;
end

--- Restore original values saved before any preset was applied.
function Module:RestoreOriginal()
  local db = GetDB();
  if (not db or not db.originalValues) then return end;

  for cvar, value in pairs(db.originalValues) do
    SafeSetCVar(cvar, value);
  end

  db.originalValues = {};
  db.presetApplied = nil;
end

--- Apply a single CVar.
---@param cvar string
---@param value string
function Module:ApplySingleCVar(cvar, value)
  SafeSetCVar(cvar, value);
end

--- Get the current value of a CVar as a string.
---@param cvar string
---@return string
function Module:GetCVarStatus(cvar)
  local value = SafeGetCVar(cvar);
  return value or "N/A";
end

--- Check whether a preset is currently applied.
---@return string|nil
function Module:IsPresetApplied()
  local db = GetDB();
  if (not db) then return nil end;
  return db.presetApplied;
end

function Module:OnEnable()
end

function Module:OnDisable()
end
