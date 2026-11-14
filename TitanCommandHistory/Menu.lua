local _, ns = ...
-- The right click menu of the minimap button and of the Titan plugin.
local Menu = {}
ns.Menu = Menu

local function setting(key) return ns.History.Settings()[key] end

function Menu.Open(owner)
    if not MenuUtil or not MenuUtil.CreateContextMenu then ns.Window.Toggle(); return end
    MenuUtil.CreateContextMenu(owner or UIParent, function(_, root)
        root:CreateTitle('Titan Command History ' .. ns.version)
        root:CreateButton('Open history', function() ns.Window.Show() end)
        local quick = root:CreateButton('Quick commands')
        if quick.SetScrollMode then quick:SetScrollMode(350) end
        for _, command in ipairs(ns.History.Quick()) do
            local line = command
            quick:CreateButton(line, function() ns.Actions.Run(line) end)
        end
        if #ns.History.Quick() == 0 then quick:CreateTitle('None yet.') end
        quick:CreateTitle('Add commands from the history window (right click a line).')
        local remove = root:CreateButton('Remove a quick command')
        if remove.SetScrollMode then remove:SetScrollMode(350) end
        for _, command in ipairs(ns.History.Quick()) do
            local line = command
            remove:CreateButton(line, function() ns.History.RemoveQuick(line) end)
        end
        local settings = root:CreateButton('Settings')
        settings:CreateCheckbox('Record conversation lines', function() return setting('recordChat') end, function()
            ns.History.Settings().recordChat = not setting('recordChat')
        end)
        settings:CreateCheckbox('Record only successful input', function() return setting('onlySuccess') end, function()
            ns.History.Settings().onlySuccess = not setting('onlySuccess')
        end)
        settings:CreateCheckbox('Show minimap button', function() return setting('showMinimapButton') ~= false end, function()
            ns.History.Settings().showMinimapButton = setting('showMinimapButton') == false
            ns.MinimapButton.Update()
        end)
        local scope = settings:CreateButton('History is kept for')
        scope:CreateRadio('All characters', function() return setting('scope') ~= 'character' end, function()
            ns.History.Settings().scope = 'account'
        end)
        scope:CreateRadio('This character only', function() return setting('scope') == 'character' end, function()
            ns.History.Settings().scope = 'character'
        end)
        local size = settings:CreateButton('Saved lines')
        for _, value in ipairs({ 100, 250, 500, 1000 }) do
            local max = value
            size:CreateRadio(tostring(max), function() return setting('max') == max end, function()
                ns.History.Settings().max = max
            end)
        end
        local clear = root:CreateButton('Clear history')
        clear:CreateTitle('Pinned lines are kept.')
        clear:CreateButton('Confirm', function()
            ns.History.Clear(true); ns.Window.Refresh(); ns.Titan.Refresh()
        end)
        root:CreateButton('Print the recording log to chat', function() ns.PrintLog() end)
    end)
end
