---@class DebugLogViewer
local DebugLogViewer = {};
UtilityHub.DebugLogViewer = DebugLogViewer;

local frame = nil;

function DebugLogViewer:CreateFrame()
  if (frame) then
    return frame;
  end

  frame = CreateFrame("Frame", "UHDebugLogViewerFrame", UIParent, "BasicFrameTemplateWithInset");
  frame:SetSize(800, 600);
  frame:SetPoint("CENTER");
  frame:SetFrameStrata("DIALOG");
  frame:EnableMouse(true);
  frame:SetMovable(true);
  frame:RegisterForDrag("LeftButton");
  frame:SetScript("OnDragStart", frame.StartMoving);
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing);
  frame:Hide();

  frame.title = frame:CreateFontString(nil, "OVERLAY");
  frame.title:SetFontObject("GameFontHighlight");
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.title:SetText("Debug Logs");

  -- Info text
  local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  infoText:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 8, -8);
  infoText:SetText("Press Ctrl+A to select all, then Ctrl+C to copy");
  infoText:SetTextColor(0.7, 0.7, 0.7);

  -- Scrollable edit box for logs
  local scrollFrame = CreateFrame("ScrollFrame", "UHDebugLogScrollFrame", frame, "UIPanelScrollFrameTemplate");
  scrollFrame:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 8, -30);
  scrollFrame:SetPoint("BOTTOMRIGHT", frame.InsetBg, "BOTTOMRIGHT", -26, 8);

  local editBox = CreateFrame("EditBox", "UHDebugLogEditBox", scrollFrame);
  editBox:SetMultiLine(true);
  editBox:SetAutoFocus(false);
  editBox:SetFontObject("ChatFontNormal");
  editBox:SetWidth(scrollFrame:GetWidth());
  editBox:SetScript("OnEscapePressed", function()
    frame:Hide();
  end);

  scrollFrame:SetScrollChild(editBox);
  frame.editBox = editBox;

  -- Buttons
  local buttonPanel = CreateFrame("Frame", nil, frame);
  buttonPanel:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8);
  buttonPanel:SetSize(frame:GetWidth() - 20, 30);

  local refreshBtn = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate");
  refreshBtn:SetSize(100, 25);
  refreshBtn:SetPoint("LEFT", buttonPanel, "LEFT", 10, 0);
  refreshBtn:SetText("Refresh");
  refreshBtn:SetScript("OnClick", function()
    DebugLogViewer:RefreshLogs();
  end);

  local clearBtn = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate");
  clearBtn:SetSize(100, 25);
  clearBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 5, 0);
  clearBtn:SetText("Clear Logs");
  clearBtn:SetScript("OnClick", function()
    UtilityHub.Helpers.DebugLog:Clear();
    DebugLogViewer:RefreshLogs();
    UtilityHub.Helpers.Notification:ShowNotification("Debug logs cleared");
  end);

  local closeBtn = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate");
  closeBtn:SetSize(100, 25);
  closeBtn:SetPoint("RIGHT", buttonPanel, "RIGHT", -10, 0);
  closeBtn:SetText("Close");
  closeBtn:SetScript("OnClick", function()
    frame:Hide();
  end);

  return frame;
end

function DebugLogViewer:RefreshLogs()
  if (not frame) then
    return;
  end

  local logs = UtilityHub.Helpers.DebugLog:Export();
  local count = UtilityHub.Helpers.DebugLog:Count();

  if (logs == "") then
    frame.editBox:SetText("No logs available.\n\nEnable debug mode with: /uh debug");
  else
    frame.editBox:SetText(string.format("Total logs: %d\n%s\n%s", count, string.rep("-", 80), logs));
  end

  frame.editBox:SetCursorPosition(0);
end

function DebugLogViewer:Show()
  local f = DebugLogViewer:CreateFrame();
  DebugLogViewer:RefreshLogs();
  f:Show();
end

function DebugLogViewer:Hide()
  if (frame) then
    frame:Hide();
  end
end

function DebugLogViewer:Toggle()
  local f = DebugLogViewer:CreateFrame();

  if (f:IsShown()) then
    f:Hide();
  else
    DebugLogViewer:Show();
  end
end
