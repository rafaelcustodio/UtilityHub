-- Mixins
TreeGroupMixin = {};

function TreeGroupMixin:OnEnter()
  self.Label:SetFontObject(GameFontHighlight_NoShadow);
end

function TreeGroupMixin:OnLeave()
  self.Label:SetFontObject(GameFontNormal_NoShadow);
end

function TreeGroupMixin:SetCollapseState(collapsed)
  if (collapsed) then
    self.CollapseIcon:SetTexCoord(0.302246, 0.312988, 0.0537109, 0.0693359)
    self.CollapseIconAlphaAdd:SetTexCoord(0.302246, 0.312988, 0.0537109, 0.0693359)
  else
    self.CollapseIcon:SetTexCoord(0.270508, 0.28125, 0.0537109, 0.0693359)
    self.CollapseIconAlphaAdd:SetTexCoord(0.270508, 0.28125, 0.0537109, 0.0693359)
  end
end
