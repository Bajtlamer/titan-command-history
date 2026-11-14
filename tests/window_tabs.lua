local passed = 0
local function eq(a, b) assert(a == b, 'expected ' .. tostring(b) .. ', got ' .. tostring(a)) end
local function test(name, fn) local ok, err = pcall(fn); if not ok then error(name .. ': ' .. err) end; passed = passed + 1 end

local function frame(template)
    local f = { scripts = {}, template = template, calls = {}, width = 60 }
    for _, m in ipairs({ 'SetSize', 'SetPoint', 'SetID', 'LockHighlight', 'UnlockHighlight' }) do
        f[m] = function(self, ...) self.calls[m] = { ... } end
    end
    function f:SetText(v) self.text = v end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:Hide() self.shown = false end
    function f:IsShown() return true end
    function f:GetWidth() return self.width end
    function f:SetWidth(v) self.width = v end
    return f
end
local function load()
    local ns = { History = {} }
    assert(loadfile('TitanCommandHistory/Window.lua'))('TitanCommandHistory', ns)
    return ns
end

test('the three tabs use the classic panel tab template and select the active one', function()
    local numTabs, selected
    PanelTemplates_SetNumTabs = function(_, n) numTabs = n end
    PanelTemplates_SetTab = function(_, i) selected = i end
    CreateFrame = function(_, _, _, template) return frame(template) end
    local ns = load()
    local window = frame()
    ns.Window.Tabs(window)
    eq(numTabs, 3); eq(selected, 1); eq(#window.tabButtons, 3)
    eq(window.tabButtons[2].template, 'PanelTabButtonTemplate'); eq(window.tabButtons[2].text, 'Conversations')
    eq(window.tabButtons[3].text, 'Favorites')
    eq(window.tabButtons[3].calls.SetID[1], 3); eq(window.panelTabs, true)
end)

test('clicking a tab selects it and returns to the top of the list', function()
    PanelTemplates_SetNumTabs, PanelTemplates_SetTab = function() end, function() end
    CreateFrame = function(_, _, _, template) return frame(template) end
    local ns = load()
    local window = frame()
    ns.Window.Tabs(window)
    ns.Window.offset = 40
    local refreshed = 0
    ns.Window.Refresh = function() refreshed = refreshed + 1 end
    window.tabButtons[2].scripts.OnClick()
    eq(ns.Window.tab, 'chat'); eq(ns.Window.offset, 0); eq(refreshed, 1)
    window.tabButtons[3].scripts.OnClick(); eq(ns.Window.tab, 'favorite')
end)

test('tabs are measured when created, without the fixed text width, and again after the window is shown', function()
    PanelTemplates_SetNumTabs, PanelTemplates_SetTab = function() end, function() end
    local resized, order, timers = 0, {}, {}
    PanelTemplates_TabResize = function() resized = resized + 1 end
    C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    CreateFrame = function(_, _, _, template)
        local f = frame(template)
        f.Text = { SetWidth = function(_, w) order[#order + 1] = 'set' .. w end,
            GetStringWidth = function() order[#order + 1] = 'get'; return 90 end }
        return f
    end
    local ns = load()
    local window = frame()
    ns.Window.Tabs(window)
    eq(resized, 3 * 2)                        -- at creation and once more from the OnShow call
    eq(order[1], 'set0'); eq(order[2], 'get') -- the fixed text width goes first
    eq(#timers, 3)
    timers[3](); eq(resized, 9)
    window.scripts.OnShow(); eq(resized, 12)
    -- a tab still narrower than its text gets a width of its own
    window.tabButtons[1].width = 72
    PanelTemplates_TabResize = function() end
    window.scripts.OnShow(); eq(window.tabButtons[1].width, 120)
    PanelTemplates_TabResize, C_Timer = nil, nil
end)

test('without the panel tab template the tabs fall back to buttons inside the window', function()
    PanelTemplates_SetNumTabs, PanelTemplates_SetTab = function() end, function() end
    CreateFrame = function(_, _, _, template)
        if template == 'PanelTabButtonTemplate' then error('unknown template') end
        return frame(template)
    end
    local ns = load()
    local window = frame()
    ns.Window.Tabs(window)
    eq(#window.tabButtons, 3); eq(window.tabButtons[1].template, 'UIPanelButtonTemplate'); eq(window.panelTabs, nil)
    PanelTemplates_SetNumTabs, PanelTemplates_SetTab = nil, nil
    window = frame(); ns.Window.Tabs(window)
    eq(window.tabButtons[3].template, 'UIPanelButtonTemplate')
end)

print('PASS window tabs ' .. passed .. ' checks')
