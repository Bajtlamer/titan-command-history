local _, ns = ...
-- LibDataBroker object: Titan Panel shows it as a plugin (and any other bar can read it too).
local Titan = {}
ns.Titan = Titan

function Titan.Refresh()
    if Titan.broker then Titan.broker.text = 'History: ' .. ns.History.Count() end
    if ns.Window then ns.Window.Refresh() end
end

function Titan.Initialize()
    local ldb = LibStub and LibStub:GetLibrary('LibDataBroker-1.1', true)
    if not ldb then return end
    Titan.broker = ldb:NewDataObject('TitanCommandHistory', {
        type = 'data source', label = 'History', text = 'History: ' .. ns.History.Count(), icon = 'Interface\\AddOns\\TitanCommandHistory\\Artwork\\AddonIcon',
        OnEnter = function(owner)
            GameTooltip:SetOwner(owner, 'ANCHOR_BOTTOM')
            GameTooltip:AddLine('|cffffd100Titan Command History|r')
            local recent = ns.History.Entries('all')
            for index = 1, math.min(8, #recent) do GameTooltip:AddLine(recent[index].text, 1, 1, 1) end
            if #recent == 0 then GameTooltip:AddLine('|cff9d9d9dNothing saved yet.|r') end
            GameTooltip:AddLine('|cff9d9d9dLeft click: history window. Right click: menu.|r')
            GameTooltip:Show()
        end,
        OnLeave = function() GameTooltip:Hide() end,
        OnClick = function(owner, button)
            if button == 'RightButton' then ns.Menu.Open(owner) else GameTooltip:Hide(); ns.Window.Toggle() end
        end,
    })
    Titan.Refresh()
end
