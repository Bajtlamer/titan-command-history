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
        local favorites = root:CreateButton('Favorites')
        if favorites.SetScrollMode then favorites:SetScrollMode(350) end
        for _, favorite in ipairs(ns.History.Favorites()) do
            local line = favorite.text
            favorites:CreateButton(line, function() ns.Actions.Run(line) end)
        end
        if #ns.History.Favorites() == 0 then favorites:CreateTitle('None yet.') end
        favorites:CreateTitle('Add favorites in the history window (right click a line, or type one in the Favorites tab).')
        local remove = root:CreateButton('Remove a favorite')
        if remove.SetScrollMode then remove:SetScrollMode(350) end
        for _, favorite in ipairs(ns.History.Favorites()) do
            local item = favorite
            remove:CreateButton(item.text, function() ns.History.RemoveFavorite(item); ns.Window.Refresh() end)
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
        clear:CreateTitle('Favorites are kept.')
        clear:CreateButton('Confirm', function()
            ns.History.Clear(); ns.Window.Refresh(); ns.Titan.Refresh()
        end)
        root:CreateButton('Print the recording log to chat', function() ns.PrintLog() end)
    end)
end
