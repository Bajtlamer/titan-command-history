local _, ns = ...
-- A round button on the minimap edge, for players who do not use Titan Panel or do not want the plugin there.
-- Left click toggles the window, right click opens the menu, dragging moves it around the minimap.
local Button = {}
ns.MinimapButton = Button

local DEFAULT_ANGLE, OFFSET = 160, 22

function Button.Position(angle, width, height)
    local radians = math.rad(angle)
    return math.cos(radians) * (width / 2 + OFFSET), math.sin(radians) * (height / 2 + OFFSET)
end

function Button.AngleFromCursor(cursorX, cursorY, centerX, centerY)
    local angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
    if angle < 0 then angle = angle + 360 end
    return angle
end

local function place()
    local button = Button.button
    if not button or not Minimap then return end
    local x, y = Button.Position(ns.History.Settings().minimapButtonAngle or DEFAULT_ANGLE, Minimap:GetWidth(), Minimap:GetHeight())
    button:ClearAllPoints()
    button:SetPoint('CENTER', Minimap, 'CENTER', x, y)
end

function Button.Update()
    if Button.button then Button.button:SetShown(ns.History.Settings().showMinimapButton ~= false) end
end

function Button.Attach()
    if Button.button or not Minimap then return end
    local button = CreateFrame('Button', 'TitanCommandHistoryMinimapButton', UIParent)
    Button.button = button
    button:SetSize(32, 32)
    button:SetFrameStrata('MEDIUM')
    button:SetFrameLevel(8)
    local background = button:CreateTexture(nil, 'BACKGROUND')
    background:SetTexture('Interface\\Minimap\\UI-Minimap-Background')
    background:SetSize(24, 24)
    background:SetPoint('CENTER')
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetTexture('Interface\\Icons\\INV_Misc_Note_01')
    icon:SetSize(20, 20)
    icon:SetPoint('CENTER')
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    if button.CreateMaskTexture then
        local mask = button:CreateMaskTexture()
        if mask then
            mask:SetTexture('Interface\\CHARACTERFRAME\\TempPortraitAlphaMask')
            mask:SetAllPoints(icon)
            icon:AddMaskTexture(mask)
        end
    end
    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
    border:SetSize(54, 54)
    border:SetPoint('TOPLEFT')
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:RegisterForDrag('LeftButton')
    button:SetScript('OnClick', function(self, which)
        if which == 'RightButton' then ns.Menu.Open(self) else ns.Window.Toggle() end
    end)
    button:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:AddLine('|cffffd100Titan Command History|r')
        GameTooltip:AddLine('|cff9d9d9d' .. ns.History.Count() .. ' saved lines|r')
        GameTooltip:AddLine('|cff9d9d9dLeft click: history window|r')
        GameTooltip:AddLine('|cff9d9d9dRight click: favorites and settings|r')
        GameTooltip:AddLine('|cff9d9d9dDrag: move around the minimap|r')
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function() GameTooltip:Hide() end)
    button:SetScript('OnDragStart', function(self)
        self:SetScript('OnUpdate', function()
            local centerX, centerY = Minimap:GetCenter()
            if not centerX then return end
            local scale = Minimap:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            ns.History.Settings().minimapButtonAngle = Button.AngleFromCursor(cursorX / scale, cursorY / scale, centerX, centerY)
            place()
        end)
    end)
    button:SetScript('OnDragStop', function(self) self:SetScript('OnUpdate', nil) end)
    place()
    Button.Update()
end
